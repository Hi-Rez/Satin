//
//  Mesh.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Combine
import Metal
import simd

open class Mesh: Object, Renderable {
    public var renderOrder = 0

    public var receiveShadow = false {
        didSet {
            if receiveShadow != oldValue {
                material?.receiveShadow = receiveShadow
                for submesh in submeshes {
                    submesh.material?.receiveShadow = receiveShadow
                }
            }
        }
    }

    public var castShadow = false {
        didSet {
            if castShadow != oldValue {
                material?.castShadow = castShadow
                for submesh in submeshes {
                    submesh.material?.castShadow = castShadow
                }
            }
        }
    }

    public var triangleFillMode: MTLTriangleFillMode = .fill
    public var cullMode: MTLCullMode = .back

    public var drawable: Bool {
        guard instanceCount > 0, !geometry.vertexBuffers.isEmpty, uniforms != nil else { return false }

        if submeshes.isEmpty, let material = material, material.pipeline != nil {
            return true
        } else if let submesh = submeshes.first, let material = submesh.material, material.pipeline != nil {
            return true
        } else {
            return false
        }
    }

    public var instanceCount = 1

    var uniforms: VertexUniformBuffer?

    public var preDraw: ((_ renderEncoder: MTLRenderCommandEncoder) -> Void)?

    open var geometry: Geometry {
        didSet {
            if geometry != oldValue {
                setupGeometry()
                _updateLocalBounds = true
            }
        }
    }

    open var material: Material? {
        didSet {
            if material != oldValue {
                setupMaterial()
            }
        }
    }

    open var materials: [Material] {
        var allMaterials = [Material]()
        if let material = material {
            allMaterials.append(material)
        }
        for submesh in submeshes {
            if let material = submesh.material {
                allMaterials.append(material)
            }
        }
        return allMaterials
    }

    internal var geometrySubscriber: AnyCancellable?

    public var submeshes: [Submesh] = []

    public init(geometry: Geometry, material: Material?) {
        self.geometry = geometry
        self.material = material
        super.init()
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

    override open func update(_ commandBuffer: MTLCommandBuffer) {
        geometry.update(commandBuffer)
        material?.update(commandBuffer)
        for submesh in submeshes {
            submesh.update(commandBuffer)
        }
        super.update(commandBuffer)
    }

    override open func update(camera: Camera, viewport: simd_float4) {
        material?.update(camera: camera)
        uniforms?.update(object: self, camera: camera, viewport: viewport)
    }

    open func draw(renderEncoder: MTLRenderCommandEncoder, shadow: Bool = false) {
        draw(renderEncoder: renderEncoder, instanceCount: instanceCount, shadow: shadow)
    }

    open func bind(_ renderEncoder: MTLRenderCommandEncoder, shadow: Bool) {
        bindDrawingStates(renderEncoder, shadow: shadow)
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

    open func bindDrawingStates(_ renderEncoder: MTLRenderCommandEncoder, shadow _: Bool) {
        renderEncoder.setFrontFacing(geometry.windingOrder)
        renderEncoder.setCullMode(cullMode)
        renderEncoder.setTriangleFillMode(triangleFillMode)
    }

    open func draw(renderEncoder: MTLRenderCommandEncoder, instanceCount: Int, shadow: Bool) {
        preDraw?(renderEncoder)
        bind(renderEncoder, shadow: shadow)

        if !submeshes.isEmpty {
            for submesh in submeshes where submesh.visible {
                if let indexBuffer = submesh.indexBuffer, let material = submesh.material {
                    material.bind(renderEncoder, shadow: shadow)
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
        } else {
            bindMaterial(renderEncoder, shadow: shadow)
            if let indexBuffer = geometry.indexBuffer {
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
}
