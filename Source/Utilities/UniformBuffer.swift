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

open class UniformBuffer: Buffer {
    public var index: Int = -1
    public var offset: Int = 0
    public var alignedSize: Int = 0
    
    public init(context: Context, parameters: ParameterGroup, options: MTLResourceOptions = [.storageModeShared]) {
        super.init()
        self.parameters = parameters
        self.alignedSize = ((parameters.size + 255) / 256) * 256
        setupBuffer(context: context, count: maxBuffersInFlight, options: options)
    }
    
    override func setupBuffer(context: Context, count: Int, options: MTLResourceOptions) {
        guard alignedSize > 0, let buffer = context.device.makeBuffer(length: alignedSize * count, options: options) else { fatalError("Unable to create UniformBuffer") }
        buffer.label = parameters.label
        self.buffer = buffer
    }
        
    public override func update(_ index: Int = 0) {
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
