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
                               context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex), let fragmentProgram = library.makeFunction(name: fragment) {
        let device = library.device
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor()
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
                               context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex) {
        let device = library.device
        let fragmentProgram = try library.makeFunction(name: fragment, constantValues: fragmentConstants)
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor()
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
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor()
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
                                       context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex), let fragmentProgram = library.makeFunction(name: fragment) {
        let device = library.device
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor()
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
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor()
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
                                    label: String,
                                    context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex), let fragmentProgram = library.makeFunction(name: fragment) {
        let device = library.device
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor()
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
                                    context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex) {
        let device = library.device
        let fragmentProgram = try library.makeFunction(name: fragment, constantValues: fragmentConstants)
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor()
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
                                     context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex) {
        let device = library.device
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = nil
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor()
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
                                       context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex), let fragmentProgram = library.makeFunction(name: fragment) {
        let device = library.device
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor()
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
                                       label: String,
                                       context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex), let fragmentProgram = library.makeFunction(name: fragment) {
        let device = library.device
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor()
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
    }
    catch {
        print(error)
        return nil
    }
}

public func injectConstants(source: inout String) {
    source = source.replacingOccurrences(of: "// inject constants\n", with: (ConstantsSource.get() ?? "\n") + "\n")
}

public func injectVertex(source: inout String) {
    source = source.replacingOccurrences(of: "// inject vertex\n", with: (VertexSource.get() ?? "\n") + "\n")
}

public func injectVertex(source: inout String, vertexDescriptor: MTLVertexDescriptor) {
    print(vertexDescriptor.description)
    source = source.replacingOccurrences(of: "// inject vertex\n", with: (VertexSource.get() ?? "\n") + "\n")
}

public func injectVertexData(source: inout String) {
    source = source.replacingOccurrences(of: "// inject vertex data\n", with: (VertexDataSource.get() ?? "\n") + "\n")
}

public func injectVertexUniforms(source: inout String) {
    source = source.replacingOccurrences(of: "// inject vertex uniforms\n", with: (VertexUniformsSource.get() ?? "\n") + "\n")
}

public func injectPassThroughVertex(label: String, source: inout String) {
    let vertexFunctionName = label.camelCase + "Vertex"
    if !source.contains(vertexFunctionName), let passThroughVertexSource = PassThroughVertexPipelineSource.get() {
        let vertexSource = passThroughVertexSource.replacingOccurrences(of: "satinVertex", with: vertexFunctionName)
        source = source.replacingOccurrences(of: "// inject vertex shader\n", with: vertexSource + "\n")
    }
    else {
        source = source.replacingOccurrences(of: "// inject vertex shader\n", with: "\n")
    }
}

public func injectPassThroughVertex(source: inout String) {
    source = source.replacingOccurrences(of: "// inject vertex shader\n", with: (PassThroughVertexPipelineSource.get() ?? "\n") + "\n")
}


class PassThroughVertexPipelineSource {
    static let shared = PassThroughVertexPipelineSource()
    private static var sharedSource: String?
    
    class func get() -> String? {
        guard PassThroughVertexPipelineSource.sharedSource == nil else {
            return sharedSource
        }
        if let vertexURL = getPipelinesCommonUrl("Vertex.metal") {
            do {
                sharedSource = try MetalFileCompiler().parse(vertexURL)
            }
            catch {
                print(error)
            }
        }
        return sharedSource
    }
}

class ConstantsSource {
    static let shared = ConstantsSource()
    private static var sharedSource: String?
    
    class func get() -> String? {
        guard ConstantsSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinUrl("Constants.metal") {
            do {
                sharedSource = try MetalFileCompiler().parse(url)
            }
            catch {
                print(error)
            }
        }
        return sharedSource
    }
}

class VertexSource {
    static let shared = VertexSource()
    private static var sharedSource: String?
    
    class func get() -> String? {
        guard VertexSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinUrl("Vertex.metal") {
            do {
                sharedSource = try MetalFileCompiler().parse(url)
            }
            catch {
                print(error)
            }
        }
        return sharedSource
    }
}

class VertexDataSource {
    static let shared = VertexDataSource()
    private static var sharedSource: String?
    
    class func get() -> String? {
        guard VertexDataSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinUrl("VertexData.metal") {
            do {
                sharedSource = try MetalFileCompiler().parse(url)
            }
            catch {
                print(error)
            }
        }
        return sharedSource
    }
}

class VertexUniformsSource {
    static let shared = VertexUniformsSource()
    private static var sharedSource: String?
    
    class func get() -> String? {
        guard VertexUniformsSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinUrl("VertexUniforms.metal") {
            do {
                sharedSource = try MetalFileCompiler().parse(url)
            }
            catch {
                print(error)
            }
        }
        return sharedSource
    }
}
