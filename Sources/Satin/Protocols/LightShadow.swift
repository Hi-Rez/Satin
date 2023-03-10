//
//  LightShadow.swift
//  Satin
//
//  Created by Reza Ali on 3/2/23.
//

import Combine
import Foundation
import Metal

public protocol LightShadow {
    var label: String { get set }
    var texture: MTLTexture? { get }
    var data: ShadowData { get }

    var camera: Camera { get }
    var resolution: (width: Int, height: Int) { get set }

    var strength: Float { get set }
    var bias: Float { get set }
    var radius: Float { get set }
    
    func update(light: Object)
    func draw(commandBuffer: MTLCommandBuffer, renderables: [Renderable])

    var texturePublisher: PassthroughSubject<LightShadow, Never> { get }
    var resolutionPublisher: PassthroughSubject<LightShadow, Never> { get }
    var dataPublisher: PassthroughSubject<LightShadow, Never> { get }
}
