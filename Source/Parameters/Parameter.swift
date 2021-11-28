//
//  AnyParameter.swift
//  Satin
//
//  Created by Reza Ali on 10/22/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

public protocol ParameterDelegate: AnyObject {
    func update(parameter: Parameter)
}
    
public protocol Parameter: NSObject, Codable {
    static var type: ParameterType { get }
    var controlType: ControlType { get set }
    var label: String { get }
    var string: String { get }
    var size: Int { get }
    var stride: Int { get }
    var alignment: Int { get }
    var count: Int { get }    
    subscript<T>(index: Int) -> T { get set }
    func dataType<T>() -> T.Type
    var delegate: ParameterDelegate? { get set }
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
    case dropdown
    case label
    case filepicker
}

public enum ParameterType: String, Codable {
    case float, float2, float3, float4, bool, int, int2, int3, int4, double, string, packedfloat3, uint32, file

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
        case .file:
            return FileParameter.self
        }
    }
}
