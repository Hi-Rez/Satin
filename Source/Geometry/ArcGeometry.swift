//
//  ArcGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/6/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class ArcGeometry: Geometry {
    public init(radius: (inner: Float, outer: Float), angle: (start: Float, end: Float), res: (angular: Int, radial: Int)) {
        super.init()
        self.setup(radius: radius, angle: angle, res: res)
    }

    func setup(radius: (inner: Float, outer: Float), angle: (start: Float, end: Float), res: (angular: Int, radial: Int)) {
        let radial = max(res.radial, 1)
        let angular = max(res.angular, 3)

        let radialf = Float(radial)
        let angularf = Float(angular)

        let radialInc = (radius.outer - radius.inner) / radialf
        let angularInc = (angle.end - angle.start) / angularf

        for r in 0...radial {
            let rf = Float(r)
            let rad = radius.inner + rf * radialInc
            for a in 0...angular {
                let af = Float(a)
                let angle = angle.start + af * angularInc
                let x = rad * cos(angle)
                let y = rad * sin(angle)

                vertexData.append(
                    Vertex(
                        simd_make_float4(x, y, 0.0, 1.0),
                        simd_make_float2(rf / radialf, af / angularf),
                        normalize(simd_make_float3(0.0, 0.0, 1.0))
                    )
                )

                if r != radial, a != angular {
                    let perLoop = angular + 1
                    let index = a + r * perLoop

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
