//
//  Renderer+AR.swift
//  SatinSceneKitAR-iOS
//
//  Created by Reza Ali on 6/24/21.
//  Copyright © 2021 Hi-Rez. All rights reserved.
//

#if os(iOS)

import ARKit

extension SatinSceneKitARRenderer {
    // MARK: - Setup AR Session
    
    func setupARSession() {
        session = ARSession()
        session.delegate = self
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        session.run(configuration)
    }
    
    func getOrientation() -> UIInterfaceOrientation? {
        return mtkView.window?.windowScene?.interfaceOrientation
    }
    
    func updateCamera() {
        guard let frame = session.currentFrame, let orientation = getOrientation() else {
            return
        }
        
        camera.viewMatrix = frame.camera.viewMatrix(for: orientation)
        camera.projectionMatrix = frame.camera.projectionMatrix(for: orientation, viewportSize: viewportSize, zNear: 0.01, zFar: 100)        
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
