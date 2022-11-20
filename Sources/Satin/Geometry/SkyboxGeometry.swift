//
//  SkyboxGeometry.swift
//  Satin
//
//  Created by Reza Ali on 4/16/20.

import simd

open class SkyboxGeometry: Geometry {
    public init(size: Float = 2) {
        super.init()
        self.setupData(size: size)
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    func setupData(size: Float) {
        var geometryData = generateSkyboxGeometryData(size)
        setFrom(&geometryData)
        freeGeometryData(&geometryData)
    }
}
