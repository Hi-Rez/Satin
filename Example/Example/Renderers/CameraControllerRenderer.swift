//
//  CameraRenderer.swift
//  Example
//
//  Created by Reza Ali on 7/28/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin

class CameraControllerRenderer: BaseRenderer {
    var gridInterval: Float = 1.0

    lazy var grid: Object = {
        let object = Object()
        let material = BasicColorMaterial(simd_make_float4(1.0, 1.0, 1.0, 1.0))
        let intervals = 5
        let intervalsf = Float(intervals)
        let geometryX = CapsuleGeometry(size: (0.005, intervalsf), axis: .x)
        let geometryZ = CapsuleGeometry(size: (0.005, intervalsf), axis: .z)
        for i in 0 ... intervals {
            let fi = Float(i)
            let meshX = Mesh(geometry: geometryX, material: material)
            let offset = map(fi, 0.0, Float(intervals), -intervalsf * 0.5, intervalsf * 0.5)
            meshX.position = [0.0, 0.0, offset]
            object.add(meshX)

            let meshZ = Mesh(geometry: geometryZ, material: material)
            meshZ.position = [offset, 0.0, 0.0]
            object.add(meshZ)
        }
        return object
    }()

    lazy var axisMesh: Object = {
        let object = Object()
        let intervals = 5
        let intervalsf = Float(intervals)
        let size = (Float(0.005), intervalsf)
        object.add(Mesh(geometry: CapsuleGeometry(size: size, axis: .x), material: BasicColorMaterial(simd_make_float4(1.0, 0.0, 0.0, 1.0))))
        object.add(Mesh(geometry: CapsuleGeometry(size: size, axis: .y), material: BasicColorMaterial(simd_make_float4(0.0, 1.0, 0.0, 1.0))))
        object.add(Mesh(geometry: CapsuleGeometry(size: size, axis: .z), material: BasicColorMaterial(simd_make_float4(0.0, 0.0, 1.0, 1.0))))
        return object
    }()

    lazy var targetMesh = Mesh(geometry: BoxGeometry(size: 1.0), material: NormalColorMaterial())
    lazy var scene = Object("Scene", [grid, axisMesh])
    lazy var context: Context = .init(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)

    lazy var camera: PerspectiveCamera = {
        let pos = simd_make_float3(5.0, 5.0, 5.0)
        let camera = PerspectiveCamera(position: pos, near: 0.001, far: 200.0)

        camera.orientation = simd_quatf(from: [0, 0, 1], to: simd_normalize(pos))

        let forward = simd_normalize(camera.forwardDirection)
        let worldUp = Satin.worldUpDirection
        let right = -simd_normalize(simd_cross(forward, worldUp))
        let angle = acos(simd_dot(simd_normalize(camera.rightDirection), right))

        camera.orientation = simd_quatf(angle: angle, axis: forward) * camera.orientation

        return camera
    }()

    lazy var cameraController: PerspectiveCameraController = .init(camera: camera, view: mtkView)
    lazy var renderer: Satin.Renderer = .init(context: context)

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 4
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
    }

    override func setup() {
        scene.add(cameraController.target)
        cameraController.target.add(targetMesh)
        scene.attach(targetMesh)
    }

    override func update() {
        cameraController.update()
        targetMesh.orientation = cameraController.target.orientation.inverse
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
