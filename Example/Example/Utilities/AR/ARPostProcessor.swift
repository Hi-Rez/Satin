//
//  ARPostProcessor.swift
//  Example
//
//  Created by Reza Ali on 3/16/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

#if os(iOS)

import ARKit
import Foundation
import Metal
import Satin

class ARPostProcessor: PostProcessor {
    class PostMaterial: SourceMaterial {
        public unowned var contentTexture: MTLTexture?
        public unowned var cameraGrainTexture: MTLTexture?

        private var startTime: CFAbsoluteTime
        private var time: CFAbsoluteTime

        public required init() {
            startTime = getTime()
            time = getTime()

            super.init(pipelinesURL: Bundle.main.resourceURL!
                .appendingPathComponent("Assets")
                .appendingPathComponent("Shared")
                .appendingPathComponent("Pipelines")
            )
            blending = .alpha
        }

        override func update(_ commandBuffer: MTLCommandBuffer) {
            time = getTime() - startTime
            set("Time", Float(time))
            if let cameraGrainTexture = cameraGrainTexture {
                set("Grain Size", simd_make_float2(Float(cameraGrainTexture.width), Float(cameraGrainTexture.height)))
            }
            super.update(commandBuffer)
        }

        required init(from _: Decoder) throws {
            fatalError("init(from:) has not been implemented")
        }

        override func bind(_ renderEncoder: MTLRenderCommandEncoder, shadow: Bool) {
            super.bind(renderEncoder, shadow: shadow)
            renderEncoder.setFragmentTexture(contentTexture, index: FragmentTextureIndex.Custom0.rawValue)
            renderEncoder.setFragmentTexture(cameraGrainTexture, index: FragmentTextureIndex.Custom1.rawValue)
        }
    }

    public unowned var contentTexture: MTLTexture? {
        didSet {
            if let material = mesh.material as? PostMaterial {
                material.contentTexture = contentTexture
            }
        }
    }

    unowned var session: ARSession

    public init(context: Context, session: ARSession) {
        self.session = session
        super.init(context: context, material: PostMaterial())
        renderer.colorLoadAction = .load
        label = "AR Post Processor"
    }

    internal func update(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor) {
        guard let frame = session.currentFrame else { return }
        if let material = mesh.material as? PostMaterial {
            material.set("Camera Grain Intensity", frame.cameraGrainIntensity)
            material.cameraGrainTexture = frame.cameraGrainTexture
        }
    }

    override func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
        update(commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor)
        super.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
    }

    override func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer, renderTarget: MTLTexture) {
        update(commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor)
        super.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer, renderTarget: renderTarget)
    }
}

#endif
