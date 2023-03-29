//
//  LiveTextureComputeSystem.swift
//  Satin
//
//  Created by Reza Ali on 11/12/21.
//

import Foundation
import Metal
import simd

open class LiveTextureComputeSystem: TextureComputeSystem {
    public var compiler = MetalFileCompiler()
    public var source: String?
    public var pipelineURL: URL

    public var uniforms: UniformBuffer?
    public var parameters: ParameterGroup?

    override public var textureDescriptors: [MTLTextureDescriptor] {
        didSet {
            updateSize()
        }
    }

    open var defines: [String: String] {
        var results = [String: String]()
        #if os(iOS)
        results["MOBILE"] = "true"
        #endif
        return results
    }

    public init(device: MTLDevice,
                textureDescriptors: [MTLTextureDescriptor],
                pipelineURL: URL,
                feedback: Bool = false)
    {
        self.pipelineURL = pipelineURL

        super.init(device: device, textureDescriptors: textureDescriptors, updatePipeline: nil, resetPipeline: nil, feedback: feedback)

        label = prefixLabel
        source = compileSource()

        setup()
    }

    public init(device: MTLDevice,
                textureDescriptors: [MTLTextureDescriptor],
                pipelinesURL: URL,
                feedback: Bool = false)
    {
        pipelineURL = pipelinesURL

        super.init(device: device, textureDescriptors: textureDescriptors, updatePipeline: nil, resetPipeline: nil, feedback: feedback)

        pipelineURL = pipelineURL.appendingPathComponent(prefixLabel).appendingPathComponent("Shaders.metal")
        source = compileSource()
        setup()
    }

    override open func setup() {
        label = prefixLabel + " Texture Compute Encoder"
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
            self.delegate?.updated(textureComputeSystem: self)
        }
    }

    open func setupPipelines() {
        guard let source = source else { return }
        guard let library = setupLibrary(source) else { return }
        setupPipelines(library)
    }

    override open func update() {
        updateUniforms()
        super.update()
    }

    override open func update(_ commandBuffer: MTLCommandBuffer) {
        super.update(commandBuffer)
    }

    open func inject(source: inout String) {
        injectDefines(source: &source, defines: defines)
        injectConstants(source: &source)
    }

    func compileSource() -> String? {
        if let source = source {
            return source
        } else {
            do {
                guard let satinURL = getPipelinesSatinURL() else { return nil }
                let includesURL = satinURL.appendingPathComponent("Includes.metal")

                var source = try compiler.parse(includesURL)
                let shaderSource = try compiler.parse(pipelineURL)
                inject(source: &source)
                source += shaderSource

                if let params = parseParameters(source: source, key: "\(prefixLabel.titleCase.replacingOccurrences(of: " ", with: ""))Uniforms") {
                    params.label = prefixLabel.titleCase
                    if let parameters = parameters {
                        parameters.setFrom(params)
                    } else {
                        parameters = params
                    }

                    uniforms = UniformBuffer(device: device, parameters: parameters!)
                }

                self.source = source
                return source
            } catch {
                print("\(prefixLabel) TextureComputeError: Failed to compile source - \(error.localizedDescription)")
            }
            return nil
        }
    }

    func setupLibrary(_ source: String) -> MTLLibrary? {
        do {
            return try device.makeLibrary(source: source, options: .none)
        } catch {
            print("\(prefixLabel) TextureComputeError: Failed to setup MTLLibrary - \(error.localizedDescription)")
        }
        return nil
    }

    open func setupPipelines(_ library: MTLLibrary) {
        do {
            resetPipeline = try createResetPipeline(library: library, kernel: "\(prefixLabel.camelCase)Reset")
            updatePipeline = try createUpdatePipeline(library: library, kernel: "\(prefixLabel.camelCase)Update")
            reset()
        } catch {
            print("\(prefixLabel) TextureComputeError: Failed to setup Pipelines - \(error.localizedDescription)")
        }
    }

    open func createResetPipeline(library: MTLLibrary, kernel: String) throws -> MTLComputePipelineState? {
        guard let kernelFunction = library.makeFunction(name: kernel) else { return nil }
        let descriptor = MTLComputePipelineDescriptor()
        descriptor.computeFunction = kernelFunction
        descriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
        let result = try device.makeComputePipelineState(descriptor: descriptor, options: [])
        return result.0
    }

    open func createUpdatePipeline(library: MTLLibrary, kernel: String) throws -> MTLComputePipelineState? {
        guard let kernelFunction = library.makeFunction(name: kernel) else { return nil }
        let descriptor = MTLComputePipelineDescriptor()
        descriptor.computeFunction = kernelFunction
        descriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
        let result = try device.makeComputePipelineState(descriptor: descriptor, options: [])
        return result.0
    }

    func updateSize() {
        guard let parameters = parameters, let txDsx = textureDescriptors.first else { return }
        if txDsx.depth > 1 {
            parameters.set("Size", [txDsx.width, txDsx.height, txDsx.depth])
        } else if txDsx.height > 1 {
            parameters.set("Size", [txDsx.width, txDsx.height])
        } else if txDsx.width > 1 {
            parameters.set("Size", txDsx.width)
        }
    }

    func updateUniforms() {
        guard let uniforms = uniforms else { return }
        uniforms.update()
    }

    override open func bind(_ computeEncoder: MTLComputeCommandEncoder) -> Int {
        bindUniforms(computeEncoder)
        return super.bind(computeEncoder)
    }

    open func bindUniforms(_ computeEncoder: MTLComputeCommandEncoder) {
        guard let uniforms = uniforms else { return }
        computeEncoder.setBuffer(uniforms.buffer, offset: uniforms.offset, index: ComputeBufferIndex.Uniforms.rawValue)
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

    public func set(_ name: String, _ value: simd_float2x2) {
        guard let parameters = parameters else { return }
        parameters.set(name, value)
    }

    public func set(_ name: String, _ value: simd_float3x3) {
        guard let parameters = parameters else { return }
        parameters.set(name, value)
    }

    public func set(_ name: String, _ value: simd_float4x4) {
        guard let parameters = parameters else { return }
        parameters.set(name, value)
    }

    public func get(_ name: String) -> Parameter? {
        guard let parameters = parameters else { return nil }
        return parameters.get(name)
    }
}
