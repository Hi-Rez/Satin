//
//  Renderer.swift
//  Example Shared
//
//  Created by Reza Ali on 8/22/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin

class Tweener {
    static let shared = Tweener()
    private static var tweens: [Tween] = []
    
    #if os(macOS)
    
    private static var displayLink: CVDisplayLink?
    
    private class func setupDisplayLink() {
        var cvReturn = CVDisplayLinkCreateWithActiveCGDisplays(&Tweener.displayLink)
        assert(cvReturn == kCVReturnSuccess)
        cvReturn = CVDisplayLinkSetOutputCallback(Tweener.displayLink!, Tweener.displayLoop, Unmanaged.passUnretained(Tweener.shared).toOpaque())
        assert(cvReturn == kCVReturnSuccess)
        cvReturn = CVDisplayLinkSetCurrentCGDisplay(Tweener.displayLink!, CGMainDisplayID())
        assert(cvReturn == kCVReturnSuccess)
        CVDisplayLinkStart(Tweener.displayLink!)
    }
    
    private static let displayLoop: CVDisplayLinkOutputCallback = {
        _, _, _, _, _, _ in
        autoreleasepool {
            Tweener.update()
        }
        return kCVReturnSuccess
    }
    
    #else
    
    private static var displayLink: CADisplayLink?
    
    private class func setupDisplayLink() {
        Tweener.displayLink = CADisplayLink(target: self, selector: #selector(Tweener.update))
        Tweener.displayLink!.add(to: .current, forMode: .default)
    }
    
    #endif
    
    @objc class func update()
    {
        for (index, tween) in Tweener.tweens.enumerated() {
            tween.update()
            if tween.complete {
                Tweener.tweens.remove(at: index)
            }
        }
    }
    
    class func tween(duration: Double, delay: Double = 0.0) -> Tween {
        if Tweener.displayLink == nil {
            setupDisplayLink()
        }
        let tween = Tween(duration: duration, delay: delay)
        tweens.append(tween)
        return tween
    }
}

class Tween {
    public var _onStart: (() -> ())?
    public var _onUpdate: ((_ time: Double) -> ())?
    public var _onComplete: (() -> ())?
    
    public var tweening: Bool = false
    public var complete: Bool = false
    
    private var delay: CFTimeInterval = 0.0
    private var duration: CFTimeInterval = 0.0
    private var startTime: CFTimeInterval = 0.0
    
    init(duration: Double, delay: Double = 0.0) {
        self.duration = duration
        self.delay = delay
    }
    
    public func start() -> Tween {
        tweening = true
        startTime = CFAbsoluteTimeGetCurrent() + delay
        _onStart?()
        return self
    }
    
    func update() {
        guard tweening else { return }
        let deltaTime = (CFAbsoluteTimeGetCurrent() - startTime)
        guard deltaTime >= 0 else { return }
        let time = deltaTime / duration
        _onUpdate?(time)
        if time >= 1.0 {
            complete = true
            _onComplete?()
        }
    }
    
    public func onStart(_ startFn: @escaping (() -> ())) -> Tween {
        _onStart = startFn
        return self
    }
    
    public func onUpdate(_ updateFn: @escaping ((_ time: Double) -> ())) -> Tween {
        _onUpdate = updateFn
        return self
    }
    
    public func onComplete(_ completeFn: @escaping (() -> ())) -> Tween {
        _onComplete = completeFn
        return self
    }
    
    deinit {
        print("killing tween!")
    }
}

class Renderer: Forge.Renderer {
    var scene = Object()
    var mesh: Mesh!
//    var tween: Tween!
    
    lazy var context: Context = {
        Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }()
    
    lazy var camera: ArcballPerspectiveCamera = {
        let camera = ArcballPerspectiveCamera()
        camera.position = simd_make_float3(0.0, 0.0, 30.0)
        camera.near = 0.001
        camera.far = 100.0
        return camera
    }()
    
    lazy var cameraController: ArcballCameraController = {
        ArcballCameraController(camera: camera, view: mtkView, defaultPosition: camera.position, defaultOrientation: camera.orientation)
    }()
    
    lazy var renderer: Satin.Renderer = {
        let renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
        renderer.clearColor = .init(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        return renderer
    }()
    
    required init?(metalKitView: MTKView) {
        super.init(metalKitView: metalKitView)
    }
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
    }
    
    override func setup() {
        setupText()
        _ = Tweener.tween(duration: 5.0, delay: 1.0)
            .onStart {
                print("starting")
            }
            .onUpdate { [unowned self] (time: Double) in
                self.mesh.position = [0.0, 0.0, Float(10.0 * time)]
            }
            .onComplete { [unowned self] in
                print("on complete")
                _ = Tweener.tween(duration: 5.0, delay: 1.0).onUpdate { [unowned self] (time: Double) in
                    self.mesh.position = [0.0, 0.0, 10.0 * Float(1.0 - time)]
                }.onStart {
                    print("starting second tween")
                }
                .start()
            }
            .start()
    }
    
    func setupText() {
        let input = "HELLO\nWORLD"
        
        /*
         Times
         AvenirNext-UltraLight
         Helvetica
         SFMono-HeavyItalic
         SFProRounded-Thin
         SFProRounded-Heavy
         */
        
        let geo = ExtrudedTextGeometry(
            text: input,
            fontName: "SFProRounded-Heavy",
            fontSize: 8,
            distance: 4.0,
            bounds: CGSize(width: -1, height: -1),
            pivot: simd_make_float2(0, 0),
            textAlignment: .center,
            verticalAlignment: .center
        )
        
        let mat = DepthMaterial()
        mat.near.value = 10.0
        mat.far.value = 40.0
        mat.invert.value = true
        mesh = Mesh(geometry: geo, material: mat)
        scene.add(mesh)
    }
    
    override func update() {
        cameraController.update()
        renderer.update()
    }
    
    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        renderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
    }
    
    override func resize(_ size: (width: Float, height: Float)) {
        camera.aspect = size.width / size.height
        renderer.resize(size)
    }
}
