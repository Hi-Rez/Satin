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

class Renderer: Forge.Renderer {
    lazy var mesh: Mesh = {
        let mesh = Mesh(geometry: PlaneGeometry(size: 500), material: UvColorMaterial())
        mesh.label = "Quad"
        return mesh
    }()
    
    lazy var scene: Object = {
        let scene = Object()
        scene.add(mesh)
        return scene
    }()
    
    lazy var context: Context = {
        Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }()
    
    #if os(macOS) || os(iOS)
    lazy var raycaster: Raycaster = {
        Raycaster(context: context)
    }()
    #endif
    
    var camera = OrthographicCamera()
    
    lazy var renderer: Satin.Renderer = {
        Satin.Renderer(context: context, scene: scene, camera: camera)
    }()
    
    required init?(metalKitView: MTKView) {
        super.init(metalKitView: metalKitView)
    }
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .invalid
        metalKitView.preferredFramesPerSecond = 60
    }
    
    override func setup() {
        // Setup things here
    }
    
    override func update() {
        renderer.update()
    }
    
    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        renderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
    }
    
    override func resize(_ size: (width: Float, height: Float)) {
        let hw = size.width * 0.5
        let hh = size.height * 0.5
        camera.update(left: -hw, right: hw, bottom: -hh, top: hh)
        renderer.resize(size)
    }
    
    #if os(macOS)
    override func mouseDown(with event: NSEvent) {
        let m = event.locationInWindow
        let pt = normalizePoint(m, mtkView.frame.size)
        raycaster.setFromCamera(camera, pt)
        let results = raycaster.intersect(scene, true)
        for result in results {
            print(result.object.label)
            print(result.position)
        }
    }
    #elseif os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let first = touches.first {
            let point = first.location(in: self.mtkView)
            let size = self.mtkView.frame.size
            let pt = normalizePoint(point, size)
            raycaster.setFromCamera(camera, pt)
            let results = raycaster.intersect(scene, true)
            for result in results {
                print(result.object.label)
                print(result.position)
            }
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
}
