//
//  ContactShadowRenderer.swift
//  Example
//
//  Created by Reza Ali on 3/22/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit
import MetalPerformanceShaders

import Forge
import Satin

class ContactShadowRenderer: BaseRenderer {
    override var texturesURL: URL { sharedAssetsURL.appendingPathComponent("Textures") }

    lazy var matcapTexture: MTLTexture? = {
        let fileName = "8A6565_2E214D_D48A5F_ADA59C.png" // from https://github.com/nidorx/matcaps
        let loader = MTKTextureLoader(device: device)
        do {
            return try loader.newTexture(URL: self.texturesURL.appendingPathComponent(fileName), options: [
                MTKTextureLoader.Option.SRGB: false,
                MTKTextureLoader.Option.origin: MTKTextureLoader.Origin.flippedVertically,
            ])
        } catch {
            print(error)
            return nil
        }
    }()

    // MARK: - 3D Scene

    lazy var spheres: Object = {
        let geometry = RoundedBoxGeometry(size: (1, 1, 1), radius: 0.25, res: 3)
        let geometrySize = geometry.bounds.size

        let material = MatCapMaterial(texture: matcapTexture)
        let sphere0 = Mesh(geometry: geometry, material: material)
        sphere0.position.y += 0.5
        sphere0.onUpdate = { [weak self, weak sphere0] in
            if let self = self, let sphere = sphere0 {
                sphere0?.position.y = 0.01 + sin(-0.25 * self.theta + 0.34 * Float.pi)
                sphere.orientation = simd_quatf(angle: 0.33 * self.theta, axis: [0, 1, 0])
            }
        }

        let sphere1 = Mesh(geometry: geometry, material: material)
        sphere1.position.x += 1.5
        sphere1.position.y += 0.25
        sphere1.scale *= 0.75
        sphere1.onUpdate = { [weak self, weak sphere1] in
            if let self = self, let sphere = sphere1 {
                sphere.position.y = 0.25 * sin(0.75 * self.theta + 0.4938 * Float.pi)
                sphere.orientation = simd_quatf(angle: 0.5 * self.theta, axis: simd_normalize(.one))
                sphere.orientation *= simd_quatf(angle: -0.25 * self.theta, axis: [0.0, 1.0, 0.0])
            }
        }

        let sphere2 = Mesh(geometry: geometry, material: material)
        sphere2.position.x -= 1.5
        sphere2.position.z -= 1.0
        sphere2.position.y += 0.25
        sphere2.scale *= 0.5
        sphere2.onUpdate = { [weak self, weak sphere2] in
            if let self = self, let sphere = sphere2 {
                sphere.position.y = 0.75 * sin(1.25 * self.theta + 0.83475 * Float.pi)
                sphere.orientation = simd_quatf(angle: -0.25 * self.theta, axis: [1, 0, 0])
                sphere.orientation *= simd_quatf(angle: 0.75 * self.theta, axis: simd_normalize([1, 0, 1]))
            }
        }

        let sphere3 = Mesh(geometry: geometry, material: material)
        sphere3.position.x -= 0.25
        sphere3.position.z += 1.5
        sphere3.position.y += 0.0
        sphere3.scale *= 0.33
        sphere3.onUpdate = { [weak self, weak sphere3] in
            if let self = self, let sphere = sphere3 {
                sphere.position.y = 0.66 * sin(-0.66 * self.theta + 0.12475 * Float.pi)
                sphere.orientation = simd_quatf(angle: -self.theta, axis: simd_normalize([1, 0, 1]))
                sphere.orientation *= simd_quatf(angle: self.theta * 0.5, axis: [0, 0, 1])
            }
        }

        let sphere4 = Mesh(geometry: geometry, material: material)
        sphere4.position.x += 0.75
        sphere4.position.z -= 1.25
        sphere4.position.y += 0.875
        sphere4.scale *= 0.275
        sphere4.onUpdate = { [weak self, weak sphere4] in
            if let self = self, let sphere = sphere4 {
                sphere.position.y = 0.348957 * sin(-0.234 * self.theta + 0.66 * Float.pi)
                sphere.orientation = simd_quatf(angle: -self.theta * 0.5, axis: simd_normalize([1, 1, 0]))
                sphere.orientation *= simd_quatf(angle: self.theta * 0.25, axis: simd_normalize([0, 1, 0]))
            }
        }

        let sphere5 = Mesh(geometry: geometry, material: material)
        sphere5.position.x -= 1.5
        sphere5.position.z += 1.25
        sphere5.position.y += 0.25
        sphere5.scale *= 0.66
        sphere5.onUpdate = { [weak self, weak sphere5] in
            if let self = self, let sphere = sphere5 {
                sphere.position.y = 0.33 * sin(0.124 * self.theta + 0.7 * Float.pi)
                sphere.orientation = simd_quatf(angle: self.theta * 0.5, axis: simd_normalize([0, 1, 1]))
                sphere.orientation *= simd_quatf(angle: -self.theta * 0.25, axis: simd_normalize([1, 0, 0]))
            }
        }

        let spheres = Object("Spheres", [sphere0, sphere1, sphere2, sphere3, sphere4, sphere5])
        spheres.position.y += geometrySize.y
        return spheres
    }()

    lazy var spheresContainer = Object("Spheres Container", [spheres, floorMesh])

    lazy var scene = Object("Scene", [spheresContainer])
    lazy var floorMesh = Mesh(geometry: PlaneGeometry(size: 1.0, plane: .zx), material: BasicTextureMaterial())

    lazy var camera: PerspectiveCamera = {
        var camera = PerspectiveCamera(position: [20, 20, 20], near: 0.01, far: 100.0, fov: 10)
        camera.lookAt(target: .zero)
        return camera
    }()

    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: mtkView)
    lazy var renderer = Satin.Renderer(context: context)

    lazy var shadowRenderer = ObjectShadowRenderer(
        context: context,
        object: spheres,
        container: spheresContainer,
        scene: scene,
        catcher: floorMesh,
        padding: 0.25
    )

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 120
    }

    override func setup() {
        spheres.position.y = 1.5
        cameraController.target.position.y += 1
        renderer.setClearColor(.one)
    }

    deinit {
        cameraController.disable()
    }

    lazy var startTime = getTime()
    var theta: Float = 0

    override func update() {
        theta = 2.0 * Float(getTime() - startTime)
        cameraController.update()
    }

    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }

        shadowRenderer.update(commandBuffer: commandBuffer)

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
