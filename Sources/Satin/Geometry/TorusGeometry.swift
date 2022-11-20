//
//  TorusGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/8/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class TorusGeometry: Geometry {
    override public init() {
        super.init()
        self.setupData(radius: (1, 2), res: (60, 60))
    }

    public init(radius: (minor: Float, major: Float), res: (minor: Int, major: Int) = (60, 60)) {
        super.init()
        self.setupData(radius: radius, res: res)
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    func setupData(radius: (minor: Float, major: Float), res: (minor: Int, major: Int)) {
        var geometryData = generateTorusGeometryData(radius.minor, radius.major, Int32(res.minor), Int32(res.major))
        setFrom(&geometryData)
        freeGeometryData(&geometryData)
    }
}
