//
//  FileParameter.swift
//  Satin
//
//  Created by Sean Patrick O'Brien on 7/12/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

import Foundation

open class FileParameter: NSObject, Parameter {
    public weak var delegate: ParameterDelegate?
    
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
    
    public static let baseURLCodingUserInfoKey = CodingUserInfoKey(rawValue: "FileParameterBaseURL")!

    enum CodingKeys: String, CodingKey {
        case label
        case value
        case controlType
        case recents
        case allowedTypes
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        label = try container.decode(String.self, forKey: .label)
        value = try container.decode(String.self, forKey: .value)
        controlType = try container.decode(ControlType.self, forKey: .controlType)
        recents = try container.decode([String].self, forKey: .recents)
        allowedTypes = try container.decode([String].self, forKey: .allowedTypes)
        
        if let baseURL = decoder.userInfo[FileParameter.baseURLCodingUserInfoKey] as? URL {
            func transformPath(_ path: String) -> String {
                guard !NSString(string: path).isAbsolutePath else { return path }
                return baseURL.appendingPathComponent(path).path
            }
            
            value = transformPath(value)
            recents = recents.map(transformPath)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        var transformedValue = value
        var transformedRecents = recents
        
        if let baseURL = encoder.userInfo[FileParameter.baseURLCodingUserInfoKey] as? URL {
            let baseComponents = baseURL.pathComponents
            func transformPath(_ path: String) -> String {
                guard NSString(string: path).isAbsolutePath else { return path }
                
                let url = URL(fileURLWithPath: path)
                let pathComponents = url.pathComponents
                
                if pathComponents.count > baseComponents.count && !zip(baseComponents, pathComponents).contains(where: !=) {
                    let relativeComponents: [String] = Array(pathComponents.dropFirst(baseComponents.count))
                    return NSString.path(withComponents: relativeComponents)
                }

                return path
            }
            
            transformedValue = transformPath(transformedValue)
            transformedRecents = transformedRecents.map(transformPath)
        }
        
        try container.encode(label, forKey: .label)
        try container.encode(transformedValue, forKey: .value)
        try container.encode(controlType, forKey: .controlType)
        try container.encode(transformedRecents, forKey: .recents)
        try container.encode(allowedTypes, forKey: .allowedTypes)
    }
}
