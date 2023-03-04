//
//  ShadowRenderer.swift
//
//
//  Created by Reza Ali on 3/2/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin

class ShadowRenderer: BaseRenderer {
    class CustomMaterial: LiveMaterial {}

    var assetsURL: URL { Bundle.main.resourceURL!.appendingPathComponent("Assets") }
    var rendererAssetsURL: URL { assetsURL.appendingPathComponent(String(describing: type(of: self))) }
    var pipelinesURL: URL { rendererAssetsURL.appendingPathComponent("Pipelines") }

    var lightHelperMesh = Mesh(geometry: BoxGeometry(size: (0.1, 0.1, 0.5), res: 10), material: BasicDiffuseMaterial(0.7))

    var baseMesh = Mesh(geometry: BoxGeometry(size: (1.25, 0.125, 1.25), res: 5), material: BasicDiffuseMaterial(0.7))

    var mesh = Mesh(geometry: BoxGeometry(size: 1.0), material: StandardMaterial())
    lazy var floorMesh = Mesh(geometry: PlaneGeometry(size: 8.0, plane: .zx), material: CustomMaterial(pipelinesURL: pipelinesURL))

    var light = DirectionalLight(color: .one, intensity: 2.0)

    lazy var scene = Object("Scene", [light, floorMesh, baseMesh, mesh])
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var camera = PerspectiveCamera(position: .init(repeating: 5.0), near: 0.01, far: 100.0, fov: 30)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: mtkView)
    lazy var renderer = Satin.Renderer(context: context)

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
    }

    override func setup() {
        light.position.y = 5.0
        light.lookAt(.zero, -Satin.worldForwardDirection)
        light.castShadow = true
        light.add(lightHelperMesh)
        light.shadow.resolution = (1024, 1024)

        // Setup things here
        camera.lookAt(.zero)
        floorMesh.position.y = -1.0

        mesh.castShadow = true
        mesh.receiveShadow = true

        baseMesh.position.y = -0.75
        baseMesh.castShadow = true
        baseMesh.receiveShadow = true

        floorMesh.material?.set("Color", [1.0, 1.0, 0.0, 1.0])
        floorMesh.receiveShadow = true
    }

    lazy var startTime = getTime()

    override func update() {
        cameraController.update()

        let time = getTime() - startTime
        let theta = Float(time)
        let radius: Float = 5.0

        light.position = simd_make_float3(radius * sin(theta), 5.0, radius * cos(theta))
        light.lookAt(.zero, -Satin.worldForwardDirection)
    }

    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera
        )
    }

    override func resize(_ size: (width: Float, height: Float)) {
        camera.aspect = size.width / size.height
        renderer.resize(size)
    }

    #if os(macOS)

    override func keyDown(with event: NSEvent) {
        if event.characters == "e" {
            openEditor()
        }
    }

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

    #endif

    func getTime() -> CFAbsoluteTime {
        return CFAbsoluteTimeGetCurrent()
    }
}
