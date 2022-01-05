//
//  FPSCameraController.swift
//  Satin-macOS
//
//  Created by Reza Ali on 9/3/19.
//

#if os(macOS)

import Cocoa
import simd

open class FPSCameraController {
    public weak var camera: PerspectiveCamera!
    
    var leftMouseDownHandler: Any?
    var leftMouseDraggedHandler: Any?
    
    var keyDownHandler: Any?
    var keyUpHandler: Any?
    
    var moveForward: Bool = false
    var moveBackwards: Bool = false
    var moveRight: Bool = false
    var moveLeft: Bool = false
    var moveUp: Bool = false
    var moveDown: Bool = false
    
    var hitPoint: simd_float2 = simd_make_float2(0.0)
    
    open var damping: Float = 0.875
    open var rotateScalar: Float = 0.5
    open var translateScalar: Float = 0.01
    
    var rotateVelocity: simd_float3 = simd_make_float3(0.0)
    var translateVelocity: simd_float3 = simd_make_float3(0.0)
    
    var defaultPosition: simd_float3 = simd_make_float3(0.0)
    var defaultOrientation: simd_quatf = simd_quaternion(0.0, simd_make_float3(0.0))
    
    public init(camera: PerspectiveCamera, defaultPosition: simd_float3, defaultOrientation: simd_quatf) {
        self.camera = camera
        
        self.defaultPosition = defaultPosition
        self.defaultOrientation = defaultOrientation
        
        enable()
    }
    
    public init(_ camera: PerspectiveCamera) {
        self.camera = camera
        
        defaultPosition = self.camera.position
        defaultOrientation = self.camera.orientation
        
        enable()
    }
    
    open func update() {
        guard let camera = self.camera else { return }
        
        if moveForward {
            translateVelocity.z += translateScalar
        }
        else if moveBackwards {
            translateVelocity.z -= translateScalar
        }
        
        if moveRight {
            translateVelocity.x -= translateScalar
        }
        else if moveLeft {
            translateVelocity.x += translateScalar
        }
        
        if moveUp {
            translateVelocity.y += translateScalar
        }
        else if moveDown {
            translateVelocity.y -= translateScalar
        }
        
        if length(translateVelocity) > Float.ulpOfOne {
            camera.position += camera.forwardDirection * translateVelocity.z
            camera.position += camera.rightDirection * translateVelocity.x
            camera.position += camera.upDirection * translateVelocity.y
            translateVelocity *= damping
        }
        
        if length(rotateVelocity) > Float.ulpOfOne {
            camera.orientation *= simd_quaternion(rotateVelocity.x * rotateScalar, worldUpDirection)
            camera.orientation *= simd_quaternion(-rotateVelocity.y * rotateScalar, worldRightDirection)
            camera.orientation *= simd_quaternion(rotateVelocity.z, worldForwardDirection)
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
        
        keyDownHandler = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [unowned self] in
            self.keyDown(with: $0)
            return $0
        }
        
        keyUpHandler = NSEvent.addLocalMonitorForEvents(matching: .keyUp) { [unowned self] in
            self.keyUp(with: $0)
            return $0
        }
    }
    
    open func disable() {
        guard let leftMouseDownHandler = self.leftMouseDownHandler else { return }
        NSEvent.removeMonitor(leftMouseDownHandler)
        
        guard let leftMouseDraggedHandler = self.leftMouseDraggedHandler else { return }
        NSEvent.removeMonitor(leftMouseDraggedHandler)
        
        guard let keyDownHandler = self.keyDownHandler else { return }
        NSEvent.removeMonitor(keyDownHandler)
        
        guard let keyUpHandler = self.keyUpHandler else { return }
        NSEvent.removeMonitor(keyUpHandler)
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
            hitPoint = normalizeMouse(event.locationInWindow, window.frame.size)
        }
    }
    
    open func mouseDragged(with event: NSEvent) {
        guard let window = event.window else { return }
        let currMouse = normalizeMouse(event.locationInWindow, window.frame.size)
        let deltaMouse = currMouse - hitPoint
        rotateVelocity.x = deltaMouse.x
        rotateVelocity.y = deltaMouse.y
        hitPoint = currMouse
    }
    
    open func keyDown(with event: NSEvent) {
        switch event.characters {
        case "w":
            moveForward = true
            moveBackwards = false
            moveUp = false
            moveDown = false
        case "s":
            moveForward = false
            moveBackwards = true
            moveUp = false
            moveDown = false
        case "a":
            moveLeft = true
            moveRight = false
        case "d":
            moveLeft = false
            moveRight = true
        case "W":
            moveForward = false
            moveBackwards = false
            moveUp = true
            moveDown = false
        case "S":
            moveForward = false
            moveBackwards = false
            moveUp = false
            moveDown = true
        default:
            return
        }
    }
    
    open func keyUp(with event: NSEvent) {
        switch event.characters {
        case "w":
            moveForward = false
            moveUp = false
        case "s":
            moveBackwards = false
            moveDown = false
        case "a":
            moveLeft = false
        case "d":
            moveRight = false
        case "W":
            moveForward = false
            moveUp = false
        case "S":
            moveBackwards = false
            moveDown = false
        default:
            return
        }
    }
    
    open func reset() {
        camera.position = defaultPosition
        camera.orientation = defaultOrientation
        
        rotateVelocity = simd_make_float3(0.0)
        translateVelocity = simd_make_float3(0.0)
    }
    
    deinit {
        disable()
    }
}

#endif
