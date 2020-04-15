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
        self.alignedSize = ((parameters.size + 255) / 256) * 256
        setupBuffer(context: context)
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
    
    public func reset()
    {
        index = -1
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
                let size = param.size
                let alignment = param.alignment
                // Set proper alignment
                let rem = pointerOffset % alignment
                if rem > 0 {
                    let offset = alignment - rem
                    pointer += offset
                    pointerOffset += offset
                }
                
                if param is BoolParameter {
                    let boolParam = param as! BoolParameter
                    pointer.storeBytes(of: boolParam.value, as: Bool.self)
                    pointer += size
                }
                else if param is IntParameter {
                    let intParam = param as! IntParameter
                    pointer.storeBytes(of: Int32(intParam.value), as: Int32.self)
                    pointer += size
                }
                else if param is Int2Parameter {
                    let intParam = param as! Int2Parameter
                    let isize = MemoryLayout<Int32>.size
                    pointer.storeBytes(of: intParam.x, as: Int32.self)
                    pointer += isize
                    pointer.storeBytes(of: intParam.y, as: Int32.self)
                    pointer += isize
                }
                else if param is Int3Parameter {
                    let intParam = param as! Int3Parameter
                    let isize = MemoryLayout<Int32>.size
                    pointer.storeBytes(of: intParam.x, as: Int32.self)
                    pointer += isize
                    pointer.storeBytes(of: intParam.y, as: Int32.self)
                    pointer += isize
                    pointer.storeBytes(of: intParam.z, as: Int32.self)
                    pointer += isize
                    // because alignment is 16 not 12
                    pointer += isize
                }
                else if param is Int4Parameter {
                    let intParam = param as! Int4Parameter
                    let isize = MemoryLayout<Int32>.size
                    pointer.storeBytes(of: intParam.x, as: Int32.self)
                    pointer += isize
                    pointer.storeBytes(of: intParam.y, as: Int32.self)
                    pointer += isize
                    pointer.storeBytes(of: intParam.z, as: Int32.self)
                    pointer += isize
                    pointer.storeBytes(of: intParam.w, as: Int32.self)
                    pointer += isize
                }
                else if param is FloatParameter {
                    let floatParam = param as! FloatParameter
                    pointer.storeBytes(of: floatParam.value, as: Float.self)
                    pointer += size
                }
                else if param is Float2Parameter {
                    let floatParam = param as! Float2Parameter
                    let fsize = MemoryLayout<Float>.size
                    pointer.storeBytes(of: floatParam.x, as: Float.self)
                    pointer += fsize
                    pointer.storeBytes(of: floatParam.y, as: Float.self)
                    pointer += fsize
                }
                else if param is Float3Parameter {
                    let floatParam = param as! Float3Parameter
                    let fsize = MemoryLayout<Float>.size
                    pointer.storeBytes(of: floatParam.x, as: Float.self)
                    pointer += fsize
                    pointer.storeBytes(of: floatParam.y, as: Float.self)
                    pointer += fsize
                    pointer.storeBytes(of: floatParam.z, as: Float.self)
                    pointer += fsize
                    // because alignment is 16 not 12
                    pointer += fsize
                }
                else if param is Float4Parameter {
                    let floatParam = param as! Float4Parameter
                    let fsize = MemoryLayout<Float>.size
                    pointer.storeBytes(of: floatParam.x, as: Float.self)
                    pointer += fsize
                    pointer.storeBytes(of: floatParam.y, as: Float.self)
                    pointer += fsize
                    pointer.storeBytes(of: floatParam.z, as: Float.self)
                    pointer += fsize
                    pointer.storeBytes(of: floatParam.w, as: Float.self)
                    pointer += fsize
                }
                pointerOffset += size
            }
        }
    }
}
