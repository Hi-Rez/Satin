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

open class Material: Codable, ParameterGroupDelegate, ObservableObject {
    var prefix: String {
        var result = String(describing: type(of: self)).replacingOccurrences(of: "Material", with: "")
        if let bundleName = Bundle(for: type(of: self)).displayName, bundleName != result {
            result = result.replacingOccurrences(of: bundleName, with: "")
        }
        result = result.replacingOccurrences(of: ".", with: "")
        return result
    }
    
    public lazy var label: String = prefix
    
    public var vertexDescriptor: MTLVertexDescriptor = SatinVertexDescriptor {
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
    
    public internal(set) var isClone: Bool = false
    public weak var delegate: MaterialDelegate?
    
    public var pipeline: MTLRenderPipelineState? {
        return shader?.pipeline
    }
    
    public weak var context: Context? {
        didSet {
            if context != nil, context != oldValue {
                setup()
            }
        }
    }
    
    public var instancing: Bool = false {
        didSet {
            if oldValue != instancing {
                shaderDefinesNeedsUpdate = true
            }
        }
    }
    
    public var lighting: Bool = false {
        didSet {
            if oldValue != lighting {
                shaderDefinesNeedsUpdate = true
            }
        }
    }
    
    public var maxLights: Int = -1 {
        didSet {
            if oldValue != maxLights {
                shaderDefinesNeedsUpdate = true
            }
        }
    }
    
    public var blending: Blending = .alpha {
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
    
    public var depthWriteEnabled: Bool = true {
        didSet {
            if oldValue != depthWriteEnabled {
                depthNeedsUpdate = true
            }
        }
    }

    var uniformsNeedsUpdate = false
    var shaderNeedsUpdate = false
    
    var shaderDefinesNeedsUpdate = false {
        didSet {
            if shaderDefinesNeedsUpdate {
                shaderNeedsUpdate = true
            }
        }
    }
    
    var shaderBlendingNeedsUpdate = false {
        didSet {
            if shaderBlendingNeedsUpdate {
                shaderNeedsUpdate = true
            }
        }
    }
    
    var shaderVertexDescriptorNeedsUpdate = false {
        didSet {
            if shaderVertexDescriptorNeedsUpdate {
                shaderNeedsUpdate = true
            }
        }
    }
    
    var depthNeedsUpdate = false
    
    public var depthBias: DepthBias?
    public var onBind: ((_ renderEncoder: MTLRenderCommandEncoder) -> ())?
    public var onUpdate: (() -> ())?
    
    public required init() {}
    
    public init(shader: Shader) {
        self.instancing = shader.instancing
        self.lighting = shader.lighting
        self.vertexDescriptor = shader.vertexDescriptor
        self.blending = shader.blending
        
        self.sourceRGBBlendFactor = shader.sourceRGBBlendFactor
        self.sourceAlphaBlendFactor = shader.sourceAlphaBlendFactor
        self.destinationRGBBlendFactor = shader.destinationRGBBlendFactor
        self.destinationAlphaBlendFactor = shader.destinationAlphaBlendFactor
        self.rgbBlendOperation = shader.rgbBlendOperation
        self.alphaBlendOperation = shader.alphaBlendOperation
        
        self.label = shader.label
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
    
    func setupParametersSubscriber() {
        guard let shader = shader else { return }
        parametersSubscriber?.cancel()
        parametersSubscriber = shader.parametersPublisher.sink { [weak self] newParameters in
            self?.updateParameters(newParameters)
        }
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
        return SourceShader(label, getPipelinesMaterialsUrl(label)!.appendingPathComponent("Shaders.metal"))
    }
    
    open func cloneShader(_ shader: Shader) -> Shader {
        return shader.clone()
    }
    
    open func setupShader() {
        if shader == nil {
            shader = createShader()
            isClone = false
        }
        else if let shader = shader, isClone, shaderBlendingNeedsUpdate || shaderVertexDescriptorNeedsUpdate || shaderDefinesNeedsUpdate {
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
    
    open func update(camera: Camera) {}
    
    open func update() {
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
    
    open func bindPipeline(_ renderEncoder: MTLRenderCommandEncoder) {
        guard let pipeline = pipeline else { return }
        renderEncoder.setRenderPipelineState(pipeline)
    }
    
    open func bindUniforms(_ renderEncoder: MTLRenderCommandEncoder) {
        guard let uniforms = uniforms else { return }
        renderEncoder.setVertexBuffer(uniforms.buffer, offset: uniforms.offset, index: VertexBufferIndex.MaterialUniforms.rawValue)
        renderEncoder.setFragmentBuffer(uniforms.buffer, offset: uniforms.offset, index: FragmentBufferIndex.MaterialUniforms.rawValue)
    }
    
    open func bindDepthStencilState(_ renderEncoder: MTLRenderCommandEncoder) {
        guard let depthStencilState = depthStencilState else { return }
        renderEncoder.setDepthStencilState(depthStencilState)
        if let depthBias = depthBias {
            renderEncoder.setDepthBias(depthBias.bias, slopeScale: depthBias.slope, clamp: depthBias.clamp)
        }
    }
    
    open func bind(_ renderEncoder: MTLRenderCommandEncoder) {
        bindPipeline(renderEncoder)
        bindUniforms(renderEncoder)
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
    
    func updateShaderBlending() {
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
    
    func updateShaderVertexDescriptor() {
        guard let shader = shader else { return }
        shader.vertexDescriptor = vertexDescriptor
        shaderVertexDescriptorNeedsUpdate = false
    }
    
    open func updateShaderDefines() {
        guard let shader = shader else { return }
        shader.instancing = instancing
        shader.lighting = lighting
        shader.maxLights = maxLights
    }
    
    public func set(_ name: String, _ value: [Float]) {
        let count = value.count
        if count == 1 {
            set(name, value[0])
        }
        else if count == 2 {
            set(name, simd_make_float2(value[0], value[1]))
        }
        else if count == 3 {
            set(name, simd_make_float3(value[0], value[1], value[2]))
        }
        else if count == 4 {
            set(name, simd_make_float4(value[0], value[1], value[2], value[3]))
        }
    }
    
    public func set(_ name: String, _ value: [Int]) {
        let count = value.count
        if count == 1 {
            set(name, value[0])
        }
        else if count == 2 {
            set(name, simd_make_int2(Int32(value[0]), Int32(value[1])))
        }
        else if count == 3 {
            set(name, simd_make_int3(Int32(value[0]), Int32(value[1]), Int32(value[2])))
        }
        else if count == 4 {
            set(name, simd_make_int4(Int32(value[0]), Int32(value[1]), Int32(value[2]), Int32(value[3])))
        }
    }
    
    public func set(_ name: String, _ value: Float) {
        if let param = parameters.get(name) as? FloatParameter {
            param.value = value
        }
        else {
            parameters.append(FloatParameter(name, value))
        }
    }
    
    public func set(_ name: String, _ value: simd_float2) {
        if let param = parameters.get(name) as? Float2Parameter {
            param.value = value
        }
        else {
            parameters.append(Float2Parameter(name, value))
        }
    }
    
    public func set(_ name: String, _ value: simd_float3) {
        if let param = parameters.get(name) as? Float3Parameter {
            param.value = value
        }
        else {
            parameters.append(Float3Parameter(name, value))
        }
    }
    
    public func set(_ name: String, _ value: simd_float4) {
        if let param = parameters.get(name) as? Float4Parameter {
            param.value = value
        }
        else {
            parameters.append(Float4Parameter(name, value))
        }
    }
    
    public func set(_ name: String, _ value: Int) {
        if let param = parameters.get(name) as? IntParameter {
            param.value = value
        }
        else {
            parameters.append(IntParameter(name, value))
        }
    }
    
    public func set(_ name: String, _ value: simd_int2) {
        if let param = parameters.get(name) as? Int2Parameter {
            param.value = value
        }
        else {
            parameters.append(Int2Parameter(name, value))
        }
    }
    
    public func set(_ name: String, _ value: simd_int3) {
        if let param = parameters.get(name) as? Int3Parameter {
            param.value = value
        }
        else {
            parameters.append(Int3Parameter(name, value))
        }
    }
    
    public func set(_ name: String, _ value: simd_int4) {
        if let param = parameters.get(name) as? Int4Parameter {
            param.value = value
        }
        else {
            parameters.append(Int4Parameter(name, value))
        }
    }
    
    public func set(_ name: String, _ value: Bool) {
        if let param = parameters.get(name) as? BoolParameter {
            param.value = value
        }
        else {
            parameters.append(BoolParameter(name, value))
        }
    }
    
    public func set(_ name: String, _ value: simd_float2x2) {
        if let param = parameters.get(name) as? Float2x2Parameter {
            param.value = value
        }
        else {
            parameters.append(Float2x2Parameter(name, value))
        }
    }
    
    public func set(_ name: String, _ value: simd_float3x3) {
        if let param = parameters.get(name) as? Float3x3Parameter {
            param.value = value
        }
        else {
            parameters.append(Float3x3Parameter(name, value))
        }
    }
    
    public func set(_ name: String, _ value: simd_float4x4) {
        if let param = parameters.get(name) as? Float4x4Parameter {
            param.value = value
        }
        else {
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
    
    public func clone() -> Material {
        let clone: Material = type(of: self).init()
        clone.isClone = true
        
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
        
        return clone
    }
}

public extension Material {
    func added(parameter: Parameter, from group: ParameterGroup) {
        objectWillChange.send()
        uniformsNeedsUpdate = true
    }
    
    func removed(parameter: Parameter, from group: ParameterGroup) {
        objectWillChange.send()
        uniformsNeedsUpdate = true
    }
    
    func loaded(group: ParameterGroup) {
        objectWillChange.send()
        uniformsNeedsUpdate = true
    }
    
    func saved(group: ParameterGroup) {}
    
    func cleared(group: ParameterGroup) {
        objectWillChange.send()
        uniformsNeedsUpdate = true
    }
    
    func update(parameter: Parameter, from group: ParameterGroup) {
        objectWillChange.send()
    }
}

public extension Material {
    func updateParameters(_ newParameters: ParameterGroup) {
        objectWillChange.send()
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
