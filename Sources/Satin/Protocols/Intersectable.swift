//
//  Intersectable.swift
//
//
//  Created by Reza Ali on 4/19/22.
//

import Combine
import Metal
import MetalPerformanceShaders
import simd

public protocol Intersectable {
    var id: String { get }
    var label: String { get }
    var geometryPublisher: PassthroughSubject<Intersectable, Never> { get }
    
    var intersectable: Bool { get }
    
    var intersectionBounds: Bounds { get }
    var worldMatrix: matrix_float4x4 { get }
    
    var vertexBuffer: MTLBuffer? { get }
    var vertexCount: Int { get }
    var vertexStride: Int { get }
    
    var indexBuffer: MTLBuffer? { get }
    var indexCount: Int { get }
    
    var cullMode: MTLCullMode { get }
    var windingOrder: MTLWinding { get }
    
    func intersects(ray: Ray) -> Bool
    func getRaycastResult(ray: Ray, distance: Float, primitiveIndex: UInt32, barycentricCoordinate: simd_float2) -> RaycastResult?
}
