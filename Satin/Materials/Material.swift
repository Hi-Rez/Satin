//
//  Material.swift
//  Satin
//
//  Created by Reza Ali on 7/24/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal

open class Material {
    var pipeline: MTLRenderPipelineState?
    
    public var onBind: ((_ renderEncoder: MTLRenderCommandEncoder) -> ())?
    public var onUpdate: (() -> ())?
    
    public init(library: MTLLibrary,
                vertex: String,
                fragment: String,
                label: String,
                sampleCount: Int,
                colorPixelFormat: MTLPixelFormat,
                depthPixelFormat: MTLPixelFormat,
                stencilPixelFormat: MTLPixelFormat) {
        let device = library.device
        
        let vertexProgram = library.makeFunction(name: vertex)
        let fragmentProgram = library.makeFunction(name: fragment)
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = depthPixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = stencilPixelFormat
        
        pipeline = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
        setup(device: device)
    }
    
    func setup(device: MTLDevice) {}
    
    func update() {
        onUpdate?()
    }
    
    open func bind(_ renderEncoder: MTLRenderCommandEncoder) {
        guard let pipeline = self.pipeline else { return }
        renderEncoder.setRenderPipelineState(pipeline)
        onBind?(renderEncoder)
        
    }
    
    deinit {}
}
