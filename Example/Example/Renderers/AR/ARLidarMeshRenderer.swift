//
//  ARLidarMeshRenderer.swift
//  Example
//
//  Created by Reza Ali on 4/10/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

#if os(iOS)

import ARKit
import Metal
import MetalKit

import Forge
import Satin

class ARLidarMeshRenderer: BaseRenderer {
    class LidarMeshMaterial: SourceMaterial {}

    lazy var material: LidarMeshMaterial = {
        let material = LidarMeshMaterial(pipelinesURL: pipelinesURL)
        material.blending = .alpha
        material.set("Color", [1.0, 1.0, 1.0, 0.25])
        material.vertexDescriptor = ARMeshVertexDescriptor()
        return material
    }()

    var lidarMeshes: [UUID: ARMesh] = [:]

    var session = ARSession()

    var scene = Object("Scene")

    lazy var context = Context(device, sampleCount, colorPixelFormat, .depth32Float)
    lazy var camera = ARPerspectiveCamera(session: session, mtkView: mtkView, near: 0.01, far: 100.0)
    lazy var renderer = Satin.Renderer(context: context)

    var backgroundRenderer: ARBackgroundRenderer!

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .invalid
        metalKitView.preferredFramesPerSecond = 60
    }

    override init() {
        super.init()
        session.delegate = self

        let config = ARWorldTrackingConfiguration()
        config.sceneReconstruction = .mesh
        session.run(config)
    }

    override func setup() {
        renderer.colorLoadAction = .load

        backgroundRenderer = ARBackgroundRenderer(
            context: Context(device, 1, colorPixelFormat),
            session: session
        )
    }

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
    }

    override func resize(_ size: (width: Float, height: Float)) {
        renderer.resize(size)
        backgroundRenderer.resize(size)
    }

    override func cleanup() {
        session.pause()
    }
}

extension ARLidarMeshRenderer: ARSessionDelegate {
    // MARK: - ARSession Delegate

    func session(_: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let meshAnchor = anchor as? ARMeshAnchor {
                let id = anchor.identifier
                if let lidarMesh = lidarMeshes[id] {
                    lidarMesh.meshAnchor = meshAnchor
                }
            }
        }
    }

    func session(_: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let meshAnchor = anchor as? ARMeshAnchor {
                let id = anchor.identifier
                let mesh = ARMesh(meshAnchor: meshAnchor, material: material)
                mesh.triangleFillMode = .lines
                lidarMeshes[id] = mesh
                scene.add(mesh)
            }
        }
    }
}

#endif
