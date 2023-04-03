//
//  TessellationComputeSystem.swift
//  Tesselation
//
//  Created by Reza Ali on 4/2/23.
//  Copyright © 2023 Reza Ali. All rights reserved.
//

import Foundation
import Metal
import Satin

class TessellationComputeSystem<T>: Tessellator {
    open var defines: [String: NSObject] {
        var results = [String: NSObject]()
#if os(iOS)
        results["MOBILE"] = NSString(string: "true")
#endif
        return results
    }

    lazy var label = prefixLabel + " Compute System"

    private var prefixLabel: String {
        var className = String(describing: type(of: self))
        do {
            let regex = try NSRegularExpression(pattern: "(<.+>)", options: NSRegularExpression.Options.caseInsensitive)
            let range = NSMakeRange(0, className.count)
            className = regex.stringByReplacingMatches(in: className, range: range, withTemplate: "")
        } catch {
            print(error.localizedDescription)
        }
        var prefix = className.replacingOccurrences(of: "ComputeSystem", with: "")
        if let bundleName = Bundle(for: type(of: self)).displayName, bundleName != prefix {
            prefix = prefix.replacingOccurrences(of: bundleName, with: "")
        }
        prefix = prefix.replacingOccurrences(of: ".", with: "")
        return prefix
    }

    var live: Bool = false {
        didSet {
            compiler.watch = live
        }
    }

    public internal(set) var buffer: MTLBuffer?

    unowned let device: MTLDevice
    let pipelineURL: URL

    public internal(set) var pipeline: MTLComputePipelineState?

    var _parameters = ParameterGroup()
    public var parameters: ParameterGroup? {
        _parameters
    }

    private var uniforms: UniformBuffer?
    private let compiler: MetalFileCompiler

    public var threadPerGrid: MTLSize {
        MTLSize(width: geometry!.patchCount, height: 1, depth: 1)
    }

    public var threadsPerThreadgroup: MTLSize {
        MTLSize(width: pipeline!.threadExecutionWidth, height: 1, depth: 1)
    }

    public internal(set) var source: String?

    private var functionName: String = ""
    private var uniformsKey: String = ""

    unowned var geometry: TessellatedGeometry? {
        didSet {
            if oldValue != geometry, let geometry = geometry {
                setupBuffer(geometry)
            }
        }
    }

    init(device: MTLDevice,
         pipelineURL: URL,
         functionName: String? = nil,
         uniformsKey: String? = nil,
         live: Bool = false)
    {
        self.device = device
        self.pipelineURL = pipelineURL
        self.live = live

        self.compiler = MetalFileCompiler(watch: live)
        compiler.onUpdate = { [weak self] in
            guard let self = self else { return }
            self.setupSource()
            self.setupPipeline()
        }

        self.functionName = functionName ?? prefixLabel
        self.uniformsKey = prefixLabel.titleCase + "Uniforms"

        setupSource()
    }

    func setup(_ geometry: TessellatedGeometry) {
        self.geometry = geometry
        setupPipeline()
        setupBuffer(geometry)
    }

    // MARK: - Setup Buffer

    open func setupBuffer(_ geometry: TessellatedGeometry) {
        buffer = device.makeBuffer(
            length: MemoryLayout<T>.stride * geometry.patchCount,
            options: [.storageModePrivate]
        )
    }

    // MARK: - Setup Source

    open func setupSource() {
        source = nil
        source = compileSource()
    }

    open func inject(source: inout String) {

    }

    open func compileSource() -> String? {
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

                if let params = parseParameters(source: source, key: uniformsKey) {
                    params.label = prefixLabel.titleCase
                    _parameters.setFrom(params)
                    uniforms = UniformBuffer(device: device, parameters: _parameters)
                }

                self.source = source
                return source
            } catch {
                print("\(prefixLabel)ComputeSystem: \(error.localizedDescription)")
            }
            return nil
        }
    }

    func setupLibrary(_ source: String) -> MTLLibrary? {
        do {
            let compileOptions = MTLCompileOptions()
            compileOptions.preprocessorMacros = defines
            return try device.makeLibrary(source: source, options: compileOptions)
        } catch {
            print("\(prefixLabel)ComputeSystem: \(error.localizedDescription)")
        }
        return nil
    }

    open func setupPipeline() {
        guard let source = source else { return }
        guard let library = setupLibrary(source) else { return }
        setupPipeline(library)
    }

    open func setupPipeline(_ library: MTLLibrary) {
        do {
            pipeline = try createPipeline(library: library, functionName: functionName)
        } catch {
            print("\(prefixLabel)ComputeSystem: \(error.localizedDescription)")
        }
    }

    open func createPipeline(library: MTLLibrary, functionName: String) throws -> MTLComputePipelineState? {
        guard let computeFunction = library.makeFunction(name: functionName) else { return nil }
        let descriptor = MTLComputePipelineDescriptor()
        descriptor.computeFunction = computeFunction
        descriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
        let result = try device.makeComputePipelineState(descriptor: descriptor, options: [])
        return result.0
    }

    open func update(commandBuffer: MTLCommandBuffer) {
        guard let buffer = buffer, let uniforms = uniforms, let pipeline = pipeline else { return }
        uniforms.update()

        commandBuffer.pushDebugGroup(label)
        let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()!
        computeCommandEncoder.label = label
        computeCommandEncoder.setComputePipelineState(pipeline)
        computeCommandEncoder.setBuffer(buffer, offset: 0, index: 0)
        computeCommandEncoder.setBuffer(uniforms.buffer, offset: uniforms.offset, index: 1)
        computeCommandEncoder.dispatchThreads(threadPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        computeCommandEncoder.endEncoding()
        commandBuffer.popDebugGroup()
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
        _parameters.set(name, value)
    }

    public func set(_ name: String, _ value: simd_float2) {
        _parameters.set(name, value)
    }

    public func set(_ name: String, _ value: simd_float3) {
        _parameters.set(name, value)
    }

    public func set(_ name: String, _ value: simd_float4) {
        _parameters.set(name, value)
    }

    public func set(_ name: String, _ value: simd_float2x2) {
        _parameters.set(name, value)
    }

    public func set(_ name: String, _ value: simd_float3x3) {
        _parameters.set(name, value)
    }

    public func set(_ name: String, _ value: simd_float4x4) {
        _parameters.set(name, value)
    }

    public func set(_ name: String, _ value: Int) {
        _parameters.set(name, value)
    }

    public func set(_ name: String, _ value: simd_int2) {
        _parameters.set(name, value)
    }

    public func set(_ name: String, _ value: simd_int3) {
        _parameters.set(name, value)
    }

    public func set(_ name: String, _ value: simd_int4) {
        _parameters.set(name, value)
    }

    public func set(_ name: String, _ value: Bool) {
        _parameters.set(name, value)
    }

    public func get(_ name: String) -> Parameter? {
        return _parameters.get(name)
    }
}
