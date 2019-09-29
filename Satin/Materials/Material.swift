//
//  Material.swift
//  Satin
//
//  Created by Reza Ali on 7/24/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal

protocol MaterialDelegate: AnyObject {
    func materialUpdated()
}

open class Material {
    weak var delegate: MaterialDelegate?
    var pipeline: MTLRenderPipelineState?
    var context: Context? {
        didSet {
            setup()
        }
    }
    
    public var onBind: ((_ renderEncoder: MTLRenderCommandEncoder) -> ())?
    public var onUpdate: (() -> ())?
    
    init() {}
    
    public init(library: MTLLibrary?,
                vertex: String,
                fragment: String,
                label: String,
                context: Context) {
        do {
            pipeline = try makeRenderPipeline(library: library, vertex: vertex, fragment: fragment, label: label, context: context)
        }
        catch {
            print(error)
        }
        self.context = context
    }
    
    public init(pipeline: MTLRenderPipelineState) {
        self.pipeline = pipeline
    }
    
    func setup() {}
    
    func update() {
        onUpdate?()
    }
    
    open func bind(_ renderEncoder: MTLRenderCommandEncoder) {
        onBind?(renderEncoder)
    }
    
    deinit {}
}
