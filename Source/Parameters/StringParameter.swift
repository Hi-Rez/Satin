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
    
    @objc dynamic public var value: String    
    
    public init(_ label: String, _ value: String, _ controlType: ControlType = .unknown) {
        self.label = label
        self.controlType = controlType
        
        self.value = value        
    }
}
