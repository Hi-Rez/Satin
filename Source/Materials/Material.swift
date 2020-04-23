//
//  Material.swift
//  Satin
//
//  Created by Reza Ali on 7/24/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal

public protocol MaterialDelegate: AnyObject {
    func materialUpdated(material: Material)
}

open class Material {
    public var label: String {
        var label = String(describing: self).replacingOccurrences(of: "Material", with: "")
        if let bundleName = Bundle(for: type(of: self)).displayName {
            label = label.replacingOccurrences(of: bundleName, with: "")
        }
        label = label.replacingOccurrences(of: ".", with: "")
        return label
    }
    
    public weak var delegate: MaterialDelegate?
    public var pipeline: MTLRenderPipelineState?
    public var context: Context? {
        didSet {
            setup()
        }
    }
    
    public var onBind: ((_ renderEncoder: MTLRenderCommandEncoder) -> ())?
    public var onUpdate: (() -> ())?
    
    public init() {}
    
    public init(pipeline: MTLRenderPipelineState) {
        self.pipeline = pipeline
    }
    
    open func setup() {}
    
    open func update() {
        onUpdate?()
    }
    
    open func bind(_ renderEncoder: MTLRenderCommandEncoder) {
        onBind?(renderEncoder)
    }
    
    deinit {}
}
