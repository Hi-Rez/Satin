//
//  OrthographicCameraController.swift
//  Satin
//
//  Created by Reza Ali on 03/26/23.
//

import Combine
import MetalKit
import simd

public final class OrthographicCameraController: CameraController, Codable {
    public internal(set) var isEnabled = false

    public var camera: OrthographicCamera {
        willSet {
            disable()
        }
        didSet {
            enable()
        }
    }

    public var view: MTKView? {
        willSet {
            disable()
        }
        didSet {
            enable()
        }
    }

    public internal(set) var state: CameraControllerState = .inactive {
        didSet {
            if oldValue == .inactive, state != .inactive {
                onStartPublisher.send(self)
            } else if oldValue != .inactive, state == .inactive {
                onEndPublisher.send(self)
            }
        }
    }

    // MARK: - Events

    public let onStartPublisher = PassthroughSubject<OrthographicCameraController, Never>()
    public let onChangePublisher = PassthroughSubject<OrthographicCameraController, Never>()
    public let onEndPublisher = PassthroughSubject<OrthographicCameraController, Never>()

    private var defaultPosition = simd_make_float3(0.0, 0.0, 1.0)
    private var defaultOrientation = simd_quaternion(matrix_identity_float4x4)

    private var defaultZoom: Float = 0.5
    private var zoomDelta: Float = 0.5
    private var panDelta: simd_float2 = .zero
    private var panCurrentPoint: simd_float2 = .zero
    private var panPreviousPoint: simd_float2 = .zero

    #if os(macOS)

    private var leftMouseDownHandler: Any?
    private var leftMouseDraggedHandler: Any?
    private var leftMouseUpHandler: Any?

    private var rightMouseDownHandler: Any?
    private var rightMouseDraggedHandler: Any?
    private var rightMouseUpHandler: Any?

    private var otherMouseDownHandler: Any?
    private var otherMouseDraggedHandler: Any?
    private var otherMouseUpHandler: Any?

    private var scrollWheelHandler: Any?

    private var magnification: Float = 1.0
    private var magnifyGestureRecognizer: NSMagnificationGestureRecognizer!
    private var rollGestureRecognizer: NSRotationGestureRecognizer!

    #elseif os(iOS)

    private var rollRotation: Float = 0.0
    private var rollGestureRecognizer: UIRotationGestureRecognizer!

    private var panGestureRecognizer: UIPanGestureRecognizer!

    private var rotateGestureRecognizer: UIPanGestureRecognizer!

    private var pinchScale: Float = 1.0
    private var pinchGestureRecognizer: UIPinchGestureRecognizer!

    private var tapGestureRecognizer: UITapGestureRecognizer!

    #endif

    private var isSetup = false

    public init(camera: OrthographicCamera, view: MTKView, defaultZoom: Float = 0.5) {
        self.camera = camera
        self.view = view

        zoomDelta = defaultZoom
        self.defaultZoom = defaultZoom

        defaultPosition = camera.position
        defaultOrientation = camera.orientation

        setup()

        enable()
    }

    // MARK: - Update

    public func update() {
        setup()
    }

    // MARK: - Enable & Disable

    public func enable() {
        guard !isEnabled else { return }

        enableEvents()

        isEnabled = true
    }

    public func disable() {
        guard isEnabled else { return }

        disableEvents()

        isEnabled = false
    }

    // MARK: - Resize

    public func resize(_ size: (width: Float, height: Float)) {
        guard let view = view, view.drawableSize.width > 0, view.drawableSize.height > 0 else { return }

        setup()

        let cameraWidth = abs(camera.right - camera.left)
        zoomDelta = cameraWidth / Float(2.0 * view.drawableSize.width)

        let hw = size.width * zoomDelta
        let hh = size.height * zoomDelta
        camera.update(left: -hw, right: hw, bottom: -hh, top: hh, near: camera.near, far: camera.far)
    }

    // MARK: - Reset

