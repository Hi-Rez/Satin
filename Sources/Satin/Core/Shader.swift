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
    // MARK: - Main Pipeline

    public internal(set) var pipelineOptions: MTLPipelineOption = [.argumentInfo, .bufferTypeInfo]
    public internal(set) var pipelineReflection: MTLRenderPipelineReflection?
    public internal(set) var pipeline: MTLRenderPipelineState?
    public internal(set) var error: Error?

    // MARK: - Shadow Pipeline

    public internal(set) var shadowPipelineOptions: MTLPipelineOption = [.argumentInfo, .bufferTypeInfo]
    public internal(set) var shadowPipelineReflection: MTLRenderPipelineReflection?
    public internal(set) var shadowPipeline: MTLRenderPipelineState?
    public internal(set) var shadowError: Error?

    // MARK: - MTLLibrary

    public internal(set) var library: MTLLibrary?
    var libraryURL: URL?

    // MARK: - Blending

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

    // MARK: - Instancing

    public var instancing = false

    // MARK: - Lighting

    public var lighting = false
    public var maxLights = 0

    // MARK: - Shadows

    public var castShadow = false {
        didSet {
            if oldValue != castShadow {
                shadowPipelineNeedsUpdate = castShadow
            }
        }
    }

    public var receiveShadow = false
    public var shadowCount = 0

    public var vertexDescriptor: MTLVertexDescriptor = SatinVertexDescriptor {
        didSet {
            if oldValue != vertexDescriptor {
                pipelineNeedsUpdate = true
                shadowPipelineNeedsUpdate = castShadow
            }
        }
    }

    public var context: Context? {
        didSet {
            if oldValue != context {
                setup()
            }
        }
    }

    public private(set) var label = "Shader"

    var libraryNeedsUpdate = true {
        didSet {
            if libraryNeedsUpdate {
                pipelineNeedsUpdate = true
                shadowPipelineNeedsUpdate = castShadow
            }
        }
    }

    var shadowPipelineNeedsUpdate = false

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

    public var shadowFunctionName = "shaderShadowVertex" {
        didSet {
            if oldValue != shadowFunctionName {
                shadowPipelineNeedsUpdate = castShadow
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

    public init(
        _ label: String,
        _ vertexFunctionName: String? = nil,
        _ fragmentFunctionName: String? = nil,
        _: String? = nil,
        _ libraryURL: URL? = nil
    ) {
        self.label = label
        self.vertexFunctionName = vertexFunctionName ?? label.camelCase + "Vertex"
        shadowFunctionName = vertexFunctionName ?? label.camelCase + "ShadowVertex"
        self.fragmentFunctionName = fragmentFunctionName ?? label.camelCase + "Fragment"
        self.libraryURL = libraryURL
    }

    func setup() {
        setupLibrary()
        updatePipeline()
        updateShadowPipeline()
        setupParameters()
    }

    func update() {
        updateLibrary()
        updatePipeline()
        updateShadowPipeline()
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

    func updateShadowPipeline() {
        if shadowPipelineNeedsUpdate {
            setupShadowPipeline()
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
            pipeline = try createPipeline(context, library)
            error = nil
        } catch {
            self.error = error
            print("\(label) Shader: \(error.localizedDescription)")
            pipeline = nil
        }
        pipelineNeedsUpdate = false
    }

    func setupShadowPipeline() {
        guard let context = context, let library = library else { return }

        do {
            shadowPipeline = try createShadowPipeline(context, library)
            shadowError = nil
        } catch {
            shadowError = error
            print("\(label) Shadow Shader: \(error.localizedDescription)")
            shadowPipeline = nil
        }

        shadowPipelineNeedsUpdate = false
    }

    open func createPipeline(_ context: Context, _ library: MTLLibrary) throws -> MTLRenderPipelineState? {
        guard let vertexFunction = library.makeFunction(name: vertexFunctionName),
              let fragmentFunction = library.makeFunction(name: fragmentFunctionName) else { return nil }

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

        return try context.device.makeRenderPipelineState(
            descriptor: pipelineStateDescriptor,
            options: pipelineOptions,
            reflection: &pipelineReflection
        )
    }

    open func createShadowPipeline(_ context: Context, _ library: MTLLibrary) throws -> MTLRenderPipelineState? {
        guard let vertexFunction = library.makeFunction(name: shadowFunctionName) ??
            library.makeFunction(name: vertexFunctionName) else { return nil }

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = label + " Shadow"

        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = nil

        pipelineStateDescriptor.sampleCount = 1
        pipelineStateDescriptor.vertexDescriptor = vertexDescriptor
        pipelineStateDescriptor.depthAttachmentPixelFormat = context.depthPixelFormat

        return try context.device.makeRenderPipelineState(
            descriptor: pipelineStateDescriptor,
            options: shadowPipelineOptions,
            reflection: &shadowPipelineReflection
        )
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

        clone.pipelineReflection = pipelineReflection
        clone.pipeline = pipeline
        clone.error = error

        clone.shadowPipelineReflection = shadowPipelineReflection
        clone.shadowPipeline = shadowPipeline
        clone.shadowError = shadowError

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
        clone.maxLights = maxLights

        clone.castShadow = castShadow

        clone.shadowCount = shadowCount
        clone.receiveShadow = receiveShadow

        clone.vertexDescriptor = vertexDescriptor

        clone.vertexFunctionName = vertexFunctionName
        clone.shadowFunctionName = shadowFunctionName
        clone.fragmentFunctionName = fragmentFunctionName

        return clone
    }
}

extension Shader: Equatable {
    public static func == (lhs: Shader, rhs: Shader) -> Bool {
        return lhs === rhs
    }
}
