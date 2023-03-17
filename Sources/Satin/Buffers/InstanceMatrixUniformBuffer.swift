//
//  InstanceMatrixUniformBuffer.swift
//  Satin
//
//  Created by Reza Ali on 10/19/22.
//

import Metal
import simd

open class InstanceMatrixUniformBuffer {
    public private(set) var buffer: MTLBuffer!
    public private(set) var offset = 0
    public private(set) var index = 0
    public private(set) var count: Int

    public init(device: MTLDevice, count: Int) {
        self.count = count
        let length = alignedSize * Satin.maxBuffersInFlight
        guard let buffer = device.makeBuffer(length: length, options: [MTLResourceOptions.cpuCacheModeWriteCombined]) else { fatalError("Couldn't not create Instance Matrix Uniform Buffer") }
        self.buffer = buffer
        self.buffer.label = "Instance Matrix Uniforms"
    }

    public func update(data: inout [InstanceMatrixUniforms]) {
        index = (index + 1) % maxBuffersInFlight
        offset = alignedSize * index
        (buffer.contents() + offset).copyMemory(from: &data, byteCount: count * MemoryLayout<InstanceMatrixUniforms>.size)
    }

    private var alignedSize: Int {
        align(size: MemoryLayout<InstanceMatrixUniforms>.size * count)
    }

    private func align(size: Int) -> Int {
        return ((size + 255) / 256) * 256
    }
}
