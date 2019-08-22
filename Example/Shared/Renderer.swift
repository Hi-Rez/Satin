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
    var library: MTLLibrary!
    var material: Material!
    var geometry: Geometry!
    var mesh: Mesh!
    var scene: Object!
    
    var perspCamera = PerspectiveCamera()
//    var cameraController: PerspectiveCameraController!
    var renderer = Satin.Renderer()
    
    required init?(metalKitView: MTKView) {
        super.init(metalKitView: metalKitView)
    }

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.depthStencilPixelFormat = .invalid
    }
    
    override func setup() {
        setupLibrary()
        setupMaterial()
        setupGeometry()
        setupMesh()
        setupScene()
        setupCamera()
        setupRenderer()
    }
    
    func setupLibrary() {        
        library = device.makeDefaultLibrary()
    }
    
    func setupMaterial() {
        material = Material(
            library: library,
            vertex: "basic_vertex",
            fragment: "basic_fragment",
            label: "basic",
            sampleCount: sampleCount,
            colorPixelFormat: colorPixelFormat,
            depthPixelFormat: .invalid,
            stencilPixelFormat: .invalid
        )
    }
    
    func setupGeometry() {
        geometry = PlaneGeometry()
    }
    
    func setupMesh() {
        mesh = Mesh(geometry: geometry, material: material)
    }
    
    func setupScene() {
        scene = Object()
        scene.addChild(mesh)
    }
    
    func setupCamera() {
        perspCamera.position.z = 9.0
//        cameraController = PerspectiveCameraController(perspCamera)
    }
    
    func setupRenderer() {
        renderer = Satin.Renderer(scene: scene, camera: perspCamera)
    }
    
    override func update() {
//        cameraController.update()
        renderer.update()
    }
    
    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        renderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
    }
    
    override func resize(_ size: (width: Float, height: Float)) {
        perspCamera.aspect = size.width / size.height
        renderer.resize(size)
    }
}
