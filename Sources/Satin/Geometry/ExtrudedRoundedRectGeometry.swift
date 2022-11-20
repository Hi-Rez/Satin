//
//  ExtrudedRoundedRectGeometry.swift
//  Satin
//
//  Created by Reza Ali on 8/6/20.
//

import Foundation

open class ExtrudedRoundedRectGeometry: Geometry {
    public init(size: (width: Float, height: Float, depth: Float), radius: Float = 0.5, res: (angular: Int, radial: Int, depth: Int) = (32, 32, 1)) {
        super.init()
        let edgeX = Int(Float(res.angular) * size.width / radius) / 6
        let edgeY = Int(Float(res.angular) * size.height / radius) / 6
        let edgeZ = res.depth
        self.setupData(size: size, radius: radius, res: (2 * res.angular / 3, edgeX, edgeY, edgeZ, res.radial))
    }

    public init(size: Float, depth: Float, radius: Float = 0.5, res: (angular: Int, radial: Int, depth: Int) = (32, 32, 1)) {
        super.init()
        let edgeX = Int(Float(res.angular) * size / radius) / 6
        let edgeY = Int(Float(res.angular) * size / radius) / 6
        let edgeZ = res.depth
        self.setupData(size: (size, size, depth), radius: radius, res: (2 * res.angular / 3, edgeX, edgeY, edgeZ, res.radial))
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    func setupData(size: (width: Float, height: Float, depth: Float), radius: Float, res: (corner: Int, edgeX: Int, edgeY: Int, edgeZ: Int, radial: Int)) {
        self.primitiveType = .triangle
        var geometryData = generateExtrudedRoundedRectGeometryData(size.width, size.height, size.depth, radius, Int32(res.corner), Int32(res.edgeX), Int32(res.edgeY), Int32(res.edgeZ), Int32(res.radial))
        setFrom(&geometryData)
        freeGeometryData(&geometryData)
    }
}
