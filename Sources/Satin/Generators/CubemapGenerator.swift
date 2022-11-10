//
//  CubemapGenerator.swift
//  PBRTemplate
//
//  Created by Reza Ali on 11/8/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Foundation
import Metal
import MetalPerformanceShaders

public class CubemapGenerator {
    class CubemapComputeSystem: LiveTextureComputeSystem {
        var sourceTexture: MTLTexture?
        
        init(device: MTLDevice) {
            super.init(device: device, textureDescriptors: [], pipelinesURL: getPipelinesComputeUrl()!)
        }
        
        override func bind(_ computeEncoder: MTLComputeCommandEncoder) -> Int {
            let index = super.bind(computeEncoder)
            computeEncoder.setTexture(sourceTexture, index: index)
            return index + 1
        }
    }
    
    private var compute: CubemapComputeSystem
    private var blur: MPSImageGaussianBlur?
    
    public init(device: MTLDevice, sigma: Float = 0.0, tonemapped: Bool = false, gammaCorrected: Bool = false) {
        self.compute = CubemapComputeSystem(device: device)
        if sigma > 0.0 {
            self.blur = MPSImageGaussianBlur(device: device, sigma: sigma)            
        }
        compute.set("Tone Mapped", tonemapped)
        compute.set("Gamma Corrected", gammaCorrected)
    }
    
    public func encode(commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        let levels = destinationTexture.mipmapLevelCount
        var size = destinationTexture.width
        
        var finalSourceTexture = sourceTexture
        if let blur = blur {
            let descriptor = MTLTextureDescriptor()
            descriptor.pixelFormat = sourceTexture.pixelFormat
            descriptor.width = sourceTexture.width
            descriptor.height = sourceTexture.height
            descriptor.textureType = sourceTexture.textureType
            descriptor.sampleCount = 1
            descriptor.usage = [.shaderRead, .shaderWrite]
            descriptor.storageMode = .private
            descriptor.resourceOptions = .storageModePrivate
            
            if let sourceTextureBlurred = commandBuffer.device.makeTexture(descriptor: descriptor) {
                blur.encode(commandBuffer: commandBuffer, sourceTexture: sourceTexture, destinationTexture: sourceTextureBlurred)
                finalSourceTexture = sourceTextureBlurred
            }
        }
        
        for level in 0..<levels {
            compute.sourceTexture = finalSourceTexture
            compute.textureDescriptors = Array(
                repeating: MTLTextureDescriptor.texture2DDescriptor(
                    pixelFormat: destinationTexture.pixelFormat,
                    width: size,
                    height: size,
                    mipmapped: false
                ),
                count: 6
            )
                        
            commandBuffer.label = "\(compute.label) Compute Command Buffer"
            compute.update(commandBuffer)
            
            commandBuffer.label = "\(compute.label) Blit Command Buffer"
            for slice in 0..<6 {
                if let blitEncoder = commandBuffer.makeBlitCommandEncoder() {
                    blitEncoder.copy(
                        from: compute.texture[slice],
                        sourceSlice: 0,
                        sourceLevel: 0,
                        to: destinationTexture,
                        destinationSlice: slice,
                        destinationLevel: level,
                        sliceCount: 1,
                        levelCount: 1
                    )
                    blitEncoder.endEncoding()
                }
            }
            
            size /= 2
        }
        
        destinationTexture.label = "Cubemap"
    }
}
