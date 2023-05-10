//
//  Bounds+Extensions.swift
//  Satin
//
//  Created by Reza Ali on 1/16/22.
//

import Foundation
import simd
import SatinCore

public extension Bounds {
    init() {
        self.init(min: .init(repeating: .infinity), max: .init(repeating: -.infinity))
    }

    var size: simd_float3 {
        max - min
    }

    var center: simd_float3 {
        (max + min) * 0.5
    }

    var corners: [simd_float3] {
        return [
            simd_make_float3(max.x, max.y, max.z), // 0
            simd_make_float3(min.x, max.y, max.z), // 1
            simd_make_float3(max.x, min.y, max.z), // 2
            simd_make_float3(min.x, min.y, max.z), // 3
            simd_make_float3(max.x, max.y, min.z), // 4
            simd_make_float3(min.x, max.y, min.z), // 5
            simd_make_float3(max.x, min.y, min.z), // 6
            simd_make_float3(min.x, min.y, min.z), // 7
        ]
    }
}
