//
//  Float2Parameter.swift
//  Satin
//
//  Created by Reza Ali on 2/4/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

import Foundation
import simd

open class Float2Parameter: NSObject, Parameter {
    public static var type = ParameterType.float2
    public let label: String
    
    @objc dynamic var x: Float
    @objc dynamic var y: Float
    
    @objc dynamic var minX: Float
    @objc dynamic var maxX: Float
    
    @objc dynamic var minY: Float
    @objc dynamic var maxY: Float
    
    public var value: simd_float2 {
        get {
            return simd_make_float2(x, y)
        }
        set(newValue) {
            x = newValue.x
            y = newValue.y
        }
    }
    
    public var min: simd_float2 {
        get {
            return simd_make_float2(minX, minY)
        }
        set(newValue) {
            minX = newValue.x
            minY = newValue.y
        }
    }
    
    
    public var max: simd_float2 {
        get {
            return simd_make_float2(maxX, maxY)
        }
        set(newValue) {
            maxX = newValue.x
            maxY = newValue.y
        }
    }

    public init(_ label: String, _ value: simd_float2, _ min: simd_float2, _ max: simd_float2) {
        self.label = label
        self.x = value.x
        self.y = value.y
        self.minX = min.x
        self.maxX = max.x
        self.minY = min.y
        self.maxY = max.y
    }
    
    public init(_ label: String, _ value: simd_float2) {
        self.label = label
        self.x = value.x
        self.y = value.y
        self.minX = 0.0
        self.maxX = 1.0
        self.minY = 0.0
        self.maxY = 1.0
    } 
}
