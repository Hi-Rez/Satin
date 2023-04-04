//
//  TessellatedGeometry.swift
//  Tesselation
//
//  Created by Reza Ali on 3/31/23.
//  Copyright © 2023 Reza Ali. All rights reserved.
//

import Foundation
import Metal
import Satin

class TessellatedGeometry: Geometry {
    var patchCount: Int { indexData.isEmpty ? (vertexData.count / 3) : (indexData.count / 3) }
    let controlPointsPerPatch: Int = 3
    var partitionMode: MTLTessellationPartitionMode { .integer }
    var stepFunction: MTLTessellationFactorStepFunction { .perPatch }
    var controlPointBuffer: MTLBuffer? { vertexBuffer }
    var controlPointIndexBuffer: MTLBuffer? { indexBuffer }
    var controlPointIndexType: MTLTessellationControlPointIndexType { indexData.isEmpty ? .none : .uint32 }



    public init(baseGeometry: Geometry) {
        super.init(primitiveType: baseGeometry.primitiveType, windingOrder: baseGeometry.windingOrder, indexType: baseGeometry.indexType)
        self.vertexDescriptor.layouts[VertexBufferIndex.Vertices.rawValue].stepRate = 1
        self.vertexDescriptor.layouts[VertexBufferIndex.Vertices.rawValue].stepFunction = .perPatchControlPoint
        self.vertexData = baseGeometry.vertexData
        self.indexData = baseGeometry.indexData
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
