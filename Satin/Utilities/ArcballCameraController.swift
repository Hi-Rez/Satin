//
//  ArcballCameraController.swift
//  Satin
//
//  Created by Reza Ali on 9/16/19.
//

#if os(macOS)

import Cocoa
import simd

open class ArcballCameraController {
    public weak var camera: ArcballPerspectiveCamera!
    
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
    
    var mouse: simd_float2 = simd_make_float2(0.0)
    
    open var damping: Float = 0.875
    open var rotateScalar: Float = 0.5
    open var translateScalar: Float = 0.01
    
    var rotateVelocity: simd_float3 = simd_make_float3(0.0)
    var translateVelocity: simd_float3 = simd_make_float3(0.0)
    
    var defaultPosition: simd_float3 = simd_make_float3(0.0)
    var defaultOrientation: simd_quatf = simd_quaternion(0.0, simd_make_float3(0.0))
    
    var insideArcBall: Bool = false
    var previouArcballPoint: simd_float3 = simd_make_float3(0.0)
    var currentArcballPoint: simd_float3 = simd_make_float3(0.0)
    
    public init(camera: ArcballPerspectiveCamera, defaultPosition: simd_float3, defaultOrientation: simd_quatf) {
        self.camera = camera
        
        self.defaultPosition = defaultPosition
        self.defaultOrientation = defaultOrientation
        
        enable()
    }
    
    public init(_ camera: ArcballPerspectiveCamera) {
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
        return 2.0 * simd_make_float2(Float(point.x / size.width), Float(point.y / size.height)) - 1.0
    }
    
    func arcballPoint(event: NSEvent) -> (point: simd_float3, inside: Bool) {
        
        guard let window = event.window else { return (point: simd_make_float3(0.0), inside:false) }
            
        var inside = false
        var pt2d = normalizeMouse(event.locationInWindow, window.frame.size)
        let size = window.frame.size
        let aspect = Float(size.width / size.height)
        pt2d.x *= aspect
        
        var ptOnArcBall: simd_float3
        
        if simd_length(pt2d) > 1.0 {
            pt2d = simd_normalize(pt2d)
            ptOnArcBall = simd_make_float3(pt2d.x, pt2d.y, 0.0)
        }
        else {
            let circleRadius = sqrt(1.0 - pow(pt2d.y, 2.0))
            ptOnArcBall = simd_make_float3(pt2d.x, pt2d.y, sqrt(circleRadius - pow(pt2d.x, 2.0)))
            ptOnArcBall = simd_normalize(ptOnArcBall)
            inside = true
        }
        
        return (point: ptOnArcBall, inside: inside)
    }
    
    open func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            reset()
        }
        else {
            let result = arcballPoint(event: event)
            previouArcballPoint = result.point
            insideArcBall = result.inside
        }
    }
    
    open func mouseDragged(with event: NSEvent) {
        let result = arcballPoint(event: event)
        let point = result.point
        let inside = result.inside
        
        if insideArcBall != inside {
            previouArcballPoint = point
        }
        
        insideArcBall = inside
        currentArcballPoint = point
        
        let quat = simd_quaternion(previouArcballPoint, currentArcballPoint)
        camera.arcballOrientation = simd_mul(quat, camera.arcballOrientation)
        previouArcballPoint = currentArcballPoint
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
        camera.arcballOrientation = defaultOrientation
        
        rotateVelocity = simd_make_float3(0.0)
        translateVelocity = simd_make_float3(0.0)
    }
    
    deinit {
        disable()
    }
}

#endif

/*
 
 - (CGPoint)normalizePoint:(NSEvent *)event {
     NSWindow *window = [event window];
     float scale = [window backingScaleFactor];
     CGPoint mouse = [event locationInWindow];
     mouse = [window convertPointToBacking:mouse];
     CGPoint normalized_point = CGPointMake(mouse.x / (self.size.width * scale), mouse.y / (self.size.height * scale));
     return CGPointMake(2.0 * (normalized_point.x) - 1.0, 2.0 * normalized_point.y - 1.0);
 }
 
 - (void)rightMouseDown:(NSEvent *)event {
     _previousRightMousePoint = [self normalizePoint:event];
 }
 
 - (void)rightMouseDragged:(NSEvent *)event {
     _currentRightMousePoint = [self normalizePoint:event];
     self.cameraDistance += (_currentRightMousePoint.y - _previousRightMousePoint.y);
     _previousRightMousePoint = _currentRightMousePoint;
 }
 
 */
