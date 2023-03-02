//
//  Shader.swift
//  Satin
//
//  Created by Reza Ali on 1/26/22.
//

import Combine
import Foundation
import Metal

open class Shader {
    var pipelineOptions: MTLPipelineOption {
        [.argumentInfo, .bufferTypeInfo]
    }

    public internal(set) var pipelineReflection: MTLRenderPipelineReflection?
    public internal(set) var pipeline: MTLRenderPipelineState?
    public internal(set) var error: Error?

    public internal(set) var shadowPipelineReflection: MTLRenderPipelineReflection?
    public internal(set) var shadowPipeline: MTLRenderPipelineState?
    public internal(set) var shadowError: Error?

    public internal(set) var library: MTLLibrary?
    var libraryURL: URL?

    public var blending: Blending = .alpha {
        didSet {
            if oldValue != blending {
                pipelineNeedsUpdate = true
            }
        }
    }

    public var sourceRGBBlendFactor: MTLBlendFactor = .sourceAlpha {
        didSet {
            if oldValue != sourceRGBBlendFactor {
                pipelineNeedsUpdate = true
            }
        }
    }

    public var sourceAlphaBlendFactor: MTLBlendFactor = .sourceAlpha {
        didSet {
            if oldValue != sourceAlphaBlendFactor {
                pipelineNeedsUpdate = true
            }
        }
    }

    public var destinationRGBBlendFactor: MTLBlendFactor = .oneMinusSourceAlpha {
        didSet {
            if oldValue != destinationRGBBlendFactor {
                pipelineNeedsUpdate = true
            }
        }
    }

    public var destinationAlphaBlendFactor: MTLBlendFactor = .oneMinusSourceAlpha {
        didSet {
            if oldValue != destinationAlphaBlendFactor {
                pipelineNeedsUpdate = true
            }
        }
    }

    public var rgbBlendOperation: MTLBlendOperation = .add {
        didSet {
            if oldValue != rgbBlendOperation {
                pipelineNeedsUpdate = true
            }
        }
    }

    public var alphaBlendOperation: MTLBlendOperation = .add {
        didSet {
            if oldValue != alphaBlendOperation {
                pipelineNeedsUpdate = true
            }
        }
    }

    public var instancing = false

    public var lighting = false

    public var maxLights: Int = -1

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

    var label = "Shader"

    var libraryNeedsUpdate = true {
        didSet {
            if libraryNeedsUpdate {
                pipelineNeedsUpdate = true
            }
        }
    }

    var pipelineNeedsUpdate = true {
        didSet {
            if pipelineNeedsUpdate {
                parametersNeedsUpdate = true
            }
        }
    }

    var parametersNeedsUpdate = true

    public var vertexFunctionName = "shaderVertex" {
        didSet {
            if oldValue != vertexFunctionName {
                pipelineNeedsUpdate = true
            }
        }
    }

    public var fragmentFunctionName = "shaderFragment" {
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
        if pipelineNeedsUpdate {
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
        guard let context = context,
              let library = library,
              let vertexFunction = library.makeFunction(name: vertexFunctionName),
              let fragmentFunction = library.makeFunction(name: fragmentFunctionName) else { return }

        createPipeline(context, vertexFunction, fragmentFunction)
        createShadowPipeline(context, vertexFunction)

        pipelineNeedsUpdate = false
    }

    func createPipeline(_ context: Context, _ vertexFunction: MTLFunction, _ fragmentFunction: MTLFunction) {
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = label
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
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

        do {
            pipeline = try context.device.makeRenderPipelineState(
                descriptor: pipelineStateDescriptor,
                options: pipelineOptions,
                reflection: &pipelineReflection
            )
            error = nil
        } catch {
            self.error = error
            print("\(label) Shader: \(error.localizedDescription)")
            pipeline = nil
        }
    }

    func createShadowPipeline(_ context: Context, _ vertexFunction: MTLFunction) {
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = label + " Shadow"
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = nil
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = vertexDescriptor
        pipelineStateDescriptor.depthAttachmentPixelFormat = context.depthPixelFormat

        do {
            shadowPipeline = try context.device.makeRenderPipelineState(
                descriptor: pipelineStateDescriptor,
                options: pipelineOptions,
                reflection: &shadowPipelineReflection
            )
            shadowError = nil
        } catch {
            shadowError = error
            print("\(label) Shadow Shader: \(error.localizedDescription)")
            shadowPipeline = nil
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
            } else {
                library = try context.device.makeDefaultLibrary(bundle: Bundle.main)
            }

            self.library = library
            error = nil
        } catch {
            self.error = error
            print("\(label) Shader: \(error.localizedDescription)")
            library = nil
            pipeline = nil
        }
        libraryNeedsUpdate = false
    }

    public func clone() -> Shader {
        print("Cloning Shader: \(label)")

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

        clone.instancing = instancing
        clone.lighting = lighting
        clone.vertexDescriptor = vertexDescriptor

        clone.vertexFunctionName = vertexFunctionName
        clone.fragmentFunctionName = fragmentFunctionName

        return clone
    }
}

extension Shader: Equatable {
    public static func == (lhs: Shader, rhs: Shader) -> Bool {
        return lhs === rhs
    }
}
