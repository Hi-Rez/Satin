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

class BufferComputeRenderer: BaseRenderer {
    
    class ParticleComputeSystem: LiveBufferComputeSystem {}
    
    class SpriteMaterial: LiveMaterial {}
    class ChromaMaterial: LiveMaterial {}

    var assetsURL: URL { Bundle.main.resourceURL!.appendingPathComponent("Assets") }
    var rendererAssetsURL: URL { assetsURL.appendingPathComponent(String(describing: type(of: self))) }
    var pipelinesURL: URL { rendererAssetsURL.appendingPathComponent("Pipelines") }
    
    lazy var particleSystem = ParticleComputeSystem(device: device, pipelinesURL: pipelinesURL, count: 8192)
    
    lazy var spriteMaterial: SpriteMaterial = {
        let material = SpriteMaterial(pipelinesURL: pipelinesURL)
        material.blending = .additive
        material.depthWriteEnabled = false
        return material
    }()
    
    lazy var mesh: Mesh = {
        let mesh = Mesh(geometry: PointGeometry(), material: spriteMaterial)
        mesh.instanceCount = particleSystem.count
        mesh.preDraw = { [unowned self] (renderEncoder: MTLRenderCommandEncoder) in
            if let buffer = self.particleSystem.getBuffer("Particle") {
                renderEncoder.setVertexBuffer(buffer, offset: 0, index: VertexBufferIndex.Custom0.rawValue)
            }
        }
        return mesh
    }()
    
    var camera = PerspectiveCamera(position: [0.0, 0.0, 100.0], near: 0.001, far: 1000.0)
    
    lazy var scene: Object = Object("Scene", [mesh])
    lazy var context = Context(device, sampleCount, colorPixelFormat, .invalid, .invalid)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: mtkView)
    lazy var renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
    
    var startTime: CFAbsoluteTime = 0.0
    
    // MARK: Render to Texture
    
    var renderTexture: MTLTexture!
    var updateRenderTexture: Bool = true
    
    lazy var chromaMaterial = ChromaMaterial(pipelinesURL: pipelinesURL)
    
    lazy var chromaticProcessor: PostProcessor = {
        let pp = PostProcessor(context: Context(context.device, context.sampleCount, context.colorPixelFormat, .invalid, .invalid), material: chromaMaterial)
        pp.mesh.preDraw = { [unowned self] (renderEncoder: MTLRenderCommandEncoder) -> Void in
            renderEncoder.setFragmentTexture(self.renderTexture, index: FragmentTextureIndex.Custom0.rawValue)
        }
        pp.label = "Chroma Processor"
        return pp
    }()
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.colorPixelFormat = .bgra8Unorm
        metalKitView.depthStencilPixelFormat = .invalid
        metalKitView.preferredFramesPerSecond = 60
    }
    
    override func setup() {
        startTime = CFAbsoluteTimeGetCurrent()
    }
    
    override func update() {
        if updateRenderTexture {
            renderTexture = createTexture("Render Texture", context.colorPixelFormat)
            updateRenderTexture = false
        }
        
        var time = Float(CFAbsoluteTimeGetCurrent() - startTime)
        chromaMaterial.set("Time", time)
        
        time *= 0.25
        let radius: Float = 10.0 * sin(time * 0.5) * cos(time)
        camera.position = simd_make_float3(radius * sin(time), radius * cos(time), 100.0)
        
        cameraController.update()
    }
    
    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        particleSystem.update(commandBuffer)
        
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
}
