//
//  BVH+Extensions.swift
//  Satin
//
//  Created by Reza Ali on 11/27/22.
//

import simd

public struct IntersectionResult {
    public let barycentricCoordinates: simd_float3
    public let distance: Float
    public let normal: simd_float3
    public let position: simd_float3
    public let uv: simd_float2
    public let primitiveIndex: UInt32
}

public extension BVHNode {
    var isLeaf: Bool { triCount > 0 }
    
    func intersects(ray: Ray) -> Bool {
        return rayBoundsIntersect(ray, aabb)
    }
}

public extension BVH {
    func getNode(index: UInt32) -> BVHNode? {
        guard index < nodesUsed else { return nil }
        return nodes.advanced(by: Int(index)).pointee
    }
    
    func getTriangle(index: UInt32) -> UInt32 {
        return triIDs.advanced(by: Int(index)).pointee
    }
    
    func intersects(ray: Ray, index: UInt32) -> Bool {
        guard let node = getNode(index: index) else { return false }
        return node.intersects(ray: ray)
    }
    
    func intersects(ray: Ray) -> Bool {
        return intersects(ray: ray, index: 0)
    }
    
    func intersect(ray: Ray, intersections: inout [IntersectionResult], index: UInt32 = 0) {
        guard let node = getNode(index: index), node.intersects(ray: ray) else { return }
        if node.isLeaf {
            let hasTriangles = geometry.indexCount > 0
            var time: Float = 0.0
            for i in 0 ..< node.triCount {
                let primitiveIndex = getTriangle(index: node.leftFirst + i)
                let triangle = hasTriangles ? geometry.indexData[Int(primitiveIndex)] : TriangleIndices(i0: primitiveIndex * 3, i1: primitiveIndex * 3 + 1, i2: primitiveIndex * 3 + 2)
                
                let v0 = geometry.vertexData[Int(triangle.i0)]
                let v1 = geometry.vertexData[Int(triangle.i1)]
                let v2 = geometry.vertexData[Int(triangle.i2)]
                
                let a = simd_make_float3(v0.position)
                let b = simd_make_float3(v1.position)
                let c = simd_make_float3(v2.position)
                
                if rayTriangleIntersectionTime(ray, a, b, c, &time) {
                    let intersection = ray.at(time)
                    let bc = getBarycentricCoordinates(intersection, a, b, c)
                
                    intersections.append(
                        IntersectionResult(
                            barycentricCoordinates: bc,
                            distance: simd_length(intersection - ray.origin),
                            normal: simd_normalize(simd_cross(b - a, c - a)),
                            position: intersection,
                            uv: v0.uv * bc.x + v1.uv * bc.y + v2.uv * bc.z,
                            primitiveIndex: primitiveIndex
                        )
                    )
                }
            }
        }
        else {
            intersect(ray: ray, intersections: &intersections, index: node.leftFirst)
            intersect(ray: ray, intersections: &intersections, index: node.leftFirst + 1)
        }
    }
}
