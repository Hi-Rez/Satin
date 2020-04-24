//
//  ArcballCameraController.swift
//  Satin
//
//  Created by Reza Ali on 9/16/19.
//

import MetalKit
import simd

public enum ArcballCameraControllerState {
    case panning
    case rotating
    case zooming
    case rolling
    case inactive
}

open class ArcballCameraController {
    public weak var camera: ArcballPerspectiveCamera!
    public weak var view: MTKView!
    
    #if os(macOS)
    
    var leftMouseDownHandler: Any?
    var leftMouseDraggedHandler: Any?
    var leftMouseUpHandler: Any?
    
    var rightMouseDownHandler: Any?
    var rightMouseDraggedHandler: Any?
    var rightMouseUpHandler: Any?
    
    var otherMouseDownHandler: Any?
    var otherMouseDraggedHandler: Any?
    var otherMouseUpHandler: Any?
    
    var scrollWheelHandler: Any?
    
    var magnification: Float = 1.0
    var magnifyGestureRecognizer: NSMagnificationGestureRecognizer!
    var rollGestureRecognizer: NSRotationGestureRecognizer!
    
    #elseif os(iOS)
    
    var rollGestureRecognizer: UIRotationGestureRecognizer!
    var rotateGestureRecognizer: UIPanGestureRecognizer!
    var panGestureRecognizer: UIPanGestureRecognizer!
    var pinchGestureRecognizer: UIPinchGestureRecognizer!
    var oneTapGestureRecognizer: UITapGestureRecognizer!
    var twoTapGestureRecognizer: UITapGestureRecognizer!
    var threeTapGestureRecognizer: UITapGestureRecognizer!
    
    #endif
    
    var state: ArcballCameraControllerState = .inactive
    
    open var rotationDamping: Float = 0.9
    #if os(macOS)
    open var rotationScalar: Float = 3.0
    #elseif os(iOS)
    open var rotationScalar: Float = 2.0
    #endif
    
    var rotationAxis = simd_make_float3(1.0, 0.0, 0.0)
    var rotationAngle: Float = 0.0
    var rotationVelocity: Float = 0.0
    
    open var translationDamping: Float = 0.9
    #if os(macOS)
    open var translationScalar: Float = 1.5
    #elseif os(iOS)
    open var translationScalar: Float = 0.5
    #endif
    var translationVelocity: simd_float3 = simd_make_float3(0.0)
    
    open var defaultPosition: simd_float3 = simd_make_float3(0.0, 0.0, 1.0)
    open var defaultOrientation: simd_quatf = simd_quaternion(Float.pi, simd_make_float3(0, 1, 0))
    
    var insideArcBall: Bool = false
    var previouArcballPoint = simd_make_float3(0.0)
    var currentArcballPoint = simd_make_float3(0.0)
    
    public init(camera: ArcballPerspectiveCamera, view: MTKView, defaultPosition: simd_float3, defaultOrientation: simd_quatf) {
        self.camera = camera
        self.view = view
        
        self.defaultPosition = defaultPosition
        self.defaultOrientation = defaultOrientation
        
        enable()
    }
    
    public init(camera: ArcballPerspectiveCamera, view: MTKView) {
        self.camera = camera
        self.view = view
        
        defaultPosition = self.camera.position
        defaultOrientation = self.camera.orientation
        
        enable()
    }
    
    open func update() {
        guard camera != nil else { return }
        
        if length(translationVelocity) > Float.ulpOfOne {
            updatePosition()
            translationVelocity *= translationDamping
        }
        
        if abs(rotationVelocity) > 0.001, length(rotationAxis) > 0.9 {
            updateOrientation()
            rotationVelocity *= rotationDamping
        }
    }
    
    func updateOrientation() {
        let quat = simd_quaternion(-rotationVelocity, rotationAxis)
        camera.arcballOrientation *= quat
    }
    
    func updatePosition() {
        camera.position += simd_make_float3(camera.forwardDirection * translationVelocity.z)
        camera.position -= simd_make_float3(camera.rightDirection * translationVelocity.x)
        camera.position += simd_make_float3(camera.upDirection * translationVelocity.y)
    }
    
