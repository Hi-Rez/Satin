//
//  ProjectedShadowRenderer.swift
//  Example
//
//  Created by Reza Ali on 1/25/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin

class ProjectedShadowRenderer: BaseRenderer {
    // MARK: - 3D Scene

    lazy var scene = Object("Scene", [shadowPlaneMesh, mesh])
    lazy var mesh: Mesh = {
        let mesh = Mesh(geometry: TorusGeometry(radius: (0.1, 0.5)), material: NormalColorMaterial(true))
        mesh.label = "Box"
        mesh.position = .init(0, 2.0, 0)
        return mesh
    }()

    lazy var shadowMaterial = BasicTextureMaterial(texture: nil, flipped: true)
    lazy var shadowRenderer = MeshShadowRenderer(device: device, mesh: mesh, size: (512, 512))
    lazy var shadowPlaneMesh = Mesh(geometry: PlaneGeometry(size: (4, 4), plane: .zx), material: shadowMaterial)

    lazy var camera: PerspectiveCamera = {
        var camera = PerspectiveCamera(position: [4.0, 6.0, 4.0], near: 0.01, far: 1000.0)
        camera.lookAt(.zero)
        return camera
    }()

    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: mtkView)
    lazy var renderer = Satin.Renderer(context: context)

    var angle: Float = 0

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 120
    }

    override func setup() {
        renderer.setClearColor(.one)
        cameraController.target.position.y += 1
    }

    override func update() {
        cameraController.update()

        mesh.orientation = simd_quatf(angle: angle, axis: simd_normalize([sin(angle), cos(angle), 0.25]))
        angle += 0.015
        mesh.position.y = 2.0 + sin(angle)
    }

    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        shadowRenderer.draw(commandBuffer: commandBuffer)

        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        shadowMaterial.texture = shadowRenderer.texture
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
