//
//  Material.swift
//  Satin
//
//  Created by Reza Ali on 7/24/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Combine
import Metal
import simd

public protocol MaterialDelegate: AnyObject {
    func updated(material: Material)
}

public struct DepthBias: Codable {
    var bias: Float
    var slope: Float
    var clamp: Float

    public init(bias: Float, slope: Float, clamp: Float) {
        self.bias = bias
        self.slope = slope
        self.clamp = clamp
    }
}

open class Material: Codable, ParameterGroupDelegate {
    var prefix: String {
        var result = String(describing: type(of: self)).replacingOccurrences(of: "Material", with: "")
        if let bundleName = Bundle(for: type(of: self)).displayName, bundleName != result {
            result = result.replacingOccurrences(of: bundleName, with: "")
        }
        result = result.replacingOccurrences(of: ".", with: "")
        return result
    }

    public lazy var label: String = prefix

    public var vertexDescriptor: MTLVertexDescriptor = SatinVertexDescriptor() {
        didSet {
            if oldValue != vertexDescriptor {
                shaderVertexDescriptorNeedsUpdate = true
            }
        }
    }

    private var parametersSubscriber: AnyCancellable?

    public var shader: Shader? {
        didSet {
            if shader != nil {
                setupParametersSubscriber()
                if !isClone {
                    shaderNeedsUpdate = true
                }
            }
        }
    }

    public var sourceRGBBlendFactor: MTLBlendFactor = .sourceAlpha {
        didSet {
            if oldValue != sourceRGBBlendFactor {
                shaderBlendingNeedsUpdate = true
            }
        }
    }

    public var sourceAlphaBlendFactor: MTLBlendFactor = .sourceAlpha {
        didSet {
            if oldValue != sourceAlphaBlendFactor {
                shaderBlendingNeedsUpdate = true
            }
        }
    }

    public var destinationRGBBlendFactor: MTLBlendFactor = .oneMinusSourceAlpha {
        didSet {
            if oldValue != destinationRGBBlendFactor {
                shaderBlendingNeedsUpdate = true
            }
        }
    }

    public var destinationAlphaBlendFactor: MTLBlendFactor = .oneMinusSourceAlpha {
        didSet {
            if oldValue != destinationAlphaBlendFactor {
                shaderBlendingNeedsUpdate = true
            }
        }
    }

    public var rgbBlendOperation: MTLBlendOperation = .add {
        didSet {
            if oldValue != rgbBlendOperation {
                shaderBlendingNeedsUpdate = true
            }
        }
    }

    public var alphaBlendOperation: MTLBlendOperation = .add {
        didSet {
            if oldValue != alphaBlendOperation {
                shaderBlendingNeedsUpdate = true
            }
        }
    }

    public var uniforms: UniformBuffer?

    public private(set) lazy var parameters: ParameterGroup = {
        let params = ParameterGroup(label)
        params.delegate = self
        return params
    }() {
        didSet {
            parameters.delegate = self
            uniformsNeedsUpdate = true
        }
    }

    open var isClone = false
    public weak var delegate: MaterialDelegate?

    public var pipeline: MTLRenderPipelineState? {
        return shader?.pipeline
    }

    public var shadowPipeline: MTLRenderPipelineState? {
        return shader?.shadowPipeline
    }

    public weak var context: Context? {
        didSet {
            if context != nil, context !== oldValue {
                setup()
            }
        }
    }

    public var instancing = false {
        didSet {
            if oldValue != instancing {
                shaderDefinesNeedsUpdate = true
            }
        }
    }

    public var castShadow = false {
        didSet {
            if oldValue != castShadow {
                shaderDefinesNeedsUpdate = true
            }
        }
    }

    public var receiveShadow = false {
        didSet {
            if oldValue != receiveShadow {
                shaderDefinesNeedsUpdate = true
            }
        }
    }

    public var lighting = false {
        didSet {
            if oldValue != lighting {
                shaderDefinesNeedsUpdate = true
            }
        }
    }

    public var shadowCount = 0 {
        didSet {
            if oldValue != shadowCount {
                shaderDefinesNeedsUpdate = true
            }
        }
    }

    public var maxLights = 0 {
        didSet {
            if oldValue != maxLights {
                shaderDefinesNeedsUpdate = true
            }
        }
    }

