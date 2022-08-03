//
//  Simd+Extensions.swift
//  Satin
//
//  Created by Reza Ali on 9/14/19.
//

import simd

extension simd_quatf: Codable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let x = try values.decode(Float.self, forKey: .x)
        let y = try values.decode(Float.self, forKey: .y)
        let z = try values.decode(Float.self, forKey: .z)
        let w = try values.decode(Float.self, forKey: .w)
        self.init(ix: x, iy: y, iz: z, r: w)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.vector.x, forKey: .x)
        try container.encode(self.vector.y, forKey: .y)
        try container.encode(self.vector.z, forKey: .z)
        try container.encode(self.vector.w, forKey: .w)
    }

    private enum CodingKeys: String, CodingKey {
        case x, y, z, w
    }
}

extension simd_float4x4: Codable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let c0 = try values.decode(simd_float4.self, forKey: .col0)
        let c1 = try values.decode(simd_float4.self, forKey: .col1)
        let c2 = try values.decode(simd_float4.self, forKey: .col2)
        let c3 = try values.decode(simd_float4.self, forKey: .col3)
        self.init(c0, c1, c2, c3)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.columns.0, forKey: .col0)
        try container.encode(self.columns.1, forKey: .col1)
        try container.encode(self.columns.2, forKey: .col2)
        try container.encode(self.columns.3, forKey: .col3)
    }

    private enum CodingKeys: String, CodingKey {
        case col0, col1, col2, col3
    }
}

extension simd_float3x3: Codable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let c0 = try values.decode(simd_float3.self, forKey: .col0)
        let c1 = try values.decode(simd_float3.self, forKey: .col1)
        let c2 = try values.decode(simd_float3.self, forKey: .col2)
        self.init(c0, c1, c2)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.columns.0, forKey: .col0)
        try container.encode(self.columns.1, forKey: .col1)
        try container.encode(self.columns.2, forKey: .col2)
    }

    private enum CodingKeys: String, CodingKey {
        case col0, col1, col2
    }
}

extension simd_float2x2: Codable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let c0 = try values.decode(simd_float2.self, forKey: .col0)
        let c1 = try values.decode(simd_float2.self, forKey: .col1)
        self.init(c0, c1)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.columns.0, forKey: .col0)
        try container.encode(self.columns.1, forKey: .col1)
    }

    private enum CodingKeys: String, CodingKey {
        case col0, col1
    }
}
