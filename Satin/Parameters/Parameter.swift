//
//  AnyParameter.swift
//  Satin
//
//  Created by Reza Ali on 10/22/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

public protocol Parameter: Codable {
    static var type: ParameterType { get }
    var label: String { get }
}

public enum ParameterType: String, Codable {
    case float, float2, float3, float4, bool, int, int2, double, string

    var metatype: Parameter.Type {
        switch self {
        case .bool:
            return BoolParameter.self
        case .int:
            return IntParameter.self
        case .int2:
            return Int2Parameter.self
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
        }
    }
}
