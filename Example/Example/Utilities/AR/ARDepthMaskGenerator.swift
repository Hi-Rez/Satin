//
//  ARDepthMaskGenerator.swift
//  Example
//
//  Created by Reza Ali on 5/15/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Foundation
import Metal

import Satin

public class ARDepthMaskGenerator {
    class DepthMaskComputeSystem: LiveTextureComputeSystem {
        var realDepthTexture: MTLTexture?
        var virtualDepthTexture: MTLTexture?

        init(device: MTLDevice, textureDescriptor: MTLTextureDescriptor) {
            super.init(
                device: device,
                textureDescriptors: [textureDescriptor],
                pipelinesURL: Bundle.main.resourceURL!
                    .appendingPathComponent("Assets")
                    .appendingPathComponent("Shared")
                    .appendingPathComponent("Pipelines")
            )
        }

        override func bind(_ computeEncoder: MTLComputeCommandEncoder) -> Int {
            var index = super.bind(computeEncoder)
            computeEncoder.setTexture(realDepthTexture, index: index)
            index += 1
            computeEncoder.setTexture(virtualDepthTexture, index: index)
            index += 1
            return index
        }
    }

    private var compute: DepthMaskComputeSystem

    public init(device: MTLDevice, width: Int, height: Int) {
        let textureDescriptor: MTLTextureDescriptor = .texture2DDescriptor(
            pixelFormat: .r16Float,
            width: width,
            height: height,
            mipmapped: false
        )
        compute = DepthMaskComputeSystem(device: device, textureDescriptor: textureDescriptor)
    }

    public func encode(commandBuffer: MTLCommandBuffer, realDepthTexture: MTLTexture, virtualDepthTexture: MTLTexture) -> MTLTexture? {
        commandBuffer.label = "\(compute.label) Compute Command Buffer"
        compute.realDepthTexture = realDepthTexture
        compute.virtualDepthTexture = virtualDepthTexture
        compute.update(commandBuffer)
        let texture = compute.texture[0]
        texture.label = "\(compute.label) Texture"
        return texture
    }

    public func resize(_ size: (width: Float, height: Float)) {
        let textureDescriptor: MTLTextureDescriptor = .texture2DDescriptor(
            pixelFormat: .r16Float,
            width: Int(size.width),
            height: Int(size.height),
            mipmapped: false
        )

        compute.textureDescriptors = [textureDescriptor]
    }
}
