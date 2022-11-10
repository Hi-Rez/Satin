//
//  LightData.swift
//  
//
//  Created by Reza Ali on 11/1/22.
//

import Foundation

public struct LightData {
    var color: simd_float4       // (rgb, intensity)
    var position: simd_float4    // (xyz, type)
    var direction: simd_float4   // (xyz, inverse radius)
    var spotInfo: simd_float4    // (spotScale, spotOffset, cosInner, cosOuter)
}
