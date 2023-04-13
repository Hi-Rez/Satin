//
//  Renderable.swift
//
//
//  Created by Reza Ali on 4/19/22.
//

import Foundation
import Metal
import simd

public protocol Renderable {
    var label: String { get }
    var renderOrder: Int { get }

    var receiveShadow: Bool { get }
    var castShadow: Bool { get }

    var drawable: Bool { get }
    var cullMode: MTLCullMode { get set }
    var opaque: Bool { get }
    
    var material: Material? { get set }
    var materials: [Material] { get }

    func update(camera: Camera, viewport: simd_float4)
    func draw(renderEncoder: MTLRenderCommandEncoder, shadow: Bool)
}
