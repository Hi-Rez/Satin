//
//  ShadowMaterial.swift
//  Satin
//
//  Created by Reza Ali on 9/30/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation

import Metal
import simd

struct ShadowMaterialUniforms {
    var color: simd_float4
}

open class ShadowMaterial: Material {
    public var color: simd_float4 = simd_make_float4(1.0, 1.0, 1.0, 1.0)
    let alignedUniformsSize = ((MemoryLayout<ShadowMaterialUniforms>.size + 255) / 256) * 256

    var uniformBufferIndex: Int = 0
    var uniformBufferOffset: Int = 0
    var uniforms: UnsafeMutablePointer<ShadowMaterialUniforms>!
    var uniformsBuffer: MTLBuffer!

    public init(_ color: simd_float4) {
        super.init()
        self.color = color
    }

    override func setup() {
        setupPipeline()
        setupUniformsBuffer()
    }

    override func update() {
        updateUniformsBuffer()
        updateUniforms()
        super.update()
    }

    func setupPipeline() {
        guard let context = self.context else { return }
        let metalFileCompiler = MetalFileCompiler()
        if let materialPath = getPipelinesPath("Materials/ShadowMaterial/Shaders.metal") {
            do {
                let source = try metalFileCompiler.parse(URL(fileURLWithPath: materialPath))                
                let library = try context.device.makeLibrary(source: source, options: .none)
                pipeline = try makeShadowRenderPipeline(
                    library: library,
                    vertex: "shadowVertex",
                    label: "Shadow Material",
                    context: context)
            }
            catch {
                print(error)
            }
        }
    }

    func setupUniformsBuffer() {
        guard let context = self.context else { return }
        let device = context.device
        let uniformBufferSize = alignedUniformsSize * Satin.maxBuffersInFlight
        guard let buffer = device.makeBuffer(length: uniformBufferSize, options: [MTLResourceOptions.storageModeShared]) else { return }
        uniformsBuffer = buffer
        uniformsBuffer.label = "Shadow Material Uniforms"
        uniforms = UnsafeMutableRawPointer(uniformsBuffer.contents()).bindMemory(to: ShadowMaterialUniforms.self, capacity: 1)
    }

    func updateUniforms() {
        if uniforms != nil {
            uniforms[0].color = color
        }
    }

    func updateUniformsBuffer() {
        if uniformsBuffer != nil {
            uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight
            uniformBufferOffset = alignedUniformsSize * uniformBufferIndex
            uniforms = UnsafeMutableRawPointer(uniformsBuffer.contents() + uniformBufferOffset).bindMemory(to: ShadowMaterialUniforms.self, capacity: 1)
        }
    }

    open override func bind(_ renderEncoder: MTLRenderCommandEncoder) {
        super.bind(renderEncoder)
    }
}