    public var blending: Blending = .disabled {
        didSet {
            if oldValue != blending {
                setupBlending()
            }
        }
    }

    public var depthStencilState: MTLDepthStencilState?
    public var depthCompareFunction: MTLCompareFunction = .greaterEqual {
        didSet {
            if oldValue != depthCompareFunction {
                depthNeedsUpdate = true
            }
        }
    }

    public var depthWriteEnabled = true {
        didSet {
            if oldValue != depthWriteEnabled {
                depthNeedsUpdate = true
            }
        }
    }

    private var uniformsNeedsUpdate = false
    private var shaderNeedsUpdate = false

    private var shaderDefinesNeedsUpdate = false {
        didSet {
            if shaderDefinesNeedsUpdate {
                shaderNeedsUpdate = true
            }
        }
    }

    private var shaderBlendingNeedsUpdate = false {
        didSet {
            if shaderBlendingNeedsUpdate {
                shaderNeedsUpdate = true
            }
        }
    }

    private var shaderVertexDescriptorNeedsUpdate = false {
        didSet {
            if shaderVertexDescriptorNeedsUpdate {
                shaderNeedsUpdate = true
            }
        }
    }

    private var depthNeedsUpdate = false

    public var depthBias: DepthBias?
    public var onBind: ((_ renderEncoder: MTLRenderCommandEncoder) -> Void)?
    public var onUpdate: (() -> Void)?

    public required init() {}

    public init(shader: Shader) {
        instancing = shader.instancing
        lighting = shader.lighting
        vertexDescriptor = shader.vertexDescriptor
        blending = shader.blending

        sourceRGBBlendFactor = shader.sourceRGBBlendFactor
        sourceAlphaBlendFactor = shader.sourceAlphaBlendFactor
        destinationRGBBlendFactor = shader.destinationRGBBlendFactor
        destinationAlphaBlendFactor = shader.destinationAlphaBlendFactor
        rgbBlendOperation = shader.rgbBlendOperation
        alphaBlendOperation = shader.alphaBlendOperation

        label = shader.label
        self.shader = shader

        setupParametersSubscriber()
    }

    // MARK: - CodingKeys

    public enum CodingKeys: String, CodingKey {
        case label
        case blending
        case sourceRGBBlendFactor
        case sourceAlphaBlendFactor
        case destinationRGBBlendFactor
        case destinationAlphaBlendFactor
        case rgbBlendOperation
        case alphaBlendOperation
        case depthWriteEnabled
        case depthCompareFunction
        case depthBias
        case parameters
    }

    // MARK: - Decode

    public required init(from decoder: Decoder) throws {
        try decode(from: decoder)
    }

    public func decode(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        label = try values.decode(String.self, forKey: .label)
        blending = try values.decode(Blending.self, forKey: .blending)
        sourceRGBBlendFactor = try values.decode(MTLBlendFactor.self, forKey: .sourceRGBBlendFactor)
        sourceAlphaBlendFactor = try values.decode(MTLBlendFactor.self, forKey: .sourceAlphaBlendFactor)
        destinationRGBBlendFactor = try values.decode(MTLBlendFactor.self, forKey: .destinationRGBBlendFactor)
        destinationAlphaBlendFactor = try values.decode(MTLBlendFactor.self, forKey: .destinationAlphaBlendFactor)
        rgbBlendOperation = try values.decode(MTLBlendOperation.self, forKey: .rgbBlendOperation)
        alphaBlendOperation = try values.decode(MTLBlendOperation.self, forKey: .alphaBlendOperation)
        depthWriteEnabled = try values.decode(Bool.self, forKey: .depthWriteEnabled)
        depthCompareFunction = try values.decode(MTLCompareFunction.self, forKey: .depthCompareFunction)
        depthBias = try values.decode(DepthBias?.self, forKey: .depthBias)
        parameters = try values.decode(ParameterGroup.self, forKey: .parameters)
    }

