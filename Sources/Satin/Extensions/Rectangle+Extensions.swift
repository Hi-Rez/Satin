//
//  Rectangle+Extensions.swift
//  
//
//  Created by Reza Ali on 12/2/22.
//

import Foundation
import simd

public extension Rectangle {
    init() {
        self.init(min: .init(repeating: .infinity), max: .init(repeating: -.infinity))
    }

    var size: simd_float2 {
        max - min
    }
    
    var width: Float {
        size.x
    }
    
    var height: Float {
        size.y
    }

    var center: simd_float2 {
        (max + min) * 0.5
    }

    var corners: [simd_float2] {
        return [
            simd_make_float2(max.x, max.y), // 0
            simd_make_float2(min.x, max.y), // 1
            simd_make_float2(max.x, min.y), // 2
            simd_make_float2(min.x, min.y), // 3
        ]
    }
    
    func contains(rectangle: Rectangle) {
        rectangleContainsRectangle(self, rectangle)
    }
    
    func intersects(rectangle: Rectangle) -> Bool {
        return rectangleIntersectsRectangle(self, rectangle)
    }
    
    func contains(point: simd_float2) -> Bool {
        return rectangleContainsPoint(self, point)
    }
}

