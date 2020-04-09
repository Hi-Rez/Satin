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
        case x,y,z,w
    }
}
