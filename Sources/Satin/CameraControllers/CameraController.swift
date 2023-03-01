//
//  CameraController.swift
//  Pods
//
//  Created by Reza Ali on 11/21/20.
//

import MetalKit

#if os(macOS)
import AppKit
#endif

public enum CameraControllerState {
    case panning // moves the camera either up to right
    case rotating // rotates the camera around an arcball
    case dollying // moves the camera forward
    case zooming // moves the camera closer to target
    case rolling // rotates the camera around its forward axis
    case inactive
}

open class CameraController: Codable {
    public required init(from _: Decoder) throws {}
    open func encode(to _: Encoder) throws {}

    public init() {}

    public private(set) var enabled = false

    public weak var view: MTKView? {
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

    public var onStartAction: [() -> Void] = []
    public var onChangeAction: [() -> Void] = []
    public var onEndAction: [() -> Void] = []

    public func onStart(_ startFn: @escaping (() -> Void)) {
        onStartAction.append(startFn)
    }

    public func onChange(_ changeFn: @escaping (() -> Void)) {
        onChangeAction.append(changeFn)
    }

    public func onEnd(_ endFn: @escaping (() -> Void)) {
        onEndAction.append(endFn)
    }

    internal func change() {
        for action in onChangeAction {
            action()
        }
    }

    internal func start() {
        for action in onStartAction {
            action()
        }
    }

    internal func end() {
        for action in onEndAction {
            action()
        }
    }

    public internal(set) var state: CameraControllerState = .inactive
    public internal(set) var isTweening = false

    #if os(macOS)

    open var modifierFlags: NSEvent.ModifierFlags = .init() {
        didSet {
            if modifierFlags.isEmpty {
                flagsEnabled = true
            } else {
                flagsEnabled = false
            }
        }
    }

    public var flagsEnabled = true

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
    var flagsChangedHandler: Any?

    var magnification: Float = 1.0
    var magnifyGestureRecognizer: NSMagnificationGestureRecognizer!
    var rollGestureRecognizer: NSRotationGestureRecognizer!

    #elseif os(iOS)

    var pinchScale: Float = 1.0
    var rollGestureRecognizer: UIRotationGestureRecognizer!
    var panGestureRecognizer: UIPanGestureRecognizer!
    var pinchGestureRecognizer: UIPinchGestureRecognizer!
    var oneTapGestureRecognizer: UITapGestureRecognizer!
    var twoTapGestureRecognizer: UITapGestureRecognizer!
    var threeTapGestureRecognizer: UITapGestureRecognizer!

    #endif

    open var minimumPanningTouches = 1 {
        didSet {
            #if os(iOS)
            panGestureRecognizer.minimumNumberOfTouches = minimumPanningTouches
            #endif
        }
    }

    open var maximumPanningTouches = 2 {
        didSet {
            #if os(iOS)
            panGestureRecognizer.maximumNumberOfTouches = maximumPanningTouches
            #endif
        }
    }

    init(view: MTKView) {
        self.view = view
    }

    open func update() {}

    open func enable() {
        guard let view = view else { return }
        if !enabled { _enable(view) }
        enabled = true
    }

    open func disable() {
        guard let view = view else { return }
        if enabled { _disable(view) }
        enabled = false
    }

    open func reset() {}

    func _enable(_ view: MTKView) {
        #if os(macOS)

        leftMouseDownHandler = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [unowned self] event in
            if self.flagsEnabled {
                self.mouseDown(with: event)
            }
            return event
        }

        leftMouseDraggedHandler = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDragged) { [unowned self] event in
            if self.flagsEnabled {
                self.mouseDragged(with: event)
            }
            return event
        }

        leftMouseUpHandler = NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { [unowned self] event in
            if self.flagsEnabled {
                self.mouseUp(with: event)
            }
            return event
        }

