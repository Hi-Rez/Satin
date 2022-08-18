//
//  PerspectiveCameraController.swift
//  Satin
//
//  Created by Reza Ali on 7/29/20.
//

import MetalKit
import simd

open class PerspectiveCameraController: CameraController {
    #if os(iOS)
    var rotateGestureRecognizer: UIPanGestureRecognizer!
    #endif

    override private init() {
        super.init()
    }
    
    public required convenience init(from decoder: Decoder) throws {
        self.init()
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
    }
    
    override open func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
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
    
    open var mouseDeltaSensitivity: Float = 600.0
    open var scrollDeltaSensitivity: Float = 600.0
    
    public var camera: PerspectiveCamera?
    
    // Rotation
    open var rotationDamping: Float = 0.9
    #if os(macOS)
    open var rotationScalar: Float = 5.0
    #elseif os(iOS)
    open var rotationScalar: Float = 3.0
    #elseif os(tvOS)
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
    #elseif os(tvOS)
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
    
    open var zoomScalar: Float = 0.5
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
        super.init(view: view)
        
        self.camera = camera
        
        self.defaultPosition = defaultPosition
        self.defaultOrientation = defaultOrientation
        
        setup()
    }
    
    public init(camera: PerspectiveCamera, view: MTKView) {
        super.init(view: view)
        
        self.camera = camera
        
        defaultPosition = camera.position
        defaultOrientation = camera.orientation
        
        setup()
    }
    
    func setup() {
        guard let camera = camera else { return }
        camera.orientation = defaultOrientation
        camera.position = defaultPosition
        enable()
    }
    
    override func _enable(_ view: MTKView) {
        super._enable(view)
    
        halt()
        
        if let camera = camera {
            target.orientation = camera.orientation
            camera.position = [0, 0, simd_length(camera.worldPosition - target.worldPosition)]
            camera.orientation = simd_quatf(matrix_identity_float4x4)
            target.add(camera)
        }
        
        #if os(iOS)
        let allowedTouchTypes: [NSNumber] = [UITouch.TouchType.direct.rawValue as NSNumber]
        rotateGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(rotateGesture))
        rotateGestureRecognizer.allowedTouchTypes = allowedTouchTypes
        rotateGestureRecognizer.minimumNumberOfTouches = 1
        rotateGestureRecognizer.maximumNumberOfTouches = 1
        view.addGestureRecognizer(rotateGestureRecognizer)
        
        minimumPanningTouches = 2
        maximumPanningTouches = 2
        #endif
    }
    
    override func _disable(_ view: MTKView) {
        super._disable(view)
        
        halt()
        
        if let camera = camera {
            let cameraWorldMatrix = camera.worldMatrix
            target.remove(camera)
            camera.localMatrix = cameraWorldMatrix
        }
        
        #if os(iOS)
        view.removeGestureRecognizer(rotateGestureRecognizer)
        #endif
    }
    
    deinit {
        camera = nil
    }
    
    // MARK: - Updates
    
    override open func update() {
        guard camera != nil else { return }
        
        var changed = false
        let changeLimit: Float = 0.001
        
        target.update()
        
        if length(translationVelocity) > changeLimit {
            updatePosition()
            translationVelocity *= translationDamping
            changed = true
        }
        
        if abs(zoomVelocity) > changeLimit {
            updateZoom()
            zoomVelocity *= zoomDamping
            changed = true
        }
        
        if abs(rotationVelocity) > changeLimit, length(rotationAxis) > 0.9 {
            updateOrientation()
            rotationVelocity *= rotationDamping
            changed = true
        }
        
        if abs(rollVelocity) > changeLimit {
            updateRoll()
            rollVelocity *= rollDamping
            changed = true
        }
        
        if changed == true, isTweening == false {
            start()
        }
        else if changed == true, isTweening == true {
            change()
        }
        else if changed == false, isTweening == true {
            end()
        }
        
        isTweening = changed
    }
    
    // MARK: - Reset
    
    func halt() {
        state = .inactive
        rotationVelocity = 0.0
        translationVelocity = simd_make_float3(0.0)
        zoomVelocity = 0.0
        rollVelocity = 0.0
    }
    
    override open func reset() {
        if enabled {
            DispatchQueue.main.async { [unowned self] in
                self.halt()
                
                self.target.orientation = defaultOrientation
                self.target.position = simd_float3(repeating: 0.0)
                
                guard let camera = self.camera else { return }
                camera.orientation = simd_quatf(matrix_identity_float4x4)
                camera.position = [0, 0, simd_length(defaultPosition)]
                camera.updateMatrix = true
                
                start()
                change()
                end()
            }
        }
    }
    
    func updateOrientation() {
        target.orientation = simd_mul(target.orientation, simd_quatf(angle: -rotationVelocity, axis: rotationAxis))
    }
    
    func updateRoll() {
        guard let camera = camera else { return }
        target.orientation = simd_mul(target.orientation, simd_quatf(angle: rollVelocity, axis: camera.forwardDirection))
    }
    
    func updateZoom() {
        guard let camera = camera else { return }
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
    
    override open func resize(_ size: (width: Float, height: Float)) {
        if let camera = camera {
            camera.aspect = size.width / size.height
        }
    }
    
    #if os(macOS)
    
    // MARK: - Mouse
    
    override open func mouseDown(with event: NSEvent) {
        guard let view = view, event.window == view.window else { return }
        if event.clickCount == 2 {
            reset()
        }
        else {
            let result = arcballPoint(view.convert(event.locationInWindow, from: nil), view.frame.size)
            previouArcballPoint = result.point
            insideArcBall = result.inside
            state = .rotating
        }
    }
    
    override open func mouseDragged(with event: NSEvent) {
        guard let view = view, event.window == view.window else { return }
        if state == .rotating {
            let result = arcballPoint(view.convert(event.locationInWindow, from: nil), view.frame.size)
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
            mouseDown(with: event)
        }
    }
    
    override open func mouseUp(with event: NSEvent) {
        guard let view = view, event.window == view.window else { return }
        state = .inactive
    }
    
    // MARK: - Right Mouse
    
    override open func rightMouseDown(with event: NSEvent) {
        guard let view = view, event.window == view.window else { return }
    }
    
    override open func rightMouseDragged(with event: NSEvent) {
        guard let view = view, event.window == view.window, let camera = camera else { return }
        let dy = Float(event.deltaY) / mouseDeltaSensitivity
        if event.modifierFlags.contains(NSEvent.ModifierFlags.option) {
            state = .dollying
            translationVelocity.z -= dy * translationScalar
        }
        else {
            state = .zooming
            zoomVelocity -= dy * zoomScalar * (180.0 / camera.fov)
        }
    }
    
    override open func rightMouseUp(with event: NSEvent) {
        guard let view = view, event.window == view.window else { return }
        state = .inactive
    }
    
    // MARK: - Other Mouse
    
    override open func otherMouseDown(with event: NSEvent) {
        guard let view = view, event.window == view.window else { return }
        state = .panning
    }
    
    override open func otherMouseDragged(with event: NSEvent) {
        guard let view = view, event.window == view.window, let camera = camera else { return }
        let dx = Float(event.deltaX) / mouseDeltaSensitivity
        let dy = Float(event.deltaY) / mouseDeltaSensitivity
        state = .panning
        let cd = length(camera.worldPosition - target.position) / 10.0
        translationVelocity.x += dx * translationScalar * cd
        translationVelocity.y += dy * translationScalar * cd
    }
    
    override open func otherMouseUp(with event: NSEvent) {
        guard let view = view, event.window == view.window else { return }
        state = .inactive
    }
    
    // MARK: - Scroll Wheel
    
    override open func scrollWheel(with event: NSEvent) {
        guard let camera = camera, let view = view, event.window == view.window else { return }
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
                zoomVelocity -= sdy * zoomScalar * (180.0 / camera.fov)
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
    
    // MARK: - Gestures macOS
    
    override open func magnifyGesture(_ gestureRecognizer: NSMagnificationGestureRecognizer) {
        guard let camera = camera else { return }
        let newMagnification = Float(gestureRecognizer.magnification)
        if gestureRecognizer.state == .began {
            state = .zooming
            magnification = newMagnification
        }
        else if gestureRecognizer.state == .changed, state == .zooming {
            let velocity = newMagnification - magnification
            zoomVelocity -= velocity * zoomScalar * (180.0 / camera.fov)
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
            rollVelocity -= Float(gestureRecognizer.rotation) * rollScalar * 0.5
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
            rollVelocity += Float(gestureRecognizer.rotation) * rollScalar * 0.5
            gestureRecognizer.rotation = 0.0
        }
        else {
            state = .inactive
        }
    }
    
    @objc open func rotateGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let view = view else { return }
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
            else if gestureRecognizer.state == .changed {
                if state == .rotating {
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
                    gestureRecognizer.state = .began
                    rotateGesture(gestureRecognizer)
                }
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
    
    @objc override open func panGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let camera = camera, let view = view else { return }
        if gestureRecognizer.state == .began {
            state = .panning
            panPreviousPoint = normalizePoint(gestureRecognizer.translation(in: view), view.frame.size)
        }
        else if gestureRecognizer.state == .changed {
            if state == .panning {
                panCurrentPoint = normalizePoint(gestureRecognizer.translation(in: view), view.frame.size)
                let delta = panCurrentPoint - panPreviousPoint
                let cd = length(camera.worldPosition - target.position) / 10.0
                translationVelocity.x += translationScalar * delta.x * cd
                translationVelocity.y -= translationScalar * delta.y * cd
                panPreviousPoint = panCurrentPoint
            }
            else {
                state = .panning
                panPreviousPoint = normalizePoint(gestureRecognizer.translation(in: view), view.frame.size)
            }
        }
        else {
            state = .inactive
        }
    }
    
    @objc override open func pinchGesture(_ gestureRecognizer: UIPinchGestureRecognizer) {
        guard let camera = camera else { return }
        if gestureRecognizer.state == .began {
            state = .zooming
            pinchScale = Float(gestureRecognizer.scale)
        }
        else if gestureRecognizer.state == .changed, state == .zooming {
            let newScale = Float(gestureRecognizer.scale)
            let delta = pinchScale - newScale
            zoomVelocity += delta * zoomScalar * (180.0 / camera.fov)
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
    
    func arcballPoint(_ point: CGPoint, _ size: CGSize) -> (inside: Bool, point: simd_float3) {
        var inside = false
        let pt = normalizePoint(point, size)
        var result: simd_float3
        let r = pt.x * pt.x + pt.y * pt.y
        if r > 1.0 {
            let s = 1.0 / sqrt(r)
            result = s * simd_make_float3(pt)
        }
        else {
            result = simd_make_float3(pt.x, pt.y, sqrt(1.0 - r))
            inside = true
        }
        return (inside: inside, point: result)
    }
    
    // MARK: - Load
    
    override open func load(_ url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let loaded = try JSONDecoder().decode(PerspectiveCameraController.self, from: data)
            target.setFrom(loaded.target)
            if let camera = camera, let loadedCamera = loaded.camera {
                camera.setFrom(loadedCamera)
            }
        }
        catch {
            print(error.localizedDescription)
        }
    }
}
 
