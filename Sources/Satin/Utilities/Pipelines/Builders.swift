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
                               label _: String,
                               context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex), let fragmentProgram = library.makeFunction(name: fragment) {
        let device = library.device
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor
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
                               label _: String,
                               context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex) {
        let device = library.device
        let fragmentProgram = try library.makeFunction(name: fragment, constantValues: fragmentConstants)
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor
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
                               label _: String,
                               context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library {
        let device = library.device
        let vertexProgram = try library.makeFunction(name: vertex, constantValues: vertexConstants)
        let fragmentProgram = try library.makeFunction(name: fragment, constantValues: fragmentConstants)
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor
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
                                       label _: String,
                                       context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex), let fragmentProgram = library.makeFunction(name: fragment) {
        let device = library.device
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = context.colorPixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = context.depthPixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = context.stencilPixelFormat
        pipelineStateDescriptor.supportIndirectCommandBuffers = true
        return try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    return nil
}

public func makeRenderPipeline(library: MTLLibrary?,
                               vertex: String,
                               fragment: String,
                               label: String,
                               context: Context,
                               sourceRGBBlendFactor: MTLBlendFactor,
                               sourceAlphaBlendFactor: MTLBlendFactor,
                               destinationRGBBlendFactor: MTLBlendFactor,
                               destinationAlphaBlendFactor: MTLBlendFactor,
                               rgbBlendOperation: MTLBlendOperation,
                               alphaBlendOperation: MTLBlendOperation) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex), let fragmentProgram = library.makeFunction(name: fragment) {
        let device = library.device
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = label
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = context.colorPixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = context.depthPixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = context.stencilPixelFormat

        if let colorAttachment = pipelineStateDescriptor.colorAttachments[0] {
            colorAttachment.isBlendingEnabled = true

            colorAttachment.sourceRGBBlendFactor = sourceRGBBlendFactor
            colorAttachment.sourceAlphaBlendFactor = sourceAlphaBlendFactor
            colorAttachment.destinationRGBBlendFactor = destinationRGBBlendFactor
            colorAttachment.destinationAlphaBlendFactor = destinationAlphaBlendFactor
            colorAttachment.rgbBlendOperation = rgbBlendOperation
            colorAttachment.alphaBlendOperation = alphaBlendOperation
        }

        return try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    return nil
}

public func makeAlphaRenderPipeline(library: MTLLibrary?,
                                    vertex: String,
                                    fragment: String,
                                    label _: String,
                                    context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex), let fragmentProgram = library.makeFunction(name: fragment) {
        let device = library.device
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor
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
                                    label _: String,
                                    context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex) {
        let device = library.device
        let fragmentProgram = try library.makeFunction(name: fragment, constantValues: fragmentConstants)
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor
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
                                     label _: String,
                                     context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex) {
        let device = library.device
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = nil
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor
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
                                       label _: String,
                                       context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex), let fragmentProgram = library.makeFunction(name: fragment) {
        let device = library.device
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor
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

public func makeSubtractRenderPipeline(library: MTLLibrary?,
                                       vertex: String,
                                       fragment: String,
                                       label _: String,
                                       context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex), let fragmentProgram = library.makeFunction(name: fragment) {
        let device = library.device
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = context.colorPixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = context.depthPixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = context.stencilPixelFormat

        if let colorAttachment = pipelineStateDescriptor.colorAttachments[0] {
            colorAttachment.isBlendingEnabled = true
            colorAttachment.sourceRGBBlendFactor = .sourceAlpha
            colorAttachment.sourceAlphaBlendFactor = .sourceAlpha
            colorAttachment.destinationRGBBlendFactor = .oneMinusBlendColor
            colorAttachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
            colorAttachment.rgbBlendOperation = .reverseSubtract
            colorAttachment.alphaBlendOperation = .add
        }

        return try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    return nil
}

public func makeComputePipeline(library: MTLLibrary?,
                                kernel: String) throws -> MTLComputePipelineState?
{
    if let library = library, let kernelFunction = library.makeFunction(name: kernel) {
        let device = library.device
        return try device.makeComputePipelineState(function: kernelFunction)
    }
    return nil
}

public func compilePipelineSource(_ label: String) throws -> String? {
    guard let satinURL = getPipelinesSatinUrl(),
          let materialsURL = getPipelinesMaterialsUrl() else { return nil }

    let materialURL = materialsURL.appendingPathComponent(label)

    let includesURL = satinURL.appendingPathComponent("Includes.metal")
    let shadersURL = materialURL.appendingPathComponent("Shaders.metal")

    let compiler = MetalFileCompiler()
    do {
        var source = try compiler.parse(includesURL)
        source += try compiler.parse(shadersURL)
        return source
    } catch {
        print(error)
        return nil
    }
}
