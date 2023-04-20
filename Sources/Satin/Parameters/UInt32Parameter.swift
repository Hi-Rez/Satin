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

    override public var value: GenericParameter<UInt32>.ValueType {
        didSet {
            if value != oldValue {
                delegate?.updated(parameter: self)
            }
        }
    }

    public convenience init(_ label: String, _ value: ValueType, _ controlType: ControlType = .none) {
        self.init(label, value, 0, 1, controlType)
    }
}
