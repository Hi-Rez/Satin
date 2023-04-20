//
//  DirectionalLightShadow.swift
//  Satin
//
//  Created by Reza Ali on 3/2/23.
//  Copyright © 2023 Reza Ali. All rights reserved.
//

import Combine
import Foundation
import Metal

public class DirectionalLightShadow: Shadow {
    public var label: String

    public var data: ShadowData {
        ShadowData(strength: strength, bias: bias, radius: radius)
    }

    var device: MTLDevice? {
        didSet {
            if device != nil {
                setup()
            }
        }
    }

    public var camera: Camera

    public var resolution: (width: Int, height: Int) = (1024, 1024) {
        didSet {
            if resolution.width != oldValue.width || resolution.height != oldValue.height {
                _updateTexture = true
                resolutionPublisher.send(self)
            }
        }
    }

    public var strength: Float = 1.0 {
        didSet {
            if strength != oldValue {
                dataPublisher.send(self)
            }
        }
    }

    public var radius: Float = 1.0 {
        didSet {
            if radius != oldValue {
                dataPublisher.send(self)
            }
        }
    }

    public var bias: Float = 0.00001 {
        didSet {
            if bias != oldValue {
                dataPublisher.send(self)
            }
        }
    }

    var viewport: MTLViewport {
        MTLViewport(originX: 0, originY: 0, width: Double(resolution.width), height: Double(resolution.height), znear: 0.0, zfar: 1.0)
    }

    var _viewport: simd_float4 {
        simd_make_float4(0.0, 0.0, Float(resolution.width), Float(resolution.height))
    }

    var pixelFormat: MTLPixelFormat = .depth32Float {
        didSet {
            if pixelFormat != oldValue {
                _updateTexture = true
            }
        }
    }

    @Published public var texture: MTLTexture? {
        didSet {
            texturePublisher.send(self)
        }
    }

    var _updateTexture = true

    public let texturePublisher = PassthroughSubject<Shadow, Never>()
    public let resolutionPublisher = PassthroughSubject<Shadow, Never>()
    public let dataPublisher = PassthroughSubject<Shadow, Never>()

    init(label: String) {
        self.label = label
        camera = OrthographicCamera(left: -5, right: 5, bottom: -5, top: 5, near: 0.01, far: 50.0)
    }

    func setup() {
        setupTexture()
    }

    public func update(light: Object) {
        camera.position = light.worldPosition
        camera.lookAt(target: light.worldPosition + light.worldForwardDirection, up: Satin.worldUpDirection)
    }

    public func draw(commandBuffer: MTLCommandBuffer, renderables: [Renderable]) {
        setupTexture()

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.depthAttachment.texture = texture
        renderPassDescriptor.depthAttachment.loadAction = .clear
        renderPassDescriptor.depthAttachment.storeAction = .store
        renderPassDescriptor.depthAttachment.clearDepth = 0.0

        renderPassDescriptor.renderTargetWidth = resolution.width
        renderPassDescriptor.renderTargetHeight = resolution.height

        if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        {
            renderEncoder.label = label + " Shadow Encoder"
            renderEncoder.setViewport(viewport)
            for renderable in renderables where renderable.drawable && renderable.castShadow {
                renderEncoder.pushDebugGroup(renderable.label)
                renderable.update(camera: camera, viewport: _viewport)
                renderable.draw(renderEncoder: renderEncoder, shadow: true)
                renderEncoder.popDebugGroup()
            }
            renderEncoder.endEncoding()
        }
    }

    private func setupTexture() {
        guard let device = device, _updateTexture, pixelFormat != .invalid, resolution.width > 1, resolution.height > 1 else { return }

        let descriptor = MTLTextureDescriptor
            .texture2DDescriptor(pixelFormat: pixelFormat, width: resolution.width, height: resolution.height, mipmapped: false)
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .private
        descriptor.resourceOptions = .storageModePrivate
        texture = device.makeTexture(descriptor: descriptor)
        texture?.label = label + " Depth Texture"

        _updateTexture = false
    }
}
