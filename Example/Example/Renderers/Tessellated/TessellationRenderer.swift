//
//  TessellationRenderer.swift
//  Example
//
//  Created by Reza Ali on 4/2/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin

class TessellationRenderer: BaseRenderer {
    lazy var tessellator = TessellationComputeSystem<MTLTriangleTessellationFactorsHalf>(
        device: device,
        pipelineURL: pipelinesURL.appendingPathComponent("Tessellated/Compute.metal"),
        functionName: "tessellationTriUpdate"
    )

    lazy var tessGeometry = TessellatedGeometry(baseGeometry: IcoSphereGeometry(radius: 1, res: 1))
    lazy var tessMaterial = TessellatedMaterial(pipelinesURL: pipelinesURL, geometry: tessGeometry)
    lazy var tessMesh = TessellatedMesh(geometry: tessGeometry, material: tessMaterial, tessellator: tessellator)

    lazy var tessWireMaterial = TessellatedMaterial(pipelinesURL: pipelinesURL, geometry: tessGeometry)
    lazy var tessWireMesh = TessellatedMesh(geometry: tessGeometry, material: tessWireMaterial, tessellator: tessellator)
    lazy var scene = Object("Scene", [tessMesh, tessWireMesh])

    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var camera = PerspectiveCamera(position: .init(repeating: 4.0), near: 0.01, far: 50.0, fov: 30)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: mtkView)
    lazy var renderer = Satin.Renderer(context: context)

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
    }

    override func setup() {
        camera.lookAt(target: .zero)
        renderer.compile(scene: scene, camera: camera)

        tessellator.setup(tessGeometry)

        tessMaterial.depthBias = DepthBias(bias: -1, slope: -1, clamp: -1)
        tessWireMesh.triangleFillMode = .lines

        tessWireMaterial.blending = .additive
        tessWireMaterial.depthBias = DepthBias(bias: 1, slope: 1, clamp: 1)

        tessWireMaterial.set("Color", [1.0, 1.0, 1.0, 0.33])
    }

    deinit {
        cameraController.disable()
    }

    lazy var startTime = getTime()
    override func update() {
        let currentTime = getTime() - startTime
        let osc = Float(sin(currentTime)) * 0.5

        tessMaterial.set("Amplitude", osc)
        tessWireMaterial.set("Amplitude", osc)

        let oscEdge = Float(sin(currentTime * 0.5))
        let oscInsider = Float(cos(currentTime * 1.25))

        tessellator.set("edgeTessellationFactor", abs(oscEdge) * 16.0)
        tessellator.set("insideTessellationFactor", abs(oscInsider) * 16.0)

        cameraController.update()
    }

    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        tessellator.update(commandBuffer: commandBuffer)
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
