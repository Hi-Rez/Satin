//
//  Geometry.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Combine
import Metal
import ModelIO
import simd

public protocol VertexType {
    var descriptor: MDLVertexDescriptor { get }
    var position: simd_float4 { get }
    var normal: simd_float3 { get }
    var uv: simd_float2 { get }
}

extension Vertex: VertexType {
    public var descriptor: MDLVertexDescriptor {
        SatinModelIOVertexDescriptor()
    }
}

extension Bounds {
    init() {
        self.init(min: .zero, max: .zero)
    }
}

public protocol BaseGeometry: Hashable {
    var id: String { get set }
    var primitiveType: MTLPrimitiveType { get set }
    var windingOrder: MTLWinding { get set }
    var indexType: MTLIndexType { get set }

    var vertexData: [VertexType] { get }
    var indexData: [UInt32] { get set }
    
    var context: Context? { get set }
    
    var bounds: Bounds { get }
        
    var vertexBuffer: MTLBuffer? { get set }
    var indexBuffer: MTLBuffer? { get set }
    
    var vertexDescriptor: MDLVertexDescriptor { get }
    
    func setup()
    func update()
}

open class Geometry: BaseGeometry {
    public var id: String = UUID().uuidString
    
    public var vertexDescriptor: MDLVertexDescriptor {
        SatinModelIOVertexDescriptor()
    }
    
    public var primitiveType: MTLPrimitiveType = .triangle
    public var windingOrder: MTLWinding = .counterClockwise
    public var indexType: MTLIndexType = .uint32
    
    @PublishedDidSet public var vertexData: [VertexType] = [] {
        didSet {
            _updateVertexBuffer = true
            _updateBounds = true
        }
    }
    
    @PublishedDidSet public var indexData: [UInt32] = [] {
        didSet {
            _updateIndexBuffer = true
            _updateBounds = true
        }
    }
    
    public var context: Context? {
        didSet {
            setup()
        }
    }
    
    var _updateVertexBuffer = true
    var _updateIndexBuffer = true
    var _updateBounds: Bool = true
    var _bounds = Bounds(min: simd_float3(repeating: 0.0), max: simd_float3(repeating: 0.0))
    
    public var bounds: Bounds {
        if _updateBounds {
            _bounds = computeBounds()
            _updateBounds = false
        }
        return _bounds
    }
    
    public var vertexBuffer: MTLBuffer? {
        didSet {
            _updateVertexBuffer = vertexBuffer == nil
        }
    }

    public var indexBuffer: MTLBuffer? {
        didSet {
            _updateIndexBuffer = indexBuffer == nil
        }
    }
    
    public init() {}
    
    public init(_ geometryData: inout GeometryData) {
        setFrom(&geometryData)
    }
    
    public init(primitiveType: MTLPrimitiveType, windingOrder: MTLWinding, indexType: MTLIndexType) {
        self.primitiveType = primitiveType
        self.windingOrder = windingOrder
        self.indexType = indexType
    }
    
    public func setup() {
        setupVertexBuffer()
        setupIndexBuffer()
    }
    
    public func update() {
        if _updateVertexBuffer {
            setupVertexBuffer()
        }
        if _updateIndexBuffer {
            setupIndexBuffer()
        }
    }
    
    func setupVertexBuffer() {
        guard _updateVertexBuffer, let context = context, var data = vertexData as? [Vertex], !data.isEmpty else { return }
        let device = context.device
        let verticesSize = data.count * MemoryLayout<Vertex>.stride
        
        if let vertexBuffer = vertexBuffer, vertexBuffer.length == verticesSize {
            vertexBuffer.contents().copyMemory(from: &data, byteCount: verticesSize)
        }
        else {
            vertexBuffer = device.makeBuffer(bytes: data, length: verticesSize, options: [])
            vertexBuffer?.label = "Vertices"
        }
        _updateVertexBuffer = false
    }
    
    func setupIndexBuffer() {
        guard _updateIndexBuffer, let context = context else { return }
        let device = context.device
        if !indexData.isEmpty {
            let indicesSize = indexData.count * MemoryLayout.size(ofValue: indexData[0])
            indexBuffer = device.makeBuffer(bytes: indexData, length: indicesSize, options: [])
            indexBuffer?.label = "Indices"
        }
        else {
            indexBuffer = nil
        }
        _updateIndexBuffer = false
    }
    
    public func setFrom(_ geometryData: inout GeometryData) {
        let vertexCount = Int(geometryData.vertexCount)
        if vertexCount > 0, let data = geometryData.vertexData {
            vertexData = Array(UnsafeBufferPointer(start: data, count: vertexCount))
        }
        else {
            vertexData = []
        }
        
        let indexCount = Int(geometryData.indexCount) * 3
        if indexCount > 0, let data = geometryData.indexData {
            data.withMemoryRebound(to: UInt32.self, capacity: indexCount) { ptr in
                indexData = Array(UnsafeBufferPointer(start: ptr, count: indexCount))
            }
        }
        else {
            indexData = []
        }
    }
    
    public func getGeometryData() -> GeometryData {
        var data = GeometryData()
        data.vertexCount = Int32(vertexData.count)
        data.indexCount = Int32(indexData.count / 3)
        
        if var v = vertexData as? [Vertex] {
            v.withUnsafeMutableBufferPointer { vtxPtr in
                data.vertexData = vtxPtr.baseAddress!
            }
        }
//        vertexData.withUnsafeMutableBufferPointer { vtxPtr in
//            data.vertexData = vtxPtr.baseAddress!
//        }
        
        indexData.withUnsafeMutableBufferPointer { indPtr in
            let raw = UnsafeRawBufferPointer(indPtr)
            let ptr = raw.bindMemory(to: TriangleIndices.self)
            data.indexData = UnsafeMutablePointer(mutating: ptr.baseAddress!)
        }
        
        return data
    }
    
    public func unroll() {
        var data = getGeometryData()
        var unrolled = GeometryData()
        unrollGeometryData(&unrolled, &data)
        setFrom(&unrolled)
        freeGeometryData(&unrolled)
    }
    
    public func transform(_ matrix: simd_float4x4) {
        if var v = vertexData as? [Vertex] {
            transformVertices(&v, Int32(vertexData.count), matrix)
        }
    }
    
    func computeBounds() -> Bounds {
        if var v = vertexData as? [Vertex] {
            return computeBoundsFromVertices(&v, Int32(vertexData.count))
        }
        return Bounds()
    }
    
    deinit {
        indexData = []
        vertexData = []
        vertexBuffer = nil
        indexBuffer = nil
    }
}

extension Geometry: Equatable {
    public static func == (lhs: Geometry, rhs: Geometry) -> Bool {
        return lhs === rhs
    }
}

extension Geometry: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }
}
