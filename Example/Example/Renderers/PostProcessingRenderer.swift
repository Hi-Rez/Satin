//
//  Renderer.swift
//  Example
//
//  Created by Reza Ali on 7/12/21.
//  Copyright © 2021 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit
import simd

import Forge
import Satin

class PostProcessingRenderer: BaseRenderer {
    var size = simd_int2(repeating: 0)
    
    class PostMaterial: LiveMaterial {}
    
    var assetsURL: URL {
        Bundle.main.resourceURL!.appendingPathComponent("Assets")
    }
    
    var rendererAssetsURL: URL {
        assetsURL.appendingPathComponent(String(describing: type(of: self)))
    }
    
    var pipelinesURL: URL {
        rendererAssetsURL.appendingPathComponent("Pipelines")
    }
    
    var renderTexture: MTLTexture?
    var material = BasicDiffuseMaterial(0.7)
    var geometry = IcoSphereGeometry(radius: 1.0, res: 0)
    
    lazy var scene: Object = {
        let scene = Object("Scene")
        for _ in 0...50 {
            let mesh = Mesh(geometry: geometry, material: material)
            let scale = Float.random(in: 0.1...0.75)
            let magnitude = (1.0 - scale) * 5.0
            
            mesh.scale = simd_float3(repeating: scale)
            mesh.position = [Float.random(in: -magnitude...magnitude), Float.random(in: -magnitude...magnitude), Float.random(in: -magnitude...magnitude)]
            
            mesh.orientation = simd_quatf(angle: Float.random(in: -Float.pi...Float.pi), axis: simd_normalize(mesh.position))
            scene.add(mesh)
        }
        return scene
    }()
    
    lazy var postProcessor: PostProcessor = {
        let processor = PostProcessor(
            context: Context(device, sampleCount, colorPixelFormat, .invalid, .invalid),
            material: PostMaterial(pipelinesURL: pipelinesURL))
        processor.label = "Post Processor"
        processor.mesh.preDraw = { [weak self] renderEncoder in
            guard let self = self else { return }
            renderEncoder.setFragmentTexture(self.renderTexture, index: FragmentTextureIndex.Custom0.rawValue)
        }
        return processor
    }()
    
    var camera = PerspectiveCamera(position: [0.0, 0.0, 10.0], near: 0.001, far: 100.0, fov: 30.0)
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: mtkView)
    lazy var renderer = Satin.Renderer(context: context, scene: scene, camera: camera)

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
    }
    
    override func update() {
        if size.x != Int(mtkView.drawableSize.width) || size.y != Int(mtkView.drawableSize.height) {
            renderTexture = createTexture("Render Texture", Int(mtkView.drawableSize.width), Int(mtkView.drawableSize.height), colorPixelFormat, context.device)
            size = simd_make_int2(Int32(Int(mtkView.drawableSize.width)), Int32(mtkView.drawableSize.height))
        }
        
        cameraController.update()
    }
    
    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor, let renderTexture = renderTexture else { return }
        renderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer, renderTarget: renderTexture)
        postProcessor.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
    }
    
    override func resize(_ size: (width: Float, height: Float)) {
        camera.aspect = size.width / size.height
        renderer.resize(size)
        postProcessor.resize(size)
    }
    
    func createTexture(_ label: String, _ width: Int, _ height: Int, _ pixelFormat: MTLPixelFormat, _ device: MTLDevice) -> MTLTexture? {
        guard width > 0, height > 0 else { return nil }
        let descriptor = MTLTextureDescriptor()
        descriptor.pixelFormat = pixelFormat
        descriptor.width = width
        descriptor.height = height
        descriptor.sampleCount = 1
        descriptor.textureType = .type2D
        descriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        descriptor.storageMode = .private
        descriptor.resourceOptions = .storageModePrivate
        guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }
        texture.label = label
        return texture
    }
    
    #if os(macOS)
    
    func openEditor() {
        if let editorURL = UserDefaults.standard.url(forKey: "Editor") {
            openEditor(at: editorURL)
        } else {
            let openPanel = NSOpenPanel()
            openPanel.canChooseFiles = true
            openPanel.allowsMultipleSelection = false
            openPanel.canCreateDirectories = false
            openPanel.begin(completionHandler: { [unowned self] (result: NSApplication.ModalResponse) in
                if result == .OK {
                    if let editorUrl = openPanel.url {
                        UserDefaults.standard.set(editorUrl, forKey: "Editor")
                        self.openEditor(at: editorUrl)
                    }
                }
                openPanel.close()
            })
        }
    }

    func openEditor(at editorURL: URL) {
        do {
            try NSWorkspace.shared.open([assetsURL], withApplicationAt: editorURL, options: [], configuration: [:])
        } catch {
            print(error)
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if event.characters == "e" {
            openEditor()
        }
    }
    
    #endif
}
