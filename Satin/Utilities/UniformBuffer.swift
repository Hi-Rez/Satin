//
//  BufferMaker.swift
//  Satin
//
//  Created by Reza Ali on 11/3/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation
import Metal
import simd

open class UniformBuffer {
    public var index: Int = 0
    public var offset: Int = 0
    public var alignedSize: Int = 0
    public var buffer: MTLBuffer!
    public weak var parameters: ParameterGroup?
    
    public init(context: Context, parameters: ParameterGroup) {
        self.parameters = parameters
        calculateAlignmentSize()
        setupBuffer(context: context)
    }
    
    func calculateAlignmentSize() {
        if let parameters = self.parameters {
            var pointerOffset: Int = 0
            for param in parameters.params {
                var size: Int = 0
                var alignment: Int = 0
                if param is BoolParameter {
                    size = MemoryLayout<Bool>.size
                    alignment = MemoryLayout<Bool>.alignment
                }
                else if param is IntParameter {
                    size = MemoryLayout<Int32>.size
                    alignment = MemoryLayout<Int32>.alignment
                }
                else if param is FloatParameter {
                    size = MemoryLayout<Float>.size
                    alignment = MemoryLayout<Float>.alignment
                }
                else if param is Float2Parameter {
                    size = MemoryLayout<simd_float2>.size
                    alignment = MemoryLayout<simd_float2>.alignment
                }
                else if param is Float3Parameter {
                    size = MemoryLayout<simd_float3>.size
                    alignment = MemoryLayout<simd_float3>.alignment
                }
                else if param is Float4Parameter {
                    size = MemoryLayout<simd_float4>.size
                    alignment = MemoryLayout<simd_float4>.alignment
                }
                let rem = pointerOffset % alignment
                if rem > 0 {
                    let offset = alignment - rem
                    pointerOffset += offset
                }
                pointerOffset += size
            }
            alignedSize = ((pointerOffset + 255) / 256) * 256
        }
    }
    
    func setupBuffer(context: Context) {
        if let parameters = self.parameters, alignedSize > 0 {
            guard let buffer = context.device.makeBuffer(length: alignedSize * maxBuffersInFlight, options: [.storageModeShared]) else { return }
            buffer.label = parameters.label
            self.buffer = buffer
        }
    }
    
    public func update() {
        updateOffset()
        updateBuffer()
    }
    
    func updateOffset() {
        index = (index + 1) % maxBuffersInFlight
        offset = alignedSize * index
    }
    
    func updateBuffer() {
        if buffer != nil, let parameters = self.parameters {
            var pointer = UnsafeMutableRawPointer(buffer.contents() + offset)
            var pointerOffset = offset
            for param in parameters.params {
                if param is BoolParameter {
                    let boolParam = param as! BoolParameter
                    let size = MemoryLayout<Bool>.size
                    let alignment = MemoryLayout<Bool>.alignment
                    let rem = pointerOffset % alignment
                    
                    if rem > 0 {
                        let offset = alignment - rem
                        pointer += offset
                        pointerOffset += offset
                    }
                    
                    pointer.storeBytes(of: boolParam.value, as: Bool.self)
                    pointer += size
                    pointerOffset += size
                }
                else if param is IntParameter {
                    let intParam = param as! IntParameter
                    let size = MemoryLayout<Int32>.size
                    let alignment = MemoryLayout<Int32>.alignment
                    let rem = pointerOffset % alignment
                    
                    if rem > 0 {
                        let offset = alignment - rem
                        pointer += offset
                        pointerOffset += offset
                    }
                    
                    pointer.storeBytes(of: Int32(intParam.value), as: Int32.self)
                    pointer += size
                    pointerOffset += size
                }
                else if param is FloatParameter {
                    let floatParam = param as! FloatParameter
                    let size = MemoryLayout<Float>.size
                    let alignment = MemoryLayout<Float>.alignment
                    let rem = pointerOffset % alignment
                    
                    if rem > 0 {
                        let offset = alignment - rem
                        pointer += offset
                        pointerOffset += offset
                    }
                    
                    pointer.storeBytes(of: floatParam.value, as: Float.self)
                    pointer += size
                    pointerOffset += size
                }
                else if param is Float2Parameter {
                    let floatParam = param as! Float2Parameter
                    let size = MemoryLayout<simd_float2>.size
                    let alignment = MemoryLayout<simd_float2>.alignment
                    let rem = pointerOffset % alignment
                    
                    if rem > 0 {
                        let offset = alignment - rem
                        pointer += offset
                        pointerOffset += offset
                    }
                    
                    let fsize = MemoryLayout<Float>.size
                    pointer.storeBytes(of: floatParam.x, as: Float.self)
                    pointer += fsize
                    pointer.storeBytes(of: floatParam.y, as: Float.self)
                    pointer += fsize
                    pointerOffset += size
                }
                else if param is Float3Parameter {
                    let floatParam = param as! Float3Parameter
                    let size = MemoryLayout<simd_float3>.size
                    let alignment = MemoryLayout<simd_float3>.alignment
                    let rem = pointerOffset % alignment
                    
                    if rem > 0 {
                        let offset = alignment - rem
                        pointer += offset
                        pointerOffset += offset
                    }
                    
                    let fsize = MemoryLayout<Float>.size
                    pointer.storeBytes(of: floatParam.x, as: Float.self)
                    pointer += fsize
                    pointer.storeBytes(of: floatParam.y, as: Float.self)
                    pointer += fsize
                    pointer.storeBytes(of: floatParam.z, as: Float.self)
                    pointer += fsize
                    // because alignment is 16 not 12
                    pointer += fsize
                    pointerOffset += size
                }
                else if param is Float4Parameter {
                    let floatParam = param as! Float4Parameter
                    let size = MemoryLayout<simd_float4>.size
                    let alignment = MemoryLayout<simd_float4>.alignment
                    let rem = pointerOffset % alignment
                    
                    if rem > 0 {
                        let offset = alignment - rem
                        pointer += offset
                        pointerOffset += offset
                    }
                    
                    let fsize = MemoryLayout<Float>.size
                    pointer.storeBytes(of: floatParam.x, as: Float.self)
                    pointer += fsize
                    pointer.storeBytes(of: floatParam.y, as: Float.self)
                    pointer += fsize
                    pointer.storeBytes(of: floatParam.z, as: Float.self)
                    pointer += fsize
                    pointer.storeBytes(of: floatParam.w, as: Float.self)
                    pointer += fsize
                    pointerOffset += size
                }
            }
        }
    }
}
