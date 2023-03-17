//
//  ARPerspectiveCamera.swift
//  Example
//
//  Created by Reza Ali on 3/16/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

#if os(iOS)

import ARKit
import MetalKit
import Satin

class ARPerspectiveCamera: PerspectiveCamera {
    unowned var session: ARSession
    unowned var mtkView: MTKView

    init(session: ARSession, mtkView: MTKView, near _: Float, far _: Float) {
        self.session = session
        self.mtkView = mtkView
        super.init()
        label = "AR Perspective Camera"
    }

    required init(from _: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    override func update() {
        guard let frame = session.currentFrame,
              let orientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation else { return }

        viewMatrix = frame.camera.viewMatrix(for: orientation)
        projectionMatrix = frame.camera.projectionMatrix(for: orientation, viewportSize: mtkView.drawableSize, zNear: CGFloat(near), zFar: CGFloat(far))

        super.update()
    }
}
#endif
