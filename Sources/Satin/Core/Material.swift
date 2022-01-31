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
    public lazy var label: String = {
        var label = String(describing: type(of: self)).replacingOccurrences(of: "Material", with: "")
        if let bundleName = Bundle(for: type(of: self)).displayName, bundleName != label {
            label = label.replacingOccurrences(of: bundleName, with: "")
        }
        label = label.replacingOccurrences(of: ".", with: "")
        return label
    }()
    
    public lazy var pipelineURL: URL = {
        getPipelinesMaterialsUrl(label)!.appendingPathComponent("Shaders.metal")
    }()
    
    public var shader: Shader? {
        didSet {
            if oldValue != shader, let shader = shader {
                if let oldShader = oldValue, let index = oldShader.delegates.firstIndex(of: self) {
                    oldShader.delegates.remove(at: index)
                }
                shader.delegate = self
                label = shader.label
                pipelineURL = shader.pipelineURL

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
    
    public var parameters = ParameterGroup() {
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
    
    public init(_ pipelineURL: URL? = nil) {
        if let pipelineURL = pipelineURL {
            self.pipelineURL = pipelineURL
            createShader()
        }
    }
    
    public init(shader: Shader) {
        shader.delegate = self
        self.label = shader.label
        self.pipelineURL = shader.pipelineURL
        self.parameters = shader.parameters.clone()
        parameters.delegate = self
        self.shader = shader
    }
    
    func generateShader() -> Shader {
        Shader(label, pipelineURL)
    }
    
    func createShader() {
        let shader = generateShader()
        if isClone {
            isClone = false
        }
        else {
            parameters = shader.parameters.clone()
        }
        self.shader = shader
        updateShaderBlending()
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
        if shader == nil || (isClone && shaderBlendingNeedsUpdate) {
            createShader()
        }
        shader?.context = context
        shaderNeedsUpdate = false
    }
    
    open func setupUniforms() {
        guard let context = context, parameters.size > 0 else { return }
        uniforms = UniformBuffer(device: context.device, parameters: parameters)
        uniformsNeedsUpdate = false
    }
    
    open func update(camera: Camera) {}
    
    open func update() {
        onUpdate?()
        updateShader()
        updateDepth()
        updateUniforms()
    }
    
    open func updateShader() {
        if shaderNeedsUpdate {
            setupShader()
        }
        
        if shaderBlendingNeedsUpdate {
            updateShaderBlending()
        }
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
        parameters.set(name, value)
    }
    
    public func set(_ name: String, _ value: simd_float2) {
        parameters.set(name, value)
    }
    
    public func set(_ name: String, _ value: simd_float3) {
        parameters.set(name, value)
    }
    
    public func set(_ name: String, _ value: simd_float4) {
        parameters.set(name, value)
    }
    
    public func set(_ name: String, _ value: Int) {
        parameters.set(name, value)
    }
    
    public func set(_ name: String, _ value: simd_int2) {
        parameters.set(name, value)
    }
    
    public func set(_ name: String, _ value: simd_int3) {
        parameters.set(name, value)
    }
    
    public func set(_ name: String, _ value: simd_int4) {
        parameters.set(name, value)
    }
    
    public func set(_ name: String, _ value: Bool) {
        parameters.set(name, value)
    }
    
    public func get(_ name: String) -> Parameter? {
        return parameters.get(name)
    }
    
    deinit {}
    
    public func clone() -> Material {
        let clone = Material()
        clone.isClone = true
        
        clone.label = label
        clone.pipelineURL = pipelineURL
        
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
        delegate?.updated(material: self)
    }
}

extension Material: Equatable {
    public static func == (lhs: Material, rhs: Material) -> Bool {
        return lhs === rhs
    }
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
