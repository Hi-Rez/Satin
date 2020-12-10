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

open class Material: ParameterGroupDelegate {
    public enum Blending {
        case disabled
        case alpha
        case additive
//        case subtractive
//        case multiply
//        case custom
    }
    
    public var label: String {
        var label = String(describing: type(of: self)).replacingOccurrences(of: "Material", with: "")
        if let bundleName = Bundle(for: type(of: self)).displayName, bundleName != label {
            label = label.replacingOccurrences(of: bundleName, with: "")
        }
        label = label.replacingOccurrences(of: ".", with: "")
        return label
    }
    
    var externalUniformBuffers: Set<UniformBuffer> = []
    var externalVertexUniformBuffersMap: [VertexBufferIndex: UniformBuffer] = [:]
    var externalFragmentUniformBuffersMap: [FragmentBufferIndex: UniformBuffer] = [:]
    
    public var uniforms: UniformBuffer?
    var uniformsNeedsUpdate = true
    
    public var parameters: ParameterGroup {
        didSet {
            parameters.delegate = self
            uniformsNeedsUpdate = true
        }
    }
    
    public weak var delegate: MaterialDelegate?
    
    public var pipeline: MTLRenderPipelineState? {
        didSet {
            delegate?.updated(material: self)
        }
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
                setupPipeline()
            }
        }
    }
    
    public var depthStencilState: MTLDepthStencilState?
    public var depthCompareFunction: MTLCompareFunction = .less {
        didSet {
            if oldValue != depthCompareFunction {
                setupDepthStencilState()
            }
        }
    }
    
    public var depthWriteEnabled: Bool = true {
        didSet {
            if oldValue != depthWriteEnabled {
                setupDepthStencilState()
            }
        }
    }
    
    public var depthBias = DepthBias(bias: 0.0, slope: 0.0, clamp: 0.0)
    
    public var onBind: ((_ renderEncoder: MTLRenderCommandEncoder) -> ())?
    public var onUpdate: (() -> ())?
    
    public init() {
        self.parameters = ParameterGroup()
        parameters.label = label + "Uniforms"
        parameters.delegate = self
    }
    
    public init(pipeline: MTLRenderPipelineState) {
        self.pipeline = pipeline
        self.parameters = ParameterGroup()
        parameters.label = label + "Uniforms"
        parameters.delegate = self
    }
    
    open func setup() {
        setupDepthStencilState()
        setupPipeline()
    }
    
    func setupDepthStencilState() {
        guard let context = self.context, context.depthPixelFormat != .invalid else { return }
        let device = context.device
        let depthStateDesciptor = MTLDepthStencilDescriptor()
        depthStateDesciptor.depthCompareFunction = depthCompareFunction
        depthStateDesciptor.isDepthWriteEnabled = depthWriteEnabled
        guard let state = device.makeDepthStencilState(descriptor: depthStateDesciptor) else { return }
        depthStencilState = state
    }
    
    open func setupPipeline() {
        guard let _ = context else { return }
        guard var source = compileSource() else { return }
        guard let library = makeLibrary(&source) else { return }
        guard let pipeline = createPipeline(library) else { return }
        self.pipeline = pipeline
    }
    
    open func compileSource() -> String? {
        return nil
    }
    
    open func makeLibrary(_ source: inout String) -> MTLLibrary? {
        guard let context = self.context else { return nil }
        do {
            injectConstants(source: &source)
            injectVertex(source: &source)
            injectVertexData(source: &source)
            injectVertexUniforms(source: &source)
            injectExternalUniforms(source: &source)
            injectMaterialUniforms(source: &source)
            injectPassThroughVertex(label: label, source: &source)
            return try context.device.makeLibrary(source: source, options: .none)
        }
        catch {
            print(error)
        }
        return nil
    }
    
    open func injectExternalUniforms(source: inout String) {
        var addedStructs: Set<String> = []
        var externalStructs = ""
        for externalUniformBuffer in externalUniformBuffers {
            if let params = externalUniformBuffer.parameters {
                let structName = params.label
                if !addedStructs.contains(structName), !source.contains("} \(structName);") {
                    externalStructs += externalUniformBuffer.parameters.structString + "\n"
                    addedStructs.insert(structName)
                }
            }
        }
        source = source.replacingOccurrences(of: "// inject structs\n", with: externalStructs)
    }

    open func injectMaterialUniforms(source: inout String) {
        var materialStructs = "\n"
        if !source.contains("} \(parameters.label);") {
            materialStructs = parameters.structString + "\n"
        }
        source = source.replacingOccurrences(of: "// inject material structs\n", with: materialStructs)
    }
    
    open func createPipeline(_ library: MTLLibrary?, vertex: String = "", fragment: String = "") -> MTLRenderPipelineState? {
        guard let context = self.context, let library = library else { return nil }
        let vertex = vertex.isEmpty ? label.camelCase + "Vertex" : vertex
        let fragment = fragment.isEmpty ? label.camelCase + "Fragment" : fragment
        
        do {
            switch blending {
            case .alpha:
                return try makeAlphaRenderPipeline(
                    library: library,
                    vertex: vertex,
                    fragment: fragment,
                    label: label.titleCase,
                    context: context
                )
            case .additive:
                return try makeAdditiveRenderPipeline(
                    library: library,
                    vertex: vertex,
                    fragment: fragment,
                    label: label.titleCase,
                    context: context
                )
            case .disabled:
                return try makeRenderPipeline(
                    library: library,
                    vertex: vertex,
                    fragment: fragment,
                    label: label.titleCase,
                    context: context
                )
            }
        }
        catch {
            print(error)
        }
        
        return nil
    }
    
    open func setupUniforms() {
        if let context = self.context, parameters.size > 0 {
            uniforms = UniformBuffer(context: context, parameters: parameters)
        }
        else {
            uniforms = nil
        }
    }
    
    open func update() {
        onUpdate?()
        updateUniforms()
    }
    
    open func updateUniforms() {
        if uniformsNeedsUpdate {
            setupUniforms()
            uniformsNeedsUpdate = false
        }
        uniforms?.update()
    }
    
    open func bindUniforms(_ renderEncoder: MTLRenderCommandEncoder) {
        guard let uniforms = self.uniforms else { return }
        renderEncoder.setVertexBuffer(uniforms.buffer, offset: uniforms.offset, index: VertexBufferIndex.MaterialUniforms.rawValue)
        for (vertexBufferIndex, externalUniforms) in externalVertexUniformBuffersMap {
            renderEncoder.setVertexBuffer(externalUniforms.buffer, offset: externalUniforms.offset, index: vertexBufferIndex.rawValue)
        }
        
        renderEncoder.setFragmentBuffer(uniforms.buffer, offset: uniforms.offset, index: FragmentBufferIndex.MaterialUniforms.rawValue)
        for (fragmentBufferIndex, externalUniforms) in externalFragmentUniformBuffersMap {
            renderEncoder.setFragmentBuffer(externalUniforms.buffer, offset: externalUniforms.offset, index: fragmentBufferIndex.rawValue)
        }
    }
    
    open func bindDepthStencilState(_ renderEncoder: MTLRenderCommandEncoder) {
        guard let depthStencilState = self.depthStencilState else { return }
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setDepthBias(depthBias.bias, slopeScale: depthBias.slope, clamp: depthBias.clamp)
    }
    
    open func bind(_ renderEncoder: MTLRenderCommandEncoder) {
        bindUniforms(renderEncoder)
        bindDepthStencilState(renderEncoder)
        onBind?(renderEncoder)
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
    
    public func setFragmentUniformBuffer(_ uniformBuffer: UniformBuffer, _ index: FragmentBufferIndex) {
        var needsSetup = false
        if !externalUniformBuffers.contains(uniformBuffer) {
            externalUniformBuffers.insert(uniformBuffer)
            needsSetup = true
        }
        externalFragmentUniformBuffersMap[index] = uniformBuffer
        if needsSetup {
            setupPipeline()
        }
    }
    
    public func removeFragmentUniformBuffer(_ uniformBuffer: UniformBuffer, _ index: FragmentBufferIndex) {
        if externalUniformBuffers.contains(uniformBuffer) {
            externalFragmentUniformBuffersMap.removeValue(forKey: index)
            var remove = true
            for (_, vertexUniformBuffer) in externalVertexUniformBuffersMap {
                if vertexUniformBuffer == uniformBuffer {
                    remove = false
                    break
                }
            }
            if remove {
                externalUniformBuffers.remove(uniformBuffer)
            }
            setupPipeline()
        }
    }
    
    public func setVertexUniformBuffer(_ uniformBuffer: UniformBuffer, _ index: VertexBufferIndex) {
        var needsSetup = false
        if !externalUniformBuffers.contains(uniformBuffer) {
            externalUniformBuffers.insert(uniformBuffer)
            needsSetup = true
        }
        externalVertexUniformBuffersMap[index] = uniformBuffer
        if needsSetup {
            setupPipeline()
        }
    }
    
    public func removeVertexUniformBuffer(_ uniformBuffer: UniformBuffer, _ index: VertexBufferIndex) {
        if externalUniformBuffers.contains(uniformBuffer) {
            externalVertexUniformBuffersMap.removeValue(forKey: index)
            var remove = true
            for (_, fragmentUniformBuffer) in externalFragmentUniformBuffersMap {
                if fragmentUniformBuffer == uniformBuffer {
                    remove = false
                    break
                }
            }
            if remove {
                externalUniformBuffers.remove(uniformBuffer)
            }
            setupPipeline()
        }
    }
    
    deinit {}
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
