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

    public convenience init(_ label: String, _ value: ValueType, _ controlType: ControlType = .unknown) {
        self.init(label, value, .zero, .one, controlType)
    }
}
