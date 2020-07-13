//
//  FileParameter.swift
//  Satin
//
//  Created by Sean Patrick O'Brien on 7/12/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

import Foundation

open class FileParameter: NSObject, Parameter {
    public static var type = ParameterType.file
    public var controlType: ControlType
    public let label: String
    public var string: String { return "file" }
    public var size: Int { return MemoryLayout<String>.size }
    public var stride: Int { return MemoryLayout<String>.stride }
    public var alignment: Int { return MemoryLayout<String>.alignment }
    public var count: Int { return 1 }
    public subscript<String>(index: Int) -> String {
        get {
            return value as! String
        }
        set {
            value = newValue as! Swift.String
        }
    }

    public func dataType<String>() -> String.Type {
        return String.self
    }

    @objc public dynamic var value: String
    @objc public dynamic var recents: [String] = []
    @objc public dynamic var allowedTypes: [String] = []
    
    public init(_ label: String, _ value: String = "", _ allowedTypes: [String] = [], _ controlType: ControlType = .filepicker) {
        self.label = label
        self.controlType = controlType
        self.value = value
        self.allowedTypes = allowedTypes
    }

    public init(_ label: String, _ value: String = "", _ controlType: ControlType = .filepicker) {
        self.label = label
        self.controlType = controlType
        self.value = value
    }
    
    public init(_ label: String, _ controlType: ControlType = .filepicker) {
        self.label = label
        self.controlType = controlType
        self.value = ""
    }
}
