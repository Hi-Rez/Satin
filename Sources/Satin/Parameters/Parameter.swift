//
//  AnyParameter.swift
//  Satin
//
//  Created by Reza Ali on 10/22/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Combine
import Foundation

public protocol ParameterDelegate: AnyObject {
    func updated(parameter: Parameter)
}

public protocol Parameter: Codable, CustomStringConvertible, AnyObject {
    var type: ParameterType { get }
    var string: String { get }

    var size: Int { get }
    var stride: Int { get }
    var alignment: Int { get }
    var count: Int { get }

    var controlType: ControlType { get set }
    var label: String { get }
    var description: String { get }

    var delegate: ParameterDelegate? { get set }

    subscript<T>(index: Int) -> T { get set }
    func dataType<T>() -> T.Type

    func alignData(pointer: UnsafeMutableRawPointer, offset: inout Int) -> UnsafeMutableRawPointer
    func writeData(pointer: UnsafeMutableRawPointer, offset: inout Int) -> UnsafeMutableRawPointer
}

public protocol ValueParameter: Parameter {
    associatedtype ValueType: Codable
    var value: ValueType { get set }
}

public protocol ValueMinMaxParameter: ValueParameter {
    var min: ValueType { get set }
    var max: ValueType { get set }
}

public enum ControlType: String, Codable {
    case none
    case unknown
    case slider
    case multislider
    case xypad
    case toggle
    case button
    case inputfield
    case colorpicker
    case colorpalette
    case dropdown
    case label
    case filepicker
}

public enum ParameterType: String, Codable {
    case float, float2, float3, float4, bool, int, int2, int3, int4, double, string, packedfloat3, uint32, float4x4, float3x3, float2x2, generic

    var metatype: Parameter.Type {
        switch self {
        case .bool:
            return BoolParameter.self
        case .int:
            return IntParameter.self
        case .int2:
            return Int2Parameter.self
        case .int3:
            return Int3Parameter.self
        case .int4:
            return Int4Parameter.self
        case .float:
            return FloatParameter.self
        case .float2:
            return Float2Parameter.self
        case .float3:
            return Float3Parameter.self
        case .float4:
            return Float4Parameter.self
        case .double:
            return DoubleParameter.self
        case .string:
            return StringParameter.self
        case .packedfloat3:
            return PackedFloat3Parameter.self
        case .uint32:
            return UInt32Parameter.self
        case .float3x3:
            return Float3x3Parameter.self
        case .float4x4:
            return Float4x4Parameter.self
        default:
            fatalError("Unknown Parameter Type")
        }
    }
}
