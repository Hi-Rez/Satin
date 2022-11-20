//
//  SphereGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/1/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class SphereGeometry: Geometry {
    override public init() {
        super.init()
        self.setupData(radius: 1, res: (angular: 60, vertical: 60))
    }
    
    public convenience init(radius: Float) {
        self.init(radius: radius, res: (60, 60))
    }
    
    public convenience init(radius: Float, res: Int) {
        self.init(radius: radius, res: (res, res))
    }
    
    public init(radius: Float, res: (angular: Int, vertical: Int)) {
        super.init()
        self.setupData(radius: radius, res: res)
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    func setupData(radius: Float, res: (angular: Int, vertical: Int)) {
        var geometryData = generateSphereGeometryData(radius, Int32(res.angular), Int32(res.vertical))
        setFrom(&geometryData)
        freeGeometryData(&geometryData)
    }
}
