//
//  UInt32Parameter.swift
//  Satin
//
//  Created by Reza Ali on 4/22/20.
//

import Foundation

public class UInt32Parameter: GenericParameterWithMinMax<UInt32> {
    override public var type: ParameterType { .uint32 }
    override public var string: String { "uint32_t" }
    override public var count: Int { 1 }
    
    public convenience init(_ label: String, _ value: ValueType, _ controlType: ControlType = .unknown, _ action: ((ValueType) -> Void)? = nil) {
        self.init(label, value, 0, 1, controlType, action)
    }
}

//open class UInt32Parameter: NSObject, Parameter {
//    public weak var delegate: ParameterDelegate?
//
//    public var type = ParameterType.uint32
//    public var controlType: ControlType
//    public let label: String
//    public var string: String { return "uint32_t" }
//    public var size: Int { return MemoryLayout<UInt32>.size }
//    public var stride: Int { return MemoryLayout<UInt32>.stride }
//    public var alignment: Int { return MemoryLayout<UInt32>.alignment }
//    public var count: Int { return 1 }
//    public var actions: [(UInt32) -> Void] = []
//
//    public func onChange(_ fn: @escaping ((UInt32) -> ())) {
//        actions.append(fn)
//    }
//
//    public subscript<UInt32>(index: Int) -> UInt32 {
//        get {
//            return value as! UInt32
//        }
//        set {
//            value = newValue as! Swift.UInt32
//        }
//    }
//
//    public func dataType<UInt32>() -> UInt32.Type {
//        return UInt32.self
//    }
//
//    @objc public dynamic var value: UInt32 {
//        didSet {
//            if oldValue != value {
//                emit()
//            }
//        }
//    }
//
//    @objc public dynamic var min: UInt32
//    @objc public dynamic var max: UInt32
//
//    private enum CodingKeys: String, CodingKey {
//        case controlType
//        case label
//        case value
//        case min
//        case max
//    }
//
//    public init(_ label: String, _ value: UInt32, _ min: UInt32, _ max: UInt32, _ controlType: ControlType = .unknown, _ action: ((UInt32) -> Void)? = nil) {
//        self.label = label
//        self.controlType = controlType
//
//        self.value = value
//        self.min = min
//        self.max = max
//
//        if let a = action {
//            actions.append(a)
//        }
//        super.init()
//    }
//
//    public init(_ label: String, _ value: UInt32 = 0, _ controlType: ControlType = .unknown, _ action: ((UInt32) -> Void)? = nil) {
//        self.label = label
//        self.controlType = controlType
//
//        self.value = value
//        self.min = 0
//        self.max = 100
//
//        if let a = action {
//            actions.append(a)
//        }
//        super.init()
//    }
//
//    public init(_ label: String, _ controlType: ControlType = .unknown, _ action: ((UInt32) -> Void)? = nil) {
//        self.label = label
//        self.controlType = controlType
//
//        self.value = 0
//        self.min = 0
//        self.max = 100
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
//    public func writeData(pointer: UnsafeMutableRawPointer, offset: inout Int) -> UnsafeMutableRawPointer {
//        var data = alignData(pointer: pointer, offset: &offset)
//        offset += size
//
//        data.storeBytes(of: value, as: UInt32.self)
//        data += size
//
//        return data
//    }
//
//    func emit() {
//        delegate?.updated(parameter: self)
//        for action in self.actions {
//            action(self.value)
//        }
//    }
//
//    deinit {
//        delegate = nil
//        actions = []
//    }
//}
