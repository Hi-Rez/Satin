//
//  Geometry.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal
import simd

open class Geometry {
    public var primitiveType: MTLPrimitiveType = .triangle
    public var windingOrder: MTLWinding = .counterClockwise
    public var indexType: MTLIndexType = .uint32
    
    public var vertexData: [Vertex] = [] {
        didSet {
            if context != nil {
                setupVertexBuffer()
            }
        }
    }
    
    public var indexData: [UInt32] = [] {
        didSet {
            if context != nil {
                setupIndexBuffer()
            }
        }
    }
    
    public var context: Context? {
        didSet {
            if oldValue != context {
                setup()
            }
        }
    }
    
    public var vertexBuffer: MTLBuffer?
    public var indexBuffer: MTLBuffer?
    
    public init() {}
    
    public init(primitiveType: MTLPrimitiveType, windingOrder: MTLWinding, indexType: MTLIndexType) {
        self.primitiveType = primitiveType
        self.windingOrder = windingOrder
        self.indexType = indexType
    }
    
    func setup() {
        if vertexBuffer == nil {
            setupVertexBuffer()
        }
        if indexBuffer == nil {
            setupIndexBuffer()
        }
    }
    
    func update() {}
    
    func setupVertexBuffer() {
        guard let context = self.context else { return }
        let device = context.device
        if !vertexData.isEmpty {
            let stride = MemoryLayout<Vertex>.stride
            let verticesSize = vertexData.count * stride
            vertexBuffer = device.makeBuffer(bytes: vertexData, length: verticesSize, options: [])
            vertexBuffer?.label = "Vertices"
        }
        else {
            vertexBuffer = nil
        }
    }
    
    func setupIndexBuffer() {
        guard let context = self.context else { return }
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
    
    public func calculateNormals() {
        for i in stride(from: 0, to: indexData.count, by: 3) {
            let i0 = Int(indexData[i])
            let i1 = Int(indexData[i + 1])
            let i2 = Int(indexData[i + 2])
            
            var v0 = vertexData[i0]
            var v1 = vertexData[i1]
            var v2 = vertexData[i2]
            
            let p0 = simd_make_float3(v0.position)
            let p1 = simd_make_float3(v1.position)
            let p2 = simd_make_float3(v2.position)
            
            let normal = normalize(cross(p1 - p0, p2 - p0))
            if length(normal) > 0.0 {
                let l0 = length(v0.normal)
                v0.normal += normal
                if l0 > 0.0 {
                    v0.normal *= 0.5
                }
                vertexData[i0].normal = v0.normal
                
                let l1 = length(v1.normal)
                v1.normal += normal
                if l1 > 0.0 {
                    v1.normal *= 0.5
                }
                vertexData[i1].normal = v1.normal
                
                let l2 = length(v2.normal)
                v2.normal += normal
                if l2 > 0.0 {
                    v2.normal *= 0.5
                }
                vertexData[i2].normal = v2.normal
            }
        }
    }
    
    public func setFrom(_ geometryData: GeometryData) {
        let vertexCount = Int(geometryData.vertexCount)
        if vertexCount > 0, let data = geometryData.vertexData {
            vertexData = Array(UnsafeBufferPointer(start: data, count: vertexCount))
        }
        
        let indexCount = Int(geometryData.indexCount) * 3
        if indexCount > 0, let data = geometryData.indexData {
            data.withMemoryRebound(to: UInt32.self, capacity: indexCount) { ptr in
                indexData = Array(UnsafeBufferPointer(start: ptr, count: indexCount))
            }
        }
    }
    
    deinit {
        indexData = []
        vertexData = []
        vertexBuffer = nil
        indexBuffer = nil
    }
}
