//
//  SphereGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/1/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class SphereGeometry: Geometry {
    public override init() {
        super.init()
        self.setup(radius: 1, res: (angular: 60, vertical: 60))
    }

    public convenience init(radius: Float) {
        self.init(radius: radius, res: (60, 60))
    }

    public convenience init(radius: Float, res: Int) {
        self.init(radius: radius, res: (res, res))
    }

    public init(radius: Float, res: (angular: Int, vertical: Int)) {
        super.init()
        self.setup(radius: radius, res: res)
    }

    func setup(radius: Float, res: (angular: Int, vertical: Int)) {
        let phi = max(res.angular, 3)
        let theta = max(res.vertical, 3)

        let phif = Float(phi)

        let thetaMinusOne = theta - 1
        let thetaMinusOnef = Float(thetaMinusOne)

        let phiMax = Float.pi * 2.0
        let thetaMax = Float.pi

        let phiInc = phiMax / phif
        let thetaInc = thetaMax / thetaMinusOnef

        for t in 0...thetaMinusOne {
            let tf = Float(t)
            let thetaAngle = tf * thetaInc
            let cosTheta = cos(thetaAngle)
            let sinTheta = sin(thetaAngle)

            for p in 0...phi {
                let pf = Float(p)
                let phiAngle = pf * phiInc
                let cosPhi = cos(phiAngle)
                let sinPhi = sin(phiAngle)

                let x = radius * sinTheta * cosPhi
                let y = radius * cosTheta
                let z = radius * sinTheta * sinPhi

                vertexData.append(
                    Vertex(
                        simd_make_float4(x, y, z, 1.0),
                        simd_make_float2(pf / phif, 1.0 - tf / thetaMinusOnef),
                        normalize(simd_make_float3(x, y, z))
                    )
                )

                if p != phi, t != thetaMinusOne {
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
    }

    public override func calculateNormals() {
        for i in 0..<vertexData.count {
            vertexData[i].normal = normalize(simd_make_float3(vertexData[i].position))
        }
    }
}
