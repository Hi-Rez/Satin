//
//  Renderer.swift
//  Example
//
//  Created by Reza Ali on 6/26/21.
//  Copyright © 2021 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin

class Renderer: Forge.Renderer {
    var assetsURL: URL {
        let resourcesURL = Bundle.main.resourceURL!
        return resourcesURL.appendingPathComponent("Assets")
    }
    
    var pipelinesURL: URL {
        return assetsURL.appendingPathComponent("Pipelines")
    }
    
    lazy var mesh: Mesh = {
        Mesh(geometry: BoxGeometry(size: 2.0), material: BasicDiffuseMaterial(0.7))
    }()
    
    lazy var rayMarchedMaterial: RayMarchedMaterial = {
        RayMarchedMaterial(pipelinesURL: pipelinesURL, camera: camera)
    }()
    
    lazy var rayMarchedMesh: Mesh = {
        Mesh(geometry: QuadGeometry(), material: rayMarchedMaterial)
    }()
    
    lazy var scene: Object = {
        let scene = Object()
        scene.add(mesh)
        scene.add(rayMarchedMesh)
        return scene
    }()
    
    lazy var context: Context = {
        Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }()
    
    lazy var camera: PerspectiveCamera = {
        let camera = PerspectiveCamera()
        camera.fov = 45
        camera.near = 0.01
        camera.far = 100.0
        camera.position = simd_make_float3(0.0, 0.0, 5.0)
        return camera
    }()
    
    lazy var cameraController: PerspectiveCameraController = {
        PerspectiveCameraController(camera: camera, view: mtkView)
    }()
    
    lazy var renderer: Satin.Renderer = {
        Satin.Renderer(context: context, scene: scene, camera: camera)
    }()
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
    }
    
    override func setup() {
        // Setup things here
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
