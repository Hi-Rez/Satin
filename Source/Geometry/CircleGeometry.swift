//
//  CircleGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/6/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class CircleGeometry: Geometry {
    public override init() {
        super.init()
        self.setup(radius: 1, res: (60, 1))
    }
    
    public convenience init(radius: Float) {
        self.init(radius: radius, res: (60, 1))
    }
    
    public convenience init(radius: Float, res: Int) {
        self.init(radius: radius, res: (res, 1))
    }
    
    public init(radius: Float, res: (angular: Int, radial: Int)) {
        super.init()
        self.setup(radius: radius, res: res)
    }
    
    func setup(radius: Float, res: (angular: Int, radial: Int)) {
        let radial = max(res.radial, 1)
        let angular = max(res.angular, 3)
        
        let radialf = Float(radial)
        let angularf = Float(angular)
        
        let radialInc = radius / radialf
        let angularInc = (Float.pi * 2.0) / angularf
        
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
