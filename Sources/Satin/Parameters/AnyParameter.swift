//
//  AnyParameter.swift
//  Satin
//
//  Created by Reza Ali on 10/22/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Combine
import Foundation

open class AnyParameter: Codable {
    public var base: Parameter

    public init(_ base: Parameter) {
        self.base = base
    }

    private enum CodingKeys: CodingKey {
        case type, base
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ParameterType.self, forKey: .type)
        base = try type.metatype.init(from: container.superDecoder(forKey: .base))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(base.type, forKey: .type)
        try base.encode(to: container.superEncoder(forKey: .base))
    }
}
