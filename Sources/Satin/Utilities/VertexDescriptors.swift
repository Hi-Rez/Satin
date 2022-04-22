//
//  VertexDescriptor.swift
//  Satin
//
//  Created by Reza Ali on 5/25/20.
//

import Metal
import ModelIO

func createSatinVertexDescriptor() -> MTLVertexDescriptor {
    // position
    let vertexDescriptor = MTLVertexDescriptor()
    
    vertexDescriptor.attributes[0].format = MTLVertexFormat.float4
    vertexDescriptor.attributes[0].offset = 0
    vertexDescriptor.attributes[0].bufferIndex = 0
    
    // normal
    vertexDescriptor.attributes[1].format = MTLVertexFormat.float3
    vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 4
    vertexDescriptor.attributes[1].bufferIndex = 0
    
    // uv
    vertexDescriptor.attributes[2].format = MTLVertexFormat.float2
    vertexDescriptor.attributes[2].offset = MemoryLayout<Float>.size * 8
    vertexDescriptor.attributes[2].bufferIndex = 0
    
    vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
    vertexDescriptor.layouts[0].stepRate = 1
    vertexDescriptor.layouts[0].stepFunction = .perVertex
    
    return vertexDescriptor
}

public let SatinVertexDescriptor = createSatinVertexDescriptor()

func createSatinModelIOVertexDescriptor() -> MDLVertexDescriptor {
    let descriptor = MDLVertexDescriptor()
    
    var offset = 0
    descriptor.attributes[0] = MDLVertexAttribute(
        name: MDLVertexAttributePosition,
        format: .float4,
        offset: offset,
        bufferIndex: 0
    )
    offset += MemoryLayout<Float>.size * 4
    
    descriptor.attributes[1] = MDLVertexAttribute(
        name: MDLVertexAttributeNormal,
        format: .float3,
        offset: offset,
        bufferIndex: 0
    )
    offset += MemoryLayout<Float>.size * 4
    
    descriptor.attributes[2] = MDLVertexAttribute(
        name: MDLVertexAttributeTextureCoordinate,
        format: .float2,
        offset: offset,
        bufferIndex: 0
    )
    
    descriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Vertex>.stride)
    
//    descriptor.layouts[0].stride =
//    descriptor.layouts[0].stepRate = 0
//    descriptor.layouts[0].stepFunction = .perVertex
    
    return descriptor
}

public let SatinModelIOVertexDescriptor = createSatinModelIOVertexDescriptor()