    public func reset() {
        guard let view = view else { return }

        state = .inactive

        panDelta = [0.0, 0.0]
        zoomDelta = defaultZoom

        let hw = Float(view.drawableSize.width) * defaultZoom
        let hh = Float(view.drawableSize.height) * defaultZoom
        camera.update(left: -hw, right: hw, bottom: -hh, top: hh)

        camera.orientation = defaultOrientation
        camera.position = defaultPosition

        onStartPublisher.send(self)
        onChangePublisher.send(self)
        onEndPublisher.send(self)
    }

    // MARK: - Save & Load

    public func save(url: URL) {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        do {
            let payload: Data = try jsonEncoder.encode(self)
            try payload.write(to: url)
        } catch {
            print(error.localizedDescription)
        }
    }

    public func load(url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let loaded = try JSONDecoder().decode(OrthographicCameraController.self, from: data)

            camera.setFrom(loaded.camera)

            defaultZoom = loaded.defaultZoom
            defaultPosition = loaded.defaultPosition
            defaultOrientation = loaded.defaultOrientation

            zoomDelta = loaded.zoomDelta
            panDelta = loaded.panDelta
        } catch {
            print(error.localizedDescription)
        }
    }

    // MARK: - Codable

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        camera = try values.decode(OrthographicCamera.self, forKey: .camera)
        defaultPosition = try values.decode(simd_float3.self, forKey: .defaultPosition)
        defaultOrientation = try values.decode(simd_quatf.self, forKey: .defaultOrientation)
        defaultZoom = try values.decode(Float.self, forKey: .defaultZoom)
        zoomDelta = try values.decode(Float.self, forKey: .zoomDelta)
        panDelta = try values.decode(simd_float2.self, forKey: .panDelta)
    }

    public func encode(to encoder: Encoder) throws {
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
        case defaultZoom
        case zoomDelta
        case panDelta
    }


    // MARK: - Setup & Camera Transform Updates

    private func setup() {
        guard !isSetup, let view = view, view.drawableSize.width > 0, view.drawableSize.height > 0 else { return }

        let hw = Float(view.drawableSize.width) * defaultZoom
        let hh = Float(view.drawableSize.height) * defaultZoom
        camera.update(left: -hw, right: hw, bottom: -hh, top: hh)

        isSetup = true
    }

    private func pan(_ deltaX: Float, _ deltaY: Float) {
        let cameraWidth = camera.right - camera.left
        let cameraHeight = camera.top - camera.bottom

        let deltaX = deltaX * cameraWidth
        let deltaY = deltaY * cameraHeight

        panDelta += [deltaX, deltaY]

        camera.position -= camera.worldRightDirection * deltaX
        camera.position += camera.worldUpDirection * deltaY

        onChangePublisher.send(self)
    }

    private func zoom(_ delta: Float) {
        let cameraWidth = camera.right - camera.left
        let cameraHeight = camera.top - camera.bottom

        let deltaX = delta * cameraWidth
        let deltaY = delta * cameraHeight

        camera.left -= deltaX
        camera.right += deltaX

        camera.top += deltaY
        camera.bottom -= deltaY

        onChangePublisher.send(self)
    }

    private func roll(_ delta: Float) {
        camera.orientation *= simd_quatf(angle: delta, axis: camera.worldForwardDirection)
        onChangePublisher.send(self)
    }

    // MARK: - Events

    private func enableEvents() {
        guard let view = view else { return }

        #if os(macOS)

        leftMouseDownHandler = NSEvent.addLocalMonitorForEvents(
            matching: .leftMouseDown,
            handler: mouseDown
        )

        leftMouseDraggedHandler = NSEvent.addLocalMonitorForEvents(
            matching: .leftMouseDragged,
            handler: mouseDragged
        )

        leftMouseUpHandler = NSEvent.addLocalMonitorForEvents(
            matching: .leftMouseUp,
            handler: mouseUp
        )

        rightMouseDownHandler = NSEvent.addLocalMonitorForEvents(
            matching: .rightMouseDown,
            handler: rightMouseDown
        )

        rightMouseDraggedHandler = NSEvent.addLocalMonitorForEvents(
            matching: .rightMouseDragged,
            handler: rightMouseDragged
        )

        rightMouseUpHandler = NSEvent.addLocalMonitorForEvents(
            matching: .rightMouseUp,
            handler: rightMouseUp
        )

        otherMouseDownHandler = NSEvent.addLocalMonitorForEvents(
            matching: .otherMouseDown,
            handler: otherMouseDown
        )

        otherMouseDraggedHandler = NSEvent.addLocalMonitorForEvents(
            matching: .otherMouseDragged,
            handler: otherMouseDragged
        )

        otherMouseUpHandler = NSEvent.addLocalMonitorForEvents(
            matching: .otherMouseUp,
            handler: otherMouseUp
        )

        scrollWheelHandler = NSEvent.addLocalMonitorForEvents(
            matching: .scrollWheel,
            handler: scrollWheel
        )

        magnifyGestureRecognizer = NSMagnificationGestureRecognizer(target: self, action: #selector(magnifyGesture))
        view.addGestureRecognizer(magnifyGestureRecognizer)

        rollGestureRecognizer = NSRotationGestureRecognizer(target: self, action: #selector(rollGesture))
        view.addGestureRecognizer(rollGestureRecognizer)

        #elseif os(iOS)

        view.isMultipleTouchEnabled = true

        let allowedTouchTypes = [UITouch.TouchType.direct.rawValue as NSNumber]
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGesture))
        panGestureRecognizer.allowedTouchTypes = allowedTouchTypes
        panGestureRecognizer.minimumNumberOfTouches = 1
        panGestureRecognizer.maximumNumberOfTouches = 1
        view.addGestureRecognizer(panGestureRecognizer)

        rollGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(rollGesture))
        rollGestureRecognizer.allowedTouchTypes = allowedTouchTypes
        view.addGestureRecognizer(rollGestureRecognizer)

        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
        tapGestureRecognizer.allowedTouchTypes = allowedTouchTypes
        tapGestureRecognizer.numberOfTouchesRequired = 1
        tapGestureRecognizer.numberOfTapsRequired = 2
        view.addGestureRecognizer(tapGestureRecognizer)

        pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchGesture))
        pinchGestureRecognizer.allowedTouchTypes = allowedTouchTypes
        view.addGestureRecognizer(pinchGestureRecognizer)

        #endif
    }

    private func disableEvents() {
        guard let view = view else { return }

        #if os(macOS)

        NSEvent.removeMonitor(leftMouseDownHandler!)
        NSEvent.removeMonitor(leftMouseDraggedHandler!)
        NSEvent.removeMonitor(leftMouseUpHandler!)
        NSEvent.removeMonitor(rightMouseDownHandler!)
        NSEvent.removeMonitor(rightMouseDraggedHandler!)
        NSEvent.removeMonitor(rightMouseUpHandler!)
        NSEvent.removeMonitor(otherMouseDownHandler!)
        NSEvent.removeMonitor(otherMouseDraggedHandler!)
        NSEvent.removeMonitor(otherMouseUpHandler!)
        NSEvent.removeMonitor(scrollWheelHandler!)

        view.removeGestureRecognizer(magnifyGestureRecognizer)
        view.removeGestureRecognizer(rollGestureRecognizer)

        #elseif os(iOS)

        view.removeGestureRecognizer(rollGestureRecognizer)
        view.removeGestureRecognizer(panGestureRecognizer)
        view.removeGestureRecognizer(tapGestureRecognizer)
        view.removeGestureRecognizer(pinchGestureRecognizer)

        #endif
    }

    #if os(macOS)

    // MARK: - Mouse

    private func mouseDown(with event: NSEvent) -> NSEvent? {
        if event.clickCount == 2 {
            reset()
        } else {
            state = .panning
        }

        return event
    }

    private func mouseDragged(with event: NSEvent) -> NSEvent? {
        guard let view = view, state == .panning else { return event }
        pan(Float(event.deltaX / view.frame.size.width), Float(event.deltaY / view.frame.size.height))
        return event
    }

    private func mouseUp(with event: NSEvent) -> NSEvent? {
        state = .inactive
        return event
    }

    // MARK: - Other Mouse

    private func otherMouseDown(with event: NSEvent) -> NSEvent? {
        state = .panning
        return event
    }

    private func otherMouseDragged(with event: NSEvent) -> NSEvent? {
        guard let view = view, state == .panning else { return event }
        pan(Float(event.deltaX / view.frame.size.width), Float(event.deltaY / view.frame.size.height))
        return event
    }

    private func otherMouseUp(with event: NSEvent) -> NSEvent? {
        state = .inactive
        return event
    }

    // MARK: - Right Mouse

    private func rightMouseDown(with event: NSEvent) -> NSEvent? {
        state = .zooming
        return event
    }

    private func rightMouseDragged(with event: NSEvent) -> NSEvent? {
        guard let view = view, state == .zooming else { return event }
        zoom(Float(-event.deltaY / view.frame.size.height))
        return event
    }

    private func rightMouseUp(with event: NSEvent) -> NSEvent? {
        state = .inactive
        return event
    }

    // MARK: - Scroll Wheel

    private func scrollWheel(with event: NSEvent) -> NSEvent? {
        guard let view = view else { return event }

        if event.phase == .began {
            state = .panning
        }

        guard state == .panning else { return event }

        if event.phase == .changed {
            pan(Float(event.scrollingDeltaX / view.frame.size.width), Float(event.scrollingDeltaY / view.frame.size.height))
        } else if event.phase == .ended {
            state = .inactive
        }

        return event
    }

    @objc private func magnifyGesture(_ gestureRecognizer: NSMagnificationGestureRecognizer) {
        let newMagnification = Float(gestureRecognizer.magnification)
        if gestureRecognizer.state == .began {
            state = .zooming
            magnification = newMagnification
        }

        guard state == .zooming else { return }

        if gestureRecognizer.state == .changed {
            let delta = magnification - newMagnification
            zoom(delta)
            magnification = newMagnification
        } else if gestureRecognizer.state == .ended {
            state = .inactive
        }
    }

    @objc private func rollGesture(_ gestureRecognizer: NSRotationGestureRecognizer) {
        if gestureRecognizer.state == .began { state = .rolling }

        guard state == .rolling else { return }

        if gestureRecognizer.state == .changed {
            roll(-Float(gestureRecognizer.rotation))
            gestureRecognizer.rotation = 0.0
        } else if gestureRecognizer.state == .ended {
            state = .inactive
        }
    }

    #elseif os(iOS)

    // MARK: - Gestures iOS

    @objc private func tapGesture(_ gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            reset()
        }
    }

    @objc private func rollGesture(_ gestureRecognizer: UIRotationGestureRecognizer) {
        if gestureRecognizer.state == .began {
            state = .rolling
        }

        guard state == .rolling else { return }

        if gestureRecognizer.state == .changed {
            roll(Float(gestureRecognizer.rotation))
            gestureRecognizer.rotation = 0.0
        } else if gestureRecognizer.state == .ended {
            state = .inactive
        }
    }

    @objc private func panGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let view = view else { return }

        if gestureRecognizer.state == .began {
            state = .panning
            let translation = gestureRecognizer.translation(in: view)
            panPreviousPoint = simd_make_float2(Float(translation.x), Float(translation.y))
        }

        guard state == .panning else { return }

        if gestureRecognizer.state == .changed {
            let translation = gestureRecognizer.translation(in: view)
            panCurrentPoint = simd_make_float2(Float(translation.x), Float(translation.y))

            let deltaX = panCurrentPoint.x - panPreviousPoint.x
            let deltaY = panCurrentPoint.y - panPreviousPoint.y

            let dx = deltaX / Float(view.frame.size.width)
            let dy = deltaY / Float(view.frame.size.height)

            pan(dx, dy)
            panPreviousPoint = panCurrentPoint
        } else if gestureRecognizer.state == .ended {
            state = .inactive
        }
    }

    @objc private func pinchGesture(_ gestureRecognizer: UIPinchGestureRecognizer) {
        if gestureRecognizer.state == .began {
            state = .zooming
            pinchScale = Float(gestureRecognizer.scale)
        }

        guard state == .zooming else { return }

        if gestureRecognizer.state == .changed {
            let newScale = Float(gestureRecognizer.scale)
            let delta = pinchScale - newScale
            zoom(delta)
            pinchScale = newScale
        } else if gestureRecognizer.state == .ended {
            state = .inactive
        }
    }

    #endif
}
