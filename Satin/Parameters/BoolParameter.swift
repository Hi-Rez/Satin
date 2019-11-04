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
    public let label: String
    @objc dynamic public var value: Bool

    public init(_ label: String, _ value: Bool) {
        self.label = label
        self.value = value
    }
}
