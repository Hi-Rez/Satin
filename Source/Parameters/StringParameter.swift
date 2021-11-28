//
//  StringParameter.swift
//  Satin
//
//  Created by Reza Ali on 10/30/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

open class StringParameter: NSObject, Parameter {
    public weak var delegate: ParameterDelegate?
    
    public static var type = ParameterType.string
    public var controlType: ControlType
    public let label: String
    public var string: String { return "string" }
    public var size: Int { return MemoryLayout<String>.size }
    public var stride: Int { return MemoryLayout<String>.stride }
    public var alignment: Int { return MemoryLayout<String>.alignment }
    public var count: Int { return value.count }
    public var actions: [(String) -> Void] = []
    
    public subscript<String>(index: Int) -> String {
        get {
            return value[value.index(value.startIndex, offsetBy: index % count)] as! String
        }
        set {
            let tmp = newValue as! Swift.String
            let start = value.index(value.startIndex, offsetBy: index % count)
            let end = value.index(value.startIndex, offsetBy: (index % count) + tmp.count)
            value.replaceSubrange(start..<end, with: tmp)
        }
    }

    public func dataType<String>() -> String.Type {
        return String.self
    }


    @objc public dynamic var value: String {
        didSet {
            if oldValue != value {
                emit()
            }
        }
    }

    @objc public dynamic var options: [String] = []

    private enum CodingKeys: String, CodingKey {
        case controlType
        case label
        case value
        case options
    }
    
    public init(_ label: String, _ value: String, _ controlType: ControlType = .unknown, _ action: ((String) -> Void)? = nil) {
        self.label = label
        self.controlType = controlType
        self.value = value
        if let a = action {
            actions.append(a)
        }
        super.init()
    }
    
    public init(_ label: String, _ controlType: ControlType = .unknown, _ action: ((String) -> Void)? = nil) {
        self.label = label
        self.controlType = controlType
        self.value = ""
        if let a = action {
            actions.append(a)
        }
        super.init()
    }

    public init(_ label: String, _ value: String = "", _ options: [String], _ controlType: ControlType = .dropdown, _ action: ((String) -> Void)? = nil) {
        self.label = label
        self.controlType = controlType
        self.value = value
        self.options = options
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
