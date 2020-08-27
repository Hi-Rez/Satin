//
//  PerspectiveCameraController.swift
//  Satin
//
//  Created by Reza Ali on 7/29/20.
//

import MetalKit
import simd

public enum PerspectiveCameraControllerState {
    case panning // moves the camera either up to right
    case rotating // rotates the camera around an arcball
    case dollying // moves the camera forward
    case zooming // moves the camera closer to target
    case rolling // rotates the camera around its forward axis
    case inactive
}

open class PerspectiveCameraController: Codable {
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        camera = try values.decode(PerspectiveCamera.self, forKey: .camera)
        target = try values.decode(Object.self, forKey: .target)
        defaultPosition = try values.decode(simd_float3.self, forKey: .defaultPosition)
        defaultOrientation = try values.decode(simd_quatf.self, forKey: .defaultOrientation)
        mouseDeltaSensitivity = try values.decode(Float.self, forKey: .mouseDeltaSensitivity)
        scrollDeltaSensitivity = try values.decode(Float.self, forKey: .scrollDeltaSensitivity)
        rotationDamping = try values.decode(Float.self, forKey: .rotationDamping)
        rotationScalar = try values.decode(Float.self, forKey: .rotationScalar)
        translationDamping = try values.decode(Float.self, forKey: .translationDamping)
        translationScalar = try values.decode(Float.self, forKey: .translationScalar)
        zoomScalar = try values.decode(Float.self, forKey: .zoomScalar)
        zoomDamping = try values.decode(Float.self, forKey: .zoomDamping)
        rollScalar = try values.decode(Float.self, forKey: .rollScalar)
        rollDamping = try values.decode(Float.self, forKey: .rollDamping)
        setup()
    }
    
    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(camera, forKey: .camera)
        try container.encode(target, forKey: .target)
        try container.encode(defaultPosition, forKey: .defaultPosition)
        try container.encode(defaultOrientation, forKey: .defaultOrientation)
        try container.encode(mouseDeltaSensitivity, forKey: .mouseDeltaSensitivity)
        try container.encode(scrollDeltaSensitivity, forKey: .scrollDeltaSensitivity)
        try container.encode(rotationDamping, forKey: .rotationDamping)
        try container.encode(rotationScalar, forKey: .rotationScalar)
        try container.encode(translationDamping, forKey: .translationDamping)
        try container.encode(translationScalar, forKey: .translationScalar)
        try container.encode(zoomScalar, forKey: .zoomScalar)
        try container.encode(zoomDamping, forKey: .zoomDamping)
        try container.encode(rollScalar, forKey: .rollScalar)
        try container.encode(rollDamping, forKey: .rollDamping)
    }
    
    private enum CodingKeys: String, CodingKey {
        case camera
        case target
        case defaultPosition
        case defaultOrientation
        case mouseDeltaSensitivity
        case scrollDeltaSensitivity
        case modifierFlags
        case rotationDamping
        case rotationScalar
        case translationDamping
        case translationScalar
        case zoomScalar
        case zoomDamping
        case rollScalar
        case rollDamping
    }
    
    public private(set) var enabled: Bool = false
    
    public var camera: PerspectiveCamera?
    public var view: MTKView? {
        willSet {
            if view != nil, enabled {
                disable()
            }
        }
        didSet {
            if view != nil {
                enable()
            }
        }
    }
    
    public var onChange: (() -> ())?
    
    open var mouseDeltaSensitivity: Float = 600.0
    open var scrollDeltaSensitivity: Float = 600.0
    
    #if os(macOS)
    
    open var modifierFlags: NSEvent.ModifierFlags = .init()
    
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
    
    var pinchScale: Float = 1.0
    var rollGestureRecognizer: UIRotationGestureRecognizer!
    var rotateGestureRecognizer: UIPanGestureRecognizer!
    var panGestureRecognizer: UIPanGestureRecognizer!
    var pinchGestureRecognizer: UIPinchGestureRecognizer!
    var oneTapGestureRecognizer: UITapGestureRecognizer!
    var twoTapGestureRecognizer: UITapGestureRecognizer!
    var threeTapGestureRecognizer: UITapGestureRecognizer!
    
    #endif
    
    var state: PerspectiveCameraControllerState = .inactive
    
    // Rotation
    open var rotationDamping: Float = 0.9
    #if os(macOS)
    open var rotationScalar: Float = 5.0
    #elseif os(iOS)
    open var rotationScalar: Float = 3.0
    #endif
    
    var rotationAxis = simd_make_float3(1.0, 0.0, 0.0)
    var rotationAngle: Float = 0.0
    var rotationVelocity: Float = 0.0
    
    // Translation (Panning & Dolly)
    open var translationDamping: Float = 0.9
    #if os(macOS)
    open var translationScalar: Float = 0.5
    #elseif os(iOS)
    open var translationScalar: Float = 0.5
    #endif
    var translationVelocity: simd_float3 = simd_make_float3(0.0)
    
    // Zoom
    open var minimumZoomDistance: Float = 1.0 {
        didSet {
            if minimumZoomDistance < 1.0 {
                minimumZoomDistance = oldValue
            }
        }
    }
    
    open var zoomScalar: Float = 2.0
    open var zoomDamping: Float = 0.9
    var zoomVelocity: Float = 0.0
    
    // Roll
    open var rollScalar: Float = 0.25
    open var rollDamping: Float = 0.9
    var rollVelocity: Float = 0.0
    
    open var defaultPosition: simd_float3 = simd_make_float3(0.0, 0.0, 1.0)
    open var defaultOrientation: simd_quatf = simd_quaternion(matrix_identity_float4x4)
    
    var insideArcBall: Bool = false
    var previouArcballPoint = simd_make_float3(0.0)
    var currentArcballPoint = simd_make_float3(0.0)
    
    public var target = Object()
    
    public init(camera: PerspectiveCamera, view: MTKView, defaultPosition: simd_float3, defaultOrientation: simd_quatf) {
        self.camera = camera
        self.view = view
        
        self.defaultPosition = defaultPosition
        self.defaultOrientation = defaultOrientation
        
        setup()
    }
    
    public init(camera: PerspectiveCamera, view: MTKView) {
        self.camera = camera
        self.view = view
        
        self.defaultPosition = camera.position
        self.defaultOrientation = camera.orientation
        
        setup()
    }
    
    func setup() {
        guard let camera = self.camera else { return }
        target.add(camera)
        enable()
    }
    
    deinit {
        disable()
        camera = nil
        view = nil
    }
    
    // MARK: - Updates
    
    open func update() {
        guard camera != nil else { return }
        
        var changed = false
        
        target.update()
        
        if length(translationVelocity) > 0.0001 {
            updatePosition()
            translationVelocity *= translationDamping
            changed = true
        }
        
        if abs(zoomVelocity) > 0.0001 {
            updateZoom()
            zoomVelocity *= zoomDamping
            changed = true
        }
        
        if abs(rotationVelocity) > 0.0001, length(rotationAxis) > 0.9 {
            updateOrientation()
            rotationVelocity *= rotationDamping
            changed = true
        }
        
        if abs(rollVelocity) > 0.0001 {
            updateRoll()
            rollVelocity *= rollDamping
            changed = true
        }
        
        if changed {
            onChange?()
        }
    }
    
    func updateOrientation() {
        target.orientation = simd_mul(target.orientation, simd_quatf(angle: -rotationVelocity, axis: rotationAxis))
    }
    
    func updateRoll() {
        guard let camera = self.camera else { return }
        target.orientation = simd_mul(target.orientation, simd_quatf(angle: rollVelocity, axis: camera.forwardDirection))
    }
    
    func updateZoom() {
        guard let camera = self.camera else { return }
        let offset = simd_make_float3(camera.forwardDirection * zoomVelocity)
        let offsetDistance = length(offset)
        let targetDistance = length(camera.worldPosition - target.position)
        if (targetDistance + offsetDistance * sign(zoomVelocity)) > minimumZoomDistance {
            camera.position += offset
        }
        else {
            zoomVelocity *= 0.0
        }
    }
    
    func updatePosition() {
        target.position = target.position + simd_make_float3(target.forwardDirection * translationVelocity.z)
        target.position = target.position - simd_make_float3(target.rightDirection * translationVelocity.x)
        target.position = target.position + simd_make_float3(target.upDirection * translationVelocity.y)
    }
    
    // MARK: - Events
    
    open func enable() {
        guard let view = self.view else { return }
        
        #if os(macOS)
        
        leftMouseDownHandler = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [unowned self] event in
            if self.modifierFlags.isEmpty {
                self.mouseDown(with: event)
            }
            else if event.modifierFlags.contains(self.modifierFlags) {
                self.mouseDown(with: event)
            }
            return event
        }
        
        leftMouseDraggedHandler = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDragged) { [unowned self] event in
            if self.modifierFlags.isEmpty {
                self.mouseDragged(with: event)
            }
            else if event.modifierFlags.contains(self.modifierFlags) {
                self.mouseDragged(with: event)
            }
            return event
        }
        
        leftMouseUpHandler = NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { [unowned self] event in
            if self.modifierFlags.isEmpty {
                self.mouseUp(with: event)
            }
            else if event.modifierFlags.contains(self.modifierFlags) {
                self.mouseUp(with: event)
            }
            return event
        }
        
        rightMouseDownHandler = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [unowned self] event in
            if self.modifierFlags.isEmpty {
                self.rightMouseDown(with: event)
            }
            else if event.modifierFlags.contains(self.modifierFlags) {
                self.rightMouseDown(with: event)
            }
            return event
        }
        
        rightMouseDraggedHandler = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDragged) { [unowned self] event in
            if self.modifierFlags.isEmpty {
                self.rightMouseDragged(with: event)
            }
            else if event.modifierFlags.contains(self.modifierFlags) {
                self.rightMouseDragged(with: event)
            }
            return event
        }
        
        rightMouseUpHandler = NSEvent.addLocalMonitorForEvents(matching: .rightMouseUp) { [unowned self] event in
            if self.modifierFlags.isEmpty {
                self.rightMouseUp(with: event)
            }
            else if event.modifierFlags.contains(self.modifierFlags) {
                self.rightMouseUp(with: event)
            }
            return event
        }
        
        otherMouseDownHandler = NSEvent.addLocalMonitorForEvents(matching: .otherMouseDown) { [unowned self] event in
            if self.modifierFlags.isEmpty {
                self.otherMouseDown(with: event)
            }
            else if event.modifierFlags.contains(self.modifierFlags) {
                self.otherMouseDown(with: event)
            }
            return event
        }
        
        otherMouseDraggedHandler = NSEvent.addLocalMonitorForEvents(matching: .otherMouseDragged) { [unowned self] event in
            if self.modifierFlags.isEmpty {
                self.otherMouseDragged(with: event)
            }
            else if event.modifierFlags.contains(self.modifierFlags) {
                self.otherMouseDragged(with: event)
            }
            return event
        }
        
        otherMouseUpHandler = NSEvent.addLocalMonitorForEvents(matching: .otherMouseUp) { [unowned self] event in
            if self.modifierFlags.isEmpty {
                self.otherMouseUp(with: event)
            }
            else if event.modifierFlags.contains(self.modifierFlags) {
                self.otherMouseUp(with: event)
            }
            return event
        }
        
        scrollWheelHandler = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [unowned self] event in
            if self.modifierFlags.isEmpty {
                self.scrollWheel(with: event)
            }
            else if event.modifierFlags.contains(self.modifierFlags) {
                self.scrollWheel(with: event)
            }
            return event
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
        
        enabled = true
    }
    
    open func disable() {
        guard let view = self.view else { return }
        
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
        
        enabled = false
    }
    
    #if os(macOS)
    
    // MARK: - Mouse
    
    func mouseDown(with event: NSEvent) {
        guard let view = self.view else { return }
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
        guard let view = self.view else { return }
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
        guard let view = self.view else { return }
        if event.window == view.window {
            state = .inactive
        }
    }
    
    // MARK: - Right Mouse
    
    func rightMouseDown(with event: NSEvent) {
        guard let view = self.view else { return }
        if event.window == view.window {}
    }
    
    func rightMouseDragged(with event: NSEvent) {
        guard let view = self.view else { return }
        if event.window == view.window {
            let dy = Float(event.deltaY) / mouseDeltaSensitivity
            if event.modifierFlags.contains(NSEvent.ModifierFlags.command) {
                state = .dollying
                translationVelocity.z -= dy * translationScalar
            }
            else {
                state = .zooming
                zoomVelocity -= dy * zoomScalar
            }
        }
    }
    
    func rightMouseUp(with event: NSEvent) {
        guard let view = self.view else { return }
        if event.window == view.window {
            state = .inactive
        }
    }
    
    // MARK: - Other Mouse
    
    func otherMouseDown(with event: NSEvent) {
        guard let view = self.view else { return }
        if event.window == view.window {
            state = .panning
        }
    }
    
    func otherMouseDragged(with event: NSEvent) {
        guard let view = self.view else { return }
        if event.window == view.window {
            let dx = Float(event.deltaX) / mouseDeltaSensitivity
            let dy = Float(event.deltaY) / mouseDeltaSensitivity
            state = .panning
            translationVelocity.x += dx * translationScalar
            translationVelocity.y += dy * translationScalar
        }
    }
    
    func otherMouseUp(with event: NSEvent) {
        guard let view = self.view else { return }
        if event.window == view.window {
            state = .inactive
        }
    }
    
    // MARK: - Scroll Wheel
    
    func scrollWheel(with event: NSEvent) {
        guard let camera = self.camera, let view = self.view else { return }
        if event.window == view.window {
            if length(simd_float2(Float(event.deltaX), Float(event.deltaY))) < Float.ulpOfOne {
                state = .inactive
            }
            else if event.modifierFlags.contains(NSEvent.ModifierFlags.option) && (event.phase == .began || event.phase == .changed) {
                if abs(event.deltaX) > abs(event.deltaY) {
                    state = .rolling
                    let sdx = Float(event.scrollingDeltaX) / scrollDeltaSensitivity
                    rollVelocity += sdx * rollScalar
                }
                else {
                    state = .zooming
                    let sdy = Float(event.scrollingDeltaY) / scrollDeltaSensitivity
                    zoomVelocity -= sdy * zoomScalar
                }
            }
            else if event.phase == .began || event.phase == .changed {
                state = .panning
                let cd = length(camera.worldPosition - target.position) / 10.0
                let dx = Float(event.scrollingDeltaX) / scrollDeltaSensitivity
                let dy = Float(event.scrollingDeltaY) / scrollDeltaSensitivity
                translationVelocity.x += dx * translationScalar * cd
                translationVelocity.y += dy * translationScalar * cd
            }
        }
    }
    
    // MARK: - Gestures macOS
    
    @objc func magnifyGesture(_ gestureRecognizer: NSMagnificationGestureRecognizer) {
        let newMagnification = Float(gestureRecognizer.magnification)
        if gestureRecognizer.state == .began {
            state = .zooming
            magnification = newMagnification
        }
        else if gestureRecognizer.state == .changed, state == .zooming {
            let velocity = newMagnification - magnification
            zoomVelocity -= velocity * zoomScalar
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
            rollVelocity -= Float(gestureRecognizer.rotation) * rollScalar * 0.5
            gestureRecognizer.rotation = 0.0
        }
        else {
            state = .inactive
        }
    }
    
    #elseif os(iOS)
    
    // MARK: - Gestures iOS
    
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
            rollVelocity += Float(gestureRecognizer.rotation) * rollScalar * 0.5
            gestureRecognizer.rotation = 0.0
        }
        else {
            state = .inactive
        }
    }
    
    @objc func rotateGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let view = self.view else { return }
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
    
    var panCurrentPoint = simd_float2(repeating: 0.0)
    var panPreviousPoint = simd_float2(repeating: 0.0)
    
    @objc func panGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let camera = self.camera, let view = self.view else { return }
        if gestureRecognizer.state == .began {
            state = .panning
            panPreviousPoint = normalizePoint(gestureRecognizer.translation(in: view), view.frame.size)
        }
        else if gestureRecognizer.state == .changed, state == .panning {
            panCurrentPoint = normalizePoint(gestureRecognizer.translation(in: view), view.frame.size)
            let delta = panCurrentPoint - panPreviousPoint
            let cd = length(camera.worldPosition - target.position) / 10.0
            translationVelocity.x += translationScalar * delta.x * cd
            translationVelocity.y -= translationScalar * delta.y * cd
            panPreviousPoint = panCurrentPoint
        }
        else {
            state = .inactive
        }
    }
    
    @objc func pinchGesture(_ gestureRecognizer: UIPinchGestureRecognizer) {
        if gestureRecognizer.state == .began {
            state = .zooming
            pinchScale = Float(gestureRecognizer.scale)
        }
        else if gestureRecognizer.state == .changed, state == .zooming {
            let newScale = Float(gestureRecognizer.scale)
            let delta = pinchScale - newScale
            zoomVelocity += delta * zoomScalar
            pinchScale = newScale
        }
        else {
            state = .inactive
        }
    }
    
    #endif
    
    // MARK: - Helpers
    
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
    
    open func reset() {
        DispatchQueue.main.async { [unowned self] in
            self.state = .inactive
            self.rotationVelocity = 0.0
            self.translationVelocity = simd_make_float3(0.0)
            self.zoomVelocity = 0.0
            self.rollVelocity = 0.0
            
            self.target.position = simd_float3(repeating: 0.0)
            self.target.orientation = simd_quatf(matrix_identity_float4x4)
            
            guard let camera = self.camera else { return }
            camera.position = self.defaultPosition
            camera.orientation = self.defaultOrientation
            camera.updateMatrix = true
            
            self.onChange?()
        }
    }
}
