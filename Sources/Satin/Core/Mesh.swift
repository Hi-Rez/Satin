//
//  Mesh.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Combine
import Metal
import MetalPerformanceShaders
import simd

open class Mesh: Object, Renderable, Intersectable {
    public var triangleFillMode: MTLTriangleFillMode = .fill
    public var cullMode: MTLCullMode = .back
    
    public var instanceCount: Int = 1
    open var intersectable: Bool {
        geometry.vertexBuffer != nil && instanceCount > 0
    }
    
    var uniforms: VertexUniformBuffer?
    
    public var preDraw: ((_ renderEncoder: MTLRenderCommandEncoder) -> ())?
    
    open var geometry: Geometry {
        didSet {
            if geometry != oldValue {
                geometryPublisher.send(self)
                setupGeometrySubscriber()
                setupGeometry()
                _localBounds.clear()
            }
        }
    }
    
    public let geometryPublisher = PassthroughSubject<Intersectable, Never>()
    
    open var material: Material? {
        didSet {
            if material != oldValue {
                setupMaterial()
            }
        }
    }
    
    internal var geometrySubscriber: AnyCancellable?
    
    public var submeshes: [Submesh] = []
    
    public init(geometry: Geometry, material: Material?) {
        self.geometry = geometry
        self.material = material
        super.init()
        setupGeometrySubscriber()
    }
    
    // MARK: - CodingKeys
    
    public enum CodingKeys: String, CodingKey {
        case triangleFillMode
        case cullMode
        case instanceCount
        case geometry
        case material
    }
    
