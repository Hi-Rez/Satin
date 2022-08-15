//
//  Renderer+ARSession.swift
//  AR-iOS
//
//  Created by Reza Ali on 9/26/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

#if os(iOS)

import ARKit

extension ARRenderer {
    // MARK: - Setup AR Session
    
    func setupARSession() {
        session = ARSession()
        session.delegate = self
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        session.run(configuration)
    }
    
    func updateCamera() {
        guard let frame = session.currentFrame, let orientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation else {
            return
        }
        
        camera.viewMatrix = frame.camera.viewMatrix(for: orientation)
        camera.projectionMatrix = frame.camera.projectionMatrix(for: orientation, viewportSize: viewportSize, zNear: 0.001, zFar: 100.0)
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
}

#endif
