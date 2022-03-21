//
//  Material.swift
//  Satin
//
//  Created by Reza Ali on 7/24/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal
import simd

public protocol MaterialDelegate: AnyObject {
    func updated(material: Material)
}

public struct DepthBias {
    var bias: Float
    var slope: Float
    var clamp: Float
    
    public init(bias: Float, slope: Float, clamp: Float) {
        self.bias = bias
        self.slope = slope
        self.clamp = clamp
    }
}

open class Material: ShaderDelegate, ParameterGroupDelegate {
    var prefix: String {
        var result = String(describing: type(of: self)).replacingOccurrences(of: "Material", with: "")
        if let bundleName = Bundle(for: type(of: self)).displayName, bundleName != result {
            result = result.replacingOccurrences(of: bundleName, with: "")
        }
        result = result.replacingOccurrences(of: ".", with: "")
        return result
    }
        
    public lazy var label: String = {
        prefix
    }()
    
    public var shader: Shader? {
        didSet {
            if oldValue != shader, let shader = shader {
                if let oldShader = oldValue, let index = oldShader.delegates.firstIndex(of: self) {
                    oldShader.delegates.remove(at: index)
                }

                shader.delegate = self

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
    
    public lazy var parameters: ParameterGroup = {
        let params = ParameterGroup(label)
        params.delegate = self
        return params
    }() {
        didSet {
            parameters.delegate = self
            uniformsNeedsUpdate = true
        }
    }
    
    var isClone: Bool = false
    public weak var delegate: MaterialDelegate?
    
    public var pipeline: MTLRenderPipelineState? {
        return shader?.pipeline
    }
    
    public var context: Context? {
        didSet {
            if oldValue != context {
                setup()
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
    var shaderBlendingNeedsUpdate = false
    var depthNeedsUpdate = false
    
    public var depthBias: DepthBias?
    public var onBind: ((_ renderEncoder: MTLRenderCommandEncoder) -> ())?
    public var onUpdate: (() -> ())?
    
    public required init() {}
    
    public init(shader: Shader) {
        shader.delegate = self
        self.label = shader.label
        self.shader = shader
    }
    
    open func setup() {
        setupDepthStencilState()
        setupShader()
        setupUniforms()
    }
    
    func setupDepthStencilState() {
        guard let context = context, context.depthPixelFormat != .invalid else { return }
        let device = context.device
        let depthStateDesciptor = MTLDepthStencilDescriptor()
        depthStateDesciptor.depthCompareFunction = depthCompareFunction
        depthStateDesciptor.isDepthWriteEnabled = depthWriteEnabled
        guard let state = device.makeDepthStencilState(descriptor: depthStateDesciptor) else { return }
        depthStencilState = state
        depthNeedsUpdate = false
    }
    
    open func setupShader() {
        guard let _ = context else { return }
        
        if shader == nil {
            self.shader = SourceShader(label, getPipelinesMaterialsUrl(label)!.appendingPathComponent("Shaders.metal"))
            isClone = false
        }
        else if let shader = shader, isClone, shaderBlendingNeedsUpdate {
            self.shader = shader.clone()
            isClone = false
        }
        
        guard let shader = shader else { return }
        
        updateShaderBlending()
        
        shader.context = context
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
    
    public func get(_ name: String) -> Parameter? {
        return parameters.get(name)
    }
    
    deinit {}
    
    public func clone() -> Material {
        let clone: Material = type(of: self).init()
        clone.isClone = true
        
        clone.label = label
        
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
        
        clone.shaderBlendingNeedsUpdate = false
        
        clone.depthStencilState = depthStencilState
        clone.depthCompareFunction = depthCompareFunction
        clone.depthWriteEnabled = depthWriteEnabled
       
        if let shader = shader {
            clone.shader = shader
        }
        
        if let context = context {
            clone.context = context
        }
        
        return clone
    }
}

public extension Material {
    func added(parameter: Parameter, from group: ParameterGroup) {
        uniformsNeedsUpdate = true
    }
    
    func removed(parameter: Parameter, from group: ParameterGroup) {
        uniformsNeedsUpdate = true
    }
    
    func loaded(group: ParameterGroup) {
        uniformsNeedsUpdate = true
    }
    
    func saved(group: ParameterGroup) {}
    
    func cleared(group: ParameterGroup) {
        uniformsNeedsUpdate = true
    }
    
    func update(parameter: Parameter, from group: ParameterGroup) {}
}

public extension Material {
    func updatedParameters(shader: Shader) {
        parameters.setFrom(shader.parameters)
        parameters.label = shader.parameters.label
        uniformsNeedsUpdate = true
        setupUniforms()
        delegate?.updated(material: self)
    }
}

extension Material: Equatable {
    public static func == (lhs: Material, rhs: Material) -> Bool {
        return lhs === rhs
    }
}
