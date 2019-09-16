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
    
    public init(library: MTLLibrary?,
                vertex: String,
                fragment: String,
                label: String,
                sampleCount: Int,
                colorPixelFormat: MTLPixelFormat,
                depthPixelFormat: MTLPixelFormat,
                stencilPixelFormat: MTLPixelFormat) {
        if let device = library?.device {
            do {
                pipeline = try makeRenderPipeline(library: library, vertex: vertex, fragment: fragment, label: label, sampleCount: sampleCount, colorPixelFormat: colorPixelFormat, depthPixelFormat: depthPixelFormat, stencilPixelFormat: stencilPixelFormat)
            }
            catch {
                print(error)
            }
            setup(device: device)
        }
    }
    
    public init(pipeline: MTLRenderPipelineState) {
        self.pipeline = pipeline
        setup(device: pipeline.device)
    }
    
    func setup(device: MTLDevice) {}
    
    func update() {
        onUpdate?()
    }
    
    open func bind(_ renderEncoder: MTLRenderCommandEncoder) -> Bool {
        guard let pipeline = self.pipeline else { return false }
        renderEncoder.setRenderPipelineState(pipeline)
        onBind?(renderEncoder)
        return true
    }
    
    deinit {}
}
