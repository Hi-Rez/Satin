//
//  OrthographicCameraController.swift
//  Pods
//
//  Created by Reza Ali on 11/21/20.
//

import MetalKit
import simd

open class OrthographicCameraController: CameraController {
    public required convenience init(from decoder: Decoder) throws {
        try self.init(from: decoder)
        let values = try decoder.container(keyedBy: CodingKeys.self)
        camera = try values.decode(OrthographicCamera.self, forKey: .camera)
        defaultPosition = try values.decode(simd_float3.self, forKey: .defaultPosition)
        defaultOrientation = try values.decode(simd_quatf.self, forKey: .defaultOrientation)
        defaultLeft = try values.decode(Float.self, forKey: .defaultLeft)
        defaultRight = try values.decode(Float.self, forKey: .defaultRight)
        defaultTop = try values.decode(Float.self, forKey: .defaultTop)
        defaultBottom = try values.decode(Float.self, forKey: .defaultBottom)
        setup()
    }
    
    open override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(camera, forKey: .camera)
        try container.encode(defaultPosition, forKey: .defaultPosition)
        try container.encode(defaultOrientation, forKey: .defaultOrientation)
        try container.encode(defaultLeft, forKey: .defaultLeft)
        try container.encode(defaultRight, forKey: .defaultRight)
        try container.encode(defaultTop, forKey: .defaultTop)
        try container.encode(defaultBottom, forKey: .defaultBottom)
    }
    
    private enum CodingKeys: String, CodingKey {
        case camera
        case defaultPosition
        case defaultOrientation
        case modifierFlags
        case defaultLeft
        case defaultRight
        case defaultTop
        case defaultBottom
    }
       
    public var camera: OrthographicCamera?

    open var defaultPosition: simd_float3 = simd_make_float3(0.0, 0.0, 1.0)
    open var defaultOrientation: simd_quatf = simd_quaternion(matrix_identity_float4x4)
    open var defaultLeft: Float = 0
    open var defaultRight: Float = 0
    open var defaultTop: Float = 0
    open var defaultBottom: Float = 0
    
    public init(camera: OrthographicCamera, view: MTKView, defaultPosition: simd_float3, defaultOrientation: simd_quatf) {
        super.init(view: view)
        
        self.camera = camera
        
        defaultLeft = camera.left
        defaultRight = camera.right
        defaultTop = camera.top
        defaultBottom = camera.bottom
                
        self.defaultPosition = defaultPosition
        self.defaultOrientation = defaultOrientation
        
        setup()
    }
    
    public init(camera: OrthographicCamera, view: MTKView) {
        super.init(view: view)
        
        self.camera = camera
        
        defaultLeft = camera.left
        defaultRight = camera.right
        defaultTop = camera.top
        defaultBottom = camera.bottom
        
        defaultPosition = camera.position
        defaultOrientation = camera.orientation
        
        setup()
    }
    
    func setup() {
        guard let camera = self.camera else { return }
        camera.orientation = defaultOrientation
        camera.position = defaultPosition
        enable()
    }
    
    func pan(_ deltaX: Float, _ deltaY: Float) {
        guard let camera = self.camera else { return }
        
        let cameraWidth = camera.right - camera.left
        let cameraHeight = camera.top - camera.bottom
        
        let deltaX = deltaX * cameraWidth
        let deltaY = deltaY * cameraHeight
        
        camera.left -= deltaX
        camera.right -= deltaX
        
        camera.top += deltaY
        camera.bottom += deltaY
        
        onChange?()
    }
    
    func zoom(_ delta: Float) {
        guard let camera = self.camera else { return }
        
        let cameraWidth = camera.right - camera.left
        let cameraHeight = camera.top - camera.bottom
        
        let deltaX = delta * cameraWidth
        let deltaY = delta * cameraHeight
        
        camera.left -= deltaX
        camera.right += deltaX
        
        camera.top += deltaY
        camera.bottom -= deltaY
        
        onChange?()
    }
    
    func roll(_ delta: Float) {
        guard let camera = self.camera else { return }
        camera.orientation = simd_mul(camera.orientation, simd_quatf(angle: delta, axis: camera.forwardDirection))
        onChange?()
    }
    
    var panCurrentPoint = CGPoint(x: 0, y: 0)
    var panPreviousPoint = CGPoint(x: 0, y: 0)
    
    #if os(macOS)
    
    // MARK: - Mouse
    
    override func mouseDown(with event: NSEvent) {
        guard let view = self.view, event.window == view.window else { return }
        if event.clickCount == 2 {
            reset()
        }
        else {
            state = .panning
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let view = self.view, event.window == view.window else { return }
        state = .panning
        
        let dx = Float(event.deltaX / view.frame.size.width)
        let dy = Float(event.deltaY / view.frame.size.height)
        
        pan(dx, dy)
    }
    
    override func mouseUp(with event: NSEvent) {
        guard let view = self.view, event.window == view.window else { return }
        state = .inactive
    }
    
    
    // MARK: - Other Mouse
    
    override func otherMouseDown(with event: NSEvent) {
        mouseDown(with: event)
    }
    
    override func otherMouseDragged(with event: NSEvent) {
        mouseDragged(with: event)
    }
    
    override func otherMouseUp(with event: NSEvent) {
        mouseUp(with: event)
    }
    
    
    // MARK: - Right Mouse
    
    override func rightMouseDown(with event: NSEvent) {
        guard let view = self.view, event.window == view.window else { return }
        state = .zooming
    }
    
    override func rightMouseDragged(with event: NSEvent) {
        guard let view = self.view, event.window == view.window else { return }
        state = .zooming
        zoom(Float(-event.deltaY / view.frame.size.height))
    }
    
    override func rightMouseUp(with event: NSEvent) {
        guard let view = self.view, event.window == view.window else { return }
        state = .inactive
    }
    
    // MARK: - Scroll Wheel
    
    override func scrollWheel(with event: NSEvent) {
        guard let view = self.view, event.window == view.window else { return }
        let deltaX = Float(event.scrollingDeltaX / view.frame.size.width)
        let deltaY = Float(event.scrollingDeltaY / view.frame.size.height)
        if abs(deltaX) < Float.ulpOfOne, abs(deltaY) < Float.ulpOfOne {
            state = .inactive
        }
        else if event.phase == .began || event.phase == .changed {
            state = .panning
            pan(deltaX, deltaY)
        }
    }
    
    override func magnifyGesture(_ gestureRecognizer: NSMagnificationGestureRecognizer) {
        let newMagnification = Float(gestureRecognizer.magnification)
        if gestureRecognizer.state == .began {
            state = .zooming
            magnification = newMagnification
        }
        else if gestureRecognizer.state == .changed, state == .zooming {
            let delta = magnification - newMagnification
            zoom(delta)
            magnification = newMagnification
        }
        else {
            state = .inactive
        }
    }
    
    override func rollGesture(_ gestureRecognizer: NSRotationGestureRecognizer) {
        if gestureRecognizer.state == .began {
            state = .rolling
        }
        else if gestureRecognizer.state == .changed, state == .rolling {
            roll(-Float(gestureRecognizer.rotation))
            gestureRecognizer.rotation = 0.0
        }
        else {
            state = .inactive
        }
    }
    
    #elseif os(iOS)
    
    // MARK: - Gestures iOS
    
    @objc override func tapGesture(_ gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            reset()
        }
    }
    
    @objc override func rollGesture(_ gestureRecognizer: UIRotationGestureRecognizer) {
        if gestureRecognizer.state == .began {
            state = .rolling
        }
        else if gestureRecognizer.state == .changed, state == .rolling {
            roll(Float(gestureRecognizer.rotation))
            gestureRecognizer.rotation = 0.0
        }
        else {
            state = .inactive
        }
    }
    
    @objc override func panGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let view = self.view else { return }
        if gestureRecognizer.state == .began {
            state = .panning
            panPreviousPoint = gestureRecognizer.translation(in: view)
        }
        else if gestureRecognizer.state == .changed, state == .panning {
            panCurrentPoint = gestureRecognizer.translation(in: view)
            let deltaX = panCurrentPoint.x - panPreviousPoint.x
            let deltaY = panCurrentPoint.y - panPreviousPoint.y
            
            let dx = Float(deltaX / view.frame.size.width)
            let dy = Float(deltaY / view.frame.size.height)
            
            pan(dx, dy)
            panPreviousPoint = panCurrentPoint
        }
        else {
            state = .inactive
        }
    }
    
    @objc override func pinchGesture(_ gestureRecognizer: UIPinchGestureRecognizer) {
        if gestureRecognizer.state == .began {
            state = .zooming
            pinchScale = Float(gestureRecognizer.scale)
        }
        else if gestureRecognizer.state == .changed, state == .zooming {
            let newScale = Float(gestureRecognizer.scale)
            let delta = pinchScale - newScale
            zoom(delta)
            pinchScale = newScale
        }
        else {
            state = .inactive
        }
    }
    
    #endif
    
    override open func reset() {
        DispatchQueue.main.async { [unowned self] in
            self.state = .inactive
            
            guard let camera = self.camera else { return }
            
            camera.left = defaultLeft
            camera.right = defaultRight
            camera.top = defaultTop
            camera.bottom = defaultBottom
            
            camera.orientation = defaultOrientation
            camera.position = defaultPosition
            camera.updateMatrix = true
            
            self.onChange?()
        }
    }
}