        rightMouseDownHandler = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [unowned self] event in
            if self.flagsEnabled {
                self.rightMouseDown(with: event)
            }
            return event
        }

        rightMouseDraggedHandler = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDragged) { [unowned self] event in
            if self.flagsEnabled {
                self.rightMouseDragged(with: event)
            }
            return event
        }

        rightMouseUpHandler = NSEvent.addLocalMonitorForEvents(matching: .rightMouseUp) { [unowned self] event in
            if self.flagsEnabled {
                self.rightMouseUp(with: event)
            }
            return event
        }

        otherMouseDownHandler = NSEvent.addLocalMonitorForEvents(matching: .otherMouseDown) { [unowned self] event in
            if self.flagsEnabled {
                self.otherMouseDown(with: event)
            }
            return event
        }

        otherMouseDraggedHandler = NSEvent.addLocalMonitorForEvents(matching: .otherMouseDragged) { [unowned self] event in
            if self.flagsEnabled {
                self.otherMouseDragged(with: event)
            }
            return event
        }

        otherMouseUpHandler = NSEvent.addLocalMonitorForEvents(matching: .otherMouseUp) { [unowned self] event in
            if self.flagsEnabled {
                self.otherMouseUp(with: event)
            }
            return event
        }

        scrollWheelHandler = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [unowned self] event in
            if self.flagsEnabled {
                self.scrollWheel(with: event)
            }
            return event
        }

        flagsChangedHandler = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [unowned self] event -> NSEvent? in
            guard event.window?.windowNumber == view.window?.windowNumber, !self.modifierFlags.isEmpty else { return event }
            if self.modifierFlags.isStrictSubset(of: event.modifierFlags) {
                self.flagsEnabled = true
            } else {
                self.flagsEnabled = false
            }
            return event
        }

        magnifyGestureRecognizer = NSMagnificationGestureRecognizer(target: self, action: #selector(_magnifyGesture))
        view.addGestureRecognizer(magnifyGestureRecognizer)

        rollGestureRecognizer = NSRotationGestureRecognizer(target: self, action: #selector(_rollGesture))
        view.addGestureRecognizer(rollGestureRecognizer)

        #elseif os(iOS)

        view.isMultipleTouchEnabled = true

        let allowedTouchTypes: [NSNumber] = [UITouch.TouchType.direct.rawValue as NSNumber]
        rollGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(rollGesture))
        rollGestureRecognizer.allowedTouchTypes = allowedTouchTypes
        view.addGestureRecognizer(rollGestureRecognizer)

        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGesture))
        panGestureRecognizer.allowedTouchTypes = allowedTouchTypes
        panGestureRecognizer.minimumNumberOfTouches = minimumPanningTouches
        panGestureRecognizer.maximumNumberOfTouches = maximumPanningTouches
        view.addGestureRecognizer(panGestureRecognizer)

        oneTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
        oneTapGestureRecognizer.allowedTouchTypes = allowedTouchTypes
        oneTapGestureRecognizer.numberOfTouchesRequired = 1
        oneTapGestureRecognizer.numberOfTapsRequired = 2
        view.addGestureRecognizer(oneTapGestureRecognizer)

        twoTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
        twoTapGestureRecognizer.allowedTouchTypes = allowedTouchTypes
        twoTapGestureRecognizer.numberOfTouchesRequired = 2
        twoTapGestureRecognizer.numberOfTapsRequired = 2
        view.addGestureRecognizer(twoTapGestureRecognizer)

        threeTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
        threeTapGestureRecognizer.allowedTouchTypes = allowedTouchTypes
        threeTapGestureRecognizer.numberOfTouchesRequired = 3
        threeTapGestureRecognizer.numberOfTapsRequired = 2
        view.addGestureRecognizer(threeTapGestureRecognizer)

        pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchGesture))
        pinchGestureRecognizer.allowedTouchTypes = allowedTouchTypes
        view.addGestureRecognizer(pinchGestureRecognizer)

        #endif
    }

    func _disable(_ view: MTKView) {
        #if os(macOS)

        if let leftMouseDownHandler = leftMouseDownHandler {
            NSEvent.removeMonitor(leftMouseDownHandler)
        }

        if let leftMouseDraggedHandler = leftMouseDraggedHandler {
            NSEvent.removeMonitor(leftMouseDraggedHandler)
        }

        if let leftMouseUpHandler = leftMouseUpHandler {
            NSEvent.removeMonitor(leftMouseUpHandler)
        }

        if let rightMouseDownHandler = rightMouseDownHandler {
            NSEvent.removeMonitor(rightMouseDownHandler)
        }

        if let rightMouseDraggedHandler = rightMouseDraggedHandler {
            NSEvent.removeMonitor(rightMouseDraggedHandler)
        }

        if let rightMouseUpHandler = rightMouseUpHandler {
            NSEvent.removeMonitor(rightMouseUpHandler)
        }

        if let otherMouseDownHandler = otherMouseDownHandler {
            NSEvent.removeMonitor(otherMouseDownHandler)
        }

        if let otherMouseDraggedHandler = otherMouseDraggedHandler {
            NSEvent.removeMonitor(otherMouseDraggedHandler)
        }

        if let otherMouseUpHandler = otherMouseUpHandler {
            NSEvent.removeMonitor(otherMouseUpHandler)
        }

        if let scrollWheelHandler = scrollWheelHandler {
            NSEvent.removeMonitor(scrollWheelHandler)
        }

        if let flagsChangedHandler = flagsChangedHandler {
            NSEvent.removeMonitor(flagsChangedHandler)
        }

        view.removeGestureRecognizer(magnifyGestureRecognizer)
        view.removeGestureRecognizer(rollGestureRecognizer)

        #elseif os(iOS)

        view.removeGestureRecognizer(rollGestureRecognizer)
        view.removeGestureRecognizer(panGestureRecognizer)
        view.removeGestureRecognizer(oneTapGestureRecognizer)
        view.removeGestureRecognizer(twoTapGestureRecognizer)
        view.removeGestureRecognizer(threeTapGestureRecognizer)
        view.removeGestureRecognizer(pinchGestureRecognizer)

        #endif
    }

    open func resize(_: (width: Float, height: Float)) {}

    deinit {
        onStartAction = []
        onChangeAction = []
        onEndAction = []
        disable()
        view = nil
    }

    #if os(macOS)

    // MARK: - Mouse

    open func mouseDown(with _: NSEvent) {}
    open func mouseDragged(with _: NSEvent) {}
    open func mouseUp(with _: NSEvent) {}

    // MARK: - Right Mouse

    open func rightMouseDown(with _: NSEvent) {}
    open func rightMouseDragged(with _: NSEvent) {}
    open func rightMouseUp(with _: NSEvent) {}

    // MARK: - Other Mouse

    open func otherMouseDown(with _: NSEvent) {}
    open func otherMouseDragged(with _: NSEvent) {}
    open func otherMouseUp(with _: NSEvent) {}

    // MARK: - Scroll Wheel

    open func scrollWheel(with _: NSEvent) {}

    // MARK: - Gestures macOS

    @objc open func _magnifyGesture(_ gestureRecognizer: NSMagnificationGestureRecognizer) {
        if flagsEnabled {
            magnifyGesture(gestureRecognizer)
        }
    }

    @objc open func _rollGesture(_ gestureRecognizer: NSRotationGestureRecognizer) {
        if flagsEnabled {
            rollGesture(gestureRecognizer)
        }
    }

    open func magnifyGesture(_: NSMagnificationGestureRecognizer) {}
    open func rollGesture(_: NSRotationGestureRecognizer) {}

    #elseif os(iOS)

    // MARK: - Gestures iOS

    @objc open func tapGesture(_: UITapGestureRecognizer) {}
    @objc open func rollGesture(_: UIRotationGestureRecognizer) {}
    @objc open func panGesture(_: UIPanGestureRecognizer) {}
    @objc open func pinchGesture(_: UIPinchGestureRecognizer) {}

    #endif

    // MARK: - Save & Load

    open func save(_ url: URL) {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        do {
            let payload: Data = try jsonEncoder.encode(self)
            try payload.write(to: url)
        } catch {
            print(error.localizedDescription)
        }
    }

    open func load(_: URL) {}
}
