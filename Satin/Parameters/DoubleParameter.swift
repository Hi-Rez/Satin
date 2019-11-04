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
    public let label: String
    @objc dynamic public var value: Double
    @objc dynamic public var min: Double
    @objc dynamic public var max: Double

    public init(_ label: String, _ value: Double, _ min: Double, _ max: Double) {
        self.label = label
        self.value = value
        self.min = min
        self.max = max
    }
}
