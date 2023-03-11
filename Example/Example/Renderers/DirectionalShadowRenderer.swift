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

class DirectionalShadowRenderer: BaseRenderer {
    class CustomMaterial: LiveMaterial {}

    var assetsURL: URL { Bundle.main.resourceURL!.appendingPathComponent("Assets") }
    var rendererAssetsURL: URL { assetsURL.appendingPathComponent(String(describing: type(of: self))) }
    var pipelinesURL: URL { rendererAssetsURL.appendingPathComponent("Pipelines") }

    let lightHelperGeo = BoxGeometry(size: (0.1, 0.1, 0.5))
    let lightHelperMat = BasicDiffuseMaterial(0.7)

    lazy var lightHelperMesh0 = Mesh(geometry: lightHelperGeo, material: lightHelperMat)
    lazy var lightHelperMesh1 = Mesh(geometry: lightHelperGeo, material: lightHelperMat)

    var baseMesh = Mesh(geometry: BoxGeometry(size: (1.25, 0.125, 1.25), res: 5), material: StandardMaterial(baseColor: [1.0, 0.0, 0.0, 1.0], metallic: 0.0, roughness: 0.2))

    lazy var mainGeometry: Geometry = {
        let geo = TorusGeometry(radius: (0.1, 0.5))
        return geo
    }()

    lazy var mesh = Mesh(geometry: mainGeometry, material: StandardMaterial())
    lazy var floorMesh = Mesh(geometry: PlaneGeometry(size: 8.0, plane: .zx), material: ShadowMaterial())

    var light0 = DirectionalLight(color: [1.0, 0.0, 1.0], intensity: 2.0)
    var light1 = DirectionalLight(color: [0.0, 1.0, 1.0], intensity: 2.0)

    lazy var scene = Object("Scene", [light0, light1, floorMesh, baseMesh, mesh])
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var camera = PerspectiveCamera(position: .init(repeating: 5.0), near: 0.01, far: 100.0, fov: 30)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: mtkView)
    lazy var renderer = Satin.Renderer(context: context)

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 4
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
    }

    override func setup() {
        renderer.clearColor = .init(red: 0.75, green: 0.75, blue: 0.75, alpha: 1.0)

        light0.position.y = 5.0
        light0.castShadow = true
        lightHelperMesh0.label = "Light Helper 0"
        light0.add(lightHelperMesh0)
        if let shadowCamera = light0.shadow.camera as? OrthographicCamera {
            shadowCamera.update(left: -2, right: 2, bottom: -2, top: 2)
        }
        light0.shadow.resolution = (2048, 2048)
        light0.shadow.bias = 0.0005
        light0.shadow.radius = 2

        light1.position.y = 5.0
        light1.castShadow = true
        lightHelperMesh1.label = "Light Helper 1"
        light1.add(lightHelperMesh1)
        if let shadowCamera = light1.shadow.camera as? OrthographicCamera {
            shadowCamera.update(left: -2, right: 2, bottom: -2, top: 2)
        }
        light1.shadow.resolution = (2048, 2048)
        light1.shadow.bias = 0.0005
        light1.shadow.radius = 2

        // Setup things here
        camera.lookAt(.zero)
        floorMesh.position.y = -1.0

        mesh.label = "Main"
        mesh.castShadow = true
        mesh.receiveShadow = true

        baseMesh.label = "Base"
        baseMesh.position.y = -0.75
        baseMesh.castShadow = true
        baseMesh.receiveShadow = true

        floorMesh.label = "Floor"
        floorMesh.material?.set("Color", [0.0, 0.0, 0.0, 1.0])
        floorMesh.receiveShadow = true
    }

    lazy var startTime = getTime()

    override func update() {
        cameraController.update()

        let time = getTime() - startTime
        var theta = Float(time)
        let radius: Float = 5.0


        mesh.orientation = simd_quatf(angle: theta, axis: Satin.worldUpDirection)
        mesh.orientation *= simd_quatf(angle: theta, axis: Satin.worldRightDirection)

        light0.position = simd_make_float3(radius * sin(theta), 5.0, radius * cos(theta))
        light0.lookAt(.zero, Satin.worldUpDirection)
        light0.shadow.strength = 0.5

        theta += .pi * 0.5
        light1.position = simd_make_float3(radius * sin(theta), 5.0, radius * cos(theta))
        light1.lookAt(.zero, Satin.worldUpDirection)
        light1.shadow.strength = 0.5
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
