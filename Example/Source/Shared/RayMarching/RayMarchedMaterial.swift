//
//  RayMarchedMaterial.swift
//  RayMarching-macOS
//
//  Created by Reza Ali on 6/27/21.
//  Copyright © 2021 Hi-Rez. All rights reserved.
//

import MetalKit
import Satin

class RayMarchedMaterial: LiveMaterial {
    var camera: PerspectiveCamera?
    
    init(pipelinesURL: URL, camera: PerspectiveCamera?) {
        self.camera = camera
        super.init(pipelinesURL: pipelinesURL)
        self.blending = .disabled
    }
        
    override func bind(_ renderEncoder: MTLRenderCommandEncoder) {
        super.bind(renderEncoder)
        if let camera = self.camera {
            var view = camera.viewMatrix
            renderEncoder.setFragmentBytes(&view, length: MemoryLayout<float4x4>.size, index: FragmentBufferIndex.Custom0.rawValue)
        }
    }
}
