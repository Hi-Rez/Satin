//
//  TubeGeometry.swift
//  Satin
//
//  Created by Reza Ali on 3/15/22.
//

import Foundation

open class TubeGeometry: Geometry {
    override public init() {
        super.init()
        self.setupData(size: (1, 2), angles: (0.0, Float.pi * 2.0), res: (60, 1))
    }

    public init(size: (radius: Float, height: Float), angles: (start: Float, end: Float), res: (angular: Int, vertical: Int)) {
        super.init()
        self.setupData(size: size, angles: angles, res: res)
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    func setupData(size: (radius: Float, height: Float), angles: (start: Float, end: Float), res: (angular: Int, vertical: Int)) {
        var geometryData = generateTubeGeometryData(size.radius, size.height, angles.start, angles.end, Int32(res.angular), Int32(res.vertical))
        setFrom(&geometryData)
        freeGeometryData(&geometryData)
    }
}
