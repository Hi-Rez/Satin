//
//  FloatParameter.swift
//  Satin
//
//  Created by Reza Ali on 10/22/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

open class FloatParameter: NSObject, Parameter {
    public static var type = ParameterType.float
    public var controlType: ControlType
    public let label: String
    public var string: String { return "float" }
    public var size: Int { return MemoryLayout<Float>.size }
    public var stride: Int { return MemoryLayout<Float>.stride }
    public var alignment: Int { return MemoryLayout<Float>.alignment }
     
    @objc dynamic public var value: Float
    @objc dynamic public var min: Float
    @objc dynamic public var max: Float

    public init(_ label: String, _ value: Float, _ min: Float, _ max: Float, _ controlType: ControlType = .unknown) {
        self.label = label
        self.controlType = controlType
        
        self.value = value
        self.min = min
        self.max = max
    }
    
    public init(_ label: String, _ value: Float = 0.0, _ controlType: ControlType = .unknown) {
        self.label = label
        self.controlType = controlType
        
        self.value = value
        self.min = 0.0
        self.max = 1.0
    }
}
