//
//  Float4Parameter.swift
//  Satin
//
//  Created by Reza Ali on 2/4/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

import Foundation
import simd

open class Float4Parameter: NSObject, Parameter {
    public weak var delegate: ParameterDelegate?
    
    public static var type = ParameterType.float4
    public var controlType: ControlType
    public let label: String
    public var string: String { return "float4" }
    public var size: Int { return MemoryLayout<simd_float4>.size }
    public var stride: Int { return MemoryLayout<simd_float4>.stride }
    public var alignment: Int { return MemoryLayout<simd_float4>.alignment }
    public var count: Int { return 4 }
    public var actions: [(simd_float4) -> Void] = []
    public subscript<Float>(index: Int) -> Float {
        get {
            return value[index % count] as! Float
        }
        set {
            value[index % count] = newValue as! Swift.Float
        }
    }
    
    public func dataType<Float>() -> Float.Type {
        return Float.self
    }
    
    @objc public dynamic var x: Float {
        didSet {
            if !valueChanged, oldValue != x {
                emit()
            }
        }
    }
    @objc public dynamic var y: Float {
        didSet {
            if !valueChanged, oldValue != y {
                emit()
            }
        }
    }
    @objc public dynamic var z: Float {
        didSet {
            if !valueChanged, oldValue != z {
                emit()
            }
        }
    }
    @objc public dynamic var w: Float {
        didSet {
            if !valueChanged, oldValue != w {
                emit()
            }
        }
    }
    
    @objc public dynamic var minX: Float
    @objc public dynamic var maxX: Float
    
    @objc public dynamic var minY: Float
    @objc public dynamic var maxY: Float
    
    @objc public dynamic var minZ: Float
    @objc public dynamic var maxZ: Float
    
    @objc public dynamic var minW: Float
    @objc public dynamic var maxW: Float
    
    var valueChanged: Bool = false

    public var value: simd_float4 {
        get {
            return simd_make_float4(x, y, z, w)
        }
        set(newValue) {
            if x != newValue.x || y != newValue.y || z != newValue.z || w != newValue.w {
                valueChanged = true
                x = newValue.x
                y = newValue.y
                z = newValue.z
                w = newValue.w
                emit()
            }
        }
    }
    
    public var min: simd_float4 {
        get {
            return simd_make_float4(minX, minY, minZ, minW)
        }
        set(newValue) {
            minX = newValue.x
            minY = newValue.y
            minZ = newValue.z
            minW = newValue.w
        }
    }
    
    public var max: simd_float4 {
        get {
            return simd_make_float4(maxX, maxY, maxZ, maxW)
        }
        set(newValue) {
            maxX = newValue.x
            maxY = newValue.y
            maxZ = newValue.z
            maxW = newValue.w
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case controlType
        case label
        case x
        case y
        case z
        case w
        case minX
        case maxX
        case minY
        case maxY
        case minZ
        case maxZ
        case minW
        case maxW
    }
    
    public init(_ label: String, _ value: simd_float4, _ min: simd_float4, _ max: simd_float4, _ controlType: ControlType = .unknown, _ action: ((simd_float4) -> Void)? = nil) {
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
        
        if let a = action {
            actions.append(a)
        }
        super.init()
    }
    
    public init(_ label: String, _ value: simd_float4 = simd_make_float4(0.0), _ controlType: ControlType = .unknown, _ action: ((simd_float4) -> Void)? = nil) {
        self.label = label
        self.controlType = controlType
        
        self.x = value.x
        self.y = value.y
        self.z = value.z
        self.w = value.w
        
        self.minX = 0.0
        self.maxX = 1.0
        
        self.minY = 0.0
        self.maxY = 1.0
        
        self.minZ = 0.0
        self.maxZ = 1.0
        
        self.minW = 0.0
        self.maxW = 1.0
        
        if let a = action {
            actions.append(a)
        }
        super.init()
    }
    
    public init(_ label: String, _ controlType: ControlType = .unknown, _ action: ((simd_float4) -> Void)? = nil) {
        self.label = label
        self.controlType = controlType
        
        self.x = 0.0
        self.y = 0.0
        self.z = 0.0
        self.w = 0.0
        
        self.minX = 0.0
        self.maxX = 1.0
        
        self.minY = 0.0
        self.maxY = 1.0
        
        self.minZ = 0.0
        self.maxZ = 1.0
        
        self.minW = 0.0
        self.maxW = 1.0
        
        if let a = action {
            actions.append(a)
        }
        super.init()
    }
    
    public func alignData(pointer: UnsafeMutableRawPointer, offset: inout Int) -> UnsafeMutableRawPointer {
        var data = pointer
        let rem = offset % alignment
        if rem > 0 {
            let remOffset = alignment - rem
            data += remOffset
            offset += remOffset
        }
        return data
    }
    
    
    public func writeData(pointer: UnsafeMutableRawPointer, offset: inout Int) -> UnsafeMutableRawPointer {
        var data = alignData(pointer: pointer, offset: &offset)
        offset += size
        
        let fsize = MemoryLayout<Float>.size
        data.storeBytes(of: x, as: Float.self)
        data += fsize
        data.storeBytes(of: y, as: Float.self)
        data += fsize
        data.storeBytes(of: z, as: Float.self)
        data += fsize
        data.storeBytes(of: w, as: Float.self)
        data += fsize
        
        return data
    }
    
    func emit() {
        delegate?.update(parameter: self)
        for action in self.actions {
            action(self.value)
        }
        valueChanged = false
    }
    
    deinit {
        delegate = nil
        actions = []
    }
}
