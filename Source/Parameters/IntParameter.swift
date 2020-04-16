//
//  IntParameter.swift
//  Satin
//
//  Created by Reza Ali on 10/22/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

open class IntParameter: NSObject, Parameter {
    public static var type = ParameterType.int
    public var controlType: ControlType
    public let label: String
    public var string: String { return "int" }
    public var size: Int { return MemoryLayout<Int32>.size }
    public var stride: Int { return MemoryLayout<Int32>.stride }
    public var alignment: Int { return MemoryLayout<Int32>.alignment }

    @objc public dynamic var value: Int
    @objc public dynamic var min: Int
    @objc public dynamic var max: Int

    public init(_ label: String, _ value: Int, _ min: Int, _ max: Int, _ controlType: ControlType = .unknown) {
        self.label = label
        self.controlType = controlType

        self.value = value
        self.min = min
        self.max = max
    }

    public init(_ label: String, _ value: Int = 0, _ controlType: ControlType = .unknown) {
        self.label = label
        self.controlType = controlType

        self.value = value
        self.min = 0
        self.max = 100
    }
}
