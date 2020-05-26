//
//  SolidPlaneGeometry.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class PlaneGeometry: Geometry {
    public enum Orientation {
        case xy // points in +z direction
        case yx // points in -z direction
        case xz // points in -y direction
        case zx // points in +y direction
        case yz // points in +x direction
        case zy // points in -x direction
    }
    
    public init(size: Float = 2) {
        super.init()
        self.setupData(width: size, height: size, resU: 1, resV: 1)
    }
    
    public init(size: Float, plane: Orientation = .xy) {
        super.init()
        self.setupData(width: size, height: size, resU: 1, resV: 1, plane: plane)
    }
    
    public init(size: Float, plane: Orientation = .xy, centered: Bool = true) {
        super.init()
        self.setupData(width: size, height: size, resU: 1, resV: 1, plane: plane, centered: centered)
    }
    
    public init(size: Float, res: Int) {
        super.init()
        self.setupData(width: size, height: size, resU: res, resV: res)
    }
    
    public init(size: Float, res: Int, plane: Orientation = .xy) {
        super.init()
        self.setupData(width: size, height: size, resU: res, resV: res, plane: plane)
    }
    
    public init(size: Float, res: Int, plane: Orientation = .xy, centered: Bool = true) {
        super.init()
        self.setupData(width: size, height: size, resU: res, resV: res, plane: plane, centered: centered)
    }
    
    public init(size: (width: Float, height: Float)) {
        super.init()
        self.setupData(width: size.width, height: size.height, resU: 1, resV: 1)
    }
    
    public init(size: (width: Float, height: Float), plane: Orientation = .xy) {
        super.init()
        self.setupData(width: size.width, height: size.height, resU: 1, resV: 1, plane: plane)
    }
    
    public init(size: (width: Float, height: Float), plane: Orientation = .xy, centered: Bool = true) {
        super.init()
        self.setupData(width: size.width, height: size.height, resU: 1, resV: 1, plane: plane, centered: centered)
    }
    
    public init(size: (width: Float, height: Float), res: Int) {
        super.init()
        self.setupData(width: size.width, height: size.height, resU: res, resV: res)
    }
    
    public init(size: (width: Float, height: Float), res: Int, plane: Orientation = .xy) {
        super.init()
        self.setupData(width: size.width, height: size.height, resU: res, resV: res, plane: plane)
    }
    
    public init(size: (width: Float, height: Float), res: Int, plane: Orientation = .xy, centered: Bool = true) {
        super.init()
        self.setupData(width: size.width, height: size.height, resU: res, resV: res, plane: plane, centered: centered)
    }
    
    public init(size: (width: Float, height: Float), res: (u: Int, v: Int)) {
        super.init()
        self.setupData(width: size.width, height: size.height, resU: res.u, resV: res.v)
    }
    
    public init(size: (width: Float, height: Float), res: (u: Int, v: Int), plane: Orientation = .xy) {
        super.init()
        self.setupData(width: size.width, height: size.height, resU: res.u, resV: res.v, plane: plane)
    }
    
    public init(size: (width: Float, height: Float), res: (u: Int, v: Int), plane: Orientation = .xy, centered: Bool = true) {
        super.init()
        self.setupData(width: size.width, height: size.height, resU: res.u, resV: res.v, plane: plane, centered: centered)
    }
    
    func setupData(width: Float, height: Float, resU: Int, resV: Int, plane: Orientation = .xy, centered: Bool = true) {
        var rU = resU
        var rV = resV
        
        var sizeU = width
        var sizeV = height
        
        if plane == .yx || plane == .zx || plane == .yz {
            swap(&sizeU, &sizeV)
            swap(&rU, &rV)
        }
        
        rU = max(rU, 1)
        rV = max(rV, 1)
        
        let bU = Float(rU)
        let bV = Float(rV)
        
        let hU = sizeU * 0.5
        let hV = sizeV * 0.5
        
        let dU = sizeU / bU
        let dV = sizeV / bV
        
        let cU = centered ? -hU : 0.0
        let cV = centered ? -hV : 0.0
        
        let perRow = rU + 1
        
        for v in 0...rV {
            for u in 0...rU {
                let fU = Float(u)
                let fV = Float(v)
                
                var p = simd_make_float4(cU + fU * dU, cV + fV * dV, 0.0, 1.0)
                var n = simd_make_float3(0.0, 0.0, 1.0)
                var t = simd_make_float2(fU / bU, 1.0 - fV / bV)
                
                switch plane {
                case .xy: // points in +z direction
                    break
                case .yx: // points in -z direction
                    p = simd_make_float4(p.y, p.x, p.z, p.w)
                    n = simd_make_float3(0.0, 0.0, -1.0)
                    t = simd_make_float2(t.y, 1.0 - t.x)
                case .xz: // points in -y direction
                    p = simd_make_float4(p.x, p.z, p.y, p.w)
                    n = simd_make_float3(0.0, -1.0, 0.0)
                case .zx: // points in +y direction
                    p = simd_make_float4(p.y, p.z, p.x, p.w)
                    n = simd_make_float3(0.0, 1.0, 0.0)
                    t = simd_make_float2(1.0 - t.y, t.x)
                case .yz: // points in +x direction
                    p = simd_make_float4(p.z, p.x, p.y, p.w)
                    n = simd_make_float3(1.0, 0.0, 0.0)
                    t = simd_make_float2(t.y, 1.0 - t.x)
                case .zy: // points in -x direction
                    p = simd_make_float4(p.z, p.y, p.x, p.w)
                    n = simd_make_float3(-1.0, 0.0, 0.0)
                }
                
                vertexData.append(
                    Vertex(
                        p,
                        t,
                        n
                    )
                )
                
                let index = u + v * perRow
                let bl = index
                let br = bl + 1
                let tl = index + perRow
                let tr = tl + 1
                
                if u != rU, v != rV {
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
