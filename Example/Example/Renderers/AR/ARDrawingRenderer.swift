//
//  ARDrawingRenderer.swift
//  Example
//
//  Created by Reza Ali on 3/15/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

#if os(iOS)
import ARKit
import Metal
import MetalKit

import Forge
import Satin
import SwiftUI

class ARDrawingRenderer: BaseRenderer {
    class RainbowMaterial: SourceMaterial {}

    // MARK: - Post Processor

    var compositor: ARPostProcessor!

    // MARK: - AR

    var session = ARSession()

    // MARK: - 3D

    lazy var material = RainbowMaterial(pipelinesURL: pipelinesURL)
    lazy var mesh = InstancedMesh(geometry: IcoSphereGeometry(radius: 0.03, res: 3), material: material, count: 20000)
    lazy var scene = Object("Scene", [mesh])
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat)
    lazy var camera = ARPerspectiveCamera(session: session, mtkView: mtkView, near: 0.01, far: 100.0)
    lazy var renderer = {
        let renderer = Satin.Renderer(context: context)
        renderer.label = "Content Renderer"
        renderer.setClearColor(.zero)
        renderer.colorLoadAction = .load
        renderer.depthLoadAction = .load
        return renderer
    }()

    private lazy var startTime: CFAbsoluteTime = getTime()
    private lazy var time: CFAbsoluteTime = getTime()

    // MARK: - Interaction

    var touchDown = false

    // MARK: - Background

    var backgroundRenderer: ARBackgroundDepthRenderer!

    // MARK: - Setup MTKView

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)
        metalKitView.backgroundColor = .black
        metalKitView.preferredFramesPerSecond = 120
        metalKitView.depthStencilPixelFormat = .depth32Float
    }

    // MARK: - Init

    var clear: Binding<Bool>

    init(clear: Binding<Bool>) {
        self.clear = clear
        super.init()

        let config = ARWorldTrackingConfiguration()
        config.frameSemantics = [.smoothedSceneDepth]
        session.run(config)
    }

    // MARK: - Deinit

    override func cleanup() {
        session.pause()
    }

    // MARK: - Setup

    override func setup() {
        mesh.drawCount = 0
        backgroundRenderer = ARBackgroundDepthRenderer(
            context: context,
            session: session,
            sessionPublisher: ARSessionPublisher(session: session),
            mtkView: mtkView,
            near: camera.near,
            far: camera.far
        )
        
        compositor = ARPostProcessor(context: Context(device, 1, colorPixelFormat), session: session)
        renderer.compile(scene: scene, camera: camera)
    }

    // MARK: - Update

    override func update() {
        updateDrawing()
        updateMaterial()
    }

    // MARK: - Draw

    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }

        backgroundRenderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer
        )

        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera
        )

//        compositor.contentTexture = renderPassDescriptor.colorAttachments[0].texture

//        postProcessor.draw(
//            renderPassDescriptor: renderPassDescriptor,
//            commandBuffer: commandBuffer
//        )
    }

    // MARK: - Resize

    override func resize(_ size: (width: Float, height: Float)) {
        renderer.resize(size)
        backgroundRenderer.resize(size)
        compositor.resize(size)
    }

    // MARK: - Interactions

    override func touchesBegan(_: Set<UITouch>, with _: UIEvent?) {
        touchDown = true
    }

    override func touchesEnded(_: Set<UITouch>, with _: UIEvent?) {
        touchDown = false
    }

    // MARK: - Updates

    func updateDrawing() {
        if clear.wrappedValue {
            mesh.drawCount = 0
            clear.wrappedValue = false
        } else if touchDown, let currentFrame = session.currentFrame {
            add(simd_mul(currentFrame.camera.transform, translationMatrixf(0, 0, -0.2)))
        }
    }

    func add(_ transform: simd_float4x4) {
        if let index = mesh.drawCount {
            mesh.drawCount = index + 1
            mesh.setMatrixAt(index: index, matrix: transform)
        }
    }

    func updateMaterial() {
        time = getTime() - startTime
        material.set("Time", Float(time))
    }
}
#endif
