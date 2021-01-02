//
//  Renderer.swift
//  Cubemap
//
//  Created by Reza Ali on 6/7/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//
//  PBR Code from: https://learnopengl.com/PBR/
//  Cube Map Texture from: https://hdrihaven.com/hdri/
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
        scene.add(debugMesh)
        return scene
    }()
    
    lazy var context: Context = {
        Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }()
    
    lazy var camera: PerspectiveCamera = {
        let camera = PerspectiveCamera()
        camera.position = simd_make_float3(0.0, 0.0, 40.0)
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
    
    lazy var mesh: Mesh = {
        let mesh = Mesh(geometry: IcoSphereGeometry(radius: 1.0, res: 3), material: customMaterial)
        mesh.label = "Sphere"
        mesh.instanceCount = 49
        mesh.preDraw = { [unowned self] (renderEncoder: MTLRenderCommandEncoder) in
            renderEncoder.setFragmentTexture(self.diffuseCubeTexture, index: FragmentTextureIndex.Custom0.rawValue)
            renderEncoder.setFragmentTexture(self.specularCubeTexture, index: FragmentTextureIndex.Custom1.rawValue)
            renderEncoder.setFragmentTexture(self.integrationTextureCompute.texture, index: FragmentTextureIndex.Custom2.rawValue)
        }
        return mesh
    }()
    
    lazy var customMaterial: CustomMaterial = {
        CustomMaterial(pipelineURL: pipelinesURL.appendingPathComponent("Shaders.metal"))
    }()
    
    lazy var skybox: Mesh = {
        let mesh = Mesh(geometry: SkyboxGeometry(), material: SkyboxMaterial())
        mesh.label = "Skybox"
        mesh.scale = [150, 150, 150]
        scene.add(mesh)
        return mesh
    }()
    
    lazy var debugMesh: Mesh = {
        let mesh = Mesh(geometry: PlaneGeometry(size: 10), material: BasicTextureMaterial(texture: integrationTextureCompute.texture))
        mesh.label = "Debug"
        mesh.position = [0, 0, -5]
        mesh.visible = false
        return mesh
    }()
    
    lazy var integrationTextureCompute: TextureComputeSystem = {
        let compute = TextureComputeSystem(
            context: context,
            textureDescriptor: MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rg16Float, width: 512, height: 512, mipmapped: false)
        )
        return compute
    }()
    
    // Diffuse (Irradiance) Computation
    
    lazy var diffuseTextureCompute: MultipleTextureComputeSystem = {
        let compute = MultipleTextureComputeSystem(
            context: context,
            textureDescriptors: []
        )
        compute.preCompute = { [unowned self] (computeEncoder: MTLComputeCommandEncoder, offset: Int) in
            computeEncoder.setTexture(self.hdrCubemapTexture, index: offset)
        }
        return compute
    }()
    
    // HDRI to Cubemap Computation
    
    lazy var cubemapTextureCompute: MultipleTextureComputeSystem = {
        let compute = MultipleTextureComputeSystem(
            context: context,
            textureDescriptors: []
        )
        
        compute.preCompute = { [unowned self] (computeEncoder: MTLComputeCommandEncoder, offset: Int) in
            computeEncoder.setTexture(self.hdriTexture, index: offset)
        }
        
        return compute
    }()
    
    // Specular Computation
    
    var roughnessParameter = FloatParameter("roughness", 0)
    
    lazy var specularTextureComputeParameters: ParameterGroup = {
        let params = ParameterGroup("SpecularParameters")
        params.append(roughnessParameter)
        return params
    }()
    
    lazy var specularTextureComputeUniforms: Buffer = {
        let buffer = Buffer(context: context, parameters: specularTextureComputeParameters)
        return buffer
    }()
    
    lazy var specularTextureCompute: MultipleTextureComputeSystem = {
        let compute = MultipleTextureComputeSystem(
            context: context,
            textureDescriptors:[]
        )
        
        compute.preCompute = { [unowned self] (computeEncoder: MTLComputeCommandEncoder, offset: Int) in
            computeEncoder.setTexture(self.hdrCubemapTexture, index: offset)
            computeEncoder.setBuffer(self.specularTextureComputeUniforms.buffer, offset: 0, index: 0)
        }
        return compute
    }()
    
    // HDRI to Skybox Texture
    
    lazy var skyboxTextureCompute: MultipleTextureComputeSystem = {
        let compute = MultipleTextureComputeSystem(context: context, textureDescriptors: [])
        compute.preCompute = { [unowned self] (computeEncoder: MTLComputeCommandEncoder, offset: Int) in
            computeEncoder.setTexture(self.hdriTexture, index: offset)
        }
        
        return compute
    }()
    
    // Textures
    
    var hdriTexture: MTLTexture?
    
    lazy var hdrCubemapTexture: MTLTexture? = {
        let cubeDesc = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .rgba16Float, size: 512, mipmapped: true)
        let texture = device.makeTexture(descriptor: cubeDesc)
        texture?.label = "Cubemap"
        return texture
    }()
    
    lazy var diffuseCubeTexture: MTLTexture? = {
        let cubeDesc = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .rgba16Float, size: 64, mipmapped: true)
        let texture = device.makeTexture(descriptor: cubeDesc)
        texture?.label = "Diffuse"
        return texture
    }()
    
    lazy var specularCubeTexture: MTLTexture? = {
        let cubeDesc = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .rgba16Float, size: 512, mipmapped: true)
        let texture = device.makeTexture(descriptor: cubeDesc)
        texture?.label = "Specular"
        return texture
    }()
    
    lazy var skyboxCubeTexture: MTLTexture? = {
        let cubeDesc = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .bgra8Unorm, size: 512, mipmapped: true)
        let texture = device.makeTexture(descriptor: cubeDesc)
        texture?.label = "Skybox"
        return texture
    }()
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
        metalKitView.colorPixelFormat = .bgra8Unorm
    }
    
    override func setup() {
        loadHdri()
        setupMetalCompiler()
        setupLibrary()
        
        #if os(macOS)
//        openEditor()
        #endif
    }
    
    func loadHdri() {
        let filename = "venice_sunset_2k.hdr"
        hdriTexture = loadHDR(context, texturesURL.appendingPathComponent(filename))
    }
    
    override func update() {
        if let material = skybox.material as? SkyboxMaterial {
            material.texture = skyboxCubeTexture
        }
        
        cameraController.update()
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
        if !_openEditor() {
            let openPanel = NSOpenPanel()
            openPanel.canChooseFiles = true
            openPanel.allowsMultipleSelection = false
            openPanel.canCreateDirectories = false
            openPanel.begin(completionHandler: { [unowned self] (result: NSApplication.ModalResponse) in
                if result == .OK {
                    if let editorUrl = openPanel.url {
                        let editorPath = editorUrl.path
                        UserDefaults.standard.set(editorPath, forKey: "Editor")
                        _ = _openEditor()
                    }
                }
                openPanel.close()
            })
        }
    }
    
    func _openEditor() -> Bool{
        if let editorPath = UserDefaults.standard.string(forKey: "Editor") {
            NSWorkspace.shared.open([assetsURL], withApplicationAt: URL(fileURLWithPath: editorPath), configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
            return true
        }
        return false
    }
    
    override func keyDown(with event: NSEvent) {
        if event.characters == "e" {
            openEditor()
        }
        else if event.characters == "d" {
            debugMesh.visible = !debugMesh.visible
        }
    }
    #endif
}
