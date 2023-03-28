//
//  CameraController.swift
//  Satin
//
//  Created by Reza Ali on 03/25/23.
//

import MetalKit
import Combine

public enum CameraControllerState {
    case panning // moves the camera either up to right
    case rotating // rotates the camera around an arcball
    case dollying // moves the camera forward
    case zooming // moves the camera closer to target
    case rolling // rotates the camera around its forward axis
    case tweening // tweening
    case inactive
}

public protocol CameraController {
    var isEnabled: Bool { get }

    var view: MTKView? { get set }

    var state: CameraControllerState { get }

    func update()
    func enable()
    func disable()
    func reset()
    func resize(_ size: (width: Float, height: Float))

    func save(url: URL)
    func load(url: URL)
}
