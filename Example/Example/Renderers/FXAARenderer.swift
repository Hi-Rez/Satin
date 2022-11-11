//
//  Renderer.swift
//  Example
//
//  Created by Reza Ali on 10/2/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin

class FXAARenderer: BaseRenderer {
    class FxaaMaterial: LiveMaterial {}
    
    var assetsURL: URL { Bundle.main.resourceURL!.appendingPathComponent("Assets") }
    var rendererAssetsURL: URL { assetsURL.appendingPathComponent(String(describing: type(of: self))) }
    var pipelinesURL: URL { rendererAssetsURL.appendingPathComponent("Pipelines") }

    // MARK: Render to Texture
    
    var renderTexture: MTLTexture!
    var updateRenderTexture: Bool = true
    
    lazy var fxaaMaterial = FxaaMaterial(pipelinesURL: pipelinesURL)
    
    lazy var fxaaProcessor: PostProcessor = {
        let pp = PostProcessor(context: Context(context.device, context.sampleCount, context.colorPixelFormat, .invalid, .invalid), material: fxaaMaterial)
        pp.mesh.preDraw = { [unowned self] (renderEncoder: MTLRenderCommandEncoder) -> Void in
            renderEncoder.setFragmentTexture(self.renderTexture, index: FragmentTextureIndex.Custom0.rawValue)
        }
        pp.label = "FXAA Post Processor"
        return pp
    }()
        
    lazy var mesh: Mesh = {
        let mesh = Mesh(
            geometry:
            ExtrudedTextGeometry(
                text: "FXAA",
                fontName: "Helvetica",
                fontSize: 1,
                distance: 0.5,
                pivot: [0, 0]
            ),
            material: BasicDiffuseMaterial(1.0)
        )
        return mesh
    }()
    
    var camera = PerspectiveCamera(position: [0, 0, 9], near: 0.001, far: 100.0)
    
    lazy var scene = Object("Scene", [mesh])
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: mtkView)
    lazy var renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
        
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.colorPixelFormat = .bgra8Unorm
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
    }
    
    override func update() {
        if updateRenderTexture {
            renderTexture = createTexture("Render Texture", context.colorPixelFormat)
            updateRenderTexture = false
        }
        
        cameraController.update()
    }
    
    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        renderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer, renderTarget: renderTexture)
        fxaaProcessor.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
    }
    
    override func resize(_ size: (width: Float, height: Float)) {
        camera.aspect = size.width / size.height
        renderer.resize(size)
        fxaaProcessor.resize(size)
        updateRenderTexture = true
        fxaaMaterial.set("Inverse Resolution", 1.0/simd_make_float2(size.width, size.height))
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
}
