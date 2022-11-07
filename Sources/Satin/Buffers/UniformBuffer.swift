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

open class UniformBuffer: Buffer {
    public var index: Int = -1
    public var offset: Int = 0
    public var alignedSize: Int = 0
    
    public init(device: MTLDevice, parameters: ParameterGroup, options: MTLResourceOptions = [.storageModeShared]) {
        super.init()
        self.parameters = parameters
        self.alignedSize = ((parameters.size + 255) / 256) * 256
        setupBuffer(device: device, count: maxBuffersInFlight, options: options)
    }
    
    override func setupBuffer(device: MTLDevice, count: Int, options: MTLResourceOptions) {
        guard alignedSize > 0, let buffer = device.makeBuffer(length: alignedSize * count, options: options) else { fatalError("Unable to create Uniform Buffer") }
        buffer.label = parameters.label
        self.buffer = buffer
    }
        
    override public func update(_ index: Int = 0) {
        updateOffset()
        updateBuffer()
    }
    
    public func reset() {
        index = -1
    }
    
    func updateOffset() {
        index = (index + 1) % maxBuffersInFlight
        offset = alignedSize * index
    }
    
    func updateBuffer() {
        update(UnsafeMutableRawPointer(buffer.contents() + offset))
    }
}
