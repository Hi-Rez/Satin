//
//  PerspectiveCameraController.swift
//  Satin
//
//  Created by Reza Ali on 8/15/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

open class PerspectiveCameraController {
    public var camera: PerspectiveCamera = PerspectiveCamera()
    
    public init() {
        print("using built in camera")
    }
    
    public init(_ camera: PerspectiveCamera) {
        self.camera = camera
    }
    
    deinit {
        print("destroying perspective camera controller")
    }
}
