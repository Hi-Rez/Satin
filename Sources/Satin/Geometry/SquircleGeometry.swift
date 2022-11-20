//
//  SquircleGeometry.swift
//  Satin
//
//  Created by Reza Ali on 8/3/20.
//

import simd

open class SquircleGeometry: Geometry {
    public init(size: Float = 2.0, p: Float = 4.0, res: (angular: Int, radial: Int) = (90, 20)) {
        super.init()
        self.setupData(size: size, p: p, res: res)
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    func setupData(size: Float, p: Float, res: (angular: Int, radial: Int)) {
        var geometryData = generateSquircleGeometryData(size, p, Int32(res.angular), Int32(res.radial))
        setFrom(&geometryData)
        freeGeometryData(&geometryData)
    }
}
