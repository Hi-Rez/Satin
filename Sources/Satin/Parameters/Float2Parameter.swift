//
//  Float2Parameter.swift
//  Satin
//
//  Created by Reza Ali on 2/4/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

import Foundation
import simd

public class Float2Parameter: GenericParameterWithMinMax<simd_float2> {
    override public var type: ParameterType { .float2 }
    override public var string: String { "float2" }
    override public var count: Int { 2 }

    override public subscript<Float>(index: Int) -> Float {
        get {
            return value[index % count] as! Float
        }
        set {
            value[index % count] = newValue as! Swift.Float
        }
    }

    public convenience init(_ label: String, _ value: ValueType, _ controlType: ControlType = .unknown, _ action: ((ValueType) -> Void)? = nil) {
        self.init(label, value, .zero, .one, controlType, action)
    }
}

// open class Float2Parameter: NSObject, Parameter {
//    public weak var delegate: ParameterDelegate?
//
//    public var type = ParameterType.float2
//    public var controlType: ControlType
//    public let label: String
//    public var string: String { return "float2" }
//    public var size: Int { return MemoryLayout<simd_float2>.size }
//    public var stride: Int { return MemoryLayout<simd_float2>.stride }
//    public var alignment: Int { return MemoryLayout<simd_float2>.alignment }
//    public var count: Int { return 2 }
//    public var actions: [(simd_float2) -> Void] = []
//
//    public func onChange(_ fn: @escaping ((simd_float2) -> ())) {
//        actions.append(fn)
//    }
//
//    public subscript<Float>(index: Int) -> Float {
//        get {
//            return value[index % count] as! Float
//        }
//        set {
//            value[index % count] = newValue as! Swift.Float
//        }
//    }
//
//    public func dataType<Float>() -> Float.Type {
//        return Float.self
//    }
//
//    @objc public dynamic var x: Float {
//        didSet {
//            if !valueChanged, oldValue != x {
//                emit()
//            }
//        }
//    }
//    @objc public dynamic var y: Float {
//        didSet {
//            if !valueChanged, oldValue != y {
//                emit()
//            }
//        }
//    }
//
//    @objc public dynamic var minX: Float
//    @objc public dynamic var maxX: Float
//
//    @objc public dynamic var minY: Float
//    @objc public dynamic var maxY: Float
//
//    var valueChanged: Bool = false
//
//    public var value: simd_float2 {
//        get {
//            return simd_make_float2(x, y)
//        }
//        set(newValue) {
//            if x != newValue.x || y != newValue.y {
//                valueChanged = true
//                x = newValue.x
//                y = newValue.y
//                emit()
//            }
//        }
//    }
//
//    public var min: simd_float2 {
//        get {
//            return simd_make_float2(minX, minY)
//        }
//        set(newValue) {
//            minX = newValue.x
//            minY = newValue.y
//        }
//    }
//
//    public var max: simd_float2 {
//        get {
//            return simd_make_float2(maxX, maxY)
//        }
//        set(newValue) {
//            maxX = newValue.x
//            maxY = newValue.y
//        }
//    }
//
//    private enum CodingKeys: String, CodingKey {
//        case controlType
//        case label
//        case x
//        case y
//        case minX
//        case maxX
//        case minY
//        case maxY
//    }
//
//    public init(_ label: String, _ value: simd_float2, _ min: simd_float2, _ max: simd_float2, _ controlType: ControlType = .unknown, _ action: ((simd_float2) -> Void)? = nil) {
//        self.label = label
//        self.controlType = controlType
//
//        self.x = value.x
//        self.y = value.y
//        self.minX = min.x
//        self.maxX = max.x
//        self.minY = min.y
//        self.maxY = max.y
//
//        if let a = action {
//            actions.append(a)
//        }
//        super.init()
//    }
//
//    public init(_ label: String, _ value: simd_float2 = simd_make_float2(0.0), _ controlType: ControlType = .unknown, _ action: ((simd_float2) -> Void)? = nil) {
//        self.label = label
//        self.controlType = controlType
//
//        self.x = value.x
//        self.y = value.y
//        self.minX = 0.0
//        self.maxX = 1.0
//        self.minY = 0.0
//        self.maxY = 1.0
//
//        if let a = action {
//            actions.append(a)
//        }
//        super.init()
//    }
//
//    public init(_ label: String, _ controlType: ControlType = .unknown, _ action: ((simd_float2) -> Void)? = nil) {
//        self.label = label
//        self.controlType = controlType
//
//        self.x = 0.0
//        self.y = 0.0
//        self.minX = 0.0
//        self.maxX = 1.0
//        self.minY = 0.0
//        self.maxY = 1.0
//
//        if let a = action {
//            actions.append(a)
//        }
//        super.init()
//    }
//
//    public func alignData(pointer: UnsafeMutableRawPointer, offset: inout Int) -> UnsafeMutableRawPointer {
//        var data = pointer
//        let rem = offset % alignment
//        if rem > 0 {
//            let remOffset = alignment - rem
//            data += remOffset
//            offset += remOffset
//        }
//        return data
//    }
//
//
//    public func writeData(pointer: UnsafeMutableRawPointer, offset: inout Int) -> UnsafeMutableRawPointer {
//        var data = alignData(pointer: pointer, offset: &offset)
//        offset += size
//
//        let fsize = MemoryLayout<Float>.size
//        data.storeBytes(of: x, as: Float.self)
//        data += fsize
//        data.storeBytes(of: y, as: Float.self)
//        data += fsize
//
//        return data
//    }
//
//    func emit() {
//        delegate?.updated(parameter: self)
//        for action in self.actions {
//            action(self.value)
//        }
//        valueChanged = false
//    }
//
//    deinit {
//        delegate = nil
//        actions = []
//    }
// }
