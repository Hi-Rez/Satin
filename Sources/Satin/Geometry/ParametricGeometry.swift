//
//  ParametricGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/11/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class ParametricGeometry: Geometry {
    public init(u: (min: Float, max: Float), v: (min: Float, max: Float), res: (u: Int, v: Int), generator: (_ u: Float, _ v: Float) -> simd_float3) {
        super.init()
        self.setupData(u: u, v: v, res: res, generator: generator)
    }

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    func setupData(u: (min: Float, max: Float), v: (min: Float, max: Float), res: (u: Int, v: Int), generator: (_ u: Float, _ v: Float) -> simd_float3) {
        let ru = res.u
        let rv = res.v

        let ruf = Float(ru)
        let rvf = Float(rv)

        let ruInc = (u.max - u.min) / ruf
        let rvInc = (v.max - v.min) / rvf

        let uminf = Float(u.min)
        let vminf = Float(v.min)

        for v in 0...rv {
            let vf = Float(v)
            let vIn = vminf + vf * rvInc
            for u in 0...ru {
                let uf = Float(u)
                let uIn = uminf + uf * ruInc
                let pos = generator(uIn, vIn)

                let posT = generator(uIn, vIn - rvInc)
                let posB = generator(uIn, vIn + rvInc)
                let posL = generator(uIn - ruInc, vIn)
                let posR = generator(uIn + ruInc, vIn)

                let pt = posT - pos
                let pr = posR - pos
                let n0 = normalize(cross(pr, pt))
                let pb = posB - pos
                let pl = posL - pos
                let n1 = normalize(cross(pl, pb))

                var normal = simd_make_float3(0.0, 0.0, 0.0)
                var sum: Float = 0

                if !n0.x.isNaN, !n0.y.isNaN, !n0.z.isNaN {
                    normal = n0
                    sum += 1
                }

                if !n1.x.isNaN, !n1.y.isNaN, !n1.z.isNaN {
                    normal = n1
                    sum += 1
                }

                if sum > 0 {
                    normal.x = normal.x / sum
                    normal.y = normal.y / sum
                    normal.z = normal.z / sum
                }

                vertexData.append(
                    Vertex(
                        position: simd_make_float4(pos, 1.0),
                        normal: normal,
                        uv: simd_make_float2(uf / ruf, vf / rvf)
                    )
                )

                if v != rv, u != ru {
                    let perLoop = ru + 1
                    let index = u + v * perLoop

                    let tl = index
                    let tr = tl + 1
                    let bl = index + perLoop
                    let br = bl + 1

                    indexData.append(UInt32(tl))
                    indexData.append(UInt32(tr))
                    indexData.append(UInt32(bl))
                    indexData.append(UInt32(tr))
                    indexData.append(UInt32(br))
                    indexData.append(UInt32(bl))
                }
            }
        }
    }
}
