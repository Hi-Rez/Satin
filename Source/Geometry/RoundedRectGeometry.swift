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
        let edgeX = Int(Float(res.angular) * size.width / radius) / 2
        let edgeY = Int(Float(res.angular) * size.height / radius) / 2
        self.setupData(size: size, radius: radius, res: (res.angular, edgeX, edgeY, res.radial))
    }
    
    public init(size: Float = 2.0, radius: Float = 0.5, res: (angular: Int, radial: Int) = (32, 32)) {
        super.init()
        let edgeX = Int(Float(res.angular) * size / radius)/2
        let edgeY = Int(Float(res.angular) * size / radius)/2
        self.setupData(size: (size, size), radius: radius, res: (res.angular, edgeX, edgeY, res.radial))
    }
    
    func setupData(size: (width: Float, height: Float), radius: Float, res: (corner: Int, edgeX: Int, edgeY: Int, radial: Int)) {
        self.primitiveType = .triangle
        var geometryData = generateRoundedRectGeometryData(size.width, size.height, radius, Int32(res.corner), Int32(res.edgeX), Int32(res.edgeY), Int32(res.radial))
        setFrom(&geometryData)
        freeGeometryData(&geometryData)
    }
}
