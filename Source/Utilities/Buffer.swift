//
//  Buffer.swift
//  Satin
//
//  Created by Reza Ali on 4/22/20.
//

import Metal

open class Buffer {
    public var buffer: MTLBuffer!
    public weak var parameters: ParameterGroup!

    init() {}

    public init(context: Context, parameters: ParameterGroup, options: MTLResourceOptions = [.storageModeShared]) {
        self.parameters = parameters
        setupBuffer(context: context, options: options)
    }

    func setupBuffer(context: Context, options: MTLResourceOptions) {
        guard let buffer = context.device.makeBuffer(length: parameters.size, options: options) else { fatalError("Unable to create Buffer") }
        buffer.label = parameters.label
        self.buffer = buffer
        update()
    }

    public func update() {
        update(UnsafeMutableRawPointer(buffer.contents()))
    }

    func update(_ content: UnsafeMutableRawPointer) {
        var pointer = content
        var pointerOffset = 0
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
            else if param is UInt32Parameter {
                let intParam = param as! UInt32Parameter
                pointer.storeBytes(of: intParam.value, as: UInt32.self)
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
            else if param is PackedFloat3Parameter {
                let floatParam = param as! PackedFloat3Parameter
                let fsize = MemoryLayout<Float>.size
                pointer.storeBytes(of: floatParam.x, as: Float.self)
                pointer += fsize
                pointer.storeBytes(of: floatParam.y, as: Float.self)
                pointer += fsize
                pointer.storeBytes(of: floatParam.z, as: Float.self)
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

    public func sync() {
        sync(UnsafeMutableRawPointer(buffer.contents()))
    }

    func sync(_ content: UnsafeMutableRawPointer) {
        var pointer = content
        var pointerOffset = 0
        for param in parameters.params {
            let size = param.size
            let alignment = param.alignment
            let rem = pointerOffset % alignment
            if rem > 0 {
                let offset = alignment - rem
                pointer += offset
                pointerOffset += offset
            }

            if param is BoolParameter {
                let boolParam = param as! BoolParameter
                boolParam.value = pointer.bindMemory(to: Bool.self, capacity: 1).pointee
                pointer += size
            }
            else if param is UInt32Parameter {
                let intParam = param as! UInt32Parameter
                intParam.value = pointer.bindMemory(to: UInt32.self, capacity: 1).pointee
                pointer += size
            }
            else if param is IntParameter {
                let intParam = param as! IntParameter
                intParam.value = Int(pointer.bindMemory(to: Int32.self, capacity: 1).pointee)
                pointer += size
            }
            else if param is Int2Parameter {
                let intParam = param as! Int2Parameter
                let isize = MemoryLayout<Int32>.size
                intParam.x = pointer.bindMemory(to: Int32.self, capacity: 1).pointee
                pointer += isize
                intParam.y = pointer.bindMemory(to: Int32.self, capacity: 1).pointee
                pointer += isize
            }
            else if param is Int3Parameter {
                let intParam = param as! Int3Parameter
                let isize = MemoryLayout<Int32>.size
                intParam.x = pointer.bindMemory(to: Int32.self, capacity: 1).pointee
                pointer += isize
                intParam.y = pointer.bindMemory(to: Int32.self, capacity: 1).pointee
                pointer += isize
                intParam.z = pointer.bindMemory(to: Int32.self, capacity: 1).pointee
                pointer += isize
                // because alignment is 16 not 12
                pointer += isize
            }
            else if param is Int4Parameter {
                let intParam = param as! Int4Parameter
                let isize = MemoryLayout<Int32>.size
                intParam.x = pointer.bindMemory(to: Int32.self, capacity: 1).pointee
                pointer += isize
                intParam.y = pointer.bindMemory(to: Int32.self, capacity: 1).pointee
                pointer += isize
                intParam.z = pointer.bindMemory(to: Int32.self, capacity: 1).pointee
                pointer += isize
                intParam.w = pointer.bindMemory(to: Int32.self, capacity: 1).pointee
                pointer += isize
            }
            else if param is FloatParameter {
                let floatParam = param as! FloatParameter
                floatParam.value = pointer.bindMemory(to: Float.self, capacity: 1).pointee
                pointer += size
            }
            else if param is Float2Parameter {
                let floatParam = param as! Float2Parameter
                let fsize = MemoryLayout<Float>.size
                floatParam.x = pointer.bindMemory(to: Float.self, capacity: 1).pointee
                pointer += fsize
                floatParam.y = pointer.bindMemory(to: Float.self, capacity: 1).pointee
                pointer += fsize
            }
            else if param is Float3Parameter {
                let floatParam = param as! Float3Parameter
                let fsize = MemoryLayout<Float>.size
                floatParam.x = pointer.bindMemory(to: Float.self, capacity: 1).pointee
                pointer += fsize
                floatParam.y = pointer.bindMemory(to: Float.self, capacity: 1).pointee
                pointer += fsize
                floatParam.z = pointer.bindMemory(to: Float.self, capacity: 1).pointee
                pointer += fsize
                // because alignment is 16 not 12
                pointer += fsize
            }
            else if param is PackedFloat3Parameter {
                let floatParam = param as! PackedFloat3Parameter
                let fsize = MemoryLayout<Float>.size
                floatParam.x = pointer.bindMemory(to: Float.self, capacity: 1).pointee
                pointer += fsize
                floatParam.y = pointer.bindMemory(to: Float.self, capacity: 1).pointee
                pointer += fsize
                floatParam.z = pointer.bindMemory(to: Float.self, capacity: 1).pointee
                pointer += fsize
            }
            else if param is Float4Parameter {
                let floatParam = param as! Float4Parameter
                let fsize = MemoryLayout<Float>.size
                floatParam.x = pointer.bindMemory(to: Float.self, capacity: 1).pointee
                pointer += fsize
                floatParam.y = pointer.bindMemory(to: Float.self, capacity: 1).pointee
                pointer += fsize
                floatParam.z = pointer.bindMemory(to: Float.self, capacity: 1).pointee
                pointer += fsize
                floatParam.w = pointer.bindMemory(to: Float.self, capacity: 1).pointee
                pointer += fsize
            }
            pointerOffset += size
        }
    }
}
