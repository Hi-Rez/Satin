//
//  FloatParameter.swift
//  Satin
//
//  Created by Reza Ali on 10/22/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

public class FloatParameter: GenericParameterWithMinMax<Float> {
    override public var type: ParameterType { .float }
    override public var string: String { "float" }
    override public var count: Int { 1 }

    override public var value: GenericParameter<Float>.ValueType {
        didSet {
            if value != oldValue {
                delegate?.updated(parameter: self)
            }
        }
    }

    public convenience init(_ label: String, _ value: ValueType, _ controlType: ControlType = .none) {
        self.init(label, value, 0.0, 1.0, controlType)
    }
}
