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

public func makeRenderPipeline(library: MTLLibrary?,
                               vertex: String,
                               fragment: String,
                               fragmentConstants: MTLFunctionConstantValues,
                               label: String,
                               context: Context) throws -> MTLRenderPipelineState? {
    if let library = library, let vertexProgram = library.makeFunction(name: vertex) {
        let device = library.device
        let fragmentProgram = try library.makeFunction(name: fragment, constantValues: fragmentConstants)
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

public func makeRenderPipeline(library: MTLLibrary?,
                               vertex: String,
                               vertexConstants: MTLFunctionConstantValues,
                               fragment: String,
                               fragmentConstants: MTLFunctionConstantValues,
                               label: String,
                               context: Context) throws -> MTLRenderPipelineState? {
    if let library = library {
        let device = library.device
        let vertexProgram = try library.makeFunction(name: vertex, constantValues: vertexConstants)
        let fragmentProgram = try library.makeFunction(name: fragment, constantValues: fragmentConstants)
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

public func makeIndirectRenderPipeline(library: MTLLibrary?,
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
        pipelineStateDescriptor.supportIndirectCommandBuffers = true
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

public func makeAlphaRenderPipeline(library: MTLLibrary?,
                                    vertex: String,
                                    fragment: String,
                                    fragmentConstants: MTLFunctionConstantValues,
                                    label: String,
                                    context: Context) throws -> MTLRenderPipelineState? {
    if let library = library, let vertexProgram = library.makeFunction(name: vertex) {
        let device = library.device
        let fragmentProgram = try library.makeFunction(name: fragment, constantValues: fragmentConstants)
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

public func makeShadowRenderPipeline(library: MTLLibrary?,
                                     vertex: String,
                                     label: String,
                                     context: Context) throws -> MTLRenderPipelineState? {
    if let library = library, let vertexProgram = library.makeFunction(name: vertex) {
        let device = library.device
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = nil
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = context.colorPixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = context.depthPixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = context.stencilPixelFormat
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

public func makeComputePipeline(library: MTLLibrary?,
                                kernel: String) throws -> MTLComputePipelineState? {
    if let library = library, let kernelFunction = library.makeFunction(name: kernel) {
        let device = library.device
        return try device.makeComputePipelineState(function: kernelFunction)
    }
    return nil
}

func makePipelineSource(_ pipelinesPath: String, _ materialName: String, _ parameters: ParameterGroup? = nil) throws -> String? {
    let pipelinesURL = URL(fileURLWithPath: pipelinesPath)
    let satinURL = pipelinesURL.appendingPathComponent("Satin")
    let includesURL = satinURL.appendingPathComponent("Includes.metal")

    let commonURL = pipelinesURL.appendingPathComponent("Common")
    let vertexURL = commonURL.appendingPathComponent("Vertex.metal")

    let materialsURL = pipelinesURL.appendingPathComponent("Materials")
    let materialURL = materialsURL.appendingPathComponent(materialName)
    let fragmentURL = materialURL.appendingPathComponent("Shaders.metal")

    let metalFileCompiler = MetalFileCompiler()
    do {
        var source = try metalFileCompiler.parse(includesURL)

        if let parameters = parameters {
            source += parameters.structString
        }
        source += try metalFileCompiler.parse(vertexURL)
        source += try metalFileCompiler.parse(fragmentURL)
        return source
    }
    catch {
        print(error)
        return nil
    }
}
