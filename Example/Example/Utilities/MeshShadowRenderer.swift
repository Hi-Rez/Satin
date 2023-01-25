//
//  MeshShadowRenderer.swift
//  Example
//
//  Created by Reza Ali on 1/25/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Foundation
import Combine
import Metal
import MetalPerformanceShaders
import Satin

class MeshShadowRenderer {
    public var texture: MTLTexture? {
        _texture
    }

    public var update: Bool = true

    private var subscription: AnyCancellable?
    private var device: MTLDevice
    private var renderer: Satin.Renderer
    private var camera: OrthographicCamera
    private var scene: Object
    private var shadowMesh: Mesh
    private var width: Int
    private var height: Int
    private var blurFilter: MPSImageGaussianBlur

    private var _texture: MTLTexture?

    init(device: MTLDevice, mesh: Mesh, size: (width: Float, height: Float)) {
        self.device = device

        let mat = BasicColorMaterial([0, 0, 0, 0.75], .alpha)

        shadowMesh = Mesh(geometry: mesh.geometry, material: mat)
        shadowMesh.cullMode = .front

        scene = Object("Scene")
        scene.add(shadowMesh, false)

        renderer = Satin.Renderer(context: Context(device, 1, .bgra8Unorm, .invalid))
        renderer.label = "Shadow Renderer"
        renderer.setClearColor(.zero)
        renderer.resize(size)

        let distance: Float = 2.0
        camera = OrthographicCamera(
            left: -distance,
            right: distance,
            bottom: -distance,
            top: distance,
            near: 0.01,
            far: 100
        )
        camera.position = .init(0, 5, 0)
        camera.lookAt(.zero, -Satin.worldForwardDirection)

        width = Int(size.width)
        height = Int(size.height)

        blurFilter = MPSImageGaussianBlur(device: device, sigma: 8)
        blurFilter.edgeMode = .clamp

        _texture = createTexture(device: device, width: width, height: height, pixelFormat: .bgra8Unorm)

        subscription = mesh.transformPublisher.sink { [weak self] object in
            self?.update = true
            self?.shadowMesh.worldMatrix = object.worldMatrix

            let alpha = remap(
                input: object.worldPosition.y,
                inputMin: 0,
                inputMax: 3.0,
                outputMin: 1.0,
                outputMax: 0.0
            )

            self?.shadowMesh.material?.set("Color", [0.0, 0.0, 0.0, alpha])
        }

    }

    func draw(commandBuffer: MTLCommandBuffer) {
        guard update, var _texture = _texture else { return }
        
        let rpd = MTLRenderPassDescriptor()
        rpd.colorAttachments[0].texture =  _texture
        rpd.renderTargetWidth = width
        rpd.renderTargetHeight = height

        renderer.draw(
            renderPassDescriptor: rpd,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera
        )

        blurFilter.encode(commandBuffer: commandBuffer, inPlaceTexture: &_texture)

        update = false
    }

    func createTexture(device: MTLDevice, width: Int, height: Int, pixelFormat: MTLPixelFormat) -> MTLTexture? {
        guard width > 0, height > 0 else { return nil }
        let descriptor = MTLTextureDescriptor()
        descriptor.pixelFormat = pixelFormat
        descriptor.width = width
        descriptor.height = height
        descriptor.sampleCount = 1
        descriptor.textureType = .type2D
        descriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        descriptor.storageMode = .private
        descriptor.resourceOptions = .storageModePrivate
        guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }
        texture.label = "Shadow Render Target"
        return texture
    }
}


