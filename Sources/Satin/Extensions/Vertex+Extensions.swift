//
//  Vertex+Extensions.swift
//  Pods
//
//  Created by Reza Ali on 1/31/22.
//

import Foundation

extension Vertex: Codable {
    private enum CodingKeys: String, CodingKey {
        case position
        case normal
        case uv
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let position = try values.decode(simd_float4.self, forKey: .position)
        let normal = try values.decode(simd_float3.self, forKey: .normal)
        let uv = try values.decode(simd_float2.self, forKey: .uv)
        self.init(position: position, normal: normal, uv: uv)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.position, forKey: .position)
        try container.encode(self.normal, forKey: .normal)
        try container.encode(self.uv, forKey: .uv)
    }
}
