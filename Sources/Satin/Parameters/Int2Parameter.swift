//
//  Int2Parameter.swift
//  Satin
//
//  Created by Reza Ali on 2/5/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

import Foundation
import simd

public class Int2Parameter: GenericParameterWithMinMax<simd_int2> {
    override public var type: ParameterType { .int2 }
    override public var string: String { "int2" }
    override public var count: Int { 2 }

    override public func dataType<Int32>() -> Int32.Type {
        return Int32.self
    }
    
    public override subscript<T>(index: Int) -> T {
        get {
            return value[index] as! T
        }
        set {
            value[index] = newValue as! Int32
        }
    }

    public convenience init(_ label: String, _ value: ValueType, _ controlType: ControlType = .unknown) {
        self.init(label, value, .zero, .one, controlType)
    }
}
