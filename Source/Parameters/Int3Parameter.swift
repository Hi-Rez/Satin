//
//  Int3Parameter.swift
//  Satin
//
//  Created by Reza Ali on 2/10/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

import Foundation
import simd

open class Int3Parameter: NSObject, Parameter {
    public static var type = ParameterType.int3
    public var controlType: ControlType
    public let label: String
    public var string: String { return "int3" }
    public var size: Int { return MemoryLayout<simd_int3>.size }
    public var stride: Int { return MemoryLayout<simd_int3>.stride }
    public var alignment: Int { return MemoryLayout<simd_int3>.alignment }
    
    @objc dynamic public var x: Int32
    @objc dynamic public var y: Int32
    @objc dynamic public var z: Int32
    
    @objc dynamic public var minX: Int32
    @objc dynamic public var maxX: Int32
    
    @objc dynamic public var minY: Int32
    @objc dynamic public var maxY: Int32
    
    @objc dynamic public var minZ: Int32
    @objc dynamic public var maxZ: Int32
    
    public var value: simd_int3 {
        get {
            return simd_make_int3(x, y, z)
        }
        set(newValue) {
            x = newValue.x
            y = newValue.y
            z = newValue.z
        }
    }
    
    public var min: simd_int3 {
        get {
            return simd_make_int3(minX, minY, minZ)
        }
        set(newValue) {
            minX = newValue.x
            minY = newValue.y
            minZ = newValue.z
        }
    }
    
    public var max: simd_int3 {
        get {
            return simd_make_int3(maxX, maxY, maxZ)
        }
        set(newValue) {
            maxX = newValue.x
            maxY = newValue.y
            maxZ = newValue.z
        }
    }

    public init(_ label: String, _ value: simd_int3, _ min: simd_int3, _ max: simd_int3, _ controlType: ControlType = .unknown) {
        self.label = label
        self.controlType = controlType
        
        self.x = value.x
        self.y = value.y
        self.z = value.z
        
        self.minX = min.x
        self.maxX = max.x
        
        self.minY = min.y
        self.maxY = max.y
        
        self.minZ = min.z
        self.maxZ = max.z
    }
    
    public init(_ label: String, _ value: simd_int3 = simd_make_int3(0), _ controlType: ControlType = .unknown) {
        self.label = label
        self.controlType = controlType
        
        self.x = value.x
        self.y = value.y
        self.z = value.z
        
        self.minX = 0
        self.maxX = 100
        
        self.minY = 0
        self.maxY = 100
        
        self.minZ = 0
        self.maxZ = 100
    }
}
