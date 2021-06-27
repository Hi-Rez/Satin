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
        updateCamera()
        super.update()
    }
    
    func updateCamera() {
        guard let camera = self.camera else { return }
        let imagePlaneHeight = tanf(degToRad(camera.fov) * 0.5)
        let imagePlaneWidth = camera.aspect * imagePlaneHeight
                                
        let cameraRight = normalize(camera.worldRightDirection) * imagePlaneWidth
        let cameraUp = normalize(camera.worldUpDirection) * imagePlaneHeight
        let cameraForward = normalize(camera.viewDirection)
        let cameraDelta = camera.far - camera.near
        let cameraA = camera.far / cameraDelta
        let cameraB = (camera.far * camera.near) / cameraDelta
                
        set("Camera Position", camera.worldPosition)
        set("Camera Right", cameraRight)
        set("Camera Up", cameraUp)
        set("Camera Forward", cameraForward)
        if let view = mtkView {
            let size = view.drawableSize
            set("Resolution", simd_make_float2(Float(size.width), Float(size.height)))
        }
        set("Near Far", simd_make_float2(camera.near, camera.far))
        set("Camera Depth", simd_make_float2(cameraA, cameraB))
    }
    
    override func bind(_ renderEncoder: MTLRenderCommandEncoder) {
        super.bind(renderEncoder)
        if let camera = self.camera {
            var view = camera.viewMatrix
            renderEncoder.setFragmentBytes(&view, length: MemoryLayout<float4x4>.size, index: FragmentBufferIndex.Custom0.rawValue)
        }
    }
}
