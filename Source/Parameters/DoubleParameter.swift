//
//  DoubleParameter.swift
//  Satin
//
//  Created by Reza Ali on 10/22/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

open class DoubleParameter: NSObject, Parameter {
    public weak var delegate: ParameterDelegate?
    
    public static var type = ParameterType.double
    public var controlType: ControlType
    public let label: String
    public var string: String { return "double" }
    public var size: Int { return MemoryLayout<Double>.size }
    public var stride: Int { return MemoryLayout<Double>.stride }
    public var alignment: Int { return MemoryLayout<Double>.alignment }
    public var count: Int { return 1 }
    public var actions: [(Double) -> Void] = []

    public subscript<Double>(index: Int) -> Double {
        get {
            return value as! Double
        }
        set {
            value = newValue as! Swift.Double
        }
    }
    
    public func dataType<Double>() -> Double.Type {
        return Double.self
    }
    
    private enum CodingKeys: String, CodingKey {
        case controlType
        case label
        case value
        case min
        case max
    }
    
    @objc public dynamic var value: Double {
        didSet {
            if oldValue != value {
                emit()
            }
        }
    }
    @objc public dynamic var min: Double
    @objc public dynamic var max: Double
    
    public init(_ label: String, _ value: Double, _ min: Double, _ max: Double, _ controlType: ControlType = .unknown, _ action: ((Double) -> Void)? = nil) {
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
    
    public init(_ label: String, _ value: Double = 0.0, _ controlType: ControlType = .unknown, _ action: ((Double) -> Void)? = nil) {
        self.label = label
        self.controlType = controlType
        
        self.value = value
        self.min = 0.0
        self.max = 1.0
        
        if let a = action {
            actions.append(a)
        }
        super.init()
    }
    
    public init(_ label: String, _ controlType: ControlType = .unknown, _ action: ((Double) -> Void)? = nil) {
        self.label = label
        self.controlType = controlType
        
        self.value = 0.0
        self.min = 0.0
        self.max = 1.0
        
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
