//
//  PointLight.swift
//  Satin
//
//  Created by Reza Ali on 11/6/22.
//

import Foundation
import Combine
import Metal
import simd

open class PointLight: Object, Light {
    public var type: LightType { .point }
    
    public var data: LightData {
        LightData(
            // (rgb, intensity)
            color: simd_make_float4(color, intensity),
            // (xyz, type)
            position: simd_make_float4(worldPosition, Float(type.rawValue)),
            // (xyz, inverse radius)
            direction: simd_make_float4(-worldForwardDirection, 1.0 / radius),
            // (spotScale, spotOffset, cosInner, cosOuter)
            spotInfo: .zero
        )
    }
    
    public var color: simd_float3 {
        didSet {
            if color != oldValue {
                publisher.send(self)
            }
        }
    }
    
    public var intensity: Float {
        didSet {
            publisher.send(self)
        }
    }
    
    public var radius: Float {
        didSet {
            publisher.send(self)
        }
    }
    
    public let publisher = PassthroughSubject<Light, Never>()
    private var transformSubscriber: AnyCancellable?
    
    private enum CodingKeys: String, CodingKey {
        case color
        case intensity
        case radius
    }
    
    public init(label: String = "Point Light", color: simd_float3, intensity: Float = 1.0, radius: Float = 4.0) {
        self.color = color
        self.intensity = intensity
        self.radius = radius
        super.init(label)
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        color = try values.decode(simd_float3.self, forKey: .color)
        intensity = try values.decode(Float.self, forKey: .intensity)
        radius = try values.decode(Float.self, forKey: .radius)
        try super.init(from: decoder)
    }
    
    override open func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(color, forKey: .color)
        try container.encode(intensity, forKey: .intensity)
    }
    
    open override func setup() {
        super.setup()
        transformSubscriber = transformPublisher.sink { [weak self] value in
            guard let self = self else { return }
            self.publisher.send(self)
        }
    }
}
