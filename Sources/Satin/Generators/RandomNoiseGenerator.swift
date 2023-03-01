//
//  RandomNoiseGenerator.swift
//  Satin
//
//  Created by Reza Ali on 12/15/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Foundation
import Metal

public class RandomNoiseGenerator {
    class RandomNoiseComputeSystem: LiveTextureComputeSystem {
        init(device: MTLDevice, textureDescriptor: MTLTextureDescriptor) {
            super.init(
                device: device,
                textureDescriptors: [textureDescriptor],
                pipelinesURL: getPipelinesComputeUrl()!
            )
        }
    }

    var textureDescriptor: MTLTextureDescriptor {
        .texture2DDescriptor(
            pixelFormat: .rgba32Float,
            width: size.width,
            height: size.height,
            mipmapped: false
        )
    }

    public var size: (width: Int, height: Int) {
        didSet {
            if size != oldValue {
                compute.textureDescriptors = [textureDescriptor]
            }
        }
    }

    public var seed: Int
    public var range: ClosedRange<Float>

    private var compute: RandomNoiseComputeSystem

    public init(device: MTLDevice, size: (width: Int, height: Int) = (1024, 1024), range: ClosedRange<Float> = -1.0 ... 1.0, seed: Int = 0) {
        self.size = size
        self.range = range
        self.seed = seed
        compute = RandomNoiseComputeSystem(
            device: device,
            textureDescriptor: .texture2DDescriptor(
                pixelFormat: .rgba32Float,
                width: size.width,
                height: size.height,
                mipmapped: false
            )
        )
    }

    public func encode(commandBuffer: MTLCommandBuffer) -> MTLTexture? {
        commandBuffer.label = "\(compute.label) Compute Command Buffer"
        compute.set("Range", [range.lowerBound, range.upperBound])
        compute.set("Seed", seed)
        compute.update(commandBuffer)
        let texture = compute.texture[0]
        texture.label = "Random Noise"
        return texture
    }
}
