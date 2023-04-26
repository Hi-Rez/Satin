//
//  Environment.swift
//
//
//  Created by Reza Ali on 4/25/23.
//

import Foundation
import Metal

public protocol Environment {
    var environmentIntensity: Float { get }
    
    var environment: MTLTexture? { get }
    var cubemapTexture: MTLTexture? { get }

    var irradianceTexture: MTLTexture? { get }
    var irradianceTexcoordTransform: simd_float3x3 { get }

    var reflectionTexture: MTLTexture? { get }
    var reflectionTexcoordTransform: simd_float3x3 { get }

    var brdfTexture: MTLTexture? { get }
}
