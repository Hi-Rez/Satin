//
//  IntParameter.swift
//  Satin
//
//  Created by Reza Ali on 10/22/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

public class IntParameter: GenericParameterWithMinMax<Int> {
    override public var type: ParameterType { .int }
    override public var string: String { "int" }
    override public var count: Int { 1 }

    override public var size: Int { return MemoryLayout<Int32>.size }
    override public var stride: Int { return MemoryLayout<Int32>.stride }
    override public var alignment: Int { return MemoryLayout<Int32>.alignment }

    override public func dataType<Int32>() -> Int32.Type {
        return Int32.self
    }

    public convenience init(_ label: String, _ value: ValueType, _ controlType: ControlType = .unknown) {
        self.init(label, value, 0, 1, controlType)
    }

    override public func writeData(pointer: UnsafeMutableRawPointer, offset: inout Int) -> UnsafeMutableRawPointer {
        var data = alignData(pointer: pointer, offset: &offset)
        data.storeBytes(of: Int32(value), as: dataType())
        data += size
        offset += size
        return data
    }
}
