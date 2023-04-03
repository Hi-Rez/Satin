//
//  TessellatedMesh.swift
//  Tesselation
//
//  Created by Reza Ali on 3/31/23.
//  Copyright © 2023 Reza Ali. All rights reserved.
//

import Foundation
import Metal
import Satin

class TessellatedMesh: Object, Renderable {
    var cullMode: MTLCullMode = .back
    var windingOrder: MTLWinding = .counterClockwise
    var triangleFillMode: MTLTriangleFillMode = .fill

    var renderOrder = 0
    var receiveShadow = false
    var castShadow = false

    private var vertexUniforms: VertexUniformBuffer?

    var drawable: Bool {
        guard material?.pipeline != nil else { return false }
        return true
    }

    var material: Satin.Material? {
        didSet {
            material?.context = context
        }
    }

    var materials: [Satin.Material] {
        if let material = material {
            return [material]
        }
        return []
    }

    public required init(from _: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    var geometry: TessellatedGeometry
    var tessellator: Tessellator

    public init(geometry: TessellatedGeometry, material: Material?, tessellator: Tessellator) {
        self.geometry = geometry
        self.material = material
        self.tessellator = tessellator

        self.material?.vertexDescriptor = geometry.vertexDescriptor
        super.init("Tessellated Mesh")
    }

    override func setup() {
        setupGeometry()
        setupUniforms()
        setupMaterial()
    }

    func setupGeometry() {
        guard let context = context else { return }
        geometry.context = context
    }

    func setupMaterial() {
        guard let context = context, let material = material else { return }
        material.context = context
    }

    func setupUniforms() {
        guard let context = context else { return }
        vertexUniforms = VertexUniformBuffer(device: context.device)
    }

    // MARK: - Update

    override func update(_ commandBuffer: MTLCommandBuffer) {
        material?.update(commandBuffer)
        geometry.update(commandBuffer)
        super.update(commandBuffer)
    }

    override func update(camera: Camera, viewport: simd_float4) {
        material?.update(camera: camera)
        vertexUniforms?.update(object: self, camera: camera, viewport: viewport)
    }

    // MARK: - Draw

    open func draw(renderEncoder: MTLRenderCommandEncoder, instanceCount: Int, shadow: Bool) {
        guard instanceCount > 0, let vertexUniforms = vertexUniforms, let material = material else { return }

        material.bind(renderEncoder, shadow: shadow)
        renderEncoder.setFrontFacing(windingOrder)
        renderEncoder.setCullMode(cullMode)
        renderEncoder.setTriangleFillMode(triangleFillMode)

        renderEncoder.setVertexBuffer(
            vertexUniforms.buffer,
            offset: vertexUniforms.offset,
            index: VertexBufferIndex.VertexUniforms.rawValue
        )

        renderEncoder.setVertexBuffer(
            geometry.vertexBuffer,
            offset: 0,
            index: VertexBufferIndex.Vertices.rawValue
        )

        renderEncoder.setTessellationFactorBuffer(
            tessellator.buffer,
            offset: 0,
            instanceStride: 0
        )

        if let indexBuffer = geometry.indexBuffer {
            renderEncoder.drawIndexedPatches(
                numberOfPatchControlPoints: geometry.controlPointsPerPatch,
                patchStart: 0,
                patchCount: geometry.patchCount,
                patchIndexBuffer: nil,
                patchIndexBufferOffset: 0,
                controlPointIndexBuffer: indexBuffer,
                controlPointIndexBufferOffset: 0,
                instanceCount: instanceCount,
                baseInstance: 0
            )
        } else {
            renderEncoder.drawPatches(
                numberOfPatchControlPoints: geometry.controlPointsPerPatch,
                patchStart: 0,
                patchCount: geometry.patchCount,
                patchIndexBuffer: nil,
                patchIndexBufferOffset: 0,
                instanceCount: instanceCount,
                baseInstance: 0
            )
        }
    }

    func draw(renderEncoder: MTLRenderCommandEncoder, shadow: Bool) {
        draw(renderEncoder: renderEncoder, instanceCount: 1, shadow: shadow)
    }
}
