//
//  ParameterGroup.swift
//  Satin
//
//  Created by Reza Ali on 10/22/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation
import simd

public protocol ParameterGroupDelegate: AnyObject {
    func added(parameter: Parameter, from group: ParameterGroup)
    func removed(parameter: Parameter, from group: ParameterGroup)
    func loaded(group: ParameterGroup)
    func saved(group: ParameterGroup)
    func cleared(group: ParameterGroup)
}

open class ParameterGroup: Codable {
    public var label: String = ""
    public var params: [Parameter] = []
    public var paramsMap: [String: Parameter] = [:]
    public weak var delegate: ParameterGroupDelegate? = nil

    public init(_ label: String = "") {
        self.label = label
    }

    public func append(_ param: Parameter) {
        params.append(param)
        paramsMap[param.label] = param
        delegate?.added(parameter: param, from: self)
    }

    public func remove(_ param: Parameter) {
        let key = param.label
        paramsMap.removeValue(forKey: key)
        for (i, p) in params.enumerated() {
            if p.label == key {
                params.remove(at: i)
                break
            }
        }
        delegate?.removed(parameter: param, from: self)
    }

    public func clear() {
        params = []
        paramsMap = [:]
        delegate?.cleared(group: self)
    }
    
    public func copy(_ incomingParams: ParameterGroup, setValues: Bool = true, setOptions: Bool = true) {
        clear()
        self.label = incomingParams.label
        for param in incomingParams.params {
            let label = param.label
            if let p = param as? FloatParameter {
                append(FloatParameter(label, p.value, p.min, p.max, p.controlType))
            }
            else if let p = param as? Float2Parameter {
                append(Float2Parameter(label, p.value, p.min, p.max, p.controlType))
            }
            else if let p = param as? Float3Parameter {
                append(Float3Parameter(label, p.value, p.min, p.max, p.controlType))
            }
            else if let p = param as? PackedFloat3Parameter {
                append(PackedFloat3Parameter(label, p.value, p.min, p.max, p.controlType))
            }
            else if let p = param as? Float4Parameter {
                append(Float4Parameter(label, p.value, p.min, p.max, p.controlType))
            }
            else if let p = param as? IntParameter {
                append(IntParameter(label, p.value, p.min, p.max, p.controlType))
            }
            else if let p = param as? Int2Parameter {
                append(Int2Parameter(label, p.value, p.min, p.max, p.controlType))
            }
            else if let p = param as? Int3Parameter {
                append(Int3Parameter(label, p.value, p.min, p.max, p.controlType))
            }
            else if let p = param as? DoubleParameter {
                append(DoubleParameter(label, p.value, p.min, p.max, p.controlType))
            }
            else if let p = param as? BoolParameter {
                append(BoolParameter(label, p.value, p.controlType))
            }
            else if let p = param as? StringParameter {
                append(StringParameter(label, p.value, p.options, p.controlType))
            }
            else if let p = param as? UInt32Parameter {
                append(UInt32Parameter(label, p.value, p.min, p.max, p.controlType))
            }
            else if let p = param as? FileParameter {
                let fp = FileParameter(label, p.value, p.allowedTypes, p.controlType)
                fp.recents = p.recents
                append(fp)
            }
        }
    }
    
    public func clone() -> ParameterGroup {
        let copy = ParameterGroup()
        copy.copy(self)
        return copy
    }

    public func setFrom(_ incomingParams: ParameterGroup, setValues: Bool = false, setOptions: Bool = true) {
        var order: [String] = []
        for param in incomingParams.params {
            order.append(param.label)
        }

        let incomingKeys = Set(Array(incomingParams.paramsMap.keys))
        let exisitingKeys = Set(Array(self.paramsMap.keys))
        let newKeys = incomingKeys.subtracting(exisitingKeys)
        let commonKeys = exisitingKeys.intersection(incomingKeys)
        let removedKeys = exisitingKeys.subtracting(incomingKeys)

        for key in removedKeys {
            if let param = self.paramsMap[key] {
                remove(param)
            }
        }
        for key in newKeys {
            if let param = incomingParams.paramsMap[key] {
                append(param)
            }
        }

        for key in commonKeys {
            if let inParam = incomingParams.paramsMap[key] {
                setParameterFrom(param: inParam, setValue: setValues, setOptions: setOptions, append: false)
            }
        }

        let paramsMap: [String: Parameter] = self.paramsMap
        clear()
        for key in order {
            if let param = paramsMap[key] {
                append(param)
            }
        }
    }

    private enum CodingKeys: CodingKey {
        case params, title
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.params = try container.decode([AnyParameter].self, forKey: .params).map { $0.base }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(params.map(AnyParameter.init), forKey: .params)
    }

