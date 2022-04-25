//
//  PackedFloat3Parameter.swift
//  Satin
//
//  Created by Reza Ali on 4/22/20.
//

import Foundation
import simd

public class PackedFloat3Parameter: GenericParameterWithMinMax<simd_float3> {
    override public var type: ParameterType { .packedfloat3 }
    override public var string: String { "packed_float3" }
    override public var count: Int { 3 }

    override public var size: Int { return 12 }
    override public var stride: Int { return 12 }
    override public var alignment: Int { return 4 }

    override public subscript<Float>(index: Int) -> Float {
        get {
            return value[index % count] as! Float
        }
        set {
            value[index % count] = newValue as! Swift.Float
        }
    }

    public convenience init(_ label: String, _ value: ValueType, _ controlType: ControlType = .unknown) {
        self.init(label, value, .zero, .one, controlType)
    }
}
