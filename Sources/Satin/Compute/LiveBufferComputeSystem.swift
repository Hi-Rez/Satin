//
//  LiveBufferComputeSystem.swift
//  Pods
//
//  Created by Reza Ali on 10/26/21.
//

import Metal
import simd

open class LiveBufferComputeSystem: BufferComputeSystem {
    public var compiler = MetalFileCompiler()
    public var source: String?
    public var instance: String = ""
    public var pipelineURL: URL
    
    public var uniforms: UniformBuffer?
    public var parameters: ParameterGroup?
    
    override public var count: Int {
        didSet {
            updateSize()
        }
    }
    
    var prefixLabel: String {
        var prefix = String(describing: type(of: self)).replacingOccurrences(of: "BufferComputeSystem", with: "")
        prefix = prefix.replacingOccurrences(of: "ComputeSystem", with: "")
        if let bundleName = Bundle(for: type(of: self)).displayName, bundleName != prefix {
            prefix = prefix.replacingOccurrences(of: bundleName, with: "")
        }
        prefix = prefix.replacingOccurrences(of: ".", with: "")
        return prefix
    }
    
    public init(device: MTLDevice,
                pipelineURL: URL,
                instance: String = "",
                count: Int,
                feedback: Bool = false)
    {
        self.pipelineURL = pipelineURL
        self.instance = instance
        super.init(device: device, resetPipeline: nil, updatePipeline: nil, params: [], count: count, feedback: feedback)
        self.source = compileSource()
        setup()
    }
    
    public init(device: MTLDevice,
                pipelinesURL: URL,
                instance: String = "",
                count: Int,
                feedback: Bool = false)
    {
        self.pipelineURL = pipelinesURL
        self.instance = instance
        super.init(device: device, resetPipeline: nil, updatePipeline: nil, params: [], count: count, feedback: feedback)
        self.pipelineURL = pipelineURL.appendingPathComponent(prefixLabel).appendingPathComponent("Shaders.metal")
        self.source = compileSource()
        setup()
    }
    
    override open func setup() {
        super.setup()
        setupCompiler()
        setupPipelines()
        updateSize()
    }

    open func setupCompiler() {
        compiler.onUpdate = { [weak self] in
            guard let self = self else { return }
            self.source = nil
            self.source = self.compileSource()
            self.setupPipelines()
        }
    }
    
    open func setupPipelines() {
        guard let source = source else { return }
        guard let library = setupLibrary(source) else { return }
        setupPipelines(library)
    }
    
    override public func update(_ commandBuffer: MTLCommandBuffer) {
        updateUniforms()
        super.update(commandBuffer)
    }
    
    open func inject(source: inout String) {
        injectConstants(source: &source)
    }

    func compileSource() -> String? {
        if let source = source {
            return source
        }
        else {
            do {
                guard let satinURL = getPipelinesSatinUrl() else { return nil }
                let includesURL = satinURL.appendingPathComponent("Includes.metal")
                
                var source = try compiler.parse(includesURL)
                let shaderSource = try compiler.parse(pipelineURL)
                inject(source: &source)
                source += shaderSource
                
                if let buffer = parseStruct(source: source, key: "\(prefixLabel.titleCase)") {
                    setParams([buffer])
                }
                
                if let params = parseParameters(source: source, key: "\(prefixLabel.titleCase)Uniforms") {
                    params.label = prefixLabel.titleCase + (instance.isEmpty ? "" : " \(instance)")
                    if let parameters = parameters {
                        parameters.setFrom(params)
                    }
                    else {
                        parameters = params
                    }
                        
                    uniforms = UniformBuffer(device: device, parameters: parameters!)
                }
                                
                self.source = source
                return source
            }
            catch {
                print("\(prefixLabel) BufferComputeError: \(error.localizedDescription)")
            }
            return nil
        }
    }
    
    func setupLibrary(_ source: String) -> MTLLibrary? {
        do {
            return try device.makeLibrary(source: source, options: .none)
        }
        catch {
            print("\(prefixLabel) BufferComputeError: \(error.localizedDescription)")
        }
        return nil
    }
    
    func setupPipelines(_ library: MTLLibrary) {
        do {
            resetPipeline = try makeComputePipeline(library: library, kernel: "\(prefixLabel.camelCase)Reset")
            updatePipeline = try makeComputePipeline(library: library, kernel: "\(prefixLabel.camelCase)Update")
            reset()
        }
        catch {
            print("\(prefixLabel) BufferComputeError: \(error.localizedDescription)")
        }
    }
    
    func updateSize() {
        guard let parameters = parameters else { return }
        parameters.set("Count", count)
    }
    
    func updateUniforms() {
        guard let uniforms = uniforms else { return }
        uniforms.update()
    }

    override public func dispatch(_ computeEncoder: MTLComputeCommandEncoder, _ pipeline: MTLComputePipelineState) {
        bindUniforms(computeEncoder)
        super.dispatch(computeEncoder, pipeline)
    }
    
    open func bindUniforms(_ computeEncoder: MTLComputeCommandEncoder) {
        guard let uniforms = uniforms else { return }
        computeEncoder.setBuffer(uniforms.buffer, offset: uniforms.offset, index: ComputeBufferIndex.Uniforms.rawValue)
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
        guard let parameters = parameters else { return }
        parameters.set(name, value)
    }
    
    public func set(_ name: String, _ value: simd_float2) {
        guard let parameters = parameters else { return }
        parameters.set(name, value)
    }
    
    public func set(_ name: String, _ value: simd_float3) {
        guard let parameters = parameters else { return }
        parameters.set(name, value)
    }
    
    public func set(_ name: String, _ value: simd_float4) {
        guard let parameters = parameters else { return }
        parameters.set(name, value)
    }
    
    public func set(_ name: String, _ value: Int) {
        guard let parameters = parameters else { return }
        parameters.set(name, value)
    }
    
    public func set(_ name: String, _ value: simd_int2) {
        guard let parameters = parameters else { return }
        parameters.set(name, value)
    }
    
    public func set(_ name: String, _ value: simd_int3) {
        guard let parameters = parameters else { return }
        parameters.set(name, value)
    }
    
    public func set(_ name: String, _ value: simd_int4) {
        guard let parameters = parameters else { return }
        parameters.set(name, value)
    }
    
    public func set(_ name: String, _ value: Bool) {
        guard let parameters = parameters else { return }
        parameters.set(name, value)
    }
    
    public func get(_ name: String) -> Parameter? {
        guard let parameters = parameters else { return nil }
        return parameters.get(name)
    }
}
