//
//  Renderer.swift
//  SatinSceneKitAR-iOS
//
//  Created by Reza Ali on 6/24/21.
//  Copyright © 2021 Hi-Rez. All rights reserved.
//
#if os(iOS)

import ARKit
import Metal
import MetalKit

import Forge
import Satin

class ARSatinSceneKitRenderer: BaseRenderer, ARSessionDelegate {
    override var modelsURL: URL { sharedAssetsURL.appendingPathComponent("Models") }

    // MARK: - SceneKit

    lazy var cameraNode: SCNNode = {
        let node = SCNNode()
        node.camera = scnCamera
        return node
    }()

    lazy var scnCamera: SCNCamera = {
        let scnCamera = SCNCamera()
        scnCamera.fieldOfView = CGFloat(camera.fov)
        scnCamera.zNear = Double(camera.near)
        scnCamera.zFar = Double(camera.far)
        return scnCamera
    }()

    var scnScene = SCNScene()

    lazy var scnRenderer: SCNRenderer = {
        let renderer = SCNRenderer(device: context.device, options: nil)
        renderer.scene = scnScene
        renderer.autoenablesDefaultLighting = true
        renderer.pointOfView = cameraNode
        return renderer
    }()

    // MARK: - AR

    var session: ARSession!

    // MARK: - Satin

    let boxGeometry = BoxGeometry(size: (0.1, 0.1, 0.1))
    let boxMaterial = BasicDiffuseMaterial(0.7)

    var scene = Object("Scene")
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var camera = ARPerspectiveCamera(session: session, mtkView: mtkView, near: 0.001, far: 100.0)

    lazy var renderer: Satin.Renderer = {
        let renderer = Satin.Renderer(context: context)
        renderer.colorLoadAction = .load
        renderer.depthStoreAction = .store
        return renderer
    }()

    // MARK: - AR Background

    var backgroundRenderer: ARBackgroundRenderer!

    // MARK: - Init

    override init() {
        super.init()
        session = ARSession()
        session.run(ARWorldTrackingConfiguration())
        setupScene()
    }

    // MARK: - Setup MTKView

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.colorPixelFormat = .bgra8Unorm
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
    }

    // MARK: - Setup

    override func setup() {
        backgroundRenderer = ARBackgroundRenderer(context: Context(device, 1, colorPixelFormat), session: session)
        boxGeometry.context = context
        boxMaterial.context = context
    }


    // MARK: - Draw

    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        backgroundRenderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
        
        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera
        )

        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.depthAttachment.loadAction = .load

        cameraNode.simdTransform = camera.worldMatrix
        scnCamera.projectionTransform = SCNMatrix4(camera.projectionMatrix)

        scnRenderer.render(
            atTime: 0.0,
            viewport: CGRect(x: 0, y: 0, width: mtkView.drawableSize.width, height: mtkView.drawableSize.height),
            commandBuffer: commandBuffer,
            passDescriptor: renderPassDescriptor
        )
    }

    override func resize(_ size: (width: Float, height: Float)) {
        renderer.resize(size)
        backgroundRenderer.resize(size)
    }

    override func cleanup() {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        session.pause()
    }

    override func touchesBegan(_: Set<UITouch>, with _: UIEvent?) {
        if let currentFrame = session.currentFrame {
            let anchor = ARAnchor(transform: simd_mul(currentFrame.camera.transform, translationMatrixf(0.0, 0.0, -0.25)))
            session.add(anchor: anchor)

            let torusMesh = Mesh(geometry: boxGeometry, material: boxMaterial)
            torusMesh.onUpdate = { [weak torusMesh, weak anchor] in
                guard let torusMesh = torusMesh, let anchor = anchor else { return }
                torusMesh.localMatrix = anchor.transform
            }

            scene.add(torusMesh)
        }
    }

    // MARK: - Setup SceneKit Scene

    func setupScene() {
        do {
            let scene = try SCNScene(url: modelsURL.appendingPathComponent("Ship").appendingPathComponent("Ship.scn"), options: nil)
            scnScene = scene
            scnScene.rootNode.childNodes.first?.simdScale = simd_float3(repeating: 0.01)
        } catch {
            print(error.localizedDescription)
        }
    }
}

#endif
