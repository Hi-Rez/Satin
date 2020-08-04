//
//  IcoSphereGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/11/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class IcoSphereGeometry: Geometry {
    var midPointIndexCache: [String: UInt32] = [String: UInt32]()
    var index: UInt32 = 0
    
    public override init() {
        super.init()
        setupData(radius: 1, res: 1)
    }
    
    public init(radius: Float, res: Int) {
        super.init()
        setupData(radius: radius, res: res)
    }
    
    func setupData(radius: Float, res: Int) {
        var geometryData = generateIcoSphereGeometryData(radius, Int32(res))
        setFrom(&geometryData)
        freeGeometryData(&geometryData)
    }
}
