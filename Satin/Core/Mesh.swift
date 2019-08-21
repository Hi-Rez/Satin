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

open class Mesh: Object, GeometryDelegate {
    let alignedUniformsSize = ((MemoryLayout<VertexUniforms>.size + 255) / 256) * 256
    
    public var triangleFillMode: MTLTriangleFillMode = .fill
    public var cullMode: MTLCullMode = .back
    
    public var instanceCount: Int = 1
    
    var vertexUniforms: UnsafeMutablePointer<VertexUniforms>!
    var vertexUniformsBuffer: MTLBuffer!
    
    var uniformBufferIndex: Int = 0
    var uniformBufferOffset: Int = 0
    
    public var preDraw: ((_ renderEncoder: MTLRenderCommandEncoder) -> ())?
    public var postDraw: ((_ renderEncoder: MTLRenderCommandEncoder) -> ())?
    
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
    
    public var material: Material? {
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
        setup(geometry, material)
    }
    
    func setup(_ geometry: Geometry, _ material: Material) {
        self.geometry = geometry
        self.material = material
    }
    
    func updateUniforms(camera: Camera) {
        if vertexUniforms != nil {
            vertexUniforms[0].modelMatrix = worldMatrix
            vertexUniforms[0].viewMatrix = camera.viewMatrix
            vertexUniforms[0].modelViewMatrix = simd_mul(vertexUniforms[0].viewMatrix, vertexUniforms[0].modelMatrix)
            vertexUniforms[0].projectionMatrix = camera.projectionMatrix
            let n = vertexUniforms[0].modelViewMatrix.inverse.transpose
            vertexUniforms[0].normalMatrix = simd_matrix(
                simd_make_float3(n[0].x, n[0].y, n[0].z),
                simd_make_float3(n[1].x, n[1].y, n[1].z),
                simd_make_float3(n[2].x, n[2].y, n[2].z)
            )
        }
    }
    
    func updateUniformsBuffer() {
        if vertexUniformsBuffer != nil {
            uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight
            uniformBufferOffset = alignedUniformsSize * uniformBufferIndex
            vertexUniforms = UnsafeMutableRawPointer(vertexUniformsBuffer.contents() + uniformBufferOffset).bindMemory(to: VertexUniforms.self, capacity: 1)
        }
    }
    
    public override func update() {        
        if let material = self.material {
            material.update()
        }
        super.update()
    }
    
    public func update(camera: Camera) {
        updateUniforms(camera: camera)
        updateUniformsBuffer()
    }
    
    public func draw(renderEncoder: MTLRenderCommandEncoder) {
        if updateVertexBuffer {
            let device = renderEncoder.device
            
            if !geometry.vertexData.isEmpty {
                let verticesSize = geometry.vertexData.count * MemoryLayout.size(ofValue: geometry.vertexData[0])
                vertexBuffer = device.makeBuffer(bytes: geometry.vertexData, length: verticesSize, options: [])
                vertexBuffer?.label = "Vertices"
            }
            else {
                vertexBuffer = nil
            }
            updateVertexBuffer = false
        }
        
        if updateIndexBuffer {
            let device = renderEncoder.device
            
            if !geometry.indexData.isEmpty {
                let indicesSize = geometry.indexData.count * MemoryLayout.size(ofValue: geometry.indexData[0])
                indexBuffer = device.makeBuffer(bytes: geometry.indexData, length: indicesSize, options: [])
                indexBuffer?.label = "Indices"
            }
            else {
                indexBuffer = nil
            }
            
            updateIndexBuffer = false
        }
        
        if updateUniformBuffer {
            let device = renderEncoder.device
            
            let uniformBufferSize = alignedUniformsSize * Satin.maxBuffersInFlight
            guard let buffer = device.makeBuffer(length: uniformBufferSize, options: [MTLResourceOptions.storageModeShared]) else { return }
            vertexUniformsBuffer = buffer
            vertexUniformsBuffer.label = "Vertex Uniforms"
            vertexUniforms = UnsafeMutableRawPointer(vertexUniformsBuffer.contents()).bindMemory(to: VertexUniforms.self, capacity: 1)
            updateUniformBuffer = false
        }
        
        if updateMaterial {
            updateMaterial = false
        }
        
        draw(renderEncoder: renderEncoder, instanceCount: instanceCount)
    }
    
    public func draw(renderEncoder: MTLRenderCommandEncoder, instanceCount: Int) {
        guard visible, let vertexBuffer = vertexBuffer, let material = self.material else { return }
        
        preDraw?(renderEncoder)
        
        renderEncoder.setFrontFacing(geometry.windingOrder)
        renderEncoder.setCullMode(cullMode)
        renderEncoder.setTriangleFillMode(triangleFillMode)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(vertexUniformsBuffer, offset: uniformBufferOffset, index: 1)
        
        material.bind(renderEncoder)
        
        // Do uniform binds here
        
        if let indexBuffer = indexBuffer {
            renderEncoder.drawIndexedPrimitives(
                type: geometry.primitiveType,
                indexCount: geometry.indexData.count,
                indexType: geometry.indexType,
                indexBuffer: indexBuffer,
                indexBufferOffset: 0,
                instanceCount: instanceCount
            )
        }
        else {
            renderEncoder.drawPrimitives(
                type: geometry.primitiveType,
                vertexStart: 0,
                vertexCount: geometry.vertexData.count,
                instanceCount: instanceCount
            )
        }
        
        postDraw?(renderEncoder)
    }
    
    deinit {
        vertexBuffer = nil
        indexBuffer = nil
    }
    
    // MARK: - GeometryDelegate Conformance
    
    func indexDataUpdated() {
        if !geometry.indexData.isEmpty {
            updateIndexBuffer = true
        }
    }
    
    func vertexDataUpdated() {
        if !geometry.vertexData.isEmpty {
            updateVertexBuffer = true
        }
    }
}
