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
    public var string: String { return "bool" }
    public var size: Int { return MemoryLayout<Bool>.size }
    public var stride: Int { return MemoryLayout<Bool>.stride }
    public var alignment: Int { return MemoryLayout<Bool>.alignment }
    
    @objc dynamic public var value: Bool

    public init(_ label: String, _ value: Bool = false, _ controlType: ControlType = .unknown) {
        self.label = label
        self.controlType = controlType        
        self.value = value
    }
}
