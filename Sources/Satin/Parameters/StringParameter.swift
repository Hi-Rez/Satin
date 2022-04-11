//
//  StringParameter.swift
//  Satin
//
//  Created by Reza Ali on 10/30/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

public class StringParameter: GenericParameter<String> {
    override public var type: ParameterType { .string }
    override public var string: String { "string" }
    override public var count: Int { value.count }

    @PublishedDidSet public var options: [String] = []

    private enum CodingKeys: String, CodingKey {
        case controlType
        case label
        case value
        case options
    }

    public convenience init(_ label: String, _ value: ValueType = "", _ options: [String], _ controlType: ControlType = .dropdown, _ action: ((ValueType) -> Void)? = nil) {
        self.init(label, value, controlType, action)
        self.options = options
    }
}