    // MARK: - Encode

    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(label, forKey: .label)
        try container.encode(blending, forKey: .blending)
        try container.encode(sourceRGBBlendFactor, forKey: .sourceRGBBlendFactor)
        try container.encode(sourceAlphaBlendFactor, forKey: .sourceAlphaBlendFactor)
        try container.encode(destinationRGBBlendFactor, forKey: .destinationRGBBlendFactor)
        try container.encode(destinationAlphaBlendFactor, forKey: .destinationAlphaBlendFactor)
        try container.encode(rgbBlendOperation, forKey: .rgbBlendOperation)
        try container.encode(alphaBlendOperation, forKey: .alphaBlendOperation)
        try container.encode(depthWriteEnabled, forKey: .depthWriteEnabled)
        try container.encode(depthCompareFunction, forKey: .depthCompareFunction)
        try container.encode(depthBias, forKey: .depthBias)
        try container.encode(parameters, forKey: .parameters)
    }

    private func setupParametersSubscriber() {
        guard let shader = shader else { return }
        parametersSubscriber?.cancel()
        parametersSubscriber = shader.parametersPublisher.sink(receiveValue: updateParameters)
    }

    open func setup() {
        setupDepthStencilState()
        setupShader()
        setupUniforms()
    }

    func setupDepthStencilState() {
        guard let context = context, context.depthPixelFormat != .invalid else { return }
        let depthStateDesciptor = MTLDepthStencilDescriptor()
        depthStateDesciptor.depthCompareFunction = depthCompareFunction
        depthStateDesciptor.isDepthWriteEnabled = depthWriteEnabled
        depthStencilState = context.device.makeDepthStencilState(descriptor: depthStateDesciptor)
        depthNeedsUpdate = false
    }

    open func createShader() -> Shader {
        return SourceShader(label, getPipelinesMaterialsURL(label)!.appendingPathComponent("Shaders.metal"))
    }

    open func cloneShader(_ shader: Shader) -> Shader {
        return shader.clone()
    }

    open func setupShader() {
        if shader == nil {
            shader = createShader()
            isClone = false
        } else if let shader = shader, isClone, shaderBlendingNeedsUpdate || shaderVertexDescriptorNeedsUpdate || shaderDefinesNeedsUpdate {
            self.shader = cloneShader(shader)
            isClone = false
        }

        if let shader = shader {
            updateShaderBlending()
            updateShaderVertexDescriptor()
            updateShaderDefines()
            shader.context = context
        }
        shaderNeedsUpdate = false
    }

    open func setupUniforms() {
        guard let context = context, parameters.size > 0 else { return }
        uniforms = UniformBuffer(device: context.device, parameters: parameters)
        uniformsNeedsUpdate = false
    }

    open func update(camera _: Camera) {}

    open func update(_: MTLCommandBuffer) {
        updateDepth()
        updateShader()
        updateUniforms()
        onUpdate?()
    }

    open func updateShader() {
        if shaderNeedsUpdate {
            setupShader()
        }

        if shaderBlendingNeedsUpdate {
            updateShaderBlending()
        }

        if shaderVertexDescriptorNeedsUpdate {
            updateShaderVertexDescriptor()
        }

        if shaderDefinesNeedsUpdate {
            updateShaderDefines()
        }

        shader?.update()
    }

    open func updateDepth() {
        if depthNeedsUpdate {
            setupDepthStencilState()
        }
    }

    open func updateUniforms() {
        if uniformsNeedsUpdate {
            setupUniforms()
        }
        uniforms?.update()
    }

    open func bindPipeline(_ renderEncoder: MTLRenderCommandEncoder, shadow: Bool) {
        guard let pipeline = shadow ? shadowPipeline : pipeline else { return }
        renderEncoder.setRenderPipelineState(pipeline)
    }

    open func bindUniforms(_ renderEncoder: MTLRenderCommandEncoder, shadow: Bool) {
        guard let uniforms = uniforms else { return }
        // TO DO: Should only bind this if it actually uses it, likewise for the Fragment
        renderEncoder.setVertexBuffer(uniforms.buffer, offset: uniforms.offset, index: VertexBufferIndex.MaterialUniforms.rawValue)
        if !shadow {
            renderEncoder.setFragmentBuffer(uniforms.buffer, offset: uniforms.offset, index: FragmentBufferIndex.MaterialUniforms.rawValue)
        }
    }

    open func bindDepthStencilState(_ renderEncoder: MTLRenderCommandEncoder) {
        guard let depthStencilState = depthStencilState else { return }
        renderEncoder.setDepthStencilState(depthStencilState)
        if let depthBias = depthBias {
            renderEncoder.setDepthBias(depthBias.bias, slopeScale: depthBias.slope, clamp: depthBias.clamp)
        }
    }

    open func bind(_ renderEncoder: MTLRenderCommandEncoder, shadow: Bool) {
        bindPipeline(renderEncoder, shadow: shadow)
        bindUniforms(renderEncoder, shadow: shadow)
        bindDepthStencilState(renderEncoder)
        onBind?(renderEncoder)
    }

    open func setupBlending() {
        switch blending {
        case .alpha:
            sourceRGBBlendFactor = .sourceAlpha
            sourceAlphaBlendFactor = .sourceAlpha
            destinationRGBBlendFactor = .oneMinusSourceAlpha
            destinationAlphaBlendFactor = .oneMinusSourceAlpha
            rgbBlendOperation = .add
            alphaBlendOperation = .add
        case .additive:
            sourceRGBBlendFactor = .sourceAlpha
            sourceAlphaBlendFactor = .one
            destinationRGBBlendFactor = .one
            destinationAlphaBlendFactor = .one
            rgbBlendOperation = .add
            alphaBlendOperation = .add
        case .subtract:
            sourceRGBBlendFactor = .sourceAlpha
            sourceAlphaBlendFactor = .sourceAlpha
            destinationRGBBlendFactor = .oneMinusBlendColor
            destinationAlphaBlendFactor = .oneMinusSourceAlpha
            rgbBlendOperation = .reverseSubtract
            alphaBlendOperation = .add
        case .disabled:
            break
        case .custom:
            break
        }
    }

    private func updateShaderBlending() {
        guard let shader = shader else { return }
        shader.blending = blending
        shader.sourceRGBBlendFactor = sourceRGBBlendFactor
        shader.sourceAlphaBlendFactor = sourceAlphaBlendFactor
        shader.destinationRGBBlendFactor = destinationRGBBlendFactor
        shader.destinationAlphaBlendFactor = destinationAlphaBlendFactor
        shader.rgbBlendOperation = rgbBlendOperation
        shader.alphaBlendOperation = alphaBlendOperation
        shaderBlendingNeedsUpdate = false
    }

    private func updateShaderVertexDescriptor() {
        guard let shader = shader else { return }
        shader.vertexDescriptor = vertexDescriptor
        shaderVertexDescriptorNeedsUpdate = false
    }

    open func updateShaderDefines() {
        guard let shader = shader else { return }
        shader.instancing = instancing
        shader.lighting = lighting
        shader.maxLights = maxLights
        shader.shadowCount = shadowCount
        shader.receiveShadow = receiveShadow
        shader.castShadow = castShadow
        shaderDefinesNeedsUpdate = false
    }

    public func set(_ name: String, _ value: [Float]) {
        let count = value.count
        if count == 1 {
            set(name, value[0])
        } else if count == 2 {
            set(name, simd_make_float2(value[0], value[1]))
        } else if count == 3 {
            set(name, simd_make_float3(value[0], value[1], value[2]))
        } else if count == 4 {
            set(name, simd_make_float4(value[0], value[1], value[2], value[3]))
        }
    }

    public func set(_ name: String, _ value: [Int]) {
        let count = value.count
        if count == 1 {
            set(name, value[0])
        } else if count == 2 {
            set(name, simd_make_int2(Int32(value[0]), Int32(value[1])))
        } else if count == 3 {
            set(name, simd_make_int3(Int32(value[0]), Int32(value[1]), Int32(value[2])))
        } else if count == 4 {
            set(name, simd_make_int4(Int32(value[0]), Int32(value[1]), Int32(value[2]), Int32(value[3])))
        }
    }

    public func set(_ name: String, _ value: Float) {
        if let param = parameters.get(name) as? FloatParameter {
            param.value = value
        } else {
            parameters.append(FloatParameter(name, value))
        }
    }

    public func set(_ name: String, _ value: simd_float2) {
        if let param = parameters.get(name) as? Float2Parameter {
            param.value = value
        } else {
            parameters.append(Float2Parameter(name, value))
        }
    }

    public func set(_ name: String, _ value: simd_float3) {
        if let param = parameters.get(name) as? Float3Parameter {
            param.value = value
        } else {
            parameters.append(Float3Parameter(name, value))
        }
    }

    public func set(_ name: String, _ value: simd_float4) {
        if let param = parameters.get(name) as? Float4Parameter {
            param.value = value
        } else {
            parameters.append(Float4Parameter(name, value))
        }
    }

    public func set(_ name: String, _ value: Int) {
        if let param = parameters.get(name) as? IntParameter {
            param.value = value
        } else {
            parameters.append(IntParameter(name, value))
        }
    }

    public func set(_ name: String, _ value: simd_int2) {
        if let param = parameters.get(name) as? Int2Parameter {
            param.value = value
        } else {
            parameters.append(Int2Parameter(name, value))
        }
    }

    public func set(_ name: String, _ value: simd_int3) {
        if let param = parameters.get(name) as? Int3Parameter {
            param.value = value
        } else {
            parameters.append(Int3Parameter(name, value))
        }
    }

    public func set(_ name: String, _ value: simd_int4) {
        if let param = parameters.get(name) as? Int4Parameter {
            param.value = value
        } else {
            parameters.append(Int4Parameter(name, value))
        }
    }

    public func set(_ name: String, _ value: Bool) {
        if let param = parameters.get(name) as? BoolParameter {
            param.value = value
        } else {
            parameters.append(BoolParameter(name, value))
        }
    }

    public func set(_ name: String, _ value: simd_float2x2) {
        if let param = parameters.get(name) as? Float2x2Parameter {
            param.value = value
        } else {
            parameters.append(Float2x2Parameter(name, value))
        }
    }

    public func set(_ name: String, _ value: simd_float3x3) {
        if let param = parameters.get(name) as? Float3x3Parameter {
            param.value = value
        } else {
            parameters.append(Float3x3Parameter(name, value))
        }
    }

    public func set(_ name: String, _ value: simd_float4x4) {
        if let param = parameters.get(name) as? Float4x4Parameter {
            param.value = value
        } else {
            parameters.append(Float4x4Parameter(name, value))
        }
    }

    public func get(_ name: String) -> Parameter? {
        return parameters.get(name)
    }

    deinit {
        parameters.delegate = nil
        delegate = nil
        shader = nil
    }

    open func clone() -> Material {
        let clone: Material = type(of: self).init()
        clone.isClone = true
        cloneProperties(clone: clone)
        return clone
    }

    public func cloneProperties(clone: Material) {
        clone.label = label
        clone.vertexDescriptor = vertexDescriptor
        clone.instancing = instancing
        clone.lighting = lighting
        clone.maxLights = maxLights

        clone.delegate = delegate
        clone.parameters = parameters.clone()

        clone.onUpdate = onUpdate
        clone.onBind = onBind

        clone.blending = blending
        clone.sourceRGBBlendFactor = sourceRGBBlendFactor
        clone.sourceAlphaBlendFactor = sourceAlphaBlendFactor
        clone.destinationRGBBlendFactor = destinationRGBBlendFactor
        clone.destinationAlphaBlendFactor = destinationAlphaBlendFactor
        clone.rgbBlendOperation = rgbBlendOperation
        clone.alphaBlendOperation = alphaBlendOperation

        clone.shaderDefinesNeedsUpdate = false
        clone.shaderVertexDescriptorNeedsUpdate = false
        clone.shaderBlendingNeedsUpdate = false

        clone.depthStencilState = depthStencilState
        clone.depthCompareFunction = depthCompareFunction
        clone.depthWriteEnabled = depthWriteEnabled

        clone.shader = shader
    }
}

public extension Material {
    func added(parameter _: Parameter, from _: ParameterGroup) {
        uniformsNeedsUpdate = true
    }

    func removed(parameter _: Parameter, from _: ParameterGroup) {
        uniformsNeedsUpdate = true
    }

    func loaded(group _: ParameterGroup) {
        uniformsNeedsUpdate = true
    }

    func saved(group _: ParameterGroup) {}

    func cleared(group _: ParameterGroup) {
        uniformsNeedsUpdate = true
    }

    func update(parameter _: Parameter, from _: ParameterGroup) {}
}

public extension Material {
    func updateParameters(_ newParameters: ParameterGroup) {
        parameters.setFrom(newParameters)
        parameters.label = newParameters.label
        uniformsNeedsUpdate = true
        delegate?.updated(material: self)
    }
}

extension Material: Equatable {
    public static func == (lhs: Material, rhs: Material) -> Bool {
        return lhs === rhs
    }
}
