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

class PBRRenderer: BaseRenderer {
    class CustomMaterial: LiveMaterial {}
    
    var assetsURL: URL { Bundle.main.resourceURL!.appendingPathComponent("Assets") }
    var rendererAssetsURL: URL { assetsURL.appendingPathComponent(String(describing: type(of: self))) }
    var pipelinesURL: URL { rendererAssetsURL.appendingPathComponent("Pipelines") }
    var texturesURL: URL { rendererAssetsURL.appendingPathComponent("Textures") }
    var modelsURL: URL { rendererAssetsURL.appendingPathComponent("Models") }
    
    lazy var scene = Object("Scene", [mesh, skybox])
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var camera = PerspectiveCamera(position: [0.0, 0.0, 40.0], near: 0.001, far: 1000.0)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: mtkView)
    lazy var renderer: Satin.Renderer = .init(context: context, scene: scene, camera: camera)
    
    lazy var customMaterial = CustomMaterial(pipelinesURL: pipelinesURL)
    lazy var mesh: Mesh = {
        let mesh = Mesh(geometry: IcoSphereGeometry(radius: 1.0, res: 4), material: customMaterial)
        mesh.label = "Sphere"
        mesh.instanceCount = 49
        mesh.preDraw = { [unowned self] (renderEncoder: MTLRenderCommandEncoder) in
            renderEncoder.setFragmentTexture(self.diffuseIBLTexture, index: FragmentTextureIndex.Custom0.rawValue)
            renderEncoder.setFragmentTexture(self.specularIBLTexture, index: FragmentTextureIndex.Custom1.rawValue)
            renderEncoder.setFragmentTexture(self.brdfTexture, index: FragmentTextureIndex.Custom2.rawValue)
        }
        return mesh
    }()
    
    lazy var skyboxMaterial = SkyboxMaterial(tonemapped: true, gammaCorrected: true)
    lazy var skybox = Mesh(geometry: SkyboxGeometry(size: 150), material: skyboxMaterial)
    
    // Textures
    var hdriTexture: MTLTexture?
    var cubemapTexture: MTLTexture?
    var diffuseIBLTexture: MTLTexture?
    var specularIBLTexture: MTLTexture?
    var brdfTexture: MTLTexture?

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
        metalKitView.colorPixelFormat = .bgra8Unorm
    }
    
    override func setup() {
        loadHdri()
        setupCubemap()
        setupDiffuseIBL()
        setupSpecularIBL()
        setupBRDF()
    }
    
    func loadHdri() {
        let filename = "venice_sunset_2k.hdr"
        hdriTexture = loadHDR(device, texturesURL.appendingPathComponent(filename))
    }
    
    func setupCubemap() {
        if let hdriTexture = hdriTexture, let commandBuffer = commandQueue.makeCommandBuffer(), let texture = createCubemapTexture(pixelFormat: .rgba16Float, size: 512, mipmapped: false) {
            CubemapGenerator(device: device)
                .encode(commandBuffer: commandBuffer, sourceTexture: hdriTexture, destinationTexture: texture)
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            cubemapTexture = texture
            skyboxMaterial.texture = texture
        }
    }
    
    func setupDiffuseIBL() {
        if let cubemapTexture = cubemapTexture,
           let commandBuffer = commandQueue.makeCommandBuffer(),
           let texture = createCubemapTexture(pixelFormat: .rgba16Float, size: 64, mipmapped: false)
        {
            DiffuseIBLGenerator(device: device)
                .encode(commandBuffer: commandBuffer, sourceTexture: cubemapTexture, destinationTexture: texture)
            
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            
            diffuseIBLTexture = texture
            texture.label = "Diffuse IBL"
        }
    }
    
    func setupSpecularIBL() {
        if let cubemapTexture = cubemapTexture,
           let commandBuffer = commandQueue.makeCommandBuffer(),
           let texture = createCubemapTexture(pixelFormat: .rgba16Float, size: 512, mipmapped: true)
        {
            SpecularIBLGenerator(device: device)
                .encode(commandBuffer: commandBuffer, sourceTexture: cubemapTexture, destinationTexture: texture)
            
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            
            specularIBLTexture = texture
            texture.label = "Specular IBL"
        }
    }
    
    func setupBRDF() {
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            brdfTexture = BrdfGenerator(device: device, size: 512)
                .encode(commandBuffer: commandBuffer)
            
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }
    
    func createCubemapTexture(pixelFormat: MTLPixelFormat, size: Int, mipmapped: Bool) -> MTLTexture?
    {
        let desc = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: pixelFormat, size: size, mipmapped: mipmapped)
        let texture = device.makeTexture(descriptor: desc)
        texture?.label = "Cubemap"
        return texture
    }
    
    override func update() {
        cameraController.update()
    }
    
    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        renderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
    }
    
    override func resize(_ size: (width: Float, height: Float)) {
        camera.aspect = size.width / size.height
        renderer.resize(size)
    }
}
