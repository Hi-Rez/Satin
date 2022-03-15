//
//  OctaSphereGeometry.swift
//  Satin
//
//  Created by Reza Ali on 3/15/22.
//

import Foundation

open class OctaSphereGeometry: Geometry {
    override public init() {
        super.init()
        setupData(radius: 1, res: 1)
    }

    public init(radius: Float, res: Int) {
        super.init()
        setupData(radius: radius, res: res)
    }

    func setupData(radius: Float, res: Int) {
        var geometryData = generateOctaSphereGeometryData(radius, Int32(res))
        setFrom(&geometryData)
        freeGeometryData(&geometryData)
    }
}
