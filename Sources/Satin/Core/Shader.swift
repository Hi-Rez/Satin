//
//  Shader.swift
//  Satin
//
//  Created by Reza Ali on 1/26/22.
//

import Foundation
import Metal
import Combine

open class Shader {
    var pipelineOptions: MTLPipelineOption {
        [.argumentInfo, .bufferTypeInfo]
    }

    public internal(set) var pipelineReflection: MTLRenderPipelineReflection?
    public internal(set) var pipeline: MTLRenderPipelineState?
    public internal(set) var library: MTLLibrary?
    var libraryURL: URL?

    public var blending: Blending = .alpha {
        didSet {
            if oldValue != blending {
                blendingNeedsUpdate = true
            }
        }
    }
    
    public var sourceRGBBlendFactor: MTLBlendFactor = .sourceAlpha {
        didSet {
            if oldValue != sourceRGBBlendFactor {
                blendingNeedsUpdate = true
            }
        }
    }

    public var sourceAlphaBlendFactor: MTLBlendFactor = .sourceAlpha {
        didSet {
            if oldValue != sourceAlphaBlendFactor {
                blendingNeedsUpdate = true
            }
        }
    }

    public var destinationRGBBlendFactor: MTLBlendFactor = .oneMinusSourceAlpha {
        didSet {
            if oldValue != destinationRGBBlendFactor {
                blendingNeedsUpdate = true
            }
        }
    }

    public var destinationAlphaBlendFactor: MTLBlendFactor = .oneMinusSourceAlpha {
        didSet {
            if oldValue != destinationAlphaBlendFactor {
                blendingNeedsUpdate = true
            }
        }
    }

    public var rgbBlendOperation: MTLBlendOperation = .add {
        didSet {
            if oldValue != rgbBlendOperation {
                blendingNeedsUpdate = true
            }
        }
    }

    public var alphaBlendOperation: MTLBlendOperation = .add {
        didSet {
            if oldValue != alphaBlendOperation {
                blendingNeedsUpdate = true
            }
        }
    }
    
    public var instancing: Bool = false
    
    public var vertexDescriptor: MTLVertexDescriptor = SatinVertexDescriptor {
        didSet {
            if oldValue != vertexDescriptor {
                pipelineNeedsUpdate = true
            }
        }
    }
    
    weak var context: Context? {
        didSet {
            if oldValue != context {
                setup()
            }
        }
    }
   
    var label: String = "Shader"
    
    var libraryNeedsUpdate: Bool = true {
        didSet {
            if libraryNeedsUpdate {
                pipelineNeedsUpdate = true
            }
        }
    }
    
    var pipelineNeedsUpdate: Bool = true {
        didSet {
            if pipelineNeedsUpdate {
                parametersNeedsUpdate = true
            }
        }
    }
    
    var blendingNeedsUpdate: Bool = true
    var parametersNeedsUpdate: Bool = true
    
    public var vertexFunctionName: String = "shaderVertex" {
        didSet {
            if oldValue != vertexFunctionName {
                pipelineNeedsUpdate = true
            }
        }
    }
    
    public var fragmentFunctionName: String = "shaderFragment" {
        didSet {
            if oldValue != fragmentFunctionName {
                pipelineNeedsUpdate = true
            }
        }
    }
    
    public let parametersPublisher = PassthroughSubject<ParameterGroup, Never>()
    
    public var parameters = ParameterGroup() {
        didSet {
            parametersPublisher.send(parameters)
        }
    }
    
    public required init() {}
    
    public init(_ label: String, _ vertexFunctionName: String? = nil, _ fragmentFunctionName: String? = nil, _ libraryURL: URL? = nil) {
        self.label = label
        self.vertexFunctionName = vertexFunctionName ?? label.camelCase + "Vertex"
        self.fragmentFunctionName = fragmentFunctionName ?? label.camelCase + "Fragment"
        self.libraryURL = libraryURL
    }
    
    func setup() {
        setupLibrary()
        setupPipeline()
        setupParameters()
    }
    
    func update() {
        updateLibrary()
        updatePipeline()
        updateParameters()
    }
        
    func updateLibrary() {
        if libraryNeedsUpdate {
            setupLibrary()
        }
    }
    
    func updatePipeline() {
        if pipelineNeedsUpdate || blendingNeedsUpdate {
            setupPipeline()
        }
    }
    
    func updateParameters() {
        if parametersNeedsUpdate {
            setupParameters()
        }
    }
        
    deinit {
        pipeline = nil
        library = nil
        pipelineReflection = nil
    }

    func setupPipeline() {
        guard let context = context, let library = library else { return }
        do {
            guard let vertexProgram = library.makeFunction(name: vertexFunctionName), let fragmentProgram = library.makeFunction(name: fragmentFunctionName) else { return }
            
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
            
            pipeline = try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor, options: pipelineOptions, reflection: &pipelineReflection)
            
            blendingNeedsUpdate = false
            pipelineNeedsUpdate = false
        }
        catch {
            print("\(label) Shader: \(error.localizedDescription)")
        }
    }
    
    func setupParameters() {
        guard let reflection = pipelineReflection, let fragmentArgs = reflection.fragmentArguments else { return }
        let args = fragmentArgs[FragmentBufferIndex.MaterialUniforms.rawValue]
        if let bufferStruct = args.bufferStructType {
            let newParameters = parseParameters(bufferStruct: bufferStruct)
            newParameters.label = label.titleCase + " Uniforms"
            parameters = newParameters
        }
        parametersNeedsUpdate = false
    }
    
    func setupLibrary() {
        guard let context = context else { return }
        do {
            var library: MTLLibrary?
            if let url = libraryURL {
                library = try context.device.makeLibrary(URL: url)
            }
            else {
                library = try context.device.makeDefaultLibrary(bundle: Bundle.main)
            }
            
            self.library = library
            
            libraryNeedsUpdate = false
        }
        catch {
            print("\(label) Shader: \(error.localizedDescription)")
        }
    }
    
    public func clone() -> Shader {
        let clone: Shader = type(of: self).init()
        
        clone.label = label
        clone.libraryURL = libraryURL
        clone.library = library
        clone.pipeline = pipeline
        clone.pipelineReflection = pipelineReflection
        
        clone.parameters = parameters.clone()
        
        clone.blending = blending
        clone.sourceRGBBlendFactor = sourceRGBBlendFactor
        clone.sourceAlphaBlendFactor = sourceAlphaBlendFactor
        clone.destinationRGBBlendFactor = destinationRGBBlendFactor
        clone.destinationAlphaBlendFactor = destinationAlphaBlendFactor
        clone.rgbBlendOperation = rgbBlendOperation
        clone.alphaBlendOperation = alphaBlendOperation
        
        clone.context = context
        
        return clone
    }
}

extension Shader: Equatable {
    public static func == (lhs: Shader, rhs: Shader) -> Bool {
        return lhs === rhs
    }
}
