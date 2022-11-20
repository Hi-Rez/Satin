//
//  CircleGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/6/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class CircleGeometry: Geometry {
    override public init() {
        super.init()
        self.setupData(radius: 1, res: (60, 1))
    }
    
    public convenience init(radius: Float) {
        self.init(radius: radius, res: (60, 1))
    }
    
    public convenience init(radius: Float, res: Int) {
        self.init(radius: radius, res: (res, 1))
    }
    
    public init(radius: Float, res: (angular: Int, radial: Int)) {
        super.init()
        self.setupData(radius: radius, res: res)
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    func setupData(radius: Float, res: (angular: Int, radial: Int)) {
        var geometryData = generateCircleGeometryData(radius, Int32(res.angular), Int32(res.radial))
        setFrom(&geometryData)
        freeGeometryData(&geometryData)
    }
}
