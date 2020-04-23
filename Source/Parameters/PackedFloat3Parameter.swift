//
//  PackedFloat3Parameter.swift
//  Satin
//
//  Created by Reza Ali on 4/22/20.
//

import Foundation
import simd

open class PackedFloat3Parameter: NSObject, Parameter {
    public static var type = ParameterType.packedfloat3
    public var controlType: ControlType
    public let label: String
    public var string: String { return "packed_float3" }
    public var size: Int { return 12 }
    public var stride: Int { return 12 }
    public var alignment: Int { return 4 }
    
    @objc dynamic var x: Float
    @objc dynamic var y: Float
    @objc dynamic var z: Float
    
    @objc dynamic var minX: Float
    @objc dynamic var maxX: Float
    
    @objc dynamic var minY: Float
    @objc dynamic var maxY: Float
    
    @objc dynamic var minZ: Float
    @objc dynamic var maxZ: Float
    
    public var value: simd_float3 {
        get {
            return simd_make_float3(x, y, z)
        }
        set(newValue) {
            x = newValue.x
            y = newValue.y
            z = newValue.z
        }
    }
    
    public var min: simd_float3 {
        get {
            return simd_make_float3(minX, minY, minZ)
        }
        set(newValue) {
            minX = newValue.x
            minY = newValue.y
            minZ = newValue.z
        }
    }
    
    public var max: simd_float3 {
        get {
            return simd_make_float3(maxX, maxY, maxZ)
        }
        set(newValue) {
            maxX = newValue.x
            maxY = newValue.y
            maxZ = newValue.z
        }
    }
    
    public init(_ label: String, _ value: simd_float3, _ min: simd_float3, _ max: simd_float3, _ controlType: ControlType = .unknown) {
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
    
    public init(_ label: String, _ value: simd_float3 = simd_make_float3(0.0), _ controlType: ControlType = .unknown) {
        self.label = label
        self.controlType = controlType
        
        self.x = value.x
        self.y = value.y
        self.z = value.z
        
        self.minX = 0.0
        self.maxX = 1.0
        
        self.minY = 0.0
        self.maxY = 1.0
        
        self.minZ = 0.0
        self.maxZ = 1.0
    }
}
