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
    var material: Material? { get set }

    func update(camera: Camera, viewport: simd_float4)
    func draw(renderEncoder: MTLRenderCommandEncoder)
}
