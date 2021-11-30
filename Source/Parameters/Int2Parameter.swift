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
    public weak var delegate: ParameterDelegate?
    
    public static var type = ParameterType.int2
    public var controlType: ControlType
    public let label: String
    public var string: String { return "int2" }
    public var size: Int { return MemoryLayout<simd_int2>.size }
    public var stride: Int { return MemoryLayout<simd_int2>.stride }
    public var alignment: Int { return MemoryLayout<simd_int2>.alignment }
    public var count: Int { return 2 }
    public var actions: [(simd_int2) -> Void] = []
    
    public subscript<Int32>(index: Int) -> Int32 {
        get {
            return value[index % count] as! Int32
        }
        set {
            value[index % count] = newValue as! Swift.Int32
        }
    }
    
    public func dataType<Int32>() -> Int32.Type {
        return Int32.self
    }
    
    var observers: [NSKeyValueObservation] = []
    
    @objc public dynamic var x: Int32
    @objc public dynamic var y: Int32
    
    @objc public dynamic var minX: Int32
    @objc public dynamic var maxX: Int32
    
    @objc public dynamic var minY: Int32
    @objc public dynamic var maxY: Int32
    
    var valueChanged: Bool = false
    
    public var value: simd_int2 {
        get {
            return simd_make_int2(x, y)
        }
        set(newValue) {
            if x != newValue.x || y != newValue.y {
                valueChanged = true
                x = newValue.x
                y = newValue.y
                emit()
            }
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
    
    private enum CodingKeys: String, CodingKey {
        case controlType
        case label
        case x
        case y
        case minX
        case maxX
        case minY
        case maxY
    }
    
    public init(_ label: String, _ value: simd_int2, _ min: simd_int2, _ max: simd_int2, _ controlType: ControlType = .unknown, _ action: ((simd_int2) -> Void)? = nil) {
        self.label = label
        self.controlType = controlType
        
        self.x = value.x
        self.y = value.y
        
        self.minX = min.x
        self.maxX = max.x
        
        self.minY = min.y
        self.maxY = max.y
        
        if let a = action {
            actions.append(a)
        }
        super.init()
    }
    
    public init(_ label: String, _ value: simd_int2 = simd_make_int2(0), _ controlType: ControlType = .unknown, _ action: ((simd_int2) -> Void)? = nil) {
        self.label = label
        self.controlType = controlType
        
        self.x = value.x
        self.y = value.y
        
        self.minX = 0
        self.maxX = 100
        
        self.minY = 0
        self.maxY = 100
        
        if let a = action {
            actions.append(a)
        }
        super.init()
    }
    
    public init(_ label: String, _ controlType: ControlType = .unknown, _ action: ((simd_int2) -> Void)? = nil) {
        self.label = label
        self.controlType = controlType
        
        self.x = 0
        self.y = 0
        
        self.minX = 0
        self.maxX = 100
        
        self.minY = 0
        self.maxY = 100
        
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
                
        let isize = MemoryLayout<Int32>.size
        data.storeBytes(of: x, as: Int32.self)
        data += isize
        data.storeBytes(of: y, as: Int32.self)
        data += isize
                
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
