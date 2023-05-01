//
//  ARLidarMesh.swift
//  Example
//
//  Created by Reza Ali on 4/10/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

#if os(iOS)

import ARKit
import Metal
import Satin

func ARLidarMeshVertexDescriptor() -> MTLVertexDescriptor {
    // position
    let vertexDescriptor = MTLVertexDescriptor()

    vertexDescriptor.attributes[0].format = MTLVertexFormat.float3
    vertexDescriptor.attributes[0].offset = 0
    vertexDescriptor.attributes[0].bufferIndex = 0

    vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 3
    vertexDescriptor.layouts[0].stepRate = 1
    vertexDescriptor.layouts[0].stepFunction = .perVertex

    return vertexDescriptor
}

class ARLidarMesh: Object, Renderable {
    var opaque: Bool {
        material?.blending == .disabled
    }

    var receiveShadow: Bool { false }
    var castShadow: Bool { false }

    var renderOrder = 0
    var drawable: Bool {
        if material?.pipeline != nil, uniforms != nil, vertexBuffer != nil, indexBuffer != nil {
            return true
        }
        return false
    }

    var uniforms: VertexUniformBuffer?

    var material: Material?
    var materials: [Satin.Material] {
        if let material = material {
            return [material]
        } else {
            return []
        }
    }

    var cullMode: MTLCullMode = .back
    var windingOrder: MTLWinding = .counterClockwise
    var triangleFillMode: MTLTriangleFillMode = .fill

    var indexBuffer: MTLBuffer? {
        meshAnchor?.geometry.faces.buffer ?? nil
    }

    var indexCount: Int {
        (meshAnchor?.geometry.faces.count ?? 0) * 3
    }

    var vertexBuffer: MTLBuffer? {
        meshAnchor?.geometry.vertices.buffer ?? nil
    }

    var vertexCount: Int {
        meshAnchor?.geometry.vertices.count ?? 0
    }

    var meshAnchor: ARMeshAnchor?

    init(meshAnchor: ARMeshAnchor, material: Material) {
        self.meshAnchor = meshAnchor
        self.material = material
        material.vertexDescriptor = ARLidarMeshVertexDescriptor()
        super.init("Lidar Mesh \(meshAnchor.identifier)")
    }

    override func setup() {
        setupUniforms()
        setupMaterial()
    }

    func setupMaterial() {
        guard let context = context, let material = material else { return }
        material.context = context
    }

    func setupUniforms() {
        guard let context = context else { return }
        uniforms = VertexUniformBuffer(device: context.device)
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    // MARK: - Update

    override func update(_ commandBuffer: MTLCommandBuffer) {
        if let meshAnchor = meshAnchor { localMatrix = meshAnchor.transform }
        material?.update(commandBuffer)
        super.update(commandBuffer)
    }

    override func update(camera: Camera, viewport: simd_float4) {
        super.update(camera: camera, viewport: viewport)
        material?.update(camera: camera)
        uniforms?.update(object: self, camera: camera, viewport: viewport)
    }

    // MARK: - Draw

    func draw(renderEncoder: MTLRenderCommandEncoder, shadow: Bool) {
        draw(renderEncoder: renderEncoder, instanceCount: 1, shadow: shadow)
    }

    open func draw(renderEncoder: MTLRenderCommandEncoder, instanceCount: Int, shadow: Bool) {
        guard instanceCount > 0,
              let uniforms = uniforms,
              let vertexBuffer = vertexBuffer,
              let material = material,
              let _ = material.pipeline
        else { return }

        material.bind(renderEncoder, shadow: shadow)
        renderEncoder.setFrontFacing(windingOrder)
        renderEncoder.setCullMode(cullMode)
        renderEncoder.setTriangleFillMode(triangleFillMode)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: VertexBufferIndex.Vertices.rawValue)
        renderEncoder.setVertexBuffer(uniforms.buffer, offset: uniforms.offset, index: VertexBufferIndex.VertexUniforms.rawValue)

        if let indexBuffer = indexBuffer {
            renderEncoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: indexCount,
                indexType: .uint32,
                indexBuffer: indexBuffer,
                indexBufferOffset: 0,
                instanceCount: instanceCount
            )
        } else {
            renderEncoder.drawPrimitives(
                type: .triangle,
                vertexStart: 0,
                vertexCount: vertexCount,
                instanceCount: instanceCount
            )
        }
    }
}

#endif
