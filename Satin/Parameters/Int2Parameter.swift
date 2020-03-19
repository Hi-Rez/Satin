//
//  Int2Parameter.swift
//  Satin
//
//  Created by Reza Ali on 2/5/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

import Foundation
import simd

open class Int2Parameter: NSObject, Parameter {
    public static var type = ParameterType.int2
    public var controlType: ControlType
    public let label: String
    
    @objc dynamic var x: Int32
    @objc dynamic var y: Int32
    
    @objc dynamic var minX: Int32
    @objc dynamic var maxX: Int32
    
    @objc dynamic var minY: Int32
    @objc dynamic var maxY: Int32
    
    public var value: simd_int2 {
        get {
            return simd_make_int2(x, y)
        }
        set(newValue) {
            x = newValue.x
            y = newValue.y
        }
    }
    
    public var min: simd_int2 {
        get {
            return simd_make_int2(minX, minY)
        }
        set(newValue) {
            minX = newValue.x
            minY = newValue.y
        }
    }
    
    
    public var max: simd_int2 {
        get {
            return simd_make_int2(maxX, maxY)
        }
        set(newValue) {
            maxX = newValue.x
            maxY = newValue.y
        }
    }

    public init(_ label: String, _ value: simd_int2, _ min: simd_int2, _ max: simd_int2, _ controlType: ControlType = .unknown) {
        self.label = label
        self.controlType = controlType
        
        self.x = value.x
        self.y = value.y
        
        self.minX = min.x
        self.maxX = max.x
        
        self.minY = min.y
        self.maxY = max.y
    }
    
    public init(_ label: String, _ value: simd_int2, _ controlType: ControlType = .unknown) {
        self.label = label
        self.controlType = controlType
        
        self.x = value.x
        self.y = value.y
        
        self.minX = 0
        self.maxX = 100
        
        self.minY = 0
        self.maxY = 100
    }
}
