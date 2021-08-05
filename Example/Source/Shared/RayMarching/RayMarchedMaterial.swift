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
    weak var mtkView: MTKView?
    
    init(pipelinesURL: URL, camera: PerspectiveCamera?, instance: String = "") {
        self.camera = camera
        super.init(pipelinesURL: pipelinesURL, instance: instance)
        self.blending = .disabled
    }
        
    override func update() {
        if let view = mtkView {
            let size = view.drawableSize
            set("Resolution", simd_make_float2(Float(size.width), Float(size.height)))
        }
        super.update()
    }
    
    override func bind(_ renderEncoder: MTLRenderCommandEncoder) {
        super.bind(renderEncoder)
        if let camera = self.camera {
            var view = camera.viewMatrix
            renderEncoder.setFragmentBytes(&view, length: MemoryLayout<float4x4>.size, index: FragmentBufferIndex.Custom0.rawValue)
        }
    }
}
