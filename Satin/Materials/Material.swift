//
//  Material.swift
//  Satin
//
//  Created by Reza Ali on 7/24/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

open class Material {
    public var pipeline: Pipeline = Pipeline()
    
    public init() {}
    
    public init(_ pipeline: Pipeline) {
        self.pipeline = pipeline
    }
    
    deinit {}
}
