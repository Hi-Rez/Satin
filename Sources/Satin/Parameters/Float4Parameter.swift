//
//  Float4Parameter.swift
//  Satin
//
//  Created by Reza Ali on 2/4/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

import Foundation
import simd

public class Float4Parameter: GenericParameterWithMinMax<simd_float4> {
    override public var type: ParameterType { .float4 }
    override public var string: String { "float4" }
    override public var count: Int { 4 }

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
