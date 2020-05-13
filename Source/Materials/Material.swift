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

open class Material {
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
    public lazy var parameters: ParameterGroup = {
        ParameterGroup(label + "Uniforms")
    }()
    
    public weak var delegate: MaterialDelegate?
    
    public var pipeline: MTLRenderPipelineState? {
        didSet {
            delegate?.materialUpdated(material: self)
        }
    }
    
    public var context: Context? {
        didSet {
            setup()
        }
    }
    
    public var blending: Blending = .alpha {
        didSet {
            if oldValue != blending {
                setupPipeline()
            }
        }
    }
    
    public var onBind: ((_ renderEncoder: MTLRenderCommandEncoder) -> ())?
    public var onUpdate: (() -> ())?
    
    public init() {}
    
    public init(pipeline: MTLRenderPipelineState) {
        self.pipeline = pipeline
    }
    
    open func setup() {
        setupParameters()    
        setupUniforms()
        setupPipeline()        
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
        guard let context = self.context, let source = source else { return nil }
        do {
            return try context.device.makeLibrary(source: source, options: .none)
        }
        catch {
            print(error)
        }
        return nil
    }
    
    open func createPipeline(_ library: MTLLibrary?, vertex: String = "", fragment: String = "") -> MTLRenderPipelineState? {
        guard let context = self.context, let library = library else { return nil }
        
        let vertex = vertex.isEmpty ? "satinVertex" : vertex
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
    
    open func setupParameters() {}
    
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
        uniforms?.update()
    }
    
    open func bindUniforms(_ renderEncoder: MTLRenderCommandEncoder) {
        if let uniforms = self.uniforms {
            renderEncoder.setVertexBuffer(uniforms.buffer, offset: uniforms.offset, index: VertexBufferIndex.MaterialUniforms.rawValue)
            renderEncoder.setFragmentBuffer(uniforms.buffer, offset: uniforms.offset, index: FragmentBufferIndex.MaterialUniforms.rawValue)
        }
    }
    
    open func bind(_ renderEncoder: MTLRenderCommandEncoder) {
        bindUniforms(renderEncoder)
        onBind?(renderEncoder)
    }
    
    public func set(_ name: String, _ value: Float) {
        if let param = parameters.paramsMap[name], let p = param as? FloatParameter {
            p.value = value
        }
    }
    
    public func set(_ name: String, _ value: simd_float2) {
        if let param = parameters.paramsMap[name], let p = param as? Float2Parameter {
            p.value = value
        }
    }
    
    public func set(_ name: String, _ value: simd_float3) {
        if let param = parameters.paramsMap[name], let p = param as? Float3Parameter {
            p.value = value
        }
    }
    
    public func set(_ name: String, _ value: simd_float4) {
        if let param = parameters.paramsMap[name], let p = param as? Float4Parameter {
            p.value = value
        }
    }
    
    public func set(_ name: String, _ value: Int) {
        if let param = parameters.paramsMap[name], let p = param as? IntParameter {
            p.value = value
        }
    }
    
    public func set(_ name: String, _ value: simd_int2) {
        if let param = parameters.paramsMap[name], let p = param as? Int2Parameter {
            p.value = value
        }
    }
    
    public func set(_ name: String, _ value: simd_int3) {
        if let param = parameters.paramsMap[name], let p = param as? Int3Parameter {
            p.value = value
        }
    }
    
    public func set(_ name: String, _ value: simd_int4) {
        if let param = parameters.paramsMap[name], let p = param as? Int4Parameter {
            p.value = value
        }
    }
    
    public func set(_ name: String, _ value: Bool) {
        if let param = parameters.paramsMap[name], let p = param as? BoolParameter {
            p.value = value
        }
    }
    
    deinit {}
}
