//
//  ParameterGroup.swift
//  Satin
//
//  Created by Reza Ali on 10/22/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

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
            }
        }
        catch {
            print(error)
        }
    }
}

extension ParameterGroup: Equatable {
    public static func == (lhs: ParameterGroup, rhs: ParameterGroup) -> Bool {
        return lhs.label == rhs.label
    }
}
