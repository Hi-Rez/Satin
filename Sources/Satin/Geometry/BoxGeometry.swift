//
//  BoxGeometry.swift
//  Satin
//
//  Created by Reza Ali on 8/28/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class BoxGeometry: Geometry {
    override public init() {
        super.init()
        self.setupData(width: 2, height: 2, depth: 2, resWidth: 1, resHeight: 1, resDepth: 1)
    }

    public convenience init(size: Float) {
        self.init(size: (size, size, size))
    }

    public convenience init(size: Float, res: Int) {
        self.init(size: (size, size, size), res: res)
    }

    public convenience init(size: (width: Float, height: Float, depth: Float)) {
        self.init(size: size, res: 1)
    }

    public convenience init(size: (width: Float, height: Float, depth: Float), res: Int) {
        self.init(size: size, res: (res, res, res))
    }

    public init(size: (width: Float, height: Float, depth: Float), res: (width: Int, height: Int, depth: Int)) {
        super.init()
        self.setupData(width: size.width, height: size.height, depth: size.depth, resWidth: res.width, resHeight: res.height, resDepth: res.depth)
    }

    public init(bounds: Bounds, res: (width: Int, height: Int, depth: Int) = (1, 1, 1)) {
        super.init()
        self.setupData(bounds, res)
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    func setupData(_ bounds: Bounds, _ res: (width: Int, height: Int, depth: Int)) {
        let size = bounds.size
        let center = bounds.center
        var geometryData = generateBoxGeometryData(size.x, size.y, size.z, center.x, center.y, center.z, Int32(res.width), Int32(res.height), Int32(res.depth))
        setFrom(&geometryData)
        freeGeometryData(&geometryData)
    }

    func setupData(width: Float, height: Float, depth: Float, resWidth: Int, resHeight: Int, resDepth: Int) {
        var geometryData = generateBoxGeometryData(width, height, depth, 0.0, 0.0, 0.0, Int32(resWidth), Int32(resHeight), Int32(resDepth))
        setFrom(&geometryData)
        freeGeometryData(&geometryData)
    }
}
