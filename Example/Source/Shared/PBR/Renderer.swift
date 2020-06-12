//
//  Renderer.swift
//  Cubemap
//
//  Created by Reza Ali on 6/7/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//
//  Cube Map Texture (quarry_01) from: https://hdrihaven.com/hdri/
//

import Metal
import MetalKit

import Forge
import Satin

class CustomMaterial: LiveMaterial {}

class Renderer: Forge.Renderer {
    var metalFileCompiler = MetalFileCompiler()
    
    var assetsURL: URL {
        let resourcesURL = Bundle.main.resourceURL!
        return resourcesURL.appendingPathComponent("Assets")
    }
    
    var texturesURL: URL {
        return assetsURL.appendingPathComponent("Textures")
    }
    
    var modelsURL: URL {
        return assetsURL.appendingPathComponent("Models")
    }
    
    var pipelinesURL: URL {
        return assetsURL.appendingPathComponent("Pipelines")
    }
    
    lazy var scene: Object = {
        let scene = Object()
        scene.add(mesh)
//        scene.add(debugMesh)
        return scene
    }()
    
    lazy var cubeTexture: MTLTexture? = {
        let url = texturesURL.appendingPathComponent("Cubemap")
        
        let texture = makeCubeTexture(
            context,
            [
                url.appendingPathComponent("px.png"),
                url.appendingPathComponent("nx.png"),
                url.appendingPathComponent("py.png"),
                url.appendingPathComponent("ny.png"),
                url.appendingPathComponent("pz.png"),
                url.appendingPathComponent("nz.png"),
            ],
            true // <- generates mipmaps
        )
        
        if let texture = texture, let material = skybox.material as? SkyboxMaterial {
            material.texture = texture
        }
        
        return texture
    }()
    
    lazy var context: Context = {
        Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }()
    
    lazy var camera: ArcballPerspectiveCamera = {
        let camera = ArcballPerspectiveCamera()
        camera.position = simd_make_float3(0.0, 0.0, 30.0)
        camera.near = 0.001
        camera.far = 1000.0
        return camera
    }()
    
    lazy var cameraController: ArcballCameraController = {
        ArcballCameraController(camera: camera, view: mtkView, defaultPosition: camera.position, defaultOrientation: camera.orientation)
    }()
    
    lazy var renderer: Satin.Renderer = {
        let renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
        return renderer
    }()
    
    lazy var mesh: Mesh = {
        let mesh = Mesh(geometry: IcoSphereGeometry(radius: 1.0, res: 3), material: customMaterial)
        mesh.cullMode = .none
        mesh.label = "Sphere"
        mesh.instanceCount = 49
        return mesh
    }()
    
    lazy var customMaterial: CustomMaterial = {
        CustomMaterial(pipelineURL: pipelinesURL.appendingPathComponent("Shaders.metal"))
    }()
    
    lazy var skybox: Mesh = {
        let mesh = Mesh(geometry: SkyboxGeometry(), material: SkyboxMaterial())
        mesh.label = "Skybox"
        mesh.scale = [50, 50, 50]
        scene.add(mesh)
        return mesh
    }()
    