    open func enable() {
        #if os(macOS)
        leftMouseDownHandler = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [unowned self] in
            self.mouseDown(with: $0)
            return $0
        }
        
        leftMouseDraggedHandler = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDragged) { [unowned self] in
            self.mouseDragged(with: $0)
            return $0
        }
        
        leftMouseUpHandler = NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { [unowned self] in
            self.mouseUp(with: $0)
            return $0
        }
        
        rightMouseDownHandler = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [unowned self] in
            self.rightMouseDown(with: $0)
            return $0
        }
        
        rightMouseDraggedHandler = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDragged) { [unowned self] in
            self.rightMouseDragged(with: $0)
            return $0
        }
        
        rightMouseUpHandler = NSEvent.addLocalMonitorForEvents(matching: .rightMouseUp) { [unowned self] in
            self.rightMouseUp(with: $0)
            return $0
        }
        
        otherMouseDownHandler = NSEvent.addLocalMonitorForEvents(matching: .otherMouseDown) { [unowned self] in
            self.otherMouseDown(with: $0)
            return $0
        }
        
        otherMouseDraggedHandler = NSEvent.addLocalMonitorForEvents(matching: .otherMouseDragged) { [unowned self] in
            self.otherMouseDragged(with: $0)
            return $0
        }
        
        otherMouseUpHandler = NSEvent.addLocalMonitorForEvents(matching: .otherMouseUp) { [unowned self] in
            self.otherMouseUp(with: $0)
            return $0
        }
        
        scrollWheelHandler = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [unowned self] in
            self.scrollWheel(with: $0)
            return $0
        }
        
        magnifyGestureRecognizer = NSMagnificationGestureRecognizer(target: self, action: #selector(magnifyGesture))
        view.addGestureRecognizer(magnifyGestureRecognizer)
        
        rollGestureRecognizer = NSRotationGestureRecognizer(target: self, action: #selector(rollGesture))
        view.addGestureRecognizer(rollGestureRecognizer)
        
        #elseif os(iOS)
        
        view.isMultipleTouchEnabled = true
        
        rollGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(rollGesture))
        view.addGestureRecognizer(rollGestureRecognizer)
        
        rotateGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(rotateGesture))
        rotateGestureRecognizer.minimumNumberOfTouches = 1
        rotateGestureRecognizer.maximumNumberOfTouches = 1
        view.addGestureRecognizer(rotateGestureRecognizer)
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGesture))
        panGestureRecognizer.minimumNumberOfTouches = 2
        panGestureRecognizer.maximumNumberOfTouches = 2
        view.addGestureRecognizer(panGestureRecognizer)
        
        oneTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
        oneTapGestureRecognizer.numberOfTouchesRequired = 1
        oneTapGestureRecognizer.numberOfTapsRequired = 2
        view.addGestureRecognizer(oneTapGestureRecognizer)
        
        twoTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
        twoTapGestureRecognizer.numberOfTouchesRequired = 2
        twoTapGestureRecognizer.numberOfTapsRequired = 2
        view.addGestureRecognizer(twoTapGestureRecognizer)
        
        threeTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
        threeTapGestureRecognizer.numberOfTouchesRequired = 3
        threeTapGestureRecognizer.numberOfTapsRequired = 2
        view.addGestureRecognizer(threeTapGestureRecognizer)
        
        pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchGesture))
        view.addGestureRecognizer(pinchGestureRecognizer)
        
        #endif
    }
    
    open func disable() {
        #if os(macOS)
        
        if let leftMouseDownHandler = self.leftMouseDownHandler {
            NSEvent.removeMonitor(leftMouseDownHandler)
        }
        
        if let leftMouseDraggedHandler = self.leftMouseDraggedHandler {
            NSEvent.removeMonitor(leftMouseDraggedHandler)
        }
        
        if let leftMouseUpHandler = self.leftMouseUpHandler {
            NSEvent.removeMonitor(leftMouseUpHandler)
        }
        
        if let rightMouseDownHandler = self.rightMouseDownHandler {
            NSEvent.removeMonitor(rightMouseDownHandler)
        }
        
        if let rightMouseDraggedHandler = self.rightMouseDraggedHandler {
            NSEvent.removeMonitor(rightMouseDraggedHandler)
        }
        
        if let rightMouseUpHandler = self.rightMouseUpHandler {
            NSEvent.removeMonitor(rightMouseUpHandler)
        }
        
        if let otherMouseDownHandler = self.otherMouseDownHandler {
            NSEvent.removeMonitor(otherMouseDownHandler)
        }
        
        if let otherMouseDraggedHandler = self.otherMouseDraggedHandler {
            NSEvent.removeMonitor(otherMouseDraggedHandler)
        }
        
        if let otherMouseUpHandler = self.otherMouseUpHandler {
            NSEvent.removeMonitor(otherMouseUpHandler)
        }
        
        if let scrollWheelHandler = self.scrollWheelHandler {
            NSEvent.removeMonitor(scrollWheelHandler)
        }
        
        view.removeGestureRecognizer(magnifyGestureRecognizer)
        view.removeGestureRecognizer(rollGestureRecognizer)
        
        #elseif os(iOS)
        
        view.removeGestureRecognizer(rollGestureRecognizer)
        view.removeGestureRecognizer(rotateGestureRecognizer)
        view.removeGestureRecognizer(panGestureRecognizer)
        view.removeGestureRecognizer(oneTapGestureRecognizer)
        view.removeGestureRecognizer(twoTapGestureRecognizer)
        view.removeGestureRecognizer(threeTapGestureRecognizer)
        view.removeGestureRecognizer(pinchGestureRecognizer)
        
        #endif
    }
    
    #if os(macOS)
    
    @objc func magnifyGesture(_ gestureRecognizer: NSMagnificationGestureRecognizer) {
        let newMagnification = Float(gestureRecognizer.magnification)
        if gestureRecognizer.state == .began {
            state = .zooming
            magnification = newMagnification
        }
        else if gestureRecognizer.state == .changed, state == .zooming {
            let cameraDistance = max(length(camera.position) * 0.175, 1.0)
            let velocity = newMagnification - magnification
            translationVelocity.z -= 0.25 * translationScalar * velocity * cameraDistance
            magnification = newMagnification
        }
        else {
            state = .inactive
        }
    }
    
    @objc func rollGesture(_ gestureRecognizer: NSRotationGestureRecognizer) {
        if gestureRecognizer.state == .began {
            state = .rolling
        }
        else if gestureRecognizer.state == .changed, state == .rolling {
            let roll = simd_quatf(angle: -Float(gestureRecognizer.rotation), axis: camera.forwardDirection)
            camera.arcballOrientation = simd_mul(roll, camera.arcballOrientation)
            gestureRecognizer.rotation = 0.0
        }
        else {
            state = .inactive
        }
    }
    
    func mouseDown(with event: NSEvent) {
        if event.window == view.window {
            if event.clickCount == 2 {
                reset()
            }
            else {
                let result = arcballPoint(event.locationInWindow, view.frame.size)
                previouArcballPoint = result.point
                insideArcBall = result.inside
                state = .rotating
            }
        }
    }
    
    func mouseDragged(with event: NSEvent) {
        if event.window == view.window {
            let result = arcballPoint(event.locationInWindow, view.frame.size)
            let point = result.point
            let inside = result.inside
            
            if insideArcBall != inside {
                previouArcballPoint = point
            }
            
            insideArcBall = inside
            currentArcballPoint = point
            
            rotationAxis = normalize(cross(previouArcballPoint, currentArcballPoint))
            rotationVelocity = rotationScalar * acos(dot(previouArcballPoint, currentArcballPoint))
            previouArcballPoint = currentArcballPoint
        }
    }
    
    func mouseUp(with event: NSEvent) {
        if event.window == view.window {
            state = .inactive
        }
    }
    
    func rightMouseDown(with event: NSEvent) {
        if event.window == view.window {}
    }
    
    func rightMouseDragged(with event: NSEvent) {
        if event.window == view.window {
            if abs(event.deltaX) > abs(event.deltaY) {
                state = .rolling
                let roll = simd_quatf(angle: Float(event.deltaX / (0.5 * view.frame.width)), axis: camera.forwardDirection)
                camera.arcballOrientation = simd_mul(roll, camera.arcballOrientation)
            }
            else {
                state = .zooming
                let cameraDistance = max(length(camera.worldPosition) * 0.25, 1.0)
                translationVelocity.z -= 2.5 * Float(event.deltaY / (0.5 * view.frame.height)) * translationScalar * cameraDistance
                translationVelocity.z /= 2.0
            }
        }
    }
    
    func rightMouseUp(with event: NSEvent) {
        if event.window == view.window {
            state = .inactive
        }
    }
    
    func otherMouseDown(with event: NSEvent) {
        if event.window == view.window {
            state = .panning
        }
    }
    
    func otherMouseDragged(with event: NSEvent) {
        if event.window == view.window {
            state = .panning
            let cameraDistance = max(length(camera.worldPosition) * 0.5, 1.0)
            translationVelocity.x += Float(event.deltaX / 200.0) * translationScalar * cameraDistance
            translationVelocity.y += Float(event.deltaY / 200.0) * translationScalar * cameraDistance
            translationVelocity.x /= 2.0
            translationVelocity.y /= 2.0
        }
    }
    
    func otherMouseUp(with event: NSEvent) {
        if event.window == view.window {
            state = .inactive
        }
    }
    
    func scrollWheel(with event: NSEvent) {
        if event.window == view.window {
            if length(simd_float2(Float(event.deltaX), Float(event.deltaY))) < Float.ulpOfOne {
                state = .inactive
            }
            else if event.phase == .changed {
                if event.modifierFlags.contains(NSEvent.ModifierFlags.command) {
                    if abs(event.deltaX) > abs(event.deltaY) {
                        state = .rolling
                        let roll = simd_quatf(angle: Float(event.deltaX / 200.0), axis: camera.forwardDirection)
                        camera.arcballOrientation = simd_mul(roll, camera.arcballOrientation)
                    }
                    else {
                        state = .zooming
                        let cameraDistance = max(length(camera.worldPosition) * 0.25, 1.0)
                        translationVelocity.z -= 2.5 * Float(event.deltaY / 100.0) * translationScalar * cameraDistance
                        translationVelocity.z /= 2.0
                    }
                }
                else if event.phase == .changed {
                    state = .panning
                    let cameraDistance = max(length(camera.worldPosition) * 0.5, 1.0)
                    translationVelocity.x += Float(event.deltaX / 100.0) * translationScalar * cameraDistance
                    translationVelocity.y += Float(event.deltaY / 100.0) * translationScalar * cameraDistance
                    translationVelocity.x /= 2.0
                    translationVelocity.y /= 2.0
                }
            }
        }
    }
    
    #elseif os(iOS)
    
    @objc func tapGesture(_ gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            reset()
        }
    }
    
    @objc func rollGesture(_ gestureRecognizer: UIRotationGestureRecognizer) {
        if gestureRecognizer.state == .began {
            state = .rolling
        }
        else if gestureRecognizer.state == .changed, state == .rolling {
            let roll = simd_quatf(angle: Float(gestureRecognizer.rotation), axis: camera.forwardDirection)
            camera.arcballOrientation = simd_mul(roll, camera.arcballOrientation)
            gestureRecognizer.rotation = 0.0
        }
        else {
            state = .inactive
        }
    }
    
    @objc func rotateGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        if gestureRecognizer.numberOfTouches == gestureRecognizer.minimumNumberOfTouches {
            if gestureRecognizer.state == .began {
                state = .rotating
                
                var centerPoint = CGPoint(x: 0.0, y: 0.0)
                let numberOfTouches = CGFloat(gestureRecognizer.numberOfTouches)
                for i in 0..<gestureRecognizer.numberOfTouches {
                    let pt = gestureRecognizer.location(ofTouch: i, in: view)
                    centerPoint.x += pt.x
                    centerPoint.y += pt.y
                }
                centerPoint.x /= numberOfTouches
                centerPoint.y /= numberOfTouches
                
                let result = arcballPoint(centerPoint, view.frame.size)
                previouArcballPoint = result.point
                insideArcBall = result.inside
            }
            else if gestureRecognizer.state == .changed, state == .rotating {
                var centerPoint = CGPoint(x: 0.0, y: 0.0)
                let numberOfTouches = CGFloat(gestureRecognizer.numberOfTouches)
                for i in 0..<gestureRecognizer.numberOfTouches {
                    let pt = gestureRecognizer.location(ofTouch: i, in: view)
                    centerPoint.x += pt.x
                    centerPoint.y += pt.y
                }
                centerPoint.x /= numberOfTouches
                centerPoint.y /= numberOfTouches
                
                let result = arcballPoint(centerPoint, view.frame.size)
                let point = result.point
                let inside = result.inside
                
                if insideArcBall != inside {
                    previouArcballPoint = point
                }
                
                insideArcBall = inside
                currentArcballPoint = point
                
                rotationAxis = normalize(cross(previouArcballPoint, currentArcballPoint))
                rotationVelocity = rotationScalar * acos(dot(previouArcballPoint, currentArcballPoint))
                previouArcballPoint = currentArcballPoint
            }
            else {
                state = .inactive
            }
        }
        else {
            state = .inactive
        }
    }
    
    @objc func panGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        if gestureRecognizer.state == .began {
            state = .panning
        }
        else if gestureRecognizer.state == .changed, state == .panning {
            var velocity = gestureRecognizer.velocity(in: view)
            velocity.x /= view.frame.width
            velocity.y /= view.frame.height
            
            let cameraDistance = CGFloat(max(length(camera.worldPosition) * 0.175, 1.0))
            
            velocity.x *= cameraDistance
            velocity.y *= cameraDistance
            
            translationVelocity.x += 0.01 * translationScalar * Float(velocity.x)
            translationVelocity.y += 0.01 * translationScalar * Float(velocity.y)
        }
        else {
            state = .inactive
        }
    }
    
    @objc func pinchGesture(_ gestureRecognizer: UIPinchGestureRecognizer) {
        if gestureRecognizer.state == .began {
            state = .zooming
        }
        else if gestureRecognizer.state == .changed, state == .zooming {
            let cameraDistance = max(length(camera.worldPosition) * 0.175, 1.0)
            translationVelocity.z -= 0.01 * translationScalar * Float(gestureRecognizer.velocity) * cameraDistance
            gestureRecognizer.scale = 1.0
        }
        else {
            state = .inactive
        }
    }
    
    #endif
    
    func normalizePoint(_ point: CGPoint, _ size: CGSize) -> simd_float2 {
        #if os(macOS)
        return 2.0 * simd_make_float2(Float(point.x / size.width), Float(point.y / size.height)) - 1.0
        #else
        return 2.0 * simd_make_float2(Float(point.x / size.width), 1.0 - Float(point.y / size.height)) - 1.0
        #endif
    }
    
    func arcballPoint(_ point: CGPoint, _ size: CGSize) -> (point: simd_float3, inside: Bool) {
        var inside = false
        var pt2d = normalizePoint(point, size)
        let aspect = size.width > size.height ? Float(size.width / size.height) : Float(size.height / size.width)
        pt2d.x /= aspect
        
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
    
    open func reset() {
        DispatchQueue.main.async { [unowned self] in
            self.state = .inactive
            self.rotationVelocity = 0.0
            self.translationVelocity = simd_make_float3(0.0)
            
            guard let camera = self.camera else { return }
            camera.position = self.defaultPosition
            camera.orientation = self.defaultOrientation
            camera.arcballOrientation = simd_quatf(matrix_identity_float4x4)
            camera.updateMatrix = true
        }
    }
    
    deinit {
        disable()
    }
}
