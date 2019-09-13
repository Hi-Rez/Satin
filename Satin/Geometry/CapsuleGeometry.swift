//
//  CapsuleGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/11/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class CapsuleGeometry: Geometry {
    public init(size: (radius: Float, height: Float)) {
        super.init()
        self.setup(size: size, res: (60,30,30))
    }

    public init(size: (radius: Float, height: Float), res: (angular: Int, vertical: Int, slices: Int)) {
        super.init()
        self.setup(size: size, res: res)
    }

    func setup(size: (radius: Float, height: Float), res: (angular: Int, vertical: Int, slices: Int)) {
        let radius = size.radius
        let height = size.height

        let phi = max(res.angular, 3)
        let theta = max(res.vertical, 1)
        let slices = max(res.slices, 1)

        let phif = Float(phi)
        let thetaf = Float(theta)
        let slicesf = Float(slices)

        let phiMax = Float.pi * 2.0
        let thetaMax = Float.pi * 0.5

        let phiInc = phiMax / phif
        let thetaInc = thetaMax / thetaf
        let heightInc = height / slicesf

        let halfHeight = height * 0.5
        let totalHeight = height + 2.0 * radius
        let vPerCap = radius / totalHeight
        let vPerCyl = height / totalHeight

        for t in 0...theta {
            let tf = Float(t)
            let thetaAngle = tf * thetaInc
            let cosTheta = cos(thetaAngle)
            let sinTheta = sin(thetaAngle)

            for p in 0...phi {
                let pf = Float(p)
                let phiAngle = pf * phiInc
                let cosPhi = cos(phiAngle)
                let sinPhi = sin(phiAngle)

                let x = radius * cosPhi * sinTheta
                let z = radius * sinPhi * sinTheta
                let y = radius * cosTheta

                vertexData.append(
                    Vertex(
                        simd_make_float4(x, y + halfHeight, z, 1.0),
                        simd_make_float2(pf / phif, map(y, 0.0, radius, vPerCap + vPerCyl, 1.0)),
                        normalize(simd_make_float3(x, y, z))
                    )
                )

                if p != phi, t != theta {
                    let perLoop = phi + 1
                    let index = p + t * perLoop

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

        var indexOffset = vertexData.count
        for t in 0...theta {
            let tf = Float(t)
            let thetaAngle = tf * thetaInc
            let cosTheta = cos(thetaAngle)
            let sinTheta = sin(thetaAngle)

            for p in 0...phi {
                let pf = Float(p)
                let phiAngle = pf * phiInc
                let cosPhi = cos(phiAngle)
                let sinPhi = sin(phiAngle)

                let x = radius * cosPhi * sinTheta
                let z = radius * sinPhi * sinTheta
                let y = -radius * cosTheta

                vertexData.append(
                    Vertex(
                        simd_make_float4(x, y - halfHeight, z, 1.0),
                        simd_make_float2(pf / phif, map(y, -radius, 0, 0.0, vPerCap)),
                        normalize(simd_make_float3(x, y, z))
                    )
                )

                if p != phi, t != theta {
                    let perLoop = phi + 1
                    let index = indexOffset + p + t * perLoop

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

        // Side Faces
        indexOffset = vertexData.count
        for s in 0...slices {
            let sf = Float(s)
            let y = sf * heightInc
            for p in 0...phi {
                let pf = Float(p)
                let phiAngle = pf * phiInc
                let cosPhi = cos(phiAngle)
                let sinPhi = sin(phiAngle)

                let x = radius * cosPhi
                let z = radius * sinPhi

                vertexData.append(
                    Vertex(
                        simd_make_float4(x, y - halfHeight , z, 1.0),
                        simd_make_float2(pf / phif, map(sf, 0.0, slicesf, vPerCap, vPerCap + vPerCyl)),
                        normalize(simd_make_float3(x, 0.0, z))
                    )
                )

                if s != slices && p != phi {
                    let perLoop = phi + 1
                    let index = indexOffset + p + s * perLoop

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
