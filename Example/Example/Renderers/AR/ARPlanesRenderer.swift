//
//  ARPlanesRenderer.swift
//  Example
//
//  Created by Reza Ali on 3/22/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

#if os(iOS)
import ARKit
import Metal
import MetalKit

import Forge
import Satin
import SwiftUI

fileprivate class ARPlaneContainer: Object {
    var anchor: ARPlaneAnchor {
        didSet {
            updateAnchor()
        }
    }

    var geometry = Geometry()
    var planeMesh: Mesh
    var meshWireframe: Mesh

    init(label: String, anchor: ARPlaneAnchor, material: Satin.Material) {
        self.anchor = anchor

        let mat = material.clone()
        mat.set("Color", [Float.random(in: 0 ... 1), Float.random(in: 0 ... 1), Float.random(in: 0 ... 1), 0.25])

        planeMesh = Mesh(geometry: geometry, material: mat)
        meshWireframe = Mesh(geometry: geometry, material: mat)
        meshWireframe.triangleFillMode = .lines
        planeMesh.add(meshWireframe)

        super.init(label, [planeMesh])
        updateAnchor()
    }

    required init(from _: Decoder) throws { fatalError("Not implemented") }

    func updateAnchor() {
        updateTransform()
        updateGeometry()
    }

    func updateTransform() {
        worldMatrix = anchor.transform
    }

    func updateGeometry() {
        let vertices = anchor.geometry.vertices
        let uvs = anchor.geometry.textureCoordinates
        var verts = [Vertex]()
        let normal = anchor.alignment == .horizontal ? Satin.worldUpDirection : Satin.worldForwardDirection
        for (vert, uv) in zip(vertices, uvs) {
            verts.append(Vertex(position: .init(vert, 1), normal: normal, uv: uv))
        }
        let indices = anchor.geometry.triangleIndices.map { UInt32($0) }
        geometry.vertexData = verts
        geometry.indexData = indices
    }
}

class ARPlanesRenderer: BaseRenderer, ARSessionDelegate {
    // MARK: - AR

    var session = ARSession()

    lazy var planeMaterial: Satin.Material = {
        let material = BasicColorMaterial(.one, .additive)
        material.depthWriteEnabled = false
        return material
    }()

    fileprivate var planesMap: [ARAnchor: ARPlaneContainer] = [:]

    // MARK: - 3D

    lazy var scene = Object("Scene")
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat)
    lazy var camera = ARPerspectiveCamera(session: session, mtkView: mtkView, near: 0.01, far: 100.0)
    lazy var renderer = {
        let renderer = Satin.Renderer(context: context)
        renderer.label = "Content Renderer"
        renderer.colorLoadAction = .load
        return renderer
    }()

    // MARK: - Background

    var backgroundRenderer: ARBackgroundRenderer!

    // MARK: - Setup MTKView

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.backgroundColor = .black
        metalKitView.preferredFramesPerSecond = 120
    }

    // MARK: - Init

    override init() {
        super.init()

        session.delegate = self
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        session.run(configuration)
    }

    // MARK: - Deinit

    override func cleanup() {
        session.pause()
    }

    // MARK: - Setup

    override func setup() {
        backgroundRenderer = ARBackgroundRenderer(context: Context(device, 1, colorPixelFormat), session: session)
        renderer.compile(scene: scene, camera: camera)
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
    }

    // MARK: - Resize

    override func resize(_ size: (width: Float, height: Float)) {
        renderer.resize(size)
        backgroundRenderer.resize(size)
    }

    // MARK: - ARSession Delegate

    func session(_: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let plane = planesMap[anchor], let planeAnchor = anchor as? ARPlaneAnchor {
                plane.anchor = planeAnchor
            }
        }
    }

    func session(_: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if planesMap[anchor] == nil, let planeAnchor = anchor as? ARPlaneAnchor {
                let planeContainer = ARPlaneContainer(label: "\(planeAnchor.identifier)", anchor: planeAnchor, material: planeMaterial)
                planesMap[anchor] = planeContainer
                scene.add(planeContainer)
            }
        }
    }
}
#endif
