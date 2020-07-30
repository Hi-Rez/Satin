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

class Renderer: Forge.Renderer {
    var scene = Object()
    var mesh: Mesh!
//    var tween: Tween!
    
    lazy var context: Context = {
        Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }()
    
    lazy var camera: PerspectiveCamera = {
        let camera = PerspectiveCamera()
        camera.position = simd_make_float3(0.0, 0.0, 30.0)
        camera.near = 0.001
        camera.far = 100.0
        return camera
    }()
    
    lazy var cameraController: PerspectiveCameraController = {
        PerspectiveCameraController(camera: camera, view: mtkView)
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
