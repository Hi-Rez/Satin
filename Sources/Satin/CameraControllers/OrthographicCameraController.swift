//
//  OrthographicCameraController.swift
//  Pods
//
//  Created by Reza Ali on 11/21/20.
//

import MetalKit
import simd

open class OrthographicCameraController: CameraController {
    override private init() {
        super.init()
    }
    
    public required convenience init(from decoder: Decoder) throws {
        self.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        camera = try values.decode(OrthographicCamera.self, forKey: .camera)
        defaultPosition = try values.decode(simd_float3.self, forKey: .defaultPosition)
        defaultOrientation = try values.decode(simd_quatf.self, forKey: .defaultOrientation)
        defaultZoom = try values.decode(Float.self, forKey: .defaultZoom)
        zoomDelta = try values.decode(Float.self, forKey: .zoomDelta)
        panDelta = try values.decode(simd_float2.self, forKey: .panDelta)
    }
    
    override open func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(camera, forKey: .camera)
        try container.encode(defaultPosition, forKey: .defaultPosition)
        try container.encode(defaultOrientation, forKey: .defaultOrientation)
        try container.encode(defaultZoom, forKey: .defaultZoom)
        try container.encode(zoomDelta, forKey: .zoomDelta)
        try container.encode(panDelta, forKey: .panDelta)
    }
    
    private enum CodingKeys: String, CodingKey {
        case camera
        case defaultPosition
        case defaultOrientation
        case modifierFlags
        case defaultZoom
        case zoomDelta
        case panDelta
    }
       
    public var camera: OrthographicCamera?
    
    var needsSetup: Bool = true
    
    open var defaultPosition: simd_float3 = simd_make_float3(0.0, 0.0, 1.0)
    open var defaultOrientation: simd_quatf = simd_quaternion(matrix_identity_float4x4)

    var defaultZoom: Float = 0.5
    var zoomDelta: Float = 0.5
    var panDelta = simd_make_float2(0.0, 0.0)
    
    public init(camera: OrthographicCamera, view: MTKView, defaultZoom: Float = 0.5, defaultPosition: simd_float3, defaultOrientation: simd_quatf) {
        self.camera = camera
        zoomDelta = defaultZoom
        self.defaultZoom = defaultZoom
        self.defaultPosition = defaultPosition
        self.defaultOrientation = defaultOrientation
        
        super.init(view: view)

        setup()
    }
    
    public init(camera: OrthographicCamera, view: MTKView, defaultZoom: Float = 0.5) {
        self.camera = camera
        zoomDelta = defaultZoom
        self.defaultZoom = defaultZoom
        defaultPosition = camera.position
        defaultOrientation = camera.orientation
        
        super.init(view: view)
        
        setup()
    }
    
    override open func update() {
        if needsSetup {
            needsSetup = setupCamera()
        }
        super.update()
    }
    
    func setupCamera() -> Bool {
        guard let camera = camera, let view = view, view.drawableSize.width > 0, view.drawableSize.height > 0 else { return true }
        let hw = Float(view.drawableSize.width) * defaultZoom
        let hh = Float(view.drawableSize.height) * defaultZoom
        camera.update(left: -hw, right: hw, bottom: -hh, top: hh, near: camera.near, far: camera.far)
        return false
    }
    
    func setup() {
        guard let camera = camera else { return }
        camera.orientation = defaultOrientation
        camera.position = defaultPosition
        enable()
    }
    
    func pan(_ deltaX: Float, _ deltaY: Float) {
        guard let camera = camera else { return }
        
        let cameraWidth = camera.right - camera.left
        let cameraHeight = camera.top - camera.bottom
        
        let deltaX = deltaX * cameraWidth
        let deltaY = deltaY * cameraHeight
        
        panDelta += [deltaX, deltaY]

        camera.position -= camera.worldRightDirection * deltaX
        camera.position += camera.worldUpDirection * deltaY
        
        change()
    }
    
    func zoom(_ delta: Float) {
        guard let camera = camera else { return }
        
        let cameraWidth = camera.right - camera.left
        let cameraHeight = camera.top - camera.bottom
        
        let deltaX = delta * cameraWidth
        let deltaY = delta * cameraHeight
        
        camera.left -= deltaX
        camera.right += deltaX
        
        camera.top += deltaY
        camera.bottom -= deltaY
        
        change()
    }
    
    func roll(_ delta: Float) {
        guard let camera = camera else { return }
        camera.orientation = simd_quatf(angle: delta, axis: camera.worldForwardDirection) * camera.orientation
        change()
    }
    
    var panCurrentPoint = CGPoint(x: 0, y: 0)
    var panPreviousPoint = CGPoint(x: 0, y: 0)
    
    #if os(macOS)
    
    // MARK: - Mouse
    
    override open func mouseDown(with event: NSEvent) {
        guard let view = view, event.window == view.window else { return }
        if event.clickCount == 2 {
            start()
            change()
            reset()
            end()
        }
        else if minimumPanningTouches == 1 {
            state = .panning
        }
    }
    
    override open func mouseDragged(with event: NSEvent) {
        guard let view = view, event.window == view.window, minimumPanningTouches == 1 else { return }
        state = .panning
        
        let dx = Float(event.deltaX / view.frame.size.width)
        let dy = Float(event.deltaY / view.frame.size.height)
        
        pan(dx, dy)
    }
    
    override open func mouseUp(with event: NSEvent) {
        guard let view = view, event.window == view.window, minimumPanningTouches == 1 else { return }
        state = .inactive
    }
    
    // MARK: - Other Mouse
    
    override open func otherMouseDown(with event: NSEvent) {
        guard let view = view, event.window == view.window else { return }
        state = .panning
    }
    
    override open func otherMouseDragged(with event: NSEvent) {
        guard let view = view, event.window == view.window else { return }
        state = .panning
        
        let dx = Float(event.deltaX / view.frame.size.width)
        let dy = Float(event.deltaY / view.frame.size.height)
        
        pan(dx, dy)
    }
    
    override open func otherMouseUp(with event: NSEvent) {
        guard let view = view, event.window == view.window else { return }
        state = .inactive
    }
    
    // MARK: - Right Mouse
    
    override open func rightMouseDown(with event: NSEvent) {
        guard let view = view, event.window == view.window else { return }
        state = .zooming
    }
    
    override open func rightMouseDragged(with event: NSEvent) {
        guard let view = view, event.window == view.window else { return }
        state = .zooming
        zoom(Float(-event.deltaY / view.frame.size.height))
    }
    
    override open func rightMouseUp(with event: NSEvent) {
        guard let view = view, event.window == view.window else { return }
        state = .inactive
    }
    
    // MARK: - Scroll Wheel
    
    override open func scrollWheel(with event: NSEvent) {
        guard let view = view, event.window == view.window else { return }
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
    
    override open func magnifyGesture(_ gestureRecognizer: NSMagnificationGestureRecognizer) {
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
    
    override open func rollGesture(_ gestureRecognizer: NSRotationGestureRecognizer) {
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
    
    @objc override open func tapGesture(_ gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            reset()
        }
    }
    
    @objc override open func rollGesture(_ gestureRecognizer: UIRotationGestureRecognizer) {
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
    
    @objc override open func panGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let view = view else { return }
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
    
    @objc override open func pinchGesture(_ gestureRecognizer: UIPinchGestureRecognizer) {
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
    
    override open func resize(_ size: (width: Float, height: Float)) {
        guard !needsSetup, let camera = camera, let view = view else { return }
        let cameraWidth = abs(camera.right - camera.left)
        zoomDelta = cameraWidth / Float(2.0 * view.drawableSize.width)
            
        let hw = size.width * zoomDelta
        let hh = size.height * zoomDelta
        self.camera?.update(left: -hw, right: hw, bottom: -hh, top: hh, near: camera.near, far: camera.far)
    }
    
    override open func reset() {
        if enabled {
            DispatchQueue.main.async { [unowned self] in
                self.state = .inactive
                
                guard let camera = self.camera else { return }
                
                panDelta = [0.0, 0.0]
                zoomDelta = defaultZoom
                
                _ = setupCamera()
                
                camera.orientation = defaultOrientation
                camera.position = defaultPosition
                camera.updateMatrix = true

                start()
                change()
                end()
            }
        }
    }
    
    // MARK: - Load
    
    override open func load(_ url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let loaded = try JSONDecoder().decode(OrthographicCameraController.self, from: data)
            if let camera = camera, let loadedCamera = loaded.camera {
                camera.setFrom(loadedCamera)
            }
            zoomDelta = loaded.zoomDelta
            panDelta = loaded.panDelta
            needsSetup = false
        }
        catch {
            print(error.localizedDescription)
        }
    }
}
