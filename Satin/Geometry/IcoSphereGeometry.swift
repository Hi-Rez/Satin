//
//  IcoSphereGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/11/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class IcoSphereGeometry: Geometry {
    
    var midPointIndexCache: [String: UInt32] = [String: UInt32]()
    var index: UInt32 = 0
    
    public override init() {
        super.init()
        setup(radius: 1, res: 1)
    }
    
    public init(radius: Float, res: Int) {
        super.init()
        setup(radius: radius, res: res)
    }
    
    func setup(radius: Float, res: Int) {
        let t = Float(1.0 + sqrt(5.0)) * 0.5
        
        _ = addVertex(position: simd_make_float3(-1, t, 0), radius: radius)
        _ = addVertex(position: simd_make_float3(1, t, 0), radius: radius)
        _ = addVertex(position: simd_make_float3(-1, -t, 0), radius: radius)
        _ = addVertex(position: simd_make_float3(1, -t, 0), radius: radius)
        
        _ = addVertex(position: simd_make_float3(0, -1, t), radius: radius)
        _ = addVertex(position: simd_make_float3(0, 1, t), radius: radius)
        _ = addVertex(position: simd_make_float3(0, -1, -t), radius: radius)
        _ = addVertex(position: simd_make_float3(0, 1, -t), radius: radius)
        
        _ = addVertex(position: simd_make_float3(t, 0, -1), radius: radius)
        _ = addVertex(position: simd_make_float3(t, 0, 1), radius: radius)
        _ = addVertex(position: simd_make_float3(-t, 0, -1), radius: radius)
        _ = addVertex(position: simd_make_float3(-t, 0, 1), radius: radius)
        
        indexData.append(UInt32(0))
        indexData.append(UInt32(11))
        indexData.append(UInt32(5))
        
        indexData.append(UInt32(0))
        indexData.append(UInt32(5))
        indexData.append(UInt32(1))
        
        indexData.append(UInt32(0))
        indexData.append(UInt32(1))
        indexData.append(UInt32(7))
        
        indexData.append(UInt32(0))
        indexData.append(UInt32(7))
        indexData.append(UInt32(10))
        
        indexData.append(UInt32(0))
        indexData.append(UInt32(10))
        indexData.append(UInt32(11))
        
        indexData.append(UInt32(1))
        indexData.append(UInt32(5))
        indexData.append(UInt32(9))
        
        indexData.append(UInt32(5))
        indexData.append(UInt32(11))
        indexData.append(UInt32(4))
        
        indexData.append(UInt32(11))
        indexData.append(UInt32(10))
        indexData.append(UInt32(2))
        
        indexData.append(UInt32(10))
        indexData.append(UInt32(7))
        indexData.append(UInt32(6))
        
        indexData.append(UInt32(7))
        indexData.append(UInt32(1))
        indexData.append(UInt32(8))
        
        indexData.append(UInt32(3))
        indexData.append(UInt32(9))
        indexData.append(UInt32(4))
        
        indexData.append(UInt32(3))
        indexData.append(UInt32(4))
        indexData.append(UInt32(2))
        
        indexData.append(UInt32(3))
        indexData.append(UInt32(2))
        indexData.append(UInt32(6))
        
        indexData.append(UInt32(3))
        indexData.append(UInt32(6))
        indexData.append(UInt32(8))
        
        indexData.append(UInt32(3))
        indexData.append(UInt32(8))
        indexData.append(UInt32(9))
        
        indexData.append(UInt32(4))
        indexData.append(UInt32(9))
        indexData.append(UInt32(5))
        
        indexData.append(UInt32(2))
        indexData.append(UInt32(4))
        indexData.append(UInt32(11))
        
        indexData.append(UInt32(6))
        indexData.append(UInt32(2))
        indexData.append(UInt32(10))
        
        indexData.append(UInt32(8))
        indexData.append(UInt32(6))
        indexData.append(UInt32(7))
        
        indexData.append(UInt32(9))
        indexData.append(UInt32(8))
        indexData.append(UInt32(1))
        
        for _ in 0..<res {
            var newIndexData: [UInt32] = []
            let len = indexData.count / 3

            for i in 0..<len {
                let index = i * 3
                let i0 = indexData[index]
                let i1 = indexData[index+1]
                let i2 = indexData[index+2]

                let a = midPoint(i0, i1, radius)
                let b = midPoint(i1, i2, radius)
                let c = midPoint(i2, i0, radius)

                newIndexData.append(i0)
                newIndexData.append(a)
                newIndexData.append(c)

                newIndexData.append(i1)
                newIndexData.append(b)
                newIndexData.append(a)

                newIndexData.append(i2)
                newIndexData.append(c)
                newIndexData.append(b)

                newIndexData.append(a)
                newIndexData.append(b)
                newIndexData.append(c)
            }
            indexData = newIndexData
        }
    }
    
    func midPoint(_ i0: UInt32, _ i1: UInt32, _ radius: Float) -> UInt32
    {
        let minKey = min(i0, i1)
        let maxKey = max(i0, i1)
        let key = String(minKey) + "_" + String(maxKey)
        if let cache = midPointIndexCache[key] {
            return cache
        }
        
        let point1 = simd_make_float3(vertexData[Int(i0)].position)
        let point2 = simd_make_float3(vertexData[Int(i1)].position)
        let middle = (point1 + point2) * 0.5
    
        let index = addVertex(position: middle, radius: radius)
        midPointIndexCache[key] = index
      
        return index
    }

    
    func addVertex(position: simd_float3, radius: Float) -> UInt32 {
        let p = simd_normalize(position)
        vertexData.append(
            Vertex(
                simd_make_float4(radius * p, 1.0),
                simd_make_float2((atan2(p.x, p.z) + .pi) / (2.0 * Float.pi), acos(p.y) / Float.pi),
                p
            )
        )
        index += 1
        return index - 1
    }
}
