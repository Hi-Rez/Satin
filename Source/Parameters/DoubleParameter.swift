//
//  DoubleParameter.swift
//  Satin
//
//  Created by Reza Ali on 10/22/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

open class DoubleParameter: NSObject, Parameter {
    public static var type = ParameterType.double
    public var controlType: ControlType
    public let label: String
    public var string: String { return "double" }
    public var size: Int { return MemoryLayout<Double>.size }
    public var stride: Int { return MemoryLayout<Double>.stride }
    public var alignment: Int { return MemoryLayout<Double>.alignment }
    
    @objc dynamic public var value: Double
    @objc dynamic public var min: Double
    @objc dynamic public var max: Double

    public init(_ label: String, _ value: Double, _ min: Double, _ max: Double, _ controlType: ControlType = .unknown) {
        self.label = label
        self.controlType = controlType
        
        self.value = value
        self.min = min
        self.max = max
    }
    
    public init(_ label: String, _ value: Double = 0.0, _ controlType: ControlType = .unknown) {
        self.label = label
        self.controlType = controlType
        
        self.value = value
        self.min = 0.0
        self.max = 1.0
    }
}
