//
//  BrdfGenerator.swift
//  PBRTemplate
//
//  Created by Reza Ali on 11/8/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Foundation
import Metal

public class BrdfGenerator {
    class BrdfComputeSystem: LiveTextureComputeSystem {
        init(device: MTLDevice, textureDescriptor: MTLTextureDescriptor) {
            super.init(
                device: device,
                textureDescriptors: [textureDescriptor],
                pipelinesURL: getPipelinesComputeUrl()!
            )
        }
    }
    
    private var compute: BrdfComputeSystem
    
    public init(device: MTLDevice, size: Int) {
        let textureDescriptor: MTLTextureDescriptor = .texture2DDescriptor(
            pixelFormat: .rg16Float,
            width: size,
            height: size,
            mipmapped: false
        )
        self.compute = BrdfComputeSystem(device: device, textureDescriptor: textureDescriptor)
    }
    
    public func encode(commandBuffer: MTLCommandBuffer) -> MTLTexture? {
        commandBuffer.label = "\(compute.label) Compute Command Buffer"
        compute.update(commandBuffer)
        let texture = compute.texture[0]
        texture.label = "BRDF LUT"
        return texture
    }
}

