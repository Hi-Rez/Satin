//
//  Pipelines.swift
//  Satin
//
//  Created by Reza Ali on 9/15/19.
//

import Metal

public func makeRenderPipeline(library: MTLLibrary?,
                               vertex: String,
                               fragment: String,
                               label: String,
                               context: Context) throws -> MTLRenderPipelineState? {
    if let library = library, let vertexProgram = library.makeFunction(name: vertex), let fragmentProgram = library.makeFunction(name: fragment) {
        let device = library.device
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = context.colorPixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = context.depthPixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = context.stencilPixelFormat
        return try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    return nil
}

public func makeAlphaRenderPipeline(library: MTLLibrary?,
                               vertex: String,
                               fragment: String,
                               label: String,
                               context: Context) throws -> MTLRenderPipelineState? {
    if let library = library, let vertexProgram = library.makeFunction(name: vertex), let fragmentProgram = library.makeFunction(name: fragment) {
        let device = library.device
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = context.colorPixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = context.depthPixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = context.stencilPixelFormat
        
        if let colorAttachment = pipelineStateDescriptor.colorAttachments[0] {
            colorAttachment.isBlendingEnabled = true
            colorAttachment.rgbBlendOperation = .add
            colorAttachment.alphaBlendOperation = .add
            colorAttachment.sourceRGBBlendFactor = .sourceAlpha
            colorAttachment.sourceAlphaBlendFactor = .sourceAlpha
            colorAttachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
            colorAttachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        }
        
        return try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    return nil
}


public func makeAdditiveRenderPipeline(library: MTLLibrary?,
                               vertex: String,
                               fragment: String,
                               label: String,
                               context: Context) throws -> MTLRenderPipelineState? {
    if let library = library, let vertexProgram = library.makeFunction(name: vertex), let fragmentProgram = library.makeFunction(name: fragment) {
        let device = library.device
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = context.colorPixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = context.depthPixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = context.stencilPixelFormat
        
        if let colorAttachment = pipelineStateDescriptor.colorAttachments[0] {
            colorAttachment.isBlendingEnabled = true
            colorAttachment.rgbBlendOperation = .add
            colorAttachment.alphaBlendOperation = .add
            colorAttachment.sourceRGBBlendFactor = .sourceAlpha
            colorAttachment.sourceAlphaBlendFactor = .one
            colorAttachment.destinationRGBBlendFactor = .one
            colorAttachment.destinationAlphaBlendFactor = .one
        }
        
        return try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    return nil
}
