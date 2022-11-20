//
//  CapsuleGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/11/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class CapsuleGeometry: Geometry {
    public enum Axis: Int32 {
        case x = 0
        case y = 1
        case z = 2
    }

    public init(size: (radius: Float, height: Float), axis: Axis = .y) {
        super.init()
        self.setupData(size: size, res: (60, 30, 30), axis: axis)
    }

    public init(size: (radius: Float, height: Float), res: (angular: Int, radial: Int, vertical: Int), axis: Axis = .y) {
        super.init()
        self.setupData(size: size, res: res, axis: axis)
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    func setupData(size: (radius: Float, height: Float), res: (angular: Int, radial: Int, vertical: Int), axis: Axis) {
        var geometryData = generateCapsuleGeometryData(size.radius, size.height, Int32(res.angular), Int32(res.radial), Int32(res.vertical), axis.rawValue)
        setFrom(&geometryData)
        freeGeometryData(&geometryData)
    }
}
