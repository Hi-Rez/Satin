//
//  InstancedMesh.swift
//  Satin
//
//  Created by Reza Ali on 10/19/22.
//

import Combine
import Foundation
import Metal
import simd

public class InstancedMesh: Mesh {
    override public var instanceCount: Int {
        didSet {
            if instanceCount != oldValue {
                _setupInstanceMatrixBuffer = true
                if instanceCount > oldValue {
                    instanceMatricesUniforms.reserveCapacity(instanceCount)
                    instanceMatrices.reserveCapacity(instanceCount)
                }
                else if instanceCount < oldValue, oldValue > 0 {
                    let delta = oldValue - instanceCount
                    instanceMatricesUniforms.removeLast(delta)
                    instanceMatrices.removeLast(delta)
                }
            }
        }
    }

    var instanceMatrices: [simd_float4x4]
    var instanceMatricesUniforms: [InstanceMatrixUniforms]

    private var transformSubscriber: AnyCancellable?
    private var _updateInstanceMatricesUniforms: Bool = true
    private var _setupInstanceMatrixBuffer: Bool = true
    private var _updateInstanceMatrixBuffer: Bool = true
    private var instanceMatrixBuffer: InstanceMatrixUniformBuffer?

    override public var material: Material? {
        didSet {
            material?.instancing = true
        }
    }

    public init(geometry: Geometry, material: Material?, count: Int) {
        material?.instancing = true

        instanceMatricesUniforms = .init(repeating: InstanceMatrixUniforms(modelMatrix: matrix_identity_float4x4, normalMatrix: matrix_identity_float3x3), count: count)

        instanceMatrices = .init(repeating: matrix_identity_float4x4, count: count)

        super.init(geometry: geometry, material: material)

        instanceCount = count

        transformSubscriber = transformPublisher.sink { [weak self] _ in
            self?._updateInstanceMatricesUniforms = true
        }
    }

    public required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    public func setMatrixAt(index: Int, matrix: matrix_float4x4) {
        guard index < instanceCount else { return }
        instanceMatrices[index] = matrix
        instanceMatricesUniforms[index].modelMatrix = simd_mul(worldMatrix, matrix)
        let n = instanceMatricesUniforms[index].modelMatrix.inverse.transpose
        instanceMatricesUniforms[index].normalMatrix = simd_float3x3(
            simd_make_float3(n.columns.0),
            simd_make_float3(n.columns.1),
            simd_make_float3(n.columns.2)
        )

        _updateInstanceMatrixBuffer = true
    }

    // MARK: - Instancing

    public func getMatrixAt(index: Int) -> matrix_float4x4 {
        guard index < instanceCount else { fatalError("Unable to get matrix at \(index)") }
        return instanceMatrices[index]
    }

    public func getWorldMatrixAt(index: Int) -> matrix_float4x4 {
        guard index < instanceCount else { fatalError("Unable to get world matrix at \(index)") }
        return instanceMatricesUniforms[index].modelMatrix
    }

    override public func setup() {
        super.setup()
        setupInstanceBuffer()
    }

    override public func update() {
        if _updateInstanceMatricesUniforms {
            updateInstanceMatricesUniforms()
        }

        if _setupInstanceMatrixBuffer {
            setupInstanceBuffer()
        }

        if _updateInstanceMatrixBuffer {
            updateInstanceBuffer()
        }

        super.update()
    }

    override open func bind(_ renderEncoder: MTLRenderCommandEncoder) {
        super.bind(renderEncoder)
        bindInstanceMatrixBuffer(renderEncoder)
    }

    func bindInstanceMatrixBuffer(_ renderEncoder: MTLRenderCommandEncoder) {
        guard let instanceMatrixBuffer = instanceMatrixBuffer else { return }
        renderEncoder.setVertexBuffer(instanceMatrixBuffer.buffer, offset: instanceMatrixBuffer.offset, index: VertexBufferIndex.InstanceMatrixUniforms.rawValue)
    }

    // MARK: - Private Instancing

    func setupInstanceBuffer() {
        guard let context = context else { return }
        instanceMatrixBuffer = InstanceMatrixUniformBuffer(device: context.device, count: instanceCount)
        _setupInstanceMatrixBuffer = false
    }

    func updateInstanceBuffer() {
        instanceMatrixBuffer?.update()
        instanceMatrixBuffer?.update(data: &instanceMatricesUniforms)
        _updateInstanceMatrixBuffer = false
    }

    func updateInstanceMatricesUniforms() {
        for i in 0 ..< instanceCount {
            instanceMatricesUniforms[i].modelMatrix = simd_mul(worldMatrix, instanceMatrices[i])
            let n = instanceMatricesUniforms[i].modelMatrix.inverse.transpose
            instanceMatricesUniforms[i].normalMatrix = simd_float3x3(
                simd_make_float3(n.columns.0),
                simd_make_float3(n.columns.1),
                simd_make_float3(n.columns.2)
            )
        }

        _updateInstanceMatricesUniforms = false
    }

    // MARK: - Intersections

    override public func intersects(ray: Ray) -> Bool {
        let geometryBounds = geometry.bounds
        for i in 0 ..< instanceCount {
            if rayBoundsIntersect(getWorldMatrixAt(index: i).inverse.act(ray), geometryBounds) {
                return true
            }
        }
        return false
    }

    override open func intersect(ray: Ray, intersections: inout [RaycastResult], recursive: Bool = true, invisible: Bool = false) {
        guard visible || invisible, intersects(ray: ray) else { return }

        var geometryIntersections = [IntersectionResult]()

        var instanceIntersections = [Int]()
        for i in 0 ..< instanceCount {
            let preCount = geometryIntersections.count
            geometry.intersect(
                ray: getWorldMatrixAt(index: i).inverse.act(ray),
                intersections: &geometryIntersections
            )
            let postCount = geometryIntersections.count

            for i in preCount ..< postCount {
                instanceIntersections.append(i)
            }
        }

        for (instance, intersection) in zip(instanceIntersections, geometryIntersections) {
            intersections.append(
                RaycastResult(
                    barycentricCoordinates: intersection.barycentricCoordinates,
                    distance: intersection.distance,
                    normal: intersection.normal,
                    position: simd_make_float3(getWorldMatrixAt(index: instance) * simd_make_float4(intersection.position, 1.0)),
                    uv: intersection.uv,
                    primitiveIndex: intersection.primitiveIndex,
                    object: self,
                    submesh: nil,
                    instance: instance
                )
            )
        }

        if recursive {
            for child in children {
                child.intersect(ray: ray, intersections: &intersections, recursive: recursive)
            }
        }
    }

    // MARK: - Deinit

    deinit {
        transformSubscriber?.cancel()
    }
}
