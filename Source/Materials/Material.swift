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
    func materialUpdated(material: Material)
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
        if let bundleName = Bundle(for: type(of: self)).displayName {
            label = label.replacingOccurrences(of: bundleName, with: "")
        }
        label = label.replacingOccurrences(of: ".", with: "")
        return label
    }
    
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
            delegate?.materialUpdated(material: self)
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
        guard let _ = self.context else { return }
        guard let source = compileSource() else { return }
        guard let library = makeLibrary(source) else { return }
        guard let pipeline = createPipeline(library) else { return }
        self.pipeline = pipeline
    }
    
    open func compileSource() -> String? {
        return nil
    }
    
    open func makeLibrary(_ source: String?) -> MTLLibrary? {
        guard let context = self.context, var source = source else { return nil }
        do {
            injectPassThroughVertex(source: &source)
            return try context.device.makeLibrary(source: source, options: .none)
        }
        catch {
            print(error)
        }
        return nil
    }
    
    open func injectPassThroughVertex(source: inout String) {
        let vertexFunctionName = label.camelCase + "Vertex"
        if !source.contains(vertexFunctionName), let passThroughVertexSource = PassThroughVertexPipelineSource.get() {
            source += "\n" + passThroughVertexSource.replacingOccurrences(of: "satinVertex", with: vertexFunctionName)
        }
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
        renderEncoder.setFragmentBuffer(uniforms.buffer, offset: uniforms.offset, index: FragmentBufferIndex.MaterialUniforms.rawValue)
    }
    
    open func bindDepthStencilState(_ renderEncoder: MTLRenderCommandEncoder) {
        guard let depthStencilState = self.depthStencilState else { return }
        renderEncoder.setDepthStencilState(depthStencilState)
    }
    
    open func bind(_ renderEncoder: MTLRenderCommandEncoder) {
        bindUniforms(renderEncoder)
        bindDepthStencilState(renderEncoder)
        onBind?(renderEncoder)
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
}

extension Material {
    public func added(parameter: Parameter, from group: ParameterGroup) {
        uniformsNeedsUpdate = true
    }
    
    public func removed(parameter: Parameter, from group: ParameterGroup) {
        uniformsNeedsUpdate = true
    }
    
    public func loaded(group: ParameterGroup) {
        uniformsNeedsUpdate = true
    }
    
    public func saved(group: ParameterGroup) {}
    
    public func cleared(group: ParameterGroup) {
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
