//
//  GesturalCameraController.swift
//  Satin
//
//  Created by Reza Ali on 8/15/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

#if os(macOS)

import Cocoa
import simd

open class GesturalCameraController {
    public weak var camera: PerspectiveCamera!
    
    var leftMouseDownHandler: Any?
    var leftMouseDraggedHandler: Any?
    var scrollWheelHandler: Any?
    var magnifyHandler: Any?
    var rotateHandler: Any?
    
    var mouse: simd_float2 = simd_make_float2(0.0)
    
    open var damping: Float = 0.9
    
    open var rotateScalar: Float = 1.0
    open var zoomScalar: Float = 1.0
    open var panScalar: Float = 0.0005
    
    var rotateVelocity: simd_float3 = simd_make_float3(0.0)
    var zoomVelocity: Float = 0.0
    var panVelocity: simd_float2 = simd_make_float2(0.0)
    
    var defaultPosition: simd_float3 = simd_make_float3(0.0)
    var defaultOrientation: simd_quatf = simd_quaternion(0.0, simd_make_float3(0.0))
    
    public init(camera: PerspectiveCamera) {
        self.camera = camera
        
        defaultPosition = self.camera.position
        defaultOrientation = self.camera.orientation
        
        enable()
    }
    
    open func update() {
        guard let camera = self.camera else { return }
        
        if length(panVelocity) > Float.ulpOfOne {
            camera.position += camera.rightDirection * panVelocity.x
            camera.position += camera.upDirection * panVelocity.y
            panVelocity *= damping
        }
        
        if abs(zoomVelocity) > Float.ulpOfOne {
            camera.position += camera.forwardDirection * zoomVelocity
            zoomVelocity *= damping
        }
        
        if length(rotateVelocity) > Float.ulpOfOne {
            camera.orientation *= simd_quaternion(rotateVelocity.x * rotateScalar, Satin.worldUpDirection)
            camera.orientation *= simd_quaternion(-rotateVelocity.y * rotateScalar, Satin.worldRightDirection)
            camera.orientation *= simd_quaternion(rotateVelocity.z, Satin.worldForwardDirection)
            rotateVelocity *= damping
        }
    }
    
    open func enable() {
        leftMouseDownHandler = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [unowned self] in
            self.mouseDown(with: $0)
            return $0
        }
        
        leftMouseDraggedHandler = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDragged) { [unowned self] in
            self.mouseDragged(with: $0)
            return $0
        }
        
        scrollWheelHandler = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [unowned self] in
            self.scrollWheel(with: $0)
            return $0
        }
        
        magnifyHandler = NSEvent.addLocalMonitorForEvents(matching: .magnify) { [unowned self] in
            self.magnify(with: $0)
            return $0
        }
        
        rotateHandler = NSEvent.addLocalMonitorForEvents(matching: .rotate) { [unowned self] in
            self.rotate(with: $0)
            return $0
        }
    }
    
    open func disable() {
        if let leftMouseDownHandler = self.leftMouseDownHandler {
            NSEvent.removeMonitor(leftMouseDownHandler)
        }
        
        if let leftMouseDraggedHandler = self.leftMouseDraggedHandler {
            NSEvent.removeMonitor(leftMouseDraggedHandler)
        }
        
        if let scrollWheelHandler = self.scrollWheelHandler {
            NSEvent.removeMonitor(scrollWheelHandler)
        }
        
        if let magnifyHandler = self.magnifyHandler {
            NSEvent.removeMonitor(magnifyHandler)
        }
        
        if let rotateHandler = self.rotateHandler {
            NSEvent.removeMonitor(rotateHandler)
        }
    }
    
    func normalizeMouse(_ point: NSPoint, _ size: CGSize) -> simd_float2 {
        return 2.0 * simd_make_float2(Float(point.x / size.width), 1.0 - Float(point.y / size.height)) - 1.0
    }
    
    func arcball(_ point: simd_float2) -> (point: simd_float3, inside: Bool) {
        var result = simd_make_float3(0.0)
        var inside: Bool
        let len = length(point)
        if len > 1 {
            result.x = point.x / len
            result.y = point.y / len
            result.z = 0.0
            inside = false
        }
        else {
            result.x = point.x
            result.y = point.y
            result.z = 1.0 - len
            result = normalize(result)
            inside = true
        }
        return (result, inside)
    }
    
    open func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            reset()
        }
        else {
            guard let window = event.window else { return }
            mouse = normalizeMouse(event.locationInWindow, window.frame.size)
        }
    }
    
    open func mouseDragged(with event: NSEvent) {
        guard let window = event.window else { return }
        let currMouse = normalizeMouse(event.locationInWindow, window.frame.size)
        let deltaMouse = currMouse - mouse
        rotateVelocity.x = deltaMouse.x
        rotateVelocity.y = deltaMouse.y
        mouse = currMouse
    }
    
    open func scrollWheel(with event: NSEvent) {
        if event.phase == .began {
            panVelocity = simd_make_float2(-Float(event.scrollingDeltaX), Float(event.scrollingDeltaY)) * panScalar
        }
        else if event.phase == .changed {
            panVelocity += simd_make_float2(-Float(event.scrollingDeltaX), Float(event.scrollingDeltaY)) * panScalar
        }
    }
    
    open func magnify(with event: NSEvent) {
        if event.phase == .began {
            zoomVelocity = -Float(event.magnification) * zoomScalar
        }
        else if event.phase == .changed {
            zoomVelocity -= Float(event.magnification) * zoomScalar
        }
    }
    
    open func rotate(with event: NSEvent) {
        rotateVelocity.z -= degToRad(event.rotation) * 0.075
    }
    
    open func reset() {
        camera.position = defaultPosition
        camera.orientation = defaultOrientation
        
        rotateVelocity = simd_make_float3(0.0)
        zoomVelocity = 0.0
        panVelocity = simd_make_float2(0.0)
    }
    
    deinit {
        disable()
    }
}

#endif
