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
    var camera: Camera { get }
    var resolution: (width: Int, height: Int) { get set }
    
    func update(light: Object)
    func draw(commandBuffer: MTLCommandBuffer, renderables: [Renderable])

    var publisher: PassthroughSubject<LightShadow, Never> { get }
}
