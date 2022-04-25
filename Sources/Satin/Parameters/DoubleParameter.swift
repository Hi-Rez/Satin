//
//  DoubleParameter.swift
//  Satin
//
//  Created by Reza Ali on 10/22/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

public class DoubleParameter: GenericParameterWithMinMax<Double> {
    override public var type: ParameterType { .double }
    override public var string: String { "double" }
    override public var count: Int { 1 }

    public convenience init(_ label: String, _ value: ValueType, _ controlType: ControlType = .unknown) {
        self.init(label, value, 0.0, 1.0, controlType)
    }
}
