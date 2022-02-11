//
//  Shader.swift
//  Satin
//
//  Created by Reza Ali on 1/26/22.
//

import Foundation
import Metal

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
    
    var pipelineOptions: MTLPipelineOption {
        [.argumentInfo, .bufferTypeInfo]
    }

    public var pipelineReflection: MTLRenderPipelineReflection?
    public var pipeline: MTLRenderPipelineState?
    public var library: MTLLibrary?
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
    
    public var vertexDescriptor: MTLVertexDescriptor = SatinVertexDescriptor() {
        didSet {
            if oldValue != vertexDescriptor {
                pipelineNeedsUpdate = true
            }
        }
    }
    
    var context: Context? {
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
    
    var parameters = ParameterGroup() {
        didSet {
            for delegate in delegates {
                delegate?.updatedParameters(shader: self)
            }
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
        delegate = nil
        pipelineReflection = nil
        delegates = []
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
        guard let reflection = pipelineReflection else { return }
        
        if let fragmentArgs = reflection.fragmentArguments {
            let args = fragmentArgs[FragmentBufferIndex.MaterialUniforms.rawValue]
            let params = ParameterGroup(label.titleCase + " Uniforms")
            if let buffer = args.bufferStructType {
                for member in buffer.members {
                    let name = member.name.titleCase
                    switch member.dataType {
                    case .float:
                        params.append(FloatParameter(name))
                    case .float2:
                        params.append(Float2Parameter(name))
                    case .float3:
                        params.append(Float3Parameter(name))
                    case .float4:
                        params.append(Float4Parameter(name))
                    case .int:
                        params.append(IntParameter(name))
                    case .int2:
                        params.append(Int2Parameter(name))
                    case .int3:
                        params.append(Int3Parameter(name))
                    case .int4:
                        params.append(Int4Parameter(name))
                    case .bool:
                        params.append(BoolParameter(name))
                    default:
                        break
                    }
                }
            }
            
            parameters = params            
            parametersNeedsUpdate = false
        }
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
        
        clone.delegates = delegates
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
