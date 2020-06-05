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
        let geometryData = generateIcoSphereGeometryData(radius, Int32(res))
        let vertexCount = Int(geometryData.vertexCount)
        if vertexCount > 0, let data = geometryData.vertexData {
            vertexData = Array(UnsafeBufferPointer(start: data, count: vertexCount))
        }
        
        let indexCount = Int(geometryData.indexCount) * 3
        if indexCount > 0, let data = geometryData.indexData {
            data.withMemoryRebound(to: UInt32.self, capacity: indexCount) { ptr in
                indexData = Array(UnsafeBufferPointer(start: ptr, count: indexCount))
            }
        }
        freeGeometryData(geometryData)
    }
}
