//
//  Int4Parameter.swift
//  Satin
//
//  Created by Reza Ali on 2/10/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

import Foundation
import simd

open class Int4Parameter: NSObject, Parameter {
    public static var type = ParameterType.int4
    public var controlType: ControlType
    public let label: String
    
    @objc dynamic public var x: Int32
    @objc dynamic public var y: Int32
    @objc dynamic public var z: Int32
    @objc dynamic public var w: Int32
    
    @objc dynamic var minX: Int32
    @objc dynamic var maxX: Int32
    
    @objc dynamic var minY: Int32
    @objc dynamic var maxY: Int32
    
    @objc dynamic var minZ: Int32
    @objc dynamic var maxZ: Int32
    
    @objc dynamic var minW: Int32
    @objc dynamic var maxW: Int32
    
    public var value: simd_int4 {
        get {
            return simd_make_int4(x, y, z, w)
        }
        set(newValue) {
            x = newValue.x
            y = newValue.y
            z = newValue.z
            w = newValue.w
        }
    }
    
    public var min: simd_int4 {
        get {
            return simd_make_int4(minX, minY, minZ, minW)
        }
        set(newValue) {
            minX = newValue.x
            minY = newValue.y
            minZ = newValue.z
            minW = newValue.w
        }
    }
    
    public var max: simd_int4 {
        get {
            return simd_make_int4(maxX, maxY, maxZ, maxW)
        }
        set(newValue) {
            maxX = newValue.x
            maxY = newValue.y
            maxZ = newValue.z
            maxW = newValue.w
        }
    }
    
    public init(_ label: String, _ value: simd_int4, _ min: simd_int4, _ max: simd_int4, _ controlType: ControlType = .unknown) {
        self.label = label
        self.controlType = controlType
        
        self.x = value.x
        self.y = value.y
        self.z = value.z
        self.w = value.w
        
        self.minX = min.x
        self.maxX = max.x
        
        self.minY = min.y
        self.maxY = max.y
        
        self.minZ = min.z
        self.maxZ = max.z
        
        self.minW = min.w
        self.maxW = max.w
    }
    
    public init(_ label: String, _ value: simd_int4, _ controlType: ControlType = .unknown) {
        self.label = label
        self.controlType = controlType
        
        self.x = value.x
        self.y = value.y
        self.z = value.z
        self.w = value.w
        
        self.minX = 0
        self.maxX = 100
        
        self.minY = 0
        self.maxY = 100
        
        self.minZ = 0
        self.maxZ = 100
        
        self.minW = 0
        self.maxW = 100
    }
}
