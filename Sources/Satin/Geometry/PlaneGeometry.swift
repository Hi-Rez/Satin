//
//  SolidPlaneGeometry.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class PlaneGeometry: Geometry {
    public enum PlaneOrientation: Int32 {
        case xy = 0 // points in +z direction
        case yx = 1 // points in -z direction
        case xz = 2 // points in -y direction
        case zx = 3 // points in +y direction
        case yz = 4 // points in +x direction
        case zy = 5 // points in -x direction
    }
    
    public init(size: Float = 2) {
        super.init()
        self.setupData(width: size, height: size, resU: 1, resV: 1)
    }
    
    public init(size: Float, plane: PlaneOrientation = .xy) {
        super.init()
        self.setupData(width: size, height: size, resU: 1, resV: 1, plane: plane)
    }
    
    public init(size: Float, plane: PlaneOrientation = .xy, centered: Bool = true) {
        super.init()
        self.setupData(width: size, height: size, resU: 1, resV: 1, plane: plane, centered: centered)
    }
    
    public init(size: Float, res: Int) {
        super.init()
        self.setupData(width: size, height: size, resU: res, resV: res)
    }
    
    public init(size: Float, res: Int, plane: PlaneOrientation = .xy) {
        super.init()
        self.setupData(width: size, height: size, resU: res, resV: res, plane: plane)
    }
    
    public init(size: Float, res: Int, plane: PlaneOrientation = .xy, centered: Bool = true) {
        super.init()
        self.setupData(width: size, height: size, resU: res, resV: res, plane: plane, centered: centered)
    }
    
    public init(size: (width: Float, height: Float)) {
        super.init()
        self.setupData(width: size.width, height: size.height, resU: 1, resV: 1)
    }
    
    public init(size: (width: Float, height: Float), plane: PlaneOrientation = .xy) {
        super.init()
        self.setupData(width: size.width, height: size.height, resU: 1, resV: 1, plane: plane)
    }
    
    public init(size: (width: Float, height: Float), plane: PlaneOrientation = .xy, centered: Bool = true) {
        super.init()
        self.setupData(width: size.width, height: size.height, resU: 1, resV: 1, plane: plane, centered: centered)
    }
    
    public init(size: (width: Float, height: Float), res: Int) {
        super.init()
        self.setupData(width: size.width, height: size.height, resU: res, resV: res)
    }
    
    public init(size: (width: Float, height: Float), res: Int, plane: PlaneOrientation = .xy) {
        super.init()
        self.setupData(width: size.width, height: size.height, resU: res, resV: res, plane: plane)
    }
    
    public init(size: (width: Float, height: Float), res: Int, plane: PlaneOrientation = .xy, centered: Bool = true) {
        super.init()
        self.setupData(width: size.width, height: size.height, resU: res, resV: res, plane: plane, centered: centered)
    }
    
    public init(size: (width: Float, height: Float), res: (u: Int, v: Int)) {
        super.init()
        self.setupData(width: size.width, height: size.height, resU: res.u, resV: res.v)
    }
    
    public init(size: (width: Float, height: Float), res: (u: Int, v: Int), plane: PlaneOrientation = .xy) {
        super.init()
        self.setupData(width: size.width, height: size.height, resU: res.u, resV: res.v, plane: plane)
    }
    
    public init(size: (width: Float, height: Float), res: (u: Int, v: Int), plane: PlaneOrientation = .xy, centered: Bool = true) {
        super.init()
        self.setupData(width: size.width, height: size.height, resU: res.u, resV: res.v, plane: plane, centered: centered)
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    func setupData(width: Float, height: Float, resU: Int, resV: Int, plane: PlaneOrientation = .xy, centered: Bool = true) {
        var geometryData = generatePlaneGeometryData(width, height, Int32(resU), Int32(resV), plane.rawValue, centered)
        setFrom(&geometryData)
        freeGeometryData(&geometryData)
    }
}
