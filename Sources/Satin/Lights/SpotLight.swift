//
//  SpotLight.swift
//  Satin
//
//  Created by Reza Ali on 11/6/22.
//

open class SpotLight: Object, Light {
    public var type: LightType {
        .spot
    }
    
    public var color: simd_float4
    public var intensity: Float
    public var angle: Float
    
    private enum CodingKeys: String, CodingKey {
        case color
        case intensity
        case angle
    }
    
    public init(label: String = "Spot Light", color: simd_float4, intensity: Float = 1.0, angle: Float = 60.0) {
        self.color = color
        self.intensity = intensity
        self.angle = angle
        super.init(label)
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        color = try values.decode(simd_float4.self, forKey: .color)
        intensity = try values.decode(Float.self, forKey: .intensity)
        angle = try values.decode(Float.self, forKey: .angle)
        try super.init(from: decoder)
    }
    
    override open func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(color, forKey: .color)
        try container.encode(intensity, forKey: .intensity)
        try container.encode(angle, forKey: .angle)
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

