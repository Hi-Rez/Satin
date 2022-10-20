//
//  InstanceMatrixUniformBuffer.swift
//  
//
//  Created by Reza Ali on 10/19/22.
//

import Metal
import simd

open class InstanceMatrixUniformBuffer {
    public private(set) var buffer: MTLBuffer!
    public private(set) var offset: Int = 0
    public private(set) var index: Int = 0
    public private(set) var count: Int
    
    private var uniforms: UnsafeMutablePointer<InstanceMatrixUniforms>!
        
    public init(device: MTLDevice, count: Int) {
        self.count = count
        let length = alignedSize * Satin.maxBuffersInFlight
        guard let buffer = device.makeBuffer(length: length, options: [MTLResourceOptions.storageModeShared]) else { fatalError("Couldn't not create Instance Matrix Uniform Buffer") }
        self.buffer = buffer
        self.buffer.label = "Instance Matrix Uniforms"
        self.uniforms = UnsafeMutableRawPointer(buffer.contents()).bindMemory(to: InstanceMatrixUniforms.self, capacity: count)
    }
    
    public func update(data: inout [InstanceMatrixUniforms]) {
        buffer.contents().copyMemory(from: &data, byteCount: count * MemoryLayout<InstanceMatrixUniforms>.stride)
    }
    
    public func update() {
        index = (index + 1) % maxBuffersInFlight
        offset = alignedSize * index
        uniforms = UnsafeMutableRawPointer(buffer.contents() + offset).bindMemory(to: InstanceMatrixUniforms.self, capacity: count)
    }
    
    private var alignedSize: Int {
        align(size: MemoryLayout<InstanceMatrixUniforms>.stride * count)
    }
    
    private func align(size: Int) -> Int {
        return ((size + 255) / 256) * 256
    }
}
