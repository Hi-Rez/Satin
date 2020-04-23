//
//  ParameterGroup.swift
//  Satin
//
//  Created by Reza Ali on 10/22/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation
import simd

open class ParameterGroup: Codable {
    public var label: String = ""
    public var params: [Parameter] = []
    public var paramsMap: [String: Parameter] = [:]

    public init(_ label: String) {
        self.label = label
    }

    public func append(_ param: Parameter) {
        params.append(param)
        paramsMap[param.label] = param
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

    public func save(_ url: URL) {
        do {
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = .prettyPrinted
            let payload: Data = try jsonEncoder.encode(self)
            try payload.write(to: url)
        }
        catch {
            print(error)
        }
    }

    public func load(_ url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let loaded = try JSONDecoder().decode(ParameterGroup.self, from: data)
            for param in loaded.params {
                let label = param.label
                if param is FloatParameter {
                    let p = param as! FloatParameter
                    if let mp = paramsMap[label] {
                        if let mfp = mp as? FloatParameter {
                            mfp.value = p.value
                        }
                    }
                }
                else if param is Float2Parameter {
                    let p = param as! Float2Parameter
                    if let mp = paramsMap[label] {
                        if let mfp = mp as? Float2Parameter {
                            mfp.x = p.x
                            mfp.y = p.y
                        }
                    }
                }
                else if param is Float3Parameter {
                    let p = param as! Float3Parameter
                    if let mp = paramsMap[label] {
                        if let mfp = mp as? Float3Parameter {
                            mfp.x = p.x
                            mfp.y = p.y
                            mfp.z = p.z
                        }
                    }
                }
                else if param is PackedFloat3Parameter {
                    let p = param as! PackedFloat3Parameter
                    if let mp = paramsMap[label] {
                        if let mfp = mp as? PackedFloat3Parameter {
                            mfp.x = p.x
                            mfp.y = p.y
                            mfp.z = p.z
                        }
                    }
                }
                else if param is Float4Parameter {
                    let p = param as! Float4Parameter
                    if let mp = paramsMap[label] {
                        if let mfp = mp as? Float4Parameter {
                            mfp.x = p.x
                            mfp.y = p.y
                            mfp.z = p.z
                            mfp.w = p.w
                        }
                    }
                }
                else if param is IntParameter {
                    let p = param as! IntParameter
                    if let mp = paramsMap[label] {
                        if let mip = mp as? IntParameter {
                            mip.value = p.value
                        }
                    }
                }
                else if param is Int2Parameter {
                    let p = param as! Int2Parameter
                    if let mp = paramsMap[label] {
                        if let mip = mp as? Int2Parameter {
                            mip.x = p.x
                            mip.y = p.y
                        }
                    }
                }
                else if param is Int3Parameter {
                    let p = param as! Int3Parameter
                    if let mp = paramsMap[label] {
                        if let mip = mp as? Int3Parameter {
                            mip.x = p.x
                            mip.y = p.y
                            mip.z = p.z
                        }
                    }
                }
                else if param is DoubleParameter {
                    let p = param as! DoubleParameter
                    if let mp = paramsMap[label] {
                        if let mdp = mp as? DoubleParameter {
                            mdp.value = p.value
                        }
                    }
                }
                else if param is BoolParameter {
                    let p = param as! BoolParameter
                    if let mp = paramsMap[label] {
                        if let mbp = mp as? BoolParameter {
                            mbp.value = p.value
                        }
                    }
                }
                else if param is StringParameter {
                    let p = param as! StringParameter
                    if let mp = paramsMap[label] {
                        if let mbp = mp as? StringParameter {
                            mbp.value = p.value
                        }
                    }
                }
                else if param is UInt32Parameter {
                    let p = param as! UInt32Parameter
                    if let mp = paramsMap[label] {
                        if let mbp = mp as? UInt32Parameter {
                            mbp.value = p.value
                        }
                    }
                }
            }
        }
        catch {
            print(error)
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
        let structName = label.replacingOccurrences(of: " ", with: "")
        var source = "typedef struct {\n"
        for param in params {
            source += "\t \(param.string) \(param.label);\n"
        }
        source += "} \(structName);\n\n"
        return source
    }
}

extension ParameterGroup: Equatable {
    public static func == (lhs: ParameterGroup, rhs: ParameterGroup) -> Bool {
        return lhs.label == rhs.label
    }
}
