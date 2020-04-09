//
//  BoolParameter.swift
//  Satin
//
//  Created by Reza Ali on 10/22/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

open class BoolParameter: NSObject, Parameter {
    public static var type = ParameterType.bool
    public var controlType: ControlType
    public let label: String
    
    @objc dynamic public var value: Bool

    public init(_ label: String, _ value: Bool, _ controlType: ControlType = .unknown) {
        self.label = label
        self.controlType = controlType
        
        self.value = value
    }
}
