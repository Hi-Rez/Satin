//
//  Renderer.swift
//  2D-macOS
//
//  Created by Reza Ali on 4/22/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin

class BaseRenderer: Forge.Renderer {
    deinit {
        print("deinit: \(String(describing: type(of: self)))")
    }
}

class Renderer2D: BaseRenderer {
    var context: Context!
    
    var camera = OrthographicCamera()
    var cameraController: OrthographicCameraController!
    
    var scene = Object("Scene")
    var renderer: Satin.Renderer!
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .invalid
        metalKitView.preferredFramesPerSecond = 60
    }
    
    override func setup() {
        setupContext()
        setupCameraController()
        setupScene()
        setupRenderer()
    }

    func setupContext() {
        context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }

    func setupCameraController() {
        cameraController = OrthographicCameraController(camera: camera, view: mtkView)
    }
    
    func setupScene() {
        let mesh = Mesh(geometry: PlaneGeometry(size: 700), material: UvColorMaterial())
        mesh.label = "Quad"
        scene.add(mesh)
    }
    
    func setupRenderer() {
        renderer = Satin.Renderer(context: context)
    }
    
    override func update() {
        cameraController.update()
    }
    
    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera
        )
    }
    
    override func resize(_ size: (width: Float, height: Float)) {
        cameraController.resize(size)
        renderer.resize(size)
    }
        
    #if os(macOS)
    override func mouseDown(with event: NSEvent) {
        let pt = normalizePoint(mtkView.convert(event.locationInWindow, from: nil), mtkView.frame.size)
        intersect(coordinate: pt)
    }

    #elseif os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let first = touches.first {
            let point = first.location(in: mtkView)
            let size = mtkView.frame.size
            let pt = normalizePoint(point, size)
            intersect(coordinate: pt)
        }
    }
    #endif
    
    func intersect(coordinate: simd_float2) {
        let results = raycast(camera: camera, coordinate: coordinate, object: scene)
        if let result = results.first {
            print(result.object.label)
            print(result.position)
        }
    }
    
    func normalizePoint(_ point: CGPoint, _ size: CGSize) -> simd_float2 {
        #if os(macOS)
        return 2.0 * simd_make_float2(Float(point.x / size.width), Float(point.y / size.height)) - 1.0
        #else
        return 2.0 * simd_make_float2(Float(point.x / size.width), 1.0 - Float(point.y / size.height)) - 1.0
        #endif
    }
}
