//
//  IcoSphereGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/11/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

open class IcoSphereGeometry: Geometry {
    override public init() {
        super.init()
        setupData(radius: 1, res: 1)
    }

    public init(radius: Float, res: Int) {
        super.init()
        setupData(radius: radius, res: res)
    }

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    func setupData(radius: Float, res: Int) {
        var geometryData = generateIcoSphereGeometryData(radius, Int32(res))
        setFrom(&geometryData)
        freeGeometryData(&geometryData)
    }
}