    public func save(_ url: URL, baseURL: URL? = nil) {
        do {
            var userInfo = [CodingUserInfoKey:Any]()
            if let baseURL = baseURL {
                userInfo[FileParameter.baseURLCodingUserInfoKey] = baseURL
            }
            
            let jsonEncoder = JSONEncoder()
            jsonEncoder.userInfo = userInfo
            jsonEncoder.outputFormatting = .prettyPrinted
            let payload: Data = try jsonEncoder.encode(self)
            try payload.write(to: url)
            delegate?.saved(group: self)
        }
        catch {
            print(error)
        }
    }

    public func load(_ url: URL, append: Bool = true, baseURL: URL? = nil) {
        do {
            var userInfo = [CodingUserInfoKey:Any]()
            if let baseURL = baseURL {
                userInfo[FileParameter.baseURLCodingUserInfoKey] = baseURL
            }
            
            let jsonDecoder = JSONDecoder()
            jsonDecoder.userInfo = userInfo
            
            let data = try Data(contentsOf: url)
            let loaded = try jsonDecoder.decode(ParameterGroup.self, from: data)
            for param in loaded.params {
                setParameterFrom(param: param, setValue: true, setOptions: false, append: append)
            }
            delegate?.loaded(group: self)
        }
        catch {
            print(error)
        }
    }

    func setParameterFrom(param: Parameter, setValue: Bool, setOptions: Bool, append: Bool = true) {
        let label = param.label
        if append, paramsMap[label] == nil {
            self.append(param)
        }
        else if param is FloatParameter {
            let p = param as! FloatParameter
            if let mp = paramsMap[label] {
                if let mfp = mp as? FloatParameter {
                    if setValue {
                        mfp.value = p.value
                    }
                    if setOptions {
                        mfp.min = p.min
                        mfp.max = p.max
                    }
                }
            }
        }
        else if param is Float2Parameter {
            let p = param as! Float2Parameter
            if let mp = paramsMap[label] {
                if let mfp = mp as? Float2Parameter {
                    if setValue {
                        mfp.x = p.x
                        mfp.y = p.y
                    }
                    if setOptions {
                        mfp.minX = p.minX
                        mfp.minY = p.minY
                        mfp.maxX = p.maxX
                        mfp.maxY = p.maxY
                    }
                }
            }
        }
        else if param is Float3Parameter {
            let p = param as! Float3Parameter
            if let mp = paramsMap[label] {
                if let mfp = mp as? Float3Parameter {
                    if setValue {
                        mfp.x = p.x
                        mfp.y = p.y
                        mfp.z = p.z
                    }
                    if setOptions {
                        mfp.minX = p.minX
                        mfp.minY = p.minY
                        mfp.minZ = p.minZ
                        mfp.maxX = p.maxX
                        mfp.maxY = p.maxY
                        mfp.maxZ = p.maxZ
                    }
                }
            }
        }
        else if param is PackedFloat3Parameter {
            let p = param as! PackedFloat3Parameter
            if let mp = paramsMap[label] {
                if let mfp = mp as? PackedFloat3Parameter {
                    if setValue {
                        mfp.x = p.x
                        mfp.y = p.y
                        mfp.z = p.z
                    }
                    if setOptions {
                        mfp.minX = p.minX
                        mfp.minY = p.minY
                        mfp.minZ = p.minZ
                        mfp.maxX = p.maxX
                        mfp.maxY = p.maxY
                        mfp.maxZ = p.maxZ
                    }
                }
            }
        }
        else if param is Float4Parameter {
            let p = param as! Float4Parameter
            if let mp = paramsMap[label] {
                if let mfp = mp as? Float4Parameter {
                    if setValue {
                        mfp.x = p.x
                        mfp.y = p.y
                        mfp.z = p.z
                        mfp.w = p.w
                    }
                    if setOptions {
                        mfp.minX = p.minX
                        mfp.minY = p.minY
                        mfp.minZ = p.minZ
                        mfp.minW = p.minW
                        mfp.maxX = p.maxX
                        mfp.maxY = p.maxY
                        mfp.maxZ = p.maxZ
                        mfp.maxW = p.maxW
                    }
                }
            }
        }
        else if param is IntParameter {
            let p = param as! IntParameter
            if let mp = paramsMap[label] {
                if let mip = mp as? IntParameter {
                    if setValue {
                        mip.value = p.value
                    }
                    if setOptions {
                        mip.min = p.min
                        mip.max = p.max
                    }
                }
            }
        }
        else if param is Int2Parameter {
            let p = param as! Int2Parameter
            if let mp = paramsMap[label] {
                if let mip = mp as? Int2Parameter {
                    if setValue {
                        mip.x = p.x
                        mip.y = p.y
                    }
                    if setOptions {
                        mip.minX = p.minX
                        mip.minY = p.minY
                        mip.maxX = p.maxX
                        mip.maxY = p.maxY
                    }
                }
            }
        }
        else if param is Int3Parameter {
            let p = param as! Int3Parameter
            if let mp = paramsMap[label] {
                if let mip = mp as? Int3Parameter {
                    if setValue {
                        mip.x = p.x
                        mip.y = p.y
                        mip.z = p.z
                    }
                    if setOptions {
                        mip.minX = p.minX
                        mip.minY = p.minY
                        mip.minZ = p.minZ
                        mip.maxX = p.maxX
                        mip.maxY = p.maxY
                        mip.maxZ = p.maxZ
                    }
                }
            }
        }
        else if param is DoubleParameter {
            let p = param as! DoubleParameter
            if let mp = paramsMap[label] {
                if let mdp = mp as? DoubleParameter {
                    if setValue {
                        mdp.value = p.value
                    }
                    if setOptions {
                        mdp.min = p.min
                        mdp.max = p.max
                    }
                }
            }
        }
        else if param is BoolParameter {
            let p = param as! BoolParameter
            if let mp = paramsMap[label] {
                if let mbp = mp as? BoolParameter {
                    if setValue {
                        mbp.value = p.value
                    }
                }
            }
        }
        else if param is StringParameter {
            let p = param as! StringParameter
            if let mp = paramsMap[label] {
                if let mbp = mp as? StringParameter {
                    if setValue {
                        mbp.value = p.value
                    }
                    if setOptions {
                        mbp.options = p.options
                    }
                }
            }
        }
        else if param is UInt32Parameter {
            let p = param as! UInt32Parameter
            if let mp = paramsMap[label] {
                if let mbp = mp as? UInt32Parameter {
                    if setValue {
                        mbp.value = p.value
                    }
                    if setOptions {
                        mbp.min = p.min
                        mbp.max = p.max
                    }
                }
            }
        }
        else if param is FileParameter {
            let p = param as! FileParameter
            if let mp = paramsMap[label] {
                if let mbp = mp as? FileParameter {
                    if setValue {
                        mbp.value = p.value
                        mbp.recents = p.recents
                    }
                    if setOptions {
                        mbp.allowedTypes = p.allowedTypes
                    }
                }
            }
        }
    }

