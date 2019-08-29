//
//  SolidPlaneGeometry.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

open class PlaneGeometry: Geometry {
    public override init() {
        super.init()
        self.setup(width: 2, height: 2, resX: 1, resY: 1, center: true)
    }
    
    public convenience init(size: Float) {
        self.init(size: (size, size))
    }
    
    public convenience init(size: Float, res: Int) {
        self.init(size: (size, size), res: res)
    }
    
    public convenience init(size: (width: Float, height: Float)) {
        self.init(size: size, res: 1)
    }
    
    public convenience init(size: (width: Float, height: Float), res: Int) {
        self.init(size: size, res: (res, res))
    }
    
    public convenience init(size: (width: Float, height: Float), res: (x: Int, y: Int)) {
        self.init(size: size, res: res, center: true)
    }
    
    public init(size: (width: Float, height: Float), res: (x: Int, y: Int), center: Bool) {
        super.init()
        self.setup(width: size.width, height: size.height, resX: res.x, resY: res.y, center: center)
    }
    
    func setup(width: Float, height: Float, resX: Int, resY: Int, center: Bool) {
        let rx = max(resX, 1)
        let ry = max(resY, 1)
        
        let bx = Float(rx)
        let by = Float(ry)
        
        let hw = width * 0.5
        let hh = height * 0.5
        
        let dx = width / bx
        let dy = height / by
        
        let cx = center ? -hw : 0.0
        let cy = center ? -hh : 0.0
        
        let perRow = rx + 1
        
        for y in 0...ry {
            for x in 0...rx {
                let fx = Float(x)
                let fy = Float(y)
                vertexData.append(
                    Vertex(
                        SIMD4<Float>(cx + fx * dx, cy + fy * dy, 0.0, 1.0),
                        SIMD2<Float>(fx / bx, fy / by),
                        SIMD3<Float>(0.0, 0.0, 1.0)
                    )
                )
                
                let index = x + y * perRow
                let bl = index
                let br = bl + 1
                let tl = index + perRow
                let tr = tl + 1
                
                if x != rx, y != ry {
                    indexData.append(UInt32(bl))
                    indexData.append(UInt32(br))
                    indexData.append(UInt32(tl))
                    indexData.append(UInt32(br))
                    indexData.append(UInt32(tr))
                    indexData.append(UInt32(tl))
                }
            }
        }
    }
}
