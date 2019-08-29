//
//  Geometry.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal

protocol GeometryDelegate: AnyObject {
    func vertexDataUpdated()
    func indexDataUpdated()
}

open class Geometry {
    public var primitiveType: MTLPrimitiveType
    public var windingOrder: MTLWinding
    public var indexType: MTLIndexType
    weak var delegate: GeometryDelegate?
    
    public var vertexData: [Vertex] = [] {
        didSet {
            delegate?.vertexDataUpdated()
        }
    }
    
    public var indexData: [UInt32] = [] {
        didSet {
            delegate?.indexDataUpdated()
        }
    }
    
    public init() {
        primitiveType = .triangle
        windingOrder = .counterClockwise
        indexType = .uint32
    }
    
    public init(primitiveType: MTLPrimitiveType, windingOrder: MTLWinding, indexType: MTLIndexType) {
        self.primitiveType = primitiveType
        self.windingOrder = windingOrder
        self.indexType = indexType
    }
    
    deinit {
        delegate = nil
        indexData = []
        vertexData = []
    }
}
