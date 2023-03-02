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
    public var renderOrder = 0

    public var drawable: Bool {
        if instanceCount > 0, !geometry.vertexBuffers.isEmpty, uniforms != nil, material?.pipeline != nil {
            return true
        }
        return false
    }

    public var instanceCount = 1
    open var intersectable: Bool {
        geometry.vertexBuffer != nil && instanceCount > 0
    }

    var uniforms: VertexUniformBuffer?

    public var preDraw: ((_ renderEncoder: MTLRenderCommandEncoder) -> Void)?

    open var geometry: Geometry {
        didSet {
            if geometry != oldValue {
                geometryPublisher.send(self)
                setupGeometrySubscriber()
                setupGeometry()
                _updateLocalBounds = true
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

    override open func encode(to encoder: Encoder) throws {
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
            self._updateLocalBounds = true
        }
    }

    internal func cleanupGeometrySubscriber() {
        geometrySubscriber?.cancel()
        geometrySubscriber = nil
    }

    open func setupGeometry() {
        guard let context = context else { return }
        geometry.context = context
    }

    open func setupSubmeshes() {
        guard let context = context else { return }
        for submesh in submeshes {
            submesh.context = context
        }
    }

    open func setupMaterial() {
        guard let context = context, let material = material else { return }
        material.context = context
    }

    open func setupUniforms() {
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

    open func draw(renderEncoder: MTLRenderCommandEncoder, shadow: Bool = false) {
        draw(renderEncoder: renderEncoder, instanceCount: instanceCount, shadow: shadow)
    }

    open func bind(_ renderEncoder: MTLRenderCommandEncoder, shadow: Bool) {
        bindDrawingStates(renderEncoder)
        bindMaterial(renderEncoder, shadow: shadow)
        bindGeometry(renderEncoder)
        bindUniforms(renderEncoder)
    }

    open func bindUniforms(_ renderEncoder: MTLRenderCommandEncoder) {
        guard let uniforms = uniforms else { return }
        renderEncoder.setVertexBuffer(uniforms.buffer, offset: uniforms.offset, index: VertexBufferIndex.VertexUniforms.rawValue)
    }

    open func bindGeometry(_ renderEncoder: MTLRenderCommandEncoder) {
        for (index, buffer) in geometry.vertexBuffers {
            renderEncoder.setVertexBuffer(buffer, offset: 0, index: index.rawValue)
        }
    }

    open func bindMaterial(_ renderEncoder: MTLRenderCommandEncoder, shadow: Bool) {
        material?.bind(renderEncoder, shadow: shadow)
    }

    open func bindDrawingStates(_ renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setFrontFacing(geometry.windingOrder)
        renderEncoder.setCullMode(cullMode)
        renderEncoder.setTriangleFillMode(triangleFillMode)
    }

    open func draw(renderEncoder: MTLRenderCommandEncoder, instanceCount: Int, shadow: Bool) {
        guard drawable else { return }

        preDraw?(renderEncoder)

        bind(renderEncoder, shadow: shadow)

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

    // MARK: - Comoute Bounds

    override open func computeLocalBounds() -> Bounds {
        return transformBounds(geometry.bounds, localMatrix)
    }

    override open func computeWorldBounds() -> Bounds {
        var result = transformBounds(geometry.bounds, worldMatrix)
        for child in children {
            result = mergeBounds(result, child.worldBounds)
        }
        return result
    }

    // MARK: - Intersect

    override open func intersect(ray: Ray, intersections: inout [RaycastResult], recursive: Bool = true, invisible: Bool = false) {
        guard visible || invisible, intersects(ray: ray) else { return }

        var geometryIntersections = [IntersectionResult]()
        geometry.intersect(
            ray: worldMatrix.inverse.act(ray),
            intersections: &geometryIntersections
        )

        var results = [RaycastResult]()
        for geometryIntersection in geometryIntersections {
            let hitPosition = simd_make_float3(
                worldMatrix * simd_make_float4(geometryIntersection.position, 1.0)
            )

            results.append(
                RaycastResult(
                    barycentricCoordinates: geometryIntersection.barycentricCoordinates,
                    distance: simd_length(hitPosition - ray.origin),
                    normal: normalMatrix * geometryIntersection.normal,
                    position: hitPosition,
                    uv: geometryIntersection.uv,
                    primitiveIndex: geometryIntersection.primitiveIndex,
                    object: self,
                    submesh: nil
                )
            )
        }

        intersections.append(contentsOf: results)

        if recursive {
            for child in children {
                child.intersect(
                    ray: ray,
                    intersections: &intersections,
                    recursive: recursive,
                    invisible: invisible
                )
            }
        }

        intersections.sort { $0.distance < $1.distance }
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
