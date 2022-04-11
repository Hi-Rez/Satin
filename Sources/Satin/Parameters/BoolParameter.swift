//
//  BoolParameter.swift
//  Satin
//
//  Created by Reza Ali on 10/22/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Combine
import Foundation

public class BoolParameter: GenericParameter<Bool> {
    override public var type: ParameterType { .bool }
    override public var string: String { "bool" }
    override public var count: Int { 1 }
}
