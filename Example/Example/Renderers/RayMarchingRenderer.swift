//
//  RayMarchingRenderer.swift
//  Example
//
//  Created by Reza Ali on 6/26/21.
//  Copyright © 2021 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin

class RayMarchingRenderer: BaseRenderer {
    
    class RayMarchedMaterial: LiveMaterial {
        var camera: PerspectiveCamera?
        
        init(pipelinesURL: URL, camera: PerspectiveCamera?) {
            self.camera = camera
            super.init(pipelinesURL: pipelinesURL)
            self.blending = .disabled
        }
        
        required init() {
            fatalError("init() has not been implemented")
        }
        
        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
        
        override func bind(_ renderEncoder: MTLRenderCommandEncoder) {
            super.bind(renderEncoder)
            if let camera = self.camera {
                var view = camera.viewMatrix
                renderEncoder.setFragmentBytes(&view, length: MemoryLayout<float4x4>.size, index: FragmentBufferIndex.Custom0.rawValue)
            }
        }
    }

    var assetsURL: URL {
        Bundle.main.resourceURL!.appendingPathComponent("Assets")
    }
    
    var rendererAssetsURL: URL {
        assetsURL.appendingPathComponent(String(describing: type(of: self)))
    }
    
    var pipelinesURL: URL {
        rendererAssetsURL.appendingPathComponent("Pipelines")
    }
    
    var mesh = Mesh(geometry: BoxGeometry(size: 2.0), material: BasicDiffuseMaterial(0.7))
    var camera = PerspectiveCamera(position: [0.0, 0.0, 5.0], near: 0.001, far: 100.0, fov: 45)
    
    lazy var rayMarchedMaterial = RayMarchedMaterial(pipelinesURL: pipelinesURL, camera: camera)
    lazy var rayMarchedMesh = Mesh(geometry: QuadGeometry(), material: rayMarchedMaterial)
    lazy var scene = Object("Scene", [mesh, rayMarchedMesh])
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: mtkView)
    lazy var renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
        
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
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
    
    #if os(macOS)
    func openEditor() {
        if let editorURL = UserDefaults.standard.url(forKey: "Editor") {
            openEditor(at: editorURL)
        }
        else {
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
            try NSWorkspace.shared.open([self.assetsURL], withApplicationAt: editorURL, options: [], configuration: [:])
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
