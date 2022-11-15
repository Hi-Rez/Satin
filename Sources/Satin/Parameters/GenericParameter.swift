//
//  File.swift
//
//
//  Created by Reza Ali on 4/7/22.
//

import Combine
import Foundation

public class GenericParameter<T: Codable>: ValueParameter, ObservableObject {
    public typealias ValueType = T

    // Delegate
    public weak var delegate: ParameterDelegate?

    // Getable Properties
    public var type: ParameterType { .generic }
    public var string: String { "generic" }

    // Computed Properties
    public var size: Int { return MemoryLayout<ValueType>.size }
    public var stride: Int { return MemoryLayout<ValueType>.stride }
    public var alignment: Int { return MemoryLayout<ValueType>.alignment }
    public var count: Int { -1 }

    // Setable Properties
    public var controlType = ControlType.none
    public var label: String
    
    public var description: String {
        "Label: \(label) type: \(string) value: \(value)"
    }

    @Published public var value: ValueType {
        didSet {
            objectWillChange.send()
            delegate?.updated(parameter: self)
        }
    }

    public subscript<T>(index: Int) -> T {
        get {
            return value as! T
        }
        set {
            value = newValue as! ValueType
        }
    }

    public func dataType<T>() -> T.Type {
        return T.self
    }

    private enum CodingKeys: String, CodingKey {
        case controlType
        case label
        case value
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        controlType = try container.decode(ControlType.self, forKey: .controlType)
        label = try container.decode(String.self, forKey: .label)
        value = try container.decode(ValueType.self, forKey: .value)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(controlType, forKey: .controlType)
        try container.encode(label, forKey: .label)
        try container.encode(value, forKey: .value)
    }

    public init(_ label: String, _ value: ValueType, _ controlType: ControlType = .unknown) {
        self.label = label
        self.controlType = controlType
        self.value = value
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
        data.storeBytes(of: value, as: dataType())
        data += size
        offset += size
        return data
    }
}

public class GenericParameterWithMinMax<T: Codable>: GenericParameter<T> {
    @Published public var min: ValueType
    @Published public var max: ValueType

    private enum CodingKeys: String, CodingKey {
        case controlType
        case label
        case value
        case min
        case max
    }

    public init(_ label: String, _ value: ValueType, _ min: ValueType, _ max: ValueType, _ controlType: ControlType = .unknown) {
        self.min = min
        self.max = max
        super.init(label, value, controlType)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let controlType = try container.decode(ControlType.self, forKey: .controlType)
        let label = try container.decode(String.self, forKey: .label)
        let value = try container.decode(ValueType.self, forKey: .value)
        self.min = try container.decode(ValueType.self, forKey: .min)
        self.max = try container.decode(ValueType.self, forKey: .max)
        super.init(label, value, controlType)
    }

    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(controlType, forKey: .controlType)
        try container.encode(label, forKey: .label)
        try container.encode(value, forKey: .value)
        try container.encode(min, forKey: .min)
        try container.encode(max, forKey: .max)
    }
}
