//
//  ARPointCloudRenderer.swift
//  Example
//
//  Created by Reza Ali on 5/8/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

#if os(iOS)

import ARKit
import Metal
import MetalKit

import Forge
import Satin
import SwiftUI

class ARPointCloudRenderer: BaseRenderer {
    class PointMaterial: SourceMaterial {}
    class PointComputeSystem: LiveBufferComputeSystem {}

    lazy var pointCloud: PointComputeSystem = {
        let pcs = PointComputeSystem(
            device: device,
            pipelineURL: pipelinesURL.appendingPathComponent("Point/Compute.metal"),
            count: 256 * 192
        )

        pcs.preCompute = { (ce: MTLComputeCommandEncoder, offset: Int) in
            if let depthTexture = self.backgroundRenderer.depthTexture {
                ce.setTexture(CVMetalTextureGetTexture(depthTexture), index: ComputeTextureIndex.Custom0.rawValue)
            }
        }

        return pcs
    }()

    // MARK: - UI

    var updateComputeParam = BoolParameter("Update", true, .toggle)
    lazy var controls = ParameterGroup("Controls", [updateComputeParam])

    override var params: [String: ParameterGroup?] {
        [controls.label: controls]
    }

    override var paramKeys: [String] {
        [controls.label]
    }

    // MARK: - AR

    var session = ARSession()

    // MARK: - 3D

    lazy var mesh = Mesh(geometry: IcoSphereGeometry(radius: 0.001, res: 2), material: PointMaterial(pipelinesURL: pipelinesURL))

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

    override init() {
        super.init()

        let config = ARWorldTrackingConfiguration()
        config.frameSemantics = [.sceneDepth, .smoothedSceneDepth]
        session.run(config)
    }

    // MARK: - Deinit

    override func cleanup() {
        session.pause()
    }

    // MARK: - Setup

    override func setup() {
        mesh.instanceCount = 256 * 192
        mesh.material?.onBind = { [weak self] re in
            re.setVertexBuffer(
                self?.pointCloud.getBuffer("Point"),
                offset: 0,
                index: VertexBufferIndex.Custom0.rawValue
            )
        }

        backgroundRenderer = ARBackgroundDepthRenderer(
            context: context,
            session: session,
            sessionPublisher: ARSessionPublisher(session: session),
            mtkView: mtkView,
            near: camera.near,
            far: camera.far
        )

        renderer.compile(scene: scene, camera: camera)
    }

    // MARK: - Draw

    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }

        backgroundRenderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer
        )

        if updateComputeParam.value {
            if let currentFrame = session.currentFrame {
                pointCloud.set("Local To World", camera.localToWorld)
                pointCloud.set("Intrinsics Inversed", camera.intrinsics.inverse)
                pointCloud.set("Resolution", simd_make_float2(
                    Float(Int(currentFrame.camera.imageResolution.width)),
                    Float(currentFrame.camera.imageResolution.height)))
            }

            pointCloud.update(commandBuffer)
        }

        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera
        )
    }

    // MARK: - Resize

    override func resize(_ size: (width: Float, height: Float)) {
        renderer.resize(size)
        backgroundRenderer.resize(size)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateComputeParam.value.toggle()
    }
}

#endif
