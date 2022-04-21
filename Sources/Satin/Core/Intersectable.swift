//
//  File.swift
//  
//
//  Created by Reza Ali on 4/19/22.
//

import Foundation
import Metal
import MetalPerformanceShaders
import simd

public protocol Intersectable {
    var bounds: Bounds { get }
    var worldMatrix: simd_float4x4 { get }
    var vertexBuffer: MTLBuffer? { get }
    var indexBuffer: MTLBuffer? { get }
    
    func intersect(ray: Ray, intersector: MPSRayIntersector, accelerationStructures: inout [MPSAccelerationStructure])
}
