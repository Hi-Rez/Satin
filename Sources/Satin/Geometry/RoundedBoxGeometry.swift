//
//  RoundedBoxGeometry.swift
//  Satin
//
//  Created by Reza Ali on 3/15/22.
//

import Foundation

open class RoundedBoxGeometry: Geometry {
    override public init() {
        super.init()
        setupData(width: 2, height: 2, depth: 2, radius: 0.25, res: 1)
    }

    public init(size: Float, radius: Float, res: Int) {
        super.init()
        setupData(width: size, height: size, depth: size, radius: radius, res: res)
    }

    public init(size: (width: Float, height: Float, depth: Float), radius: Float, res: Int) {
        super.init()
        setupData(width: size.width, height: size.height, depth: size.depth, radius: radius, res: res)
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    func setupData(width: Float, height: Float, depth: Float, radius: Float, res: Int) {
        var geometryData = generateRoundedBoxGeometryData(width, height, depth, radius, Int32(res))
        setFrom(&geometryData)
        freeGeometryData(&geometryData)
    }
}
