//
//  Geometry.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal
import simd

protocol GeometryDelegate: AnyObject {
    func vertexDataUpdated()
    func indexDataUpdated()
}

open class Geometry {
    public var primitiveType: MTLPrimitiveType
    public var windingOrder: MTLWinding
    public var indexType: MTLIndexType
    weak var delegate: GeometryDelegate?

    public var vertexData: [Vertex] = [] {
        didSet {
            delegate?.vertexDataUpdated()
        }
    }

    public var indexData: [UInt32] = [] {
        didSet {
            delegate?.indexDataUpdated()
        }
    }

    public init() {
        primitiveType = .triangle
        windingOrder = .counterClockwise
        indexType = .uint32
    }

    public init(primitiveType: MTLPrimitiveType, windingOrder: MTLWinding, indexType: MTLIndexType) {
        self.primitiveType = primitiveType
        self.windingOrder = windingOrder
        self.indexType = indexType
    }

    public func calculateNormals()
    {
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

    deinit {
        delegate = nil
        indexData = []
        vertexData = []
    }
}
