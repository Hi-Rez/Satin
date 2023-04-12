//
//  ARBackgroundDepthRenderer.swift
//  Example
//
//  Created by Reza Ali on 4/11/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

#if os(iOS)

import ARKit
import Foundation
import Metal
import Satin

class ARBackgroundDepthRenderer: ARBackgroundRenderer {
    class BackgroundDepthMaterial: BackgroundMaterial {
        public var depthTexture: CVMetalTexture?

        required init() {
            super.init()
            depthWriteEnabled = true
        }

        required init(from _: Decoder) throws {
            fatalError("init(from:) has not been implemented")
        }

        override func bind(_ renderEncoder: MTLRenderCommandEncoder, shadow: Bool) {
            super.bind(renderEncoder, shadow: shadow)
            if let depthTexture = depthTexture {
                renderEncoder.setFragmentTexture(CVMetalTextureGetTexture(depthTexture), index: FragmentTextureIndex.Custom2.rawValue)
            }
        }
    }

    // Captured image texture cache
    private var capturedImageTextureCache: CVMetalTextureCache!
    private var viewportSize = CGSize(width: 0, height: 0)
    private var _updateGeometry = true

    public init(context: Context, session: ARSession, near: Float = 0.01, far: Float = 10.0) {
        super.init(context: context, session: session)

        mesh.material = BackgroundDepthMaterial()
        mesh.material!.set("Near Far Delta", [near, far, far - near])

        renderer.depthStoreAction = .store
        self.label = "AR Background Depth Renderer"
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    override func resize(_ size: (width: Float, height: Float)) {
        super.resize(size)
        _updateGeometry = true
        viewportSize = CGSize(width: Int(size.width), height: Int(size.height))
    }

    override func updateTextures(_ frame: ARFrame) {
        super.updateTextures(frame)
        if let material = mesh.material as? BackgroundDepthMaterial,
           let sceneDepth = frame.smoothedSceneDepth ?? frame.sceneDepth
        {
            let depthPixelBuffer = sceneDepth.depthMap
            if let depthTexturePixelFormat = getMTLPixelFormat(for: depthPixelBuffer) {
                material.depthTexture = createTexture(
                    fromPixelBuffer: depthPixelBuffer,
                    pixelFormat: depthTexturePixelFormat,
                    planeIndex: 0
                )
            }
        }
    }

    private func getMTLPixelFormat(for pixelBuffer: CVPixelBuffer) -> MTLPixelFormat? {
        if CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_DepthFloat32 {
            return .r32Float
        } else if CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_OneComponent8 {
            return .r8Uint
        } else {
            return nil
        }
    }
}

#endif
