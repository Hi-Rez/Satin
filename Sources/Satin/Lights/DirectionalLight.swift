//
//  DirectionalLight.swift
//  Satin
//
//  Created by Reza Ali on 11/3/22.
//

import Foundation
import Combine
import Metal
import simd

open class DirectionalLight: Object, Light {
    public var type: LightType { .directional }
    
    public var data: LightData {
        LightData(
            // (rgb, intensity)
            color: simd_make_float4(color, intensity),
            // (xyz, type)
            position: simd_make_float4(worldPosition, Float(type.rawValue)),
            // (xyz, inverse radius)
            direction: simd_make_float4(-worldForwardDirection, 0.0),
            // (spotScale, spotOffset, cosInner, cosOuter)
            spotInfo: .zero
        )
    }

    public var color: simd_float3 {
        didSet {
            publisher.send(self)
        }
    }
    public var intensity: Float {
        didSet {
            publisher.send(self)
        }
    }
    
    public let publisher = PassthroughSubject<Light, Never>()
    private var transformSubscriber: AnyCancellable?

    private enum CodingKeys: String, CodingKey {
        case color
        case intensity
    }
    
    public init(label: String = "Directional Light", color: simd_float3, intensity: Float = 1.0) {
        self.color = color
        self.intensity = intensity
        super.init(label)
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        color = try values.decode(simd_float3.self, forKey: .color)
        intensity = try values.decode(Float.self, forKey: .intensity)
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
