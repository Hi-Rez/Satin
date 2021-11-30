//
//  BoolParameter.swift
//  Satin
//
//  Created by Reza Ali on 10/22/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

open class BoolParameter: NSObject, Parameter {
    public weak var delegate: ParameterDelegate?
    
    public static var type = ParameterType.bool
    public var controlType: ControlType
    public let label: String
    public var string: String { return "bool" }
    public var size: Int { return MemoryLayout<Bool>.size }
    public var stride: Int { return MemoryLayout<Bool>.stride }
    public var alignment: Int { return MemoryLayout<Bool>.alignment }
    public var count: Int { return 1 }
    public var actions: [(Bool) -> Void] = []
    
    public subscript<Bool>(index: Int) -> Bool {
        get {
            return value as! Bool
        }
        set {
            value = newValue as! Swift.Bool
        }
    }
    
    public func dataType<Bool>() -> Bool.Type {
        return Bool.self
    }
    
    @objc public dynamic var value: Bool {
        didSet {
            if oldValue != value {
                emit()
            }
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case controlType
        case label
        case value
    }
        
    public init(_ label: String, _ value: Bool = false, _ controlType: ControlType = .unknown, _ action: ((Bool) -> Void)? = nil) {
        self.label = label
        self.controlType = controlType
        self.value = value
        if let a = action {
            actions.append(a)
        }
        super.init()
    }
    
    public init(_ label: String, _ controlType: ControlType = .unknown, _ action: ((Bool) -> Void)? = nil) {
        self.label = label
        self.controlType = controlType
        self.value = false
        if let a = action {
            actions.append(a)
        }
        super.init()
    }
    
    public func alignData(pointer: UnsafeMutableRawPointer, offset: inout Int) -> UnsafeMutableRawPointer {
        var data = pointer
        let rem = offset % alignment
        if rem > 0 {
            let remOffset = alignment - rem
            data += remOffset
            offset += remOffset
        }
        return data
    }
    
    public func writeData(pointer: UnsafeMutableRawPointer, offset: inout Int) -> UnsafeMutableRawPointer {
        var data = alignData(pointer: pointer, offset: &offset)
        offset += size
        
        data.storeBytes(of: value, as: Bool.self)
        data += size
        
        return data
    }
    
    func emit() {
        delegate?.update(parameter: self)
        for action in actions {
            action(value)
        }
    }
    
    deinit {
        delegate = nil
        actions = []
    }
}
