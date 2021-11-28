//
//  IntParameter.swift
//  Satin
//
//  Created by Reza Ali on 10/22/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

open class IntParameter: NSObject, Parameter {
    public weak var delegate: ParameterDelegate?
    
    public static var type = ParameterType.int
    public var controlType: ControlType
    public let label: String
    public var string: String { return "int" }
    public var size: Int { return MemoryLayout<Int32>.size }
    public var stride: Int { return MemoryLayout<Int32>.stride }
    public var alignment: Int { return MemoryLayout<Int32>.alignment }
    public var count: Int { return 1 }
    public var actions: [(Int) -> Void] = []
    
    public subscript<Int32>(index: Int) -> Int32 {
        get {
            return value as! Int32
        }
        set {
            value = newValue as! Int
        }
    }

    public func dataType<Int32>() -> Int32.Type {
        return Int32.self
    }
    

    @objc public dynamic var value: Int {
        didSet {
            if oldValue != value {
                emit()
            }
        }
    }
    @objc public dynamic var min: Int
    @objc public dynamic var max: Int

    private enum CodingKeys: String, CodingKey {
        case controlType
        case label
        case value
        case min
        case max
    }
    
    public init(_ label: String, _ value: Int, _ min: Int, _ max: Int, _ controlType: ControlType = .unknown, _ action: ((Int) -> Void)? = nil) {
        self.label = label
        self.controlType = controlType

        self.value = value
        self.min = min
        self.max = max
        
        if let a = action {
            actions.append(a)
        }
        super.init()
    }

    public init(_ label: String, _ value: Int = 0, _ controlType: ControlType = .unknown, _ action: ((Int) -> Void)? = nil) {
        self.label = label
        self.controlType = controlType

        self.value = value
        self.min = 0
        self.max = 100
        
        if let a = action {
            actions.append(a)
        }
        super.init()
    }

    public init(_ label: String, _ controlType: ControlType = .unknown, _ action: ((Int) -> Void)? = nil) {
        self.label = label
        self.controlType = controlType

        self.value = 0
        self.min = 0
        self.max = 100
        
        if let a = action {
            actions.append(a)
        }
        super.init()

    }
    
    func emit() {
        delegate?.update(parameter: self)
        for action in self.actions {
            action(self.value)
        }
    }
    
    deinit {
        delegate = nil
        actions = []
    }
}
