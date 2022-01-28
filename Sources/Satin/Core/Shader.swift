//
//  Shader.swift
//  Satin
//
//  Created by Reza Ali on 1/26/22.
//

import Foundation

public protocol ShaderDelegate: AnyObject {
    func updatedParameters(shader: Shader)
}

open class Shader {
    var delegates: [Material?] = []
    public weak var delegate: ShaderDelegate? {
        didSet {
            delegates.append(delegate as? Material)            
        }
    }
    
    public var pipelineURL: URL {
        didSet {
            if oldValue != pipelineURL {
                _update = true
            }
        }
    }
    
    public var pipelineReflection: MTLRenderPipelineReflection?
    
    public var pipelineOptions: MTLPipelineOption {
        MTLPipelineOption()
    }
    
    public var pipeline: MTLRenderPipelineState? {
        if _updatePipeline {
            updatePipeline()
        }
        return _pipeline
    }
    
    public var library: MTLLibrary? {
        if _updateLibrary {
            updateLibrary()
        }
        return _library
    }
    
    public var source: String? {
        if _updateSource {
            updateSource()
        }
        return _source
    }
    
    public var blending: Blending = .alpha {
        didSet {
            if oldValue != blending {
                _updatePipeline = true
            }
        }
    }
    
    public var sourceRGBBlendFactor: MTLBlendFactor = .sourceAlpha {
        didSet {
            if oldValue != sourceRGBBlendFactor {
                _updatePipeline = true
            }
        }
    }

    public var sourceAlphaBlendFactor: MTLBlendFactor = .sourceAlpha {
        didSet {
            if oldValue != sourceAlphaBlendFactor {
                _updatePipeline = true
            }
        }
    }

    public var destinationRGBBlendFactor: MTLBlendFactor = .oneMinusSourceAlpha {
        didSet {
            if oldValue != destinationRGBBlendFactor {
                _updatePipeline = true
            }
        }
    }

    public var destinationAlphaBlendFactor: MTLBlendFactor = .oneMinusSourceAlpha {
        didSet {
            if oldValue != destinationAlphaBlendFactor {
                _updatePipeline = true
            }
        }
    }

    public var rgbBlendOperation: MTLBlendOperation = .add {
        didSet {
            if oldValue != rgbBlendOperation {
                _updatePipeline = true
            }
        }
    }

    public var alphaBlendOperation: MTLBlendOperation = .add {
        didSet {
            if oldValue != alphaBlendOperation {
                _updatePipeline = true
            }
        }
    }
    
    public var vertexDescriptor: MTLVertexDescriptor = SatinVertexDescriptor() {
        didSet {
            if oldValue != vertexDescriptor {
                _updatePipeline = true
            }
        }
    }
    
    var context: Context? {
        didSet {
            if oldValue != context {
                _updatePipeline = true
            }
        }
    }
    
    var _pipeline: MTLRenderPipelineState?
    var _library: MTLLibrary?
    var _source: String?
    
    var _update: Bool = false {
        didSet {
            if _update {
                _updateSource = true
                _updateLibrary = true
                _updatePipeline = true
                _update = false 
            }
        }
    }
    var _updatePipeline: Bool = true
    var _updateLibrary: Bool = true
    var _updateSource: Bool = true
    
    func updatePipeline() {
        _pipeline = setupPipeline()
        _updatePipeline = false
    }
    
    func updateLibrary() {
        _library = setupLibrary()
        _updateLibrary = false
    }
    
    func updateSource() {
        _source = setupSource()
        _updateSource = false
    }
    
    var label: String
    
    var vertexFunctionName: String {
        didSet {
            _updatePipeline = true
        }
    }
    
    var fragmentFunctionName: String {
        didSet {
            _updatePipeline = true
        }
    }
    
    var parameters = ParameterGroup()
    
    public init(_ label: String, _ pipelineURL: URL) {
        self.label = label
        self.pipelineURL = pipelineURL
        self.vertexFunctionName = label.camelCase + "Vertex"
        self.fragmentFunctionName = label.camelCase + "Fragment"
        updateSource()
    }
    
    deinit {
        _source = nil
        _pipeline = nil
        _library = nil
        delegate = nil
        pipelineReflection = nil
        delegates = []
    }
    
    func setupParameters(_ source: String) {
        guard let params = parseParameters(source: source, key: label + "Uniforms") else { return }
        params.label = label.titleCase
        parameters = params
        for delegate in delegates {
            delegate?.updatedParameters(shader: self)
        }
    }

    func setupPipeline() -> MTLRenderPipelineState? {
        guard let context = context, let library = library else { return nil }
        do {
            guard let vertexProgram = library.makeFunction(name: vertexFunctionName), let fragmentProgram = library.makeFunction(name: fragmentFunctionName) else { return nil }
            
            let device = library.device
            let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
            pipelineStateDescriptor.label = label
            pipelineStateDescriptor.vertexFunction = vertexProgram
            pipelineStateDescriptor.fragmentFunction = fragmentProgram
            pipelineStateDescriptor.sampleCount = context.sampleCount
            pipelineStateDescriptor.vertexDescriptor = vertexDescriptor
            pipelineStateDescriptor.colorAttachments[0].pixelFormat = context.colorPixelFormat
            pipelineStateDescriptor.depthAttachmentPixelFormat = context.depthPixelFormat
            pipelineStateDescriptor.stencilAttachmentPixelFormat = context.stencilPixelFormat
            
            if blending != .disabled, let colorAttachment = pipelineStateDescriptor.colorAttachments[0] {
                colorAttachment.isBlendingEnabled = true
                colorAttachment.sourceRGBBlendFactor = sourceRGBBlendFactor
                colorAttachment.sourceAlphaBlendFactor = sourceAlphaBlendFactor
                colorAttachment.destinationRGBBlendFactor = destinationRGBBlendFactor
                colorAttachment.destinationAlphaBlendFactor = destinationAlphaBlendFactor
                colorAttachment.rgbBlendOperation = rgbBlendOperation
                colorAttachment.alphaBlendOperation = alphaBlendOperation
            }
            
            return try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor, options: pipelineOptions, reflection: &pipelineReflection)
        }
        catch {
            print(error)
        }
        return nil
    }
    
    func setupLibrary() -> MTLLibrary? {
        guard let context = context, let source = source else { return nil }
        do {
            return try context.device.makeLibrary(source: source, options: nil)
        }
        catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    func setupShaderSource() -> String? {
        do {
            return try MetalFileCompiler().parse(pipelineURL)
        }
        catch
        {
            print(error.localizedDescription)
        }
        return nil
    }
    
    func setupSource() -> String? {
        guard let satinURL = getPipelinesSatinUrl(), let shaderSource = setupShaderSource() else { return nil }
        let includesURL = satinURL.appendingPathComponent("Includes.metal")
        do {
            let compiler = MetalFileCompiler()
            var source = try compiler.parse(includesURL)
            injectConstants(source: &source)
            injectVertex(source: &source)
            injectVertexData(source: &source)
            injectVertexUniforms(source: &source)
            setupParameters(shaderSource)
            source += shaderSource
            injectPassThroughVertex(label: label, source: &source)
            return source
        }
        catch {
            print("\(label) Shader: \(error.localizedDescription)")
        }
        return nil
    }
}


extension Shader: Equatable {
    public static func == (lhs: Shader, rhs: Shader) -> Bool {
        return lhs === rhs
    }
}

