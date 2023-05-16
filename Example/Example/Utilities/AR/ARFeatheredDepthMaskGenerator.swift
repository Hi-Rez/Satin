//
//  ARDepthMaskStencilGenerator.swift
//  Example
//
//  Created by Reza Ali on 5/15/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Foundation
import Metal
import MetalPerformanceShaders

class ARFeatheredDepthMaskGenerator {
    private var device: MTLDevice
    private var pixelFormat: MTLPixelFormat
    private var textureScale: Int

    private var depthMaskGenerator: ARDepthMaskGenerator
    private var scaleFilter: MPSImageBilinearScale
    private var blurFilter: MPSImageGaussianBlur

    private var _updateTextures = true
    private var texture: MTLTexture?
    private var scaledTexture: MTLTexture?

    public init(device: MTLDevice, pixelFormat: MTLPixelFormat, textureScale: Int, blurSigma: Float) {
        self.device = device
        self.pixelFormat = pixelFormat
        self.textureScale = textureScale

        depthMaskGenerator = ARDepthMaskGenerator(device: device, width: 1, height: 1, pixelFormat: pixelFormat)

        scaleFilter = MPSImageBilinearScale(device: device)
        blurFilter = MPSImageGaussianBlur(device: device, sigma: blurSigma)
        blurFilter.edgeMode = .clamp
    }

    public func encode(commandBuffer: MTLCommandBuffer, realDepthTexture: MTLTexture, virtualDepthTexture: MTLTexture) -> MTLTexture? {
        if _updateTextures {
            texture = createTexture(
                label: "Feathered Depth Mask Texture",
                pixelFormat: pixelFormat,
                width: realDepthTexture.width,
                height: realDepthTexture.height,
                textureScale: textureScale
            )

            scaledTexture = createTexture(
                label: "Feathered Scaled Depth Mask Texture",
                pixelFormat: pixelFormat,
                width: realDepthTexture.width,
                height: realDepthTexture.height,
                textureScale: textureScale
            )
            _updateTextures = false
        }

        if let depthMaskTexture = depthMaskGenerator.encode(
            commandBuffer: commandBuffer,
            realDepthTexture: realDepthTexture,
            virtualDepthTexture: virtualDepthTexture
        ), let texture = texture, let scaledTexture = scaledTexture {
            scaleFilter.encode(
                commandBuffer: commandBuffer,
                sourceTexture: depthMaskTexture,
                destinationTexture: scaledTexture
            )

            blurFilter.encode(
                commandBuffer: commandBuffer,
                sourceTexture: scaledTexture,
                destinationTexture: texture
            )
        }

        return texture
    }

    public func resize(_ size: (width: Float, height: Float)) {
        depthMaskGenerator.resize(size)
        _updateTextures = true
    }

    private func createTexture(label: String, pixelFormat: MTLPixelFormat, width: Int, height: Int, textureScale: Int) -> MTLTexture? {
        guard width > 0, height > 0 else { return nil }
        let descriptor = MTLTextureDescriptor()
        descriptor.pixelFormat = pixelFormat
        descriptor.width = width / textureScale
        descriptor.height = height / textureScale
        descriptor.sampleCount = 1
        descriptor.textureType = .type2D
        descriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        descriptor.storageMode = .private
        descriptor.resourceOptions = .storageModePrivate
        guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }
        texture.label = label
        return texture
    }
}
