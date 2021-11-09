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
    public var controlType: ControlType
    public let label: String
    public var string: String { return "float2" }
    public var size: Int { return MemoryLayout<simd_float2>.size }
    public var stride: Int { return MemoryLayout<simd_float2>.stride }
    public var alignment: Int { return MemoryLayout<simd_float2>.alignment }
    public var count: Int { return 2 }
    public var actions: [(simd_float2) -> Void] = []
    
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
    
    var observers: [NSKeyValueObservation] = []
    
    @objc public dynamic var x: Float
    @objc public dynamic var y: Float
    
    @objc public dynamic var minX: Float
    @objc public dynamic var maxX: Float
    
    @objc public dynamic var minY: Float
    @objc public dynamic var maxY: Float
    
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
    
    public init(_ label: String, _ value: simd_float2, _ min: simd_float2, _ max: simd_float2, _ controlType: ControlType = .unknown, _ action: ((simd_float2) -> Void)? = nil) {
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
        setup()
    }
    
    public init(_ label: String, _ value: simd_float2 = simd_make_float2(0.0), _ controlType: ControlType = .unknown, _ action: ((simd_float2) -> Void)? = nil) {
        self.label = label
        self.controlType = controlType
        
        self.x = value.x
        self.y = value.y
        self.minX = 0.0
        self.maxX = 1.0
        self.minY = 0.0
        self.maxY = 1.0
        
        if let a = action {
            actions.append(a)
        }
        super.init()
        setup()
    }
    
    public init(_ label: String, _ controlType: ControlType = .unknown, _ action: ((simd_float2) -> Void)? = nil) {
        self.label = label
        self.controlType = controlType
        
        self.x = 0.0
        self.y = 0.0
        self.minX = 0.0
        self.maxX = 1.0
        self.minY = 0.0
        self.maxY = 1.0
        
        if let a = action {
            actions.append(a)
        }
        super.init()
        setup()
    }
    
    func setup() {
        observers.append(observe(\.x) { [unowned self] _, _ in
            for action in self.actions {
                action(self.value)
            }
        })
        observers.append(observe(\.y) { [unowned self] _, _ in
            for action in self.actions {
                action(self.value)
            }
        })
    }
    
    deinit {
        observers = []
        actions = []
    }
}
