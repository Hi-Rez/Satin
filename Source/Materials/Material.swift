//
//  Material.swift
//  Satin
//
//  Created by Reza Ali on 7/24/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal

protocol MaterialDelegate: AnyObject {
    func materialUpdated(material: Material)
}

open class Material {
    public var label: String {
        return String(describing: self).replacingOccurrences(of: "Material", with: "").replacingOccurrences(of: "Satin.", with: "")
    }
    
    weak var delegate: MaterialDelegate?
    public var pipeline: MTLRenderPipelineState?
    var context: Context? {
        didSet {
            setup()
        }
    }
    
    public var onBind: ((_ renderEncoder: MTLRenderCommandEncoder) -> ())?
    public var onUpdate: (() -> ())?
    
    init() {}
    
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
