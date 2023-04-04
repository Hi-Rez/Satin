//
//  VertexDescriptor.swift
//  Satin
//
//  Created by Reza Ali on 5/25/20.
//

import Metal
import ModelIO

public func SatinVertexDescriptor() -> MTLVertexDescriptor {
    // position
    let vertexDescriptor = MTLVertexDescriptor()

    vertexDescriptor.attributes[VertexAttribute.Position.rawValue].format = MTLVertexFormat.float4
    vertexDescriptor.attributes[VertexAttribute.Position.rawValue].offset = 0
    vertexDescriptor.attributes[VertexAttribute.Position.rawValue].bufferIndex = 0

    // normal
    vertexDescriptor.attributes[VertexAttribute.Normal.rawValue].format = MTLVertexFormat.float3
    vertexDescriptor.attributes[VertexAttribute.Normal.rawValue].offset = MemoryLayout<Float>.size * 4
    vertexDescriptor.attributes[VertexAttribute.Normal.rawValue].bufferIndex = 0

    // uv
    vertexDescriptor.attributes[VertexAttribute.Texcoord.rawValue].format = MTLVertexFormat.float2
    vertexDescriptor.attributes[VertexAttribute.Texcoord.rawValue].offset = MemoryLayout<Float>.size * 8
    vertexDescriptor.attributes[VertexAttribute.Texcoord.rawValue].bufferIndex = 0

    vertexDescriptor.layouts[VertexBufferIndex.Vertices.rawValue].stride = MemoryLayout<Vertex>.stride
    vertexDescriptor.layouts[VertexBufferIndex.Vertices.rawValue].stepRate = 1
    vertexDescriptor.layouts[VertexBufferIndex.Vertices.rawValue].stepFunction = .perVertex

    return vertexDescriptor
}

public func SatinModelIOVertexDescriptor() -> MDLVertexDescriptor {
    let descriptor = MDLVertexDescriptor()

    var offset = 0
    descriptor.attributes[VertexAttribute.Position.rawValue] = MDLVertexAttribute(
        name: MDLVertexAttributePosition,
        format: .float4,
        offset: offset,
        bufferIndex: 0
    )
    offset += MemoryLayout<Float>.size * 4

    descriptor.attributes[VertexAttribute.Normal.rawValue] = MDLVertexAttribute(
        name: MDLVertexAttributeNormal,
        format: .float3,
        offset: offset,
        bufferIndex: 0
    )
    offset += MemoryLayout<Float>.size * 4

    descriptor.attributes[VertexAttribute.Texcoord.rawValue] = MDLVertexAttribute(
        name: MDLVertexAttributeTextureCoordinate,
        format: .float2,
        offset: offset,
        bufferIndex: 0
    )

    descriptor.layouts[VertexBufferIndex.Vertices.rawValue] = MDLVertexBufferLayout(stride: MemoryLayout<Vertex>.stride)

    return descriptor
}
