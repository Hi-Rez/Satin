//
//  ExtrudedTextRenderer.swift
//  Example Shared
//
//  Created by Reza Ali on 8/22/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin

class ExtrudedTextRenderer: BaseRenderer {
    var scene = Object()
    var mesh: Mesh!

    lazy var camera = PerspectiveCamera(position: [15.0, 20.0, 40.0], near: 10.0, far: 60.0, fov: 60)
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: mtkView)
    lazy var renderer = Satin.Renderer(context: context)

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
    }

    override func setup() {
        setupText()
    }

    deinit {
        cameraController.disable()
    }

    func setupText() {
        let input = "stay hungry\nstay foolish"
        let geo = ExtrudedTextGeometry(
            text: input,
            fontName: "Helvetica",
            fontSize: 8,
            distance: 8,
            bounds: CGSize(width: -1, height: -1),
            pivot: simd_make_float2(0, 0),
            textAlignment: .left,
            verticalAlignment: .center
        )

        let mat = DepthMaterial()
        mat.set("Invert", true)
        mesh = Mesh(geometry: geo, material: mat)

        camera.lookAt(target: mesh.worldBounds.center)

        scene.add(mesh)
    }

    override func update() {
        cameraController.update()
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
}
