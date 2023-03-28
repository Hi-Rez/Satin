//
//  CGSize+Extensions.swift
//  Satin
//
//  Created by Reza Ali on 3/27/23.
//

import Foundation
import simd

extension CGSize {
    var float2: simd_float2 {
        return simd_make_float2(Float(self.width), Float(self.height))
    }
}
