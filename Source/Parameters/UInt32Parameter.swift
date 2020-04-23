//
//  UInt32Parameter.swift
//  Satin
//
//  Created by Reza Ali on 4/22/20.
//

import Foundation

open class UInt32Parameter: NSObject, Parameter {
    public static var type = ParameterType.uint32
    public var controlType: ControlType
    public let label: String
    public var string: String { return "uint32_t" }
    public var size: Int { return MemoryLayout<UInt32>.size }
    public var stride: Int { return MemoryLayout<UInt32>.stride }
    public var alignment: Int { return MemoryLayout<UInt32>.alignment }

    @objc public dynamic var value: UInt32
    @objc public dynamic var min: UInt32
    @objc public dynamic var max: UInt32

    public init(_ label: String, _ value: UInt32, _ min: UInt32, _ max: UInt32, _ controlType: ControlType = .unknown) {
        self.label = label
        self.controlType = controlType

        self.value = value
        self.min = min
        self.max = max
    }

    public init(_ label: String, _ value: UInt32 = 0, _ controlType: ControlType = .unknown) {
        self.label = label
        self.controlType = controlType

        self.value = value
        self.min = 0
        self.max = 100
    }
}
