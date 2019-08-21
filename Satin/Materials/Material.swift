//
//  Material.swift
//  Satin
//
//  Created by Reza Ali on 7/24/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal

struct MaterialUniforms {
    var color: Float
}

open class Material {
    let alignedUniformsSize = ((MemoryLayout<MaterialUniforms>.size + 255) / 256) * 256
    
    var uniformBufferIndex: Int = 0
    var uniformBufferOffset: Int = 0
    
    var materialUniforms: UnsafeMutablePointer<MaterialUniforms>!
    var materialUniformsBuffer: MTLBuffer!
    
    var pipeline: MTLRenderPipelineState?
    
    public var onBind: ((_ renderEncoder: MTLRenderCommandEncoder) -> ())?
    
    public init(library: MTLLibrary,
                vertex: String,
                fragment: String,
                label: String,
                sampleCount: Int,
                colorPixelFormat: MTLPixelFormat,
                depthPixelFormat: MTLPixelFormat,
                stencilPixelFormat: MTLPixelFormat) {
        let device = library.device
        
        let vertexProgram = library.makeFunction(name: vertex)
        let fragmentProgram = library.makeFunction(name: fragment)
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = depthPixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = stencilPixelFormat
        
        pipeline = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
        setupBuffers(device: device)
    }
    
    func setupBuffers(device: MTLDevice) {
        let uniformBufferSize = alignedUniformsSize * maxBuffersInFlight
        guard let buffer = device.makeBuffer(length: uniformBufferSize, options: [MTLResourceOptions.storageModeShared]) else { return }
        buffer.label = "Material Uniforms"
        materialUniforms = UnsafeMutableRawPointer(buffer.contents()).bindMemory(to: MaterialUniforms.self, capacity: 1)
        materialUniformsBuffer = buffer
    }
    
    func updateUniformBufferIndex() {
        uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight
        uniformBufferOffset = alignedUniformsSize * uniformBufferIndex
    }
    
    func updateUniforms() {
        guard var uniforms = self.materialUniforms, let uniformBuffer = self.materialUniformsBuffer else { return }
        uniforms[0].color = 0.0
        uniforms = UnsafeMutableRawPointer(uniformBuffer.contents() + uniformBufferOffset).bindMemory(to: MaterialUniforms.self, capacity: 1)
    }
    
    open func update() {
        updateUniformBufferIndex()
        updateUniforms()
    }
    
    open func bind(_ renderEncoder: MTLRenderCommandEncoder) {
        guard let pipeline = self.pipeline, let uniformBuffer = self.materialUniformsBuffer else { return }
        renderEncoder.setRenderPipelineState(pipeline)
        renderEncoder.setFragmentBuffer(uniformBuffer, offset: uniformBufferOffset, index: 0)
        
        onBind?(renderEncoder)
    }
    
    deinit {}
}
