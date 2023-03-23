//
//  ARContactShadowRenderer.swift
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

class ARContactShadowRenderer: BaseRenderer, ARSessionDelegate {
    var session: ARSession!


    lazy var shadowMaterial = BasicTextureMaterial(texture: nil, flipped: true)
//    lazy var shadowRenderer = ObjectShadowRenderer(device: device, scene: invader, size: (512, 512))
    lazy var shadowPlaneMesh = Mesh(geometry: PlaneGeometry(size: (4, 4), plane: .zx), material: shadowMaterial)
    

    let scale: Float = 0.05
    let geometry = BoxGeometry(size: 0.05)

    lazy var invader: Object = {
        let container = Object("Container")

        let BDY: simd_float4 = [0.0, 1.0, 0.0, 1.0]
        let _E_: simd_float4 = [1.0, 1.0, 1.0, 1.0]

        var materialMap = [simd_float4: Material]()

        var fills: [[simd_float4?]] =
            [
                [nil, nil, BDY, nil, nil, nil, nil, nil, BDY, nil, nil],
                [nil, nil, nil, BDY, nil, nil, nil, BDY, nil, nil, nil],
                [nil, nil, BDY, BDY, BDY, BDY, BDY, BDY, BDY, nil, nil],
                [nil, BDY, BDY, _E_, BDY, BDY, BDY, _E_, BDY, BDY, nil],
                [BDY, BDY, BDY, BDY, BDY, BDY, BDY, BDY, BDY, BDY, BDY],
                [BDY, nil, BDY, BDY, BDY, BDY, BDY, BDY, BDY, nil, BDY],
                [BDY, nil, BDY, nil, nil, nil, nil, nil, BDY, nil, BDY],
                [nil, nil, nil, BDY, BDY, nil, BDY, BDY, nil, nil, nil],
            ]

        for y in (0..<8).reversed() {
            let row = fills[y]
            for x in 0 ..< 11 {
                if let color = row[x] {
                    var mat: Material?
                    if let existingMaterial = materialMap[color] {
                        mat = existingMaterial
                    }
                    else {
                        let newMaterial = BasicDiffuseMaterial()
                        newMaterial.color = color
                        materialMap[color] = newMaterial
                        mat = newMaterial
                    }

                    let voxel = Mesh(geometry: geometry, material: mat!)
                    voxel.position = scale * simd_make_float3(Float(x)-11.0/2.0, 8.0 - Float(y), 0)
                    container.add(voxel)
                }
            }
        }

        container.visible = false
        return container

    }()

    lazy var scene = Object("Scene", [invader])
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
        session = ARSession()
        session.delegate = self

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]

        session.run(configuration)
    }

    override func setup() {
        renderer.colorLoadAction = .load
        renderer.compile(scene: scene, camera: camera)

        backgroundRenderer = ARBackgroundRenderer(
            context: Context(device, 1, colorPixelFormat),
            session: session
        )
    }

    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
//        if invader.visible {
//            shadowRenderer.draw(commandBuffer: commandBuffer)
//        }

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

    override func touchesBegan(_: Set<UITouch>, with _: UIEvent?) {
//        if let currentFrame = session.currentFrame {
//            let anchor = ARAnchor(transform: simd_mul(currentFrame.camera.transform, translationMatrixf(0.0, 0.0, -0.25)))
//            session.add(anchor: anchor)
//
//            let mesh = Mesh(geometry: boxGeometry, material: boxMaterial)
//            mesh.onUpdate = { [weak mesh, weak anchor] in
//                guard let mesh = mesh, let anchor = anchor else { return }
//                mesh.localMatrix = anchor.transform
//            }
//
//            scene.add(mesh)
//        }
    }


    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        if !invader.visible, let anchor = anchors.first as? ARPlaneAnchor {
            invader.worldMatrix = anchor.transform
            invader.visible = true
        }
    }
}

#endif
