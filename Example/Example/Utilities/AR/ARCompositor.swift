//
//  ARMattePostProcessor.swift
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

class ARCompositor: ARPostProcessor {
    class CompositorMaterial: PostMaterial {
        public var depthTexture: MTLTexture?
        public var backgroundTexture: MTLTexture?
        public var alphaTexture: MTLTexture?
        public var dilatedDepthTexture: MTLTexture?

        override func bind(_ renderEncoder: MTLRenderCommandEncoder, shadow: Bool) {
            super.bind(renderEncoder, shadow: shadow)
            renderEncoder.setFragmentTexture(depthTexture, index: FragmentTextureIndex.Custom2.rawValue)
            renderEncoder.setFragmentTexture(backgroundTexture, index: FragmentTextureIndex.Custom3.rawValue)
            renderEncoder.setFragmentTexture(alphaTexture, index: FragmentTextureIndex.Custom4.rawValue)
            renderEncoder.setFragmentTexture(dilatedDepthTexture, index: FragmentTextureIndex.Custom5.rawValue)
        }
    }

    public var depthTexture: MTLTexture? {
        didSet {
            if let material = mesh.material as? CompositorMaterial {
                material.depthTexture = depthTexture
            }
        }
    }

    public var backgroundTexture: MTLTexture? {
        didSet {
            if let material = mesh.material as? CompositorMaterial {
                material.backgroundTexture = backgroundTexture
            }
        }
    }

    internal var alphaTexture: MTLTexture? {
        didSet {
            if let material = mesh.material as? CompositorMaterial {
                material.alphaTexture = alphaTexture
            }
        }
    }

    internal var dilatedDepthTexture: MTLTexture? {
        didSet {
            if let material = mesh.material as? CompositorMaterial {
                material.dilatedDepthTexture = dilatedDepthTexture
            }
        }
    }

    required override init(
        context: Context,
        session: ARSession
    ) {
        super.init(context: context, session: session)

        mesh.material = CompositorMaterial()

        renderer.setClearColor(.zero)

        renderer.colorLoadAction = .clear
        renderer.colorStoreAction = .store

        renderer.depthLoadAction = .clear
        renderer.depthStoreAction = .store

        label = "AR Compositor"
    }
}

#endif
