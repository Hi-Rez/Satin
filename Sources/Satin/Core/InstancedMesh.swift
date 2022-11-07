//
//  InstancedMesh.swift
//  Satin
//
//  Created by Reza Ali on 10/19/22.
//

import Foundation
import Metal
import simd

public class InstancedMesh: Mesh {
    override public var instanceCount: Int {
        didSet {
            if instanceCount != oldValue {
                _setupInstanceMatrixBuffer = true
                if instanceCount > oldValue {
                    instanceMatrices.reserveCapacity(instanceCount)
                }
                else if instanceCount < oldValue {
                    instanceMatrices.removeLast(oldValue - instanceCount)
                }
            }
        }
    }

    var instanceMatrices: [InstanceMatrixUniforms]

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
        instanceMatrices = .init(repeating: InstanceMatrixUniforms(), count: count)
        super.init(geometry: geometry, material: material)
        instanceCount = count
        instanceMatrices = .init(repeating: InstanceMatrixUniforms(modelMatrix: matrix_identity_float4x4, normalMatrix: matrix_identity_float3x3), count: instanceCount)
    }

    public required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    public func setMatrixAt(index: Int, matrix: matrix_float4x4) {
        guard index < instanceCount else { return }
        instanceMatrices[index].modelMatrix = simd_mul(worldMatrix, matrix)
        let n = instanceMatrices[index].modelMatrix.inverse.transpose
        instanceMatrices[index].normalMatrix = simd_float3x3(
            simd_make_float3(n.columns.0),
            simd_make_float3(n.columns.1),
            simd_make_float3(n.columns.2))

        _updateInstanceMatrixBuffer = true
    }

    public func getMatrixAt(index: Int) -> matrix_float4x4 {
        guard index < instanceCount else { fatalError("Unable to get matrix") }
        return instanceMatrices[index].modelMatrix
    }

    func setupInstanceBuffer() {
        guard let context = context else { return }
        instanceMatrixBuffer = InstanceMatrixUniformBuffer(device: context.device, count: instanceCount)
    }

    func updateInstanceBuffer() {
        instanceMatrixBuffer?.update()
        instanceMatrixBuffer?.update(data: &instanceMatrices)
    }

    override public func setup() {
        super.setup()
        setupInstanceBuffer()
    }

    override public func update() {
        if _setupInstanceMatrixBuffer, isVisible() {
            setupInstanceBuffer()
            _setupInstanceMatrixBuffer = false
        }

        if _updateInstanceMatrixBuffer {
            updateInstanceBuffer()
            _updateInstanceMatrixBuffer = false
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
}
