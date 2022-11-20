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
        self.setupData(radius: radius, angle: angle, res: res)
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    func setupData(radius: (inner: Float, outer: Float), angle: (start: Float, end: Float), res: (angular: Int, radial: Int)) {
        var geometryData = generateArcGeometryData(radius.inner, radius.outer, angle.start, angle.end, Int32(res.angular), Int32(res.radial))
        setFrom(&geometryData)
        freeGeometryData(&geometryData)
    }
}
