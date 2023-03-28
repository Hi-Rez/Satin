//
//  UniformBuffer.swift
//  Satin
//
//  Created by Reza Ali on 11/3/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Foundation
import Metal
import simd

open class UniformBuffer {
    public private(set) var parameters: ParameterGroup
    public private(set) var buffer: MTLBuffer!
    public private(set) var index: Int = -1
    public private(set) var offset = 0

    public init(device: MTLDevice, parameters: ParameterGroup, options: MTLResourceOptions = [.cpuCacheModeWriteCombined]) {
        self.parameters = parameters

        let length = alignedSize * Satin.maxBuffersInFlight

        guard let buffer = device.makeBuffer(length: length, options: options) else { fatalError("Unable to create Uniform Buffer") }
        buffer.label = parameters.label
        self.buffer = buffer

        update()
    }

    public func update() {
        index = (index + 1) % maxBuffersInFlight
        offset = alignedSize * index
        (buffer.contents() + offset).copyMemory(from: parameters.data, byteCount: parameters.size)
    }

    public func reset() {
        index = -1
    }

    private var alignedSize: Int {
        align(size: parameters.size)
    }

    private func align(size: Int) -> Int {
        return ((size + 255) / 256) * 256
    }
}
