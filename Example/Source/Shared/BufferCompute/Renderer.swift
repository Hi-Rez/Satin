//
//  Renderer.swift
//  Example
//
//  Created by Reza Ali on 6/25/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin

class SpriteMaterial: LiveMaterial {}
class ChromaMaterial: LiveMaterial {}

class Renderer: Forge.Renderer {
    var assetsURL: URL {
        let resourcesURL = Bundle.main.resourceURL!
        return resourcesURL.appendingPathComponent("Assets")
    }
    
    var pipelinesURL: URL {
        return assetsURL.appendingPathComponent("Pipelines")
    }
    
    var metalFileCompiler = MetalFileCompiler()
    
    var countParam = IntParameter("Count", 4096, .inputfield)
    
    lazy var computeSystem: BufferComputeSystem = {
        BufferComputeSystem(context: context, count: countParam.value)
    }()
    
    var computeParams: ParameterGroup?
    var computeUniforms: UniformBuffer?
    
    lazy var spriteMaterial: SpriteMaterial = {
        let material = SpriteMaterial(pipelinesURL: pipelinesURL)
        material.blending = .additive
        material.depthWriteEnabled = false
        return material
    }()
    
    lazy var mesh: Mesh = {
        let mesh = Mesh(geometry: PointGeometry(), material: spriteMaterial)
        mesh.instanceCount = countParam.value
        return mesh
    }()
    
    lazy var scene: Object = {
        let scene = Object()
        scene.add(mesh)
        return scene
    }()
    
    lazy var context: Context = {
        Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }()
    
    lazy var camera: PerspectiveCamera = {
        let camera = PerspectiveCamera()
        camera.position = simd_make_float3(0.0, 0.0, 100.0)
        camera.near = 0.001
        camera.far = 1000.0
        return camera
    }()
    
    lazy var cameraController: PerspectiveCameraController = {
        PerspectiveCameraController(camera: camera, view: mtkView)
    }()
    
    lazy var renderer: Satin.Renderer = {
        Satin.Renderer(context: context, scene: scene, camera: camera)
    }()
    
    var startTime: CFAbsoluteTime = 0.0
    
    // MARK: Render to Texture
    var renderTexture: MTLTexture!
    var updateRenderTexture: Bool = true
    
    lazy var chromaMaterial: ChromaMaterial = {
        let material = ChromaMaterial(pipelinesURL: pipelinesURL)
        return material
    }()
    
    lazy var chromaticProcessor: PostProcessor = {
        let pp = PostProcessor(context: Context(context.device, context.sampleCount, context.colorPixelFormat, .invalid, .invalid), material: chromaMaterial)
        pp.mesh.preDraw = { [unowned self] (renderEncoder: MTLRenderCommandEncoder) -> Void in
            renderEncoder.setFragmentTexture(self.renderTexture, index: FragmentTextureIndex.Custom0.rawValue)
        }
//        pp.mesh.material = chromaMaterial
        pp.label = "Chroma Processor"
        return pp
    }()
    
    required init?(metalKitView: MTKView) {
        super.init(metalKitView: metalKitView)
    }
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.colorPixelFormat = .bgra8Unorm
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
    }
    
    override func setup() {
        setupMetalCompiler()
        setupLibrary()
        setupMeshPreDraw()
        setupBufferComputePreCompute()
        setupChromaticProcessor()
        startTime = CFAbsoluteTimeGetCurrent()
    }
    
    override func update() {
        if updateRenderTexture {
            renderTexture = createTexture("Render Texture", context.colorPixelFormat)
            updateRenderTexture = false
        }
        
        var time = Float(CFAbsoluteTimeGetCurrent() - startTime)
        chromaMaterial.set("Time", time)
        
        time *= 0.25;
        let radius: Float = 10.0 * sin(time * 0.5) * cos(time)
        camera.position = simd_make_float3(radius * sin(time), radius * cos(time), 100.0)
        
        updateBufferComputeUniforms()
        cameraController.update()
        renderer.update()
        chromaticProcessor.update()
    }
    
    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        computeSystem.update(commandBuffer)
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        renderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer, renderTarget: renderTexture)
        
        chromaticProcessor.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
    }
    
    override func resize(_ size: (width: Float, height: Float)) {
        camera.aspect = size.width / size.height
        renderer.resize(size)
        chromaticProcessor.resize(size)
        updateRenderTexture = true
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
    
    func setupMeshPreDraw() {
        mesh.preDraw = { [unowned self] (renderEncoder: MTLRenderCommandEncoder) in
            if let buffer = self.computeSystem.getBuffer("Particle") {
                renderEncoder.setVertexBuffer(buffer, offset: 0, index: VertexBufferIndex.Custom0.rawValue)
            }
        }
    }
    
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
            
            if let params = parseStruct(source: librarySource, key: "Particle") {
                computeSystem.setParams([params])
            }
            
            if let params = parseParameters(source: librarySource, key: "ComputeUniforms") {
                params.label = "Compute"
                computeUniforms = UniformBuffer(context: context, parameters: params)
                computeParams = params
            }
            
            setupBufferCompute(library)
        }
        catch let MetalFileCompilerError.invalidFile(fileURL) {
            print("Invalid File: \(fileURL.absoluteString)")
        }
        catch {
            print("Error: \(error)")
        }
    }
    
    func setupBufferCompute(_ library: MTLLibrary) {
        do {
            computeSystem.resetPipeline = try makeComputePipeline(library: library, kernel: "resetCompute")
            computeSystem.updatePipeline = try makeComputePipeline(library: library, kernel: "updateCompute")
            computeSystem.reset()
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func setupBufferComputePreCompute() {
        computeSystem.preCompute = { [unowned self] (computeEncoder: MTLComputeCommandEncoder, bufferOffset: Int, _: Int) in
            var offset = bufferOffset
            
            if let uniforms = self.computeUniforms {
                computeEncoder.setBuffer(uniforms.buffer, offset: uniforms.offset, index: offset)
                offset += 1
            }
        }
    }
    
    func updateBufferComputeUniforms() {
        if let uniforms = self.computeUniforms {
            uniforms.parameters.set("Count", countParam.value)
            uniforms.update()
        }
    }
    
    func createTexture(_ label: String, _ pixelFormat: MTLPixelFormat) -> MTLTexture? {
        if mtkView.drawableSize.width > 0, mtkView.drawableSize.height > 0 {
            let descriptor = MTLTextureDescriptor()
            descriptor.pixelFormat = pixelFormat
            descriptor.width = Int(mtkView.drawableSize.width)
            descriptor.height = Int(mtkView.drawableSize.height)
            descriptor.sampleCount = 1
            descriptor.textureType = .type2D
            descriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
            descriptor.storageMode = .private
            descriptor.resourceOptions = .storageModePrivate
            guard let texture = context.device.makeTexture(descriptor: descriptor) else { return nil }
            texture.label = label
            return texture
        }
        return nil
    }
    
    func setupChromaticProcessor() {}
    
    func setupChromaticMeshPreDraw() {}
}