    // MARK: - Decode
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        triangleFillMode = try values.decode(MTLTriangleFillMode.self, forKey: .triangleFillMode)
        cullMode = try values.decode(MTLCullMode.self, forKey: .cullMode)
        instanceCount = try values.decode(Int.self, forKey: .instanceCount)
        geometry = try values.decode(Geometry.self, forKey: .geometry)
        material = try values.decode(AnyMaterial?.self, forKey: .material)?.material
        try super.init(from: decoder)
    }
    
    // MARK: - Encode
    
    open override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(triangleFillMode, forKey: .triangleFillMode)
        try container.encode(cullMode, forKey: .cullMode)
        try container.encode(instanceCount, forKey: .instanceCount)
        try container.encode(geometry, forKey: .geometry)
        if let material = material {
            try container.encode(AnyMaterial(material), forKey: .material)
        }
    }
    
    deinit {
        cleanupGeometrySubscriber()
    }

    override open func setup() {
        setupGeometry()
        setupSubmeshes()
        setupMaterial()
        setupUniforms()
    }
    
    internal func setupGeometrySubscriber() {
        geometrySubscriber?.cancel()
        geometrySubscriber = geometry.publisher.sink { [weak self] _ in
            guard let self = self else { return }
            self.geometryPublisher.send(self)
            self._localBounds.clear()
        }
    }
        
    internal func cleanupGeometrySubscriber() {
        geometrySubscriber?.cancel()
        geometrySubscriber = nil
    }
    
    internal func setupGeometry() {
        guard let context = context else { return }
        geometry.context = context
    }
    
    internal func setupSubmeshes() {
        guard let context = context else { return }
        for submesh in submeshes {
            submesh.context = context
        }
    }

    internal func setupMaterial() {
        guard let context = context, let material = material else { return }
        material.context = context
    }
    
    internal func setupUniforms() {
        guard let context = context else { return }
        uniforms = VertexUniformBuffer(device: context.device)
    }
    
    override open func update() {
        geometry.update()
        material?.update()
        uniforms?.update()
        super.update()
    }
    
    override open func update(camera: Camera, viewport: simd_float4) {
        material?.update(camera: camera)
        uniforms?.update(object: self, camera: camera, viewport: viewport)
    }
    
    open func draw(renderEncoder: MTLRenderCommandEncoder) {
        draw(renderEncoder: renderEncoder, instanceCount: instanceCount)
    }
    
    open func bind(_ renderEncoder: MTLRenderCommandEncoder) {
        bindDrawingStates(renderEncoder)
    }
    
    open func bindDrawingStates(_ renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setFrontFacing(geometry.windingOrder)
        renderEncoder.setCullMode(cullMode)
        renderEncoder.setTriangleFillMode(triangleFillMode)
    }

    open func draw(renderEncoder: MTLRenderCommandEncoder, instanceCount: Int) {
        guard instanceCount > 0,
              !geometry.vertexBuffers.isEmpty,
              let uniforms = uniforms,
              let material = material,
              material.pipeline != nil
        else { return }
        
        preDraw?(renderEncoder)

        material.bind(renderEncoder)
        
        self.bind(renderEncoder)

        for (index, buffer) in geometry.vertexBuffers {
            renderEncoder.setVertexBuffer(buffer, offset: 0, index: index.rawValue)
        }
        
        renderEncoder.setVertexBuffer(uniforms.buffer, offset: uniforms.offset, index: VertexBufferIndex.VertexUniforms.rawValue)
        
        if !submeshes.isEmpty {
            for submesh in submeshes {
                if submesh.visible, let indexBuffer = submesh.indexBuffer {
                    renderEncoder.drawIndexedPrimitives(
                        type: geometry.primitiveType,
                        indexCount: submesh.indexCount,
                        indexType: submesh.indexType,
                        indexBuffer: indexBuffer,
                        indexBufferOffset: submesh.indexBufferOffset,
                        instanceCount: instanceCount
                    )
                }
            }
        } else if let indexBuffer = geometry.indexBuffer {
            renderEncoder.drawIndexedPrimitives(
                type: geometry.primitiveType,
                indexCount: geometry.indexData.count,
                indexType: geometry.indexType,
                indexBuffer: indexBuffer,
                indexBufferOffset: 0,
                instanceCount: instanceCount
            )
        } else {
            renderEncoder.drawPrimitives(
                type: geometry.primitiveType,
                vertexStart: 0,
                vertexCount: geometry.vertexData.count,
                instanceCount: instanceCount
            )
        }
    }
    
    open func addSubmesh(_ submesh: Submesh) {
        submesh.parent = self
        submeshes.append(submesh)
    }
    
    override open func computeLocalBounds() -> Bounds {
        return transformBounds(geometry.bounds, localMatrix)
    }
    
    override open func computeWorldBounds() -> Bounds {
        var result = transformBounds(geometry.bounds, worldMatrix)
        children.forEach { child in
            result = mergeBounds(result, child.worldBounds)
        }
        return result
    }

    // MARK: - Intersectable
    
    public var vertexStride: Int {
        MemoryLayout<Vertex>.stride
    }
    
    public var windingOrder: MTLWinding {
        geometry.windingOrder
    }
    
    public var vertexBuffer: MTLBuffer? {
        geometry.vertexBuffer
    }
    
    public var vertexCount: Int {
        geometry.vertexData.count
    }
    
    public var indexBuffer: MTLBuffer? {
        geometry.indexBuffer
    }
    
    public var indexCount: Int {
        geometry.indexData.count
    }
    
    public var intersectionBounds: Bounds {
        geometry.bounds
    }
    
    public func intersects(ray: Ray) -> Bool {
        let worldMatrixInverse = worldMatrix.inverse
        let origin = worldMatrixInverse * simd_make_float4(ray.origin, 1.0)
        let direction = worldMatrixInverse * simd_make_float4(ray.direction, 0.0)
        var times: simd_float2 = .zero
        return rayBoundsIntersection(simd_make_float3(origin), simd_make_float3(direction), intersectionBounds, &times)
    }
    
    public func getRaycastResult(ray: Ray, distance: Float, primitiveIndex: UInt32, barycentricCoordinate: simd_float2) -> RaycastResult? {
        let index = Int(primitiveIndex) * 3
            
        var i0 = 0
        var i1 = 0
        var i2 = 0

        if geometry.indexData.count > 0 {
            i0 = Int(geometry.indexData[index])
            i1 = Int(geometry.indexData[index + 1])
            i2 = Int(geometry.indexData[index + 2])
        } else {
            i0 = index
            i1 = index + 1
            i2 = index + 2
        }
        
        guard i0 < vertexCount, i1 < vertexCount, i2 < vertexCount else { return nil }
            
        let a: Vertex = geometry.vertexData[i0]
        let b: Vertex = geometry.vertexData[i1]
        let c: Vertex = geometry.vertexData[i2]
            
        let u: Float = barycentricCoordinate.x
        let v: Float = barycentricCoordinate.y
        let w: Float = 1.0 - u - v
    
        let aUv = a.uv * u
        let bUv = b.uv * v
        let cUv = c.uv * w
            
        let aNormal = (normalMatrix * a.normal) * u
        let bNormal = (normalMatrix * b.normal) * v
        let cNormal = (normalMatrix * c.normal) * w
            
        return RaycastResult(
            barycentricCoordinates: simd_make_float3(u, v, w),
            distance: distance,
            normal: simd_normalize(simd_make_float3(aNormal + bNormal + cNormal)),
            position: ray.at(distance),
            uv: simd_make_float2(aUv + bUv + cUv),
            primitiveIndex: primitiveIndex,
            object: self,
            submesh: nil
        )
    }
}
