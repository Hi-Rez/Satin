//
//  Submesh.swift
//  Satin
//
//  Created by Reza Ali on 5/25/20.
//

import Combine
import Metal

open class Submesh {
    public var id: String = UUID().uuidString
    public var label: String = "Submesh"
    open var context: Context? {
        didSet {
            if context != nil {
                setup()
            }
        }
    }

    public var visible: Bool = true
    public var indexCount: Int {
        return indexData.count
    }

    public var indexBufferOffset: Int = 0
    public var indexType: MTLIndexType = .uint32
    public var indexBuffer: MTLBuffer?
    public var indexData: [UInt32] = [] {
        didSet {
            if context != nil {
                setup()
            }
        }
    }

    public init(indexData: [UInt32], indexBuffer: MTLBuffer? = nil, indexBufferOffset: Int = 0) {
        self.indexData = indexData
        self.indexBuffer = indexBuffer
        self.indexBufferOffset = indexBufferOffset
    }

    weak var parent: Mesh!

    func setup() {
        if indexBuffer == nil {
            setupIndexBuffer()
        }
    }

    func setupIndexBuffer() {
        guard let context = context else { return }
        let device = context.device
        if !indexData.isEmpty {
            let indicesSize = indexData.count * MemoryLayout.size(ofValue: indexData[0])
            indexBuffer = device.makeBuffer(bytes: indexData, length: indicesSize, options: [])
            indexBuffer?.label = "Indices"
        }
        else {
            indexBuffer = nil
        }
    }
}

extension Submesh: Intersectable {
    public var geometryPublisher: PassthroughSubject<Intersectable, Never> {
        parent.geometryPublisher
    }
    
    public var vertexStride: Int {
        parent.vertexStride
    }
    
    public var cullMode: MTLCullMode {
        parent.cullMode
    }
    
    public var windingOrder: MTLWinding {
        parent.windingOrder
    }
    
    public var vertexBuffer: MTLBuffer? {
        parent.vertexBuffer
    }
    
    public var vertexCount: Int {
        parent.vertexCount
    }
    
    public var intersectable: Bool {
        indexBuffer != nil
    }
    
    public var intersectionBounds: Bounds {
        parent.intersectionBounds
    }
    
    public var worldMatrix: matrix_float4x4 {
        parent.worldMatrix
    }
    
    public func intersects(ray: Ray) -> Bool {
        parent.intersects(ray: ray)
    }
    
    public func getRaycastResult(ray: Ray, distance: Float, primitiveIndex: UInt32, barycentricCoordinate: simd_float2) -> RaycastResult? {
        let index = Int(primitiveIndex) * 3
            
        let i0 = Int(indexData[index])
        let i1 = Int(indexData[index + 1])
        let i2 = Int(indexData[index + 2])
            
        let a: Vertex = parent.geometry.vertexData[i0]
        let b: Vertex = parent.geometry.vertexData[i1]
        let c: Vertex = parent.geometry.vertexData[i2]
            
        let u: Float = barycentricCoordinate.x
        let v: Float = barycentricCoordinate.y
        let w: Float = 1.0 - u - v
            
        let aUv = a.uv * u
        let bUv = b.uv * v
        let cUv = c.uv * w
            
        let aNormal = (parent.normalMatrix * a.normal) * u
        let bNormal = (parent.normalMatrix * b.normal) * v
        let cNormal = (parent.normalMatrix * c.normal) * w

        return RaycastResult(
            barycentricCoordinates: simd_make_float3(u, v, w),
            distance: distance,
            normal: normalize(simd_make_float3(aNormal + bNormal + cNormal)),
            position: ray.at(distance),
            uv: simd_make_float2(aUv + bUv + cUv),
            primitiveIndex: primitiveIndex,
            object: parent,
            submesh: self
        )
    }
}
