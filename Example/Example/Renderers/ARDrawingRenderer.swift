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

import SwiftUI
import Forge
import Satin

class ARDrawingRenderer: BaseRenderer, ARSessionDelegate {
    class RainbowMaterial: SourceMaterial {}

    // MARK: - Paths

    var assetsURL: URL { Bundle.main.resourceURL!.appendingPathComponent("Assets") }
    var rendererAssetsURL: URL { assetsURL.appendingPathComponent(String(describing: type(of: self))) }
    var pipelinesURL: URL { rendererAssetsURL.appendingPathComponent("Pipelines") }

    // MARK: - Post Processor

    var postProcessor: ARPostProcessor!

    // MARK: - AR

    var session: ARSession!

    // MARK: - 3D

    lazy var material = RainbowMaterial(pipelinesURL: pipelinesURL)
    lazy var mesh = InstancedMesh(geometry: IcoSphereGeometry(radius: 0.03, res: 3), material: material, count: 20000)
    lazy var scene = Object("Scene", [mesh])
    lazy var context = Context(device, sampleCount, colorPixelFormat, .depth32Float)
    lazy var camera = ARPerspectiveCamera(session: session, mtkView: mtkView, near: 0.01, far: 100.0)
    lazy var renderer = {
        let renderer = Satin.Renderer(context: context)
        renderer.label = "Content Renderer"
        renderer.setClearColor(.zero)
        renderer.colorLoadAction = .clear
        renderer.depthStoreAction = .dontCare
        return renderer
    }()

    private lazy var startTime: CFAbsoluteTime = getTime()
    private lazy var time: CFAbsoluteTime = getTime()

    // MARK: - Interaction

    var touchDown = false

    // MARK: - Background

    var backgroundRenderer: ARBackgroundRenderer!

    // MARK: - Setup MTKView

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)
        metalKitView.backgroundColor = .black
        metalKitView.preferredFramesPerSecond = 120
    }

    // MARK: - Init

    var clear: Binding<Bool>

    init(clear: Binding<Bool>) {
        self.clear = clear
        super.init()
        setupARSession()
    }

    // MARK: - Deinit

    override func cleanup() {
        session.pause()
    }

    // MARK: - Setup

    override func setup() {
        mesh.drawCount = 0
        backgroundRenderer = ARBackgroundRenderer(context: Context(device, 1, colorPixelFormat), session: session)
        postProcessor = ARPostProcessor(context: Context(device, 1, colorPixelFormat), session: session)
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
            renderPassDescriptor: MTLRenderPassDescriptor(),
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera
        )

        postProcessor.contentTexture = renderer.colorTexture
        postProcessor.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer
        )
    }

    // MARK: - Resize

    override func resize(_ size: (width: Float, height: Float)) {
        renderer.resize(size)
        backgroundRenderer.resize(size)
        postProcessor.resize(size)
    }

    // MARK: - Interactions

    override func touchesBegan(_: Set<UITouch>, with _: UIEvent?) {
        touchDown = true
    }

    override func touchesEnded(_: Set<UITouch>, with _: UIEvent?) {
        touchDown = false
    }

    // MARK: - Setups

    func setupARSession() {
        session = ARSession()
        session.run(ARWorldTrackingConfiguration())
    }

    // MARK: - Updates

    func updateDrawing() {
        if clear.wrappedValue {
            mesh.drawCount = 0
            clear.wrappedValue = false
        }
        if touchDown, let currentFrame = session.currentFrame {
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
