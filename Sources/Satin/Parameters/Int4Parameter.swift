//
//  Int4Parameter.swift
//  Satin
//
//  Created by Reza Ali on 2/10/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

import Foundation
import simd

public class Int4Parameter: GenericParameterWithMinMax<simd_int4> {
    override public var type: ParameterType { .int4 }
    override public var string: String { "int4" }
    override public var count: Int { 4 }

    override public func dataType<Int32>() -> Int32.Type {
        return Int32.self
    }

    public convenience init(_ label: String, _ value: ValueType, _ controlType: ControlType = .unknown) {
        self.init(label, value, .zero, .one, controlType)
    }
}
