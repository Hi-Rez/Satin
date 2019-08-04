//
//  Mesh.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal
import simd

// The 256 byte aligned size of our uniform structure

struct VertexUniforms {
    var modelMatrix: matrix_float4x4
    var viewMatrix: matrix_float4x4
    var modelViewMatrix: matrix_float4x4
    var projectionMatrix: matrix_float4x4
    var normalMatrix: matrix_float3x3
}

let alignedUniformsSize = ((MemoryLayout<VertexUniforms>.size + 255) / 256) * 256


open class Mesh: Object, GeometryDelegate {
    public var triangleFillMode: MTLTriangleFillMode = .fill
    public var cullMode: MTLCullMode = .back
    
    var vertexUniforms: UnsafeMutablePointer<VertexUniforms>!
    var vertexUniformsBuffer: MTLBuffer!
    
    var uniformBufferIndex: Int = 0
    var uniformBufferOffset: Int = 0
    
    public var geometry: Geometry = Geometry() {
        didSet {
            geometry.delegate = self
            if !geometry.vertexData.isEmpty {
                updateVertexBuffer = true
            }
            if !geometry.indexData.isEmpty {
                updateIndexBuffer = true
            }
        }
    }
    
    public var material: Material = Material() {
        didSet {
            updateMaterial = true
        }
    }
    
    public var visible: Bool = true
    
    public var uniformBuffer: MTLBuffer?
    public var vertexBuffer: MTLBuffer?
    public var indexBuffer: MTLBuffer?
    
    var updateVertexBuffer: Bool = true
    var updateIndexBuffer: Bool = true
    var updateUniformBuffer: Bool = true
    var updateMaterial: Bool = false
    
    public init(geometry: Geometry, material: Material) {
        super.init()
        print("Setup Mesh")
        setup(geometry, material)
    }
    
    func setup(_ geometry: Geometry, _ material: Material) {
        self.geometry = geometry
        self.material = material
    }
    
    func updateUniforms()
    {
        if vertexUniforms != nil {
            vertexUniforms[0].modelMatrix = matrix_identity_float4x4
            vertexUniforms[0].viewMatrix = matrix_identity_float4x4
            vertexUniforms[0].modelViewMatrix = matrix_identity_float4x4
            vertexUniforms[0].projectionMatrix = matrix_identity_float4x4
            vertexUniforms[0].normalMatrix = matrix_identity_float3x3
        }
    }
    
    func updateUniformsBuffer()
    {
        if vertexUniformsBuffer != nil {
            uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight
            uniformBufferOffset = alignedUniformsSize * uniformBufferIndex
            vertexUniforms = UnsafeMutableRawPointer(vertexUniformsBuffer.contents() + uniformBufferOffset).bindMemory(to: VertexUniforms.self, capacity: 1)
        }
    }
    
    public func update(camera: Camera) {
        updateUniformsBuffer()
        updateUniforms()
    }
    
    public func draw(renderEncoder: MTLRenderCommandEncoder) {
        if updateVertexBuffer {
            print("updateVertexBuffer")
            let device = renderEncoder.device
            
            if !geometry.vertexData.isEmpty {
                let verticesSize = geometry.vertexData.count * MemoryLayout.size(ofValue: geometry.vertexData[0])
                vertexBuffer = device.makeBuffer(bytes: geometry.vertexData, length: verticesSize, options: [])
            }
            else {
                vertexBuffer = nil
            }
            updateVertexBuffer = false
        }
        
        if updateIndexBuffer {
            print("updateIndexBuffer")
            let device = renderEncoder.device
            
            if !geometry.indexData.isEmpty {
                let indicesSize = geometry.indexData.count * MemoryLayout.size(ofValue: geometry.indexData[0])
                indexBuffer = device.makeBuffer(bytes: geometry.indexData, length: indicesSize, options: [])
            }
            else {
                indexBuffer = nil
            }
            
            updateIndexBuffer = false
        }
        
        if updateUniformBuffer {
            print("updateUniformBuffer")
            let device = renderEncoder.device
            
            let uniformBufferSize = alignedUniformsSize * Satin.maxBuffersInFlight
            guard let buffer = device.makeBuffer(length: uniformBufferSize, options: [MTLResourceOptions.storageModeShared]) else { return }
            vertexUniformsBuffer = buffer
            vertexUniformsBuffer.label = "VertexUniforms"
            vertexUniforms = UnsafeMutableRawPointer(vertexUniformsBuffer.contents()).bindMemory(to: VertexUniforms.self, capacity: 1)
            updateUniformBuffer = false
        }
        
        if updateMaterial {
            print("updateMaterial")
            updateMaterial = false
        }
        
        draw(renderEncoder: renderEncoder, instanceCount: 1)
    }
    
    public func draw(renderEncoder: MTLRenderCommandEncoder, instanceCount: Int) {
        guard visible, let vertexBuffer = vertexBuffer else { return }
        
        renderEncoder.setFrontFacing(geometry.windingOrder)
        renderEncoder.setCullMode(cullMode)
        renderEncoder.setTriangleFillMode(triangleFillMode)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(vertexUniformsBuffer, offset:uniformBufferOffset, index:1)
        
        // Do material binds here
        
        // Do uniform binds here
        
        if let indexBuffer = indexBuffer {
            renderEncoder.drawIndexedPrimitives(type: geometry.primitiveType, indexCount: geometry.indexData.count, indexType: geometry.indexType, indexBuffer: indexBuffer, indexBufferOffset: 0)
        }
        else {
            renderEncoder.drawPrimitives(type: geometry.primitiveType, vertexStart: 0, vertexCount: geometry.vertexData.count)
        }
    }
    
    deinit {
        print("Destroy Mesh")
        vertexBuffer = nil
        indexBuffer = nil
    }
    
    // MARK: - GeometryDelegate Conformance
    
    func indexDataUpdated() {
        if !geometry.indexData.isEmpty {
            print("Index Data Updated")
            updateIndexBuffer = true
        }
    }
    
    func vertexDataUpdated() {
        if !geometry.vertexData.isEmpty {
            print("Vertex Data Updated")
            updateVertexBuffer = true
        }
    }
}
