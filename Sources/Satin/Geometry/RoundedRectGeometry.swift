//
//  RoundedRectGeometry.swift
//  Satin
//
//  Created by Reza Ali on 8/3/20.
//

import Foundation

open class RoundedRectGeometry: Geometry {
    public init(size: (width: Float, height: Float), radius: Float = 0.5, res: (angular: Int, radial: Int) = (32, 32)) {
        super.init()
        let edgeX = Int(Float(res.angular) * size.width / radius) / 6
        let edgeY = Int(Float(res.angular) * size.height / radius) / 6
        self.setupData(size: size, radius: radius, res: (2 * res.angular / 3, edgeX, edgeY, res.radial))
    }

    public init(size: Float = 2.0, radius: Float = 0.5, res: (angular: Int, radial: Int) = (32, 32)) {
        super.init()
        let edgeX = Int(Float(res.angular) * size / radius) / 6
        let edgeY = Int(Float(res.angular) * size / radius) / 6
        self.setupData(size: (size, size), radius: radius, res: (2 * res.angular / 3, edgeX, edgeY, res.radial))
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    func setupData(size: (width: Float, height: Float), radius: Float, res: (corner: Int, edgeX: Int, edgeY: Int, radial: Int)) {
        var geometryData = generateRoundedRectGeometryData(size.width, size.height, radius, Int32(res.corner), Int32(res.edgeX), Int32(res.edgeY), Int32(res.radial))
        setFrom(&geometryData)
        freeGeometryData(&geometryData)
    }
}
