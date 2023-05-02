//
//  YCbCrToRGBConverter.swift
//  
//
//  Created by Reza Ali on 5/2/23.
//

import Foundation
import Metal

public class YCbCrToRGBConverter {
    class YCbCrToRGBConverter: LiveTextureComputeSystem {
        var yTexture: MTLTexture?
        var cbcrTexture: MTLTexture?

        init(device: MTLDevice, textureDescriptor: MTLTextureDescriptor) {
            super.init(
                device: device,
                textureDescriptors: [textureDescriptor],
                pipelinesURL: getPipelinesComputeURL()!
            )
        }

        override func bind(_ computeEncoder: MTLComputeCommandEncoder) -> Int {
            let index = super.bind(computeEncoder)
            computeEncoder.setTexture(yTexture, index: index)
            computeEncoder.setTexture(cbcrTexture, index: index)
            return index + 1
        }
    }

    private var compute: YCbCrToRGBConverter

    public init(device: MTLDevice, width: Int, height: Int) {
        let textureDescriptor: MTLTextureDescriptor = .texture2DDescriptor(
            pixelFormat: .rgba32Float,
            width: width,
            height: height,
            mipmapped: false
        )
        compute = YCbCrToRGBConverter(device: device, textureDescriptor: textureDescriptor)
    }

    public func encode(commandBuffer: MTLCommandBuffer, yTexture: MTLTexture, cbcrTexture: MTLTexture) -> MTLTexture? {
        commandBuffer.label = "\(compute.label) Compute Command Buffer"
        compute.yTexture = yTexture
        compute.cbcrTexture = cbcrTexture
        compute.update(commandBuffer)
        let texture = compute.texture[0]
        texture.label = "\(compute.label) Texture"
        return texture
    }
}
