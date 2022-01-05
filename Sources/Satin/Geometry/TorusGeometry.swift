//
//  TorusGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/8/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class TorusGeometry: Geometry {
    public override init() {
        super.init()
        self.setupData(radius: (1, 2), res: (60, 60))
    }
    
    public init(radius: (minor: Float, major: Float), res: (minor: Int, major: Int)) {
        super.init()
        self.setupData(radius: radius, res: res)
    }
    
    func setupData(radius: (minor: Float, major: Float), res: (minor: Int, major: Int)) {
        let majorRadius = radius.major
        let minorRadius = radius.minor
        
        let slices = max(res.minor, 3)
        let angular = max(res.major, 3)
        
        let slicesf = Float(slices)
        let angularf = Float(angular)
        
        let limit = Float(.pi * 2.0)
        let sliceInc = limit / slicesf
        let angularInc = limit / angularf
        
        for s in 0...slices {
            let sf = Float(s)
            let slice = sf * sliceInc
            
            for a in 0...angular {
                let af = Float(a)
                let angle = af * angularInc
                
                let cosSlice = cos(slice)
                let sinSlice = sin(slice)
                
                let cosAngle = cos(angle)
                let sinAngle = sin(angle)
                
                let x = cosSlice * (majorRadius + cosAngle * minorRadius)
                let y = sinSlice * (majorRadius + cosAngle * minorRadius)
                let z = sinAngle * minorRadius
                
                let tangent = simd_make_float3(-sinSlice, cosSlice, 0.0)
                let stangent = simd_make_float3(cosSlice * (-sinAngle), sinSlice * (-sinAngle), cosAngle)
                
                vertexData.append(
                    Vertex(
                        position: simd_make_float4(x, z, y, 1.0),
                        normal: normalize(cross(tangent, stangent)),
                        uv: simd_make_float2(af / angularf, sf / slicesf)
                    )
                )
                
                if s != slices, a != angular {
                    let perLoop = angular + 1
                    let index = a + s * perLoop
                    
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