    public var size: Int {
        var pointerOffset: Int = 0
        for param in params {
            let size = param.size
            let alignment = param.alignment
            let rem = pointerOffset % alignment
            if rem > 0 {
                let offset = alignment - rem
                pointerOffset += offset
            }
            pointerOffset += size
        }
        return pointerOffset
    }

    public var stride: Int {
        var stride = size
        let alignment = self.alignment
        let rem = stride % alignment
        if rem > 0 {
            let offset = alignment - rem
            stride += offset
        }
        return stride
    }

    public var alignment: Int {
        var alignment: Int = 0
        for param in params {
            alignment = max(alignment, param.alignment)
        }
        return alignment
    }

    public var structString: String {
        var structName = label.replacingOccurrences(of: " ", with: "")
        structName = structName.camelCase
        structName = structName.prefix(1).capitalized + structName.dropFirst()
        var source = "typedef struct {\n"
        for param in params {
            source += "\t \(param.string) \(param.label.camelCase);\n"
        }
        source += "} \(structName);\n\n"
        return source
    }

    public func set(_ name: String, _ value: Float) {
        if let param = paramsMap[name], let p = param as? FloatParameter {
            p.value = value
        }
    }

    public func set(_ name: String, _ value: simd_float2) {
        if let param = paramsMap[name], let p = param as? Float2Parameter {
            p.value = value
        }
    }

    public func set(_ name: String, _ value: simd_float3) {
        if let param = paramsMap[name], let p = param as? Float3Parameter {
            p.value = value
        }
    }

    public func set(_ name: String, _ value: simd_float4) {
        if let param = paramsMap[name], let p = param as? Float4Parameter {
            p.value = value
        }
    }

    public func set(_ name: String, _ value: Int) {
        if let param = paramsMap[name], let p = param as? IntParameter {
            p.value = value
        }
    }

    public func set(_ name: String, _ value: simd_int2) {
        if let param = paramsMap[name], let p = param as? Int2Parameter {
            p.value = value
        }
    }

    public func set(_ name: String, _ value: simd_int3) {
        if let param = paramsMap[name], let p = param as? Int3Parameter {
            p.value = value
        }
    }

    public func set(_ name: String, _ value: simd_int4) {
        if let param = paramsMap[name], let p = param as? Int4Parameter {
            p.value = value
        }
    }

    public func set(_ name: String, _ value: Bool) {
        if let param = paramsMap[name], let p = param as? BoolParameter {
            p.value = value
        }
    }

    public func get(_ name: String) -> Parameter? {
        return paramsMap[name]
    }
}

extension ParameterGroup: Equatable {
    public static func == (lhs: ParameterGroup, rhs: ParameterGroup) -> Bool {
        return lhs.label == rhs.label
    }
}
