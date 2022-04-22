//
//  Bounds+Extensions.swift
//  Pods
//
//  Created by Reza Ali on 1/16/22.
//

import Foundation

public extension Bounds {
    init() {
        self.init(min: .zero, max: .zero)
    }

    var size: simd_float3 {
        max - min
    }

    var center: simd_float3 {
        (max + min) * 0.5
    }
}
