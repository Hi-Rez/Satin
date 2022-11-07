//
//  PointLight.swift
//  Satin
//
//  Created by Reza Ali on 11/6/22.
//

import Foundation
import Metal
import simd

open class PointLight: Object, Light {
    public var type: LightType {
        .point
    }
    
    public var color: simd_float4
    public var intensity: Float
    
    private enum CodingKeys: String, CodingKey {
        case color
        case intensity
    }
    
    public init(label: String = "Point Light", color: simd_float4, intensity: Float = 1.0) {
        self.color = color
        self.intensity = intensity
        super.init(label)
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        color = try values.decode(simd_float4.self, forKey: .color)
        intensity = try values.decode(Float.self, forKey: .intensity)
        try super.init(from: decoder)
    }
    
    override open func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(color, forKey: .color)
        try container.encode(intensity, forKey: .intensity)
    }
    
    public func getLightData() -> LightData {
        return LightData(
            color: color,
            position: worldPosition,
            direction: -worldForwardDirection,
            intensity: intensity,
            type: type.rawValue
        )
    }
}

