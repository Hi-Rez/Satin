//
//  Pipeline.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal

open class Pipeline {
    public var pipelineState: MTLRenderPipelineState?
    
    init() {
        print("Setup Pipeline")
    }
    
    deinit {
        print("Destroy Pipeline")
    }
}
