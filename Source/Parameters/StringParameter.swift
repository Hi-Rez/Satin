//
//  StringParameter.swift
//  Satin
//
//  Created by Reza Ali on 10/30/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

open class StringParameter: NSObject, Parameter {
    public static var type = ParameterType.string
    public var controlType: ControlType
    public let label: String
    public var string: String { return "string" }
    public var size: Int { return MemoryLayout<String>.size }
    public var stride: Int { return MemoryLayout<String>.stride }
    public var alignment: Int { return MemoryLayout<String>.alignment }

    @objc public dynamic var value: String
    @objc public dynamic var options: [String] = []

    public init(_ label: String, _ value: String, _ controlType: ControlType = .unknown) {
        self.label = label
        self.controlType = controlType
        self.value = value
    }

    public init(_ label: String, _ value: String = "", _ options: [String], _ controlType: ControlType = .dropdown) {
        self.label = label
        self.controlType = controlType
        self.value = value
        self.options = options
    }
}
