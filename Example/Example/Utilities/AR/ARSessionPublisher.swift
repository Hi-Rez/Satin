//
//  ARSessionPublisher.swift
//  Example
//
//  Created by Reza Ali on 4/26/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

#if os(iOS)

import ARKit
import Combine
import Foundation

class ARSessionPublisher: NSObject, ARSessionDelegate {
    let session: ARSession

    public let addedAnchorsPublisher = PassthroughSubject<[ARAnchor], Never>()
    public let updatedAnchorsPublisher = PassthroughSubject<[ARAnchor], Never>()
    public let removedAnchorsPublisher = PassthroughSubject<[ARAnchor], Never>()

    public let addedFramePublisher = PassthroughSubject<ARFrame, Never>()

    init(session: ARSession) {
        self.session = session
        super.init()
        session.delegate = self
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        addedAnchorsPublisher.send(anchors)
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        updatedAnchorsPublisher.send(anchors)
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        removedAnchorsPublisher.send(anchors)
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        addedFramePublisher.send(frame)
    }
}

#endif
