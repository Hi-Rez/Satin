//
//  ConeGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/8/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class ConeGeometry: Geometry {
    public override init() {
        super.init()
        self.setup(size: (1, 2), res: (60, 1, 1))
    }

    public init(size: (radius: Float, height: Float), res: (angular: Int, radial: Int, vertical: Int)) {
        super.init()
        self.setup(size: size, res: res)
    }

    func setup(size: (radius: Float, height: Float), res: (angular: Int, radial: Int, vertical: Int)) {
        let radius = size.radius
        let height = size.height
        let halfHeight = height * 0.5

        let radial = max(res.radial, 1)
        let angular = max(res.angular, 3)
        let vertical = max(res.vertical, 1)

        let radialf = Float(radial)
        let angularf = Float(angular)
        let verticalf = Float(vertical)

        let radialInc = size.radius / radialf
        let angularInc = (Float.pi * 2.0) / angularf
        let heightInc = height / verticalf

        // Rear Face
        var indexOffset = vertexData.count
        for r in 0...radial {
            let rf = Float(r)
            let rad = rf * radialInc
            for a in 0...angular {
                let af = Float(a)
                let angle = af * angularInc
                let x = rad * cos(angle)
                let y = rad * sin(angle)

                vertexData.append(
                    Vertex(
                        simd_make_float4(x, -halfHeight, y, 1.0),
                        simd_make_float2(rf / radialf, af / angularf),
                        simd_make_float3(0.0, -1.0, 0.0)
                    )
                )

                if r != radial && a != angular {
                    let perLoop = angular + 1
                    let index = indexOffset + a + r * perLoop

                    let tl = index
                    let tr = tl + 1
                    let bl = index + perLoop
                    let br = bl + 1

                    indexData.append(UInt32(tl))
                    indexData.append(UInt32(bl))
                    indexData.append(UInt32(tr))

                    indexData.append(UInt32(tr))
                    indexData.append(UInt32(bl))
                    indexData.append(UInt32(br))
                }
            }
        }

        let slopeInv = -radius / height
        let theta = atan(slopeInv)
        let quatTilt = simd_quaternion(theta, simd_make_float3(0.0, 0.0, 1.0))

        // Side Face
        indexOffset = vertexData.count
        for v in 0...vertical {
            let vf = Float(v)
            let z = -halfHeight + vf * heightInc
            let rad = radius * (1.0 - vf / verticalf)
            for a in 0...angular {
                let af = Float(a)
                let angle = af * angularInc
                let cosAngle = cos(angle)
                let sinAngle = sin(angle)
                let x = rad * cosAngle
                let y = rad * sinAngle

                var normal = simd_make_float3(1.0, 0.0, 0.0)
                let quatRot = simd_quaternion(angle, simd_make_float3(0.0, 1.0, 0.0))
                normal = quatTilt.act(normal)
                normal = quatRot.act(normal)

                vertexData.append(
                    Vertex(
                        simd_make_float4(x, z, y, 1.0),
                        simd_make_float2(af / angularf, vf / verticalf),
                        normal
                    )
                )

                if v != vertical && a != angular {
                    let perLoop = angular + 1
                    let index = indexOffset + a + v * perLoop

                    let tl = index
                    let tr = tl + 1
                    let bl = index + perLoop
                    let br = bl + 1

                    indexData.append(UInt32(tl))
                    indexData.append(UInt32(bl))
                    indexData.append(UInt32(tr))

                    indexData.append(UInt32(tr))
                    indexData.append(UInt32(bl))
                    indexData.append(UInt32(br))
                }
            }
        }
    }
}