    required init?(metalKitView: MTKView) {
        super.init(metalKitView: metalKitView)
    }
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 8
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
        metalKitView.colorPixelFormat = .bgra8Unorm
    }
    
    lazy var integrationTextureCompute: TextureComputeSystem = {
        let compute = TextureComputeSystem(
            context: context,
            textureDescriptor: MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rg16Float, width: 512, height: 512, mipmapped: false)
        )
        return compute
    }()
    
    lazy var diffuseTextureCompute: TextureComputeSystem = {
        let compute = TextureComputeSystem(
            context: context,
            textureDescriptor: MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .rgba16Float, size: 64, mipmapped: false)
        )
        compute.preCompute = { [unowned self] (computeEncoder: MTLComputeCommandEncoder, offset: Int) in
            computeEncoder.setTexture(self.cubeTexture, index: offset)
        }
        
        return compute
    }()
    
    var roughnessParameter = FloatParameter("roughness", 0)
    var faceParameter = IntParameter("face", 0)
    
    lazy var specularTextureComputeParameters: ParameterGroup = {
        let params = ParameterGroup("SpecularParameters")
        params.append(roughnessParameter)
        params.append(faceParameter)
        return params
    }()
    
    lazy var specularTextureComputeUniforms: Buffer = {
        let buffer = Buffer(context: context, parameters: specularTextureComputeParameters)
        return buffer
    }()
    
    lazy var specularTextureCompute: TextureComputeSystem = {
        let compute = TextureComputeSystem(
            context: context,
            textureDescriptor: MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float, width: 512, height: 512, mipmapped: false)
        )
        compute.preCompute = { [unowned self] (computeEncoder: MTLComputeCommandEncoder, offset: Int) in
            computeEncoder.setTexture(self.cubeTexture, index: offset)
            computeEncoder.setBuffer(self.specularTextureComputeUniforms.buffer, offset: 0, index: 0)
        }
        return compute
    }()
    
    lazy var debugMesh: Mesh = {
        let mesh = Mesh(geometry: PlaneGeometry(size: 10), material: BasicTextureMaterial(texture: integrationTextureCompute.texture))
        mesh.position = [0, 0, -5]
        return mesh
    }()
    
    var diffuseCubeTexture: MTLTexture?
    lazy var specularCubeTexture: MTLTexture? = {
        let cubeDesc = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .rgba16Float, size: 512, mipmapped: true)
        return device.makeTexture(descriptor: cubeDesc)
    }()
    
    override func setup() {
        setupMetalCompiler()
        setupLibrary()
        
        setupMeshPreDraw()
        #if os(macOS)
//        openEditor()
        #endif
    }
    
    func setupMeshPreDraw() {
        mesh.preDraw = { [unowned self] (renderEncoder: MTLRenderCommandEncoder) in
            renderEncoder.setFragmentTexture(self.diffuseTextureCompute.texture, index: FragmentTextureIndex.Custom0.rawValue)
            if let specularCubeTexture = self.specularCubeTexture {
                renderEncoder.setFragmentTexture(specularCubeTexture, index: FragmentTextureIndex.Custom1.rawValue)
            }
            renderEncoder.setFragmentTexture(self.integrationTextureCompute.texture, index: FragmentTextureIndex.Custom2.rawValue)
        }
    }
    
    override func update() {
        if let material = skybox.material as? SkyboxMaterial {
            material.texture = diffuseTextureCompute.texture
////            material.texture = specularCubeTexture
        }
        
        cameraController.update()
        renderer.update()
    }
    
    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        renderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
    }
    
    override func resize(_ size: (width: Float, height: Float)) {
        let aspect = size.width / size.height
        camera.aspect = aspect
        renderer.resize(size)
    }
    
    #if os(macOS)
    func openEditor() {
        if let editorPath = UserDefaults.standard.string(forKey: "Editor") {
            NSWorkspace.shared.openFile(assetsURL.path, withApplication: editorPath)
        }
        else {
            let openPanel = NSOpenPanel()
            openPanel.canChooseFiles = true
            openPanel.allowsMultipleSelection = false
            openPanel.canCreateDirectories = false
            openPanel.begin(completionHandler: { [unowned self] (result: NSApplication.ModalResponse) in
                if result == .OK {
                    if let editorUrl = openPanel.url {
                        let editorPath = editorUrl.path
                        UserDefaults.standard.set(editorPath, forKey: "Editor")
                        NSWorkspace.shared.openFile(self.assetsURL.path, withApplication: editorPath)
                    }
                }
                openPanel.close()
            })
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if event.characters == "e" {
            openEditor()
        }
    }
    #endif
    
    func setupMetalCompiler() {
        metalFileCompiler.onUpdate = { [unowned self] in
            self.setupLibrary()
        }
    }
    
    // MARK: Setup Library
    
    func setupLibrary() {
        print("Compiling Library")
        do {
            let librarySource = try metalFileCompiler.parse(pipelinesURL.appendingPathComponent("Compute/Shaders.metal"))
            let library = try context.device.makeLibrary(source: librarySource, options: .none)
            setupCompute(library, integrationTextureCompute, "integrationCompute")
            setupCompute(library, diffuseTextureCompute, "diffuseCompute")
            setupSpecularCompute(library)
            
        }
        catch let MetalFileCompilerError.invalidFile(fileURL) {
            print("Invalid File: \(fileURL.absoluteString)")
        }
        catch {
            print("Error: \(error)")
        }
    }
    
    func setupCompute(_ library: MTLLibrary, _ computeSystem: TextureComputeSystem, _ kernel: String) {
        do {
            let pipeline = try makeComputePipeline(library: library, kernel: kernel)
            computeSystem.updatePipeline = pipeline
            
            if let commandQueue = self.device.makeCommandQueue(), let commandBuffer = commandQueue.makeCommandBuffer() {
                computeSystem.update(commandBuffer)
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()
            }
        }
        catch {
            print(error)
        }
    }
    
    func setupSpecularCompute(_ library: MTLLibrary) {
        do {
            let pipeline = try makeComputePipeline(library: library, kernel: "specularCompute")
            specularTextureCompute.updatePipeline = pipeline
            
            guard let cubeTexture = specularCubeTexture else { return }
            let levels = cubeTexture.mipmapLevelCount
            
            var size = cubeTexture.width
            for level in 0..<levels {
                print("Level: \(level)")
                print("Size: \(size)")
                specularTextureCompute.textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float, width: size, height: size, mipmapped: false)
                
                if let commandQueue = self.device.makeCommandQueue() {
                    for slice in 0..<6 {
                        print("Slice: \(slice)")
                        
                        if let commandBuffer = commandQueue.makeCommandBuffer() {
                            faceParameter.value = slice
                            roughnessParameter.value = Float(level) / Float(levels - 1)
                            
                            specularTextureComputeUniforms.update()
                            specularTextureCompute.update(commandBuffer)
                            
                            commandBuffer.commit()
                            commandBuffer.waitUntilCompleted()
                        }
                        
                        if let commandBuffer = commandQueue.makeCommandBuffer() {
                            if let blitEncoder = commandBuffer.makeBlitCommandEncoder() {
                                if let texture = specularTextureCompute.texture {
                                    blitEncoder.copy(from: texture, sourceSlice: 0, sourceLevel: 0, to: cubeTexture, destinationSlice: slice, destinationLevel: level, sliceCount: 1, levelCount: 1)
                                }
                                blitEncoder.endEncoding()
                            }
                            commandBuffer.commit()
                            commandBuffer.waitUntilCompleted()
                        }
                    }
                }
                size /= 2
            }
        }
        catch {
            print(error)
        }
    }
}
