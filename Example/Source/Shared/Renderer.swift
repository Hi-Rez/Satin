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
    var paramTest: IntParameter!
    var library: MTLLibrary!
    var material: Material!
    var geometry: Geometry!
    var mesh: Mesh!
    var scene: Object!
    var context: Context!
    
    var perspCamera: ArcballPerspectiveCamera!
    var cameraController: ArcballCameraController!
    var renderer: Satin.Renderer!
    
    required init?(metalKitView: MTKView) {
        super.init(metalKitView: metalKitView)
    }
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.autoResizeDrawable = false
        #if os(iOS)
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            metalKitView.preferredFramesPerSecond = 120
        case .phone:
            metalKitView.preferredFramesPerSecond = 60
        case .unspecified:
            metalKitView.preferredFramesPerSecond = 60
        case .tv:
            metalKitView.preferredFramesPerSecond = 60
        case .carPlay:
            metalKitView.preferredFramesPerSecond = 60
        @unknown default:
            metalKitView.preferredFramesPerSecond = 60
        }
        #else
        metalKitView.preferredFramesPerSecond = 60
        #endif
    }
    
    override func setup() {
        setupContext()
        setupLibrary()
        setupMaterial()
        setupGeometry()
        setupMesh()
        setupScene()
        setupCamera()
        setupCameraController()
        setupRenderer()
    }
    
    func setupContext() {
        context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
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
            context: context
        )
    }
    
    func setupGeometry() {
        geometry = BoxGeometry(size: 2)
    }
    
    func setupMesh() {
        mesh = Mesh(geometry: geometry, material: material)
    }
    
    func setupScene() {
        scene = Object()
        scene.add(mesh)
    }
    
    func setupCamera() {
        perspCamera = ArcballPerspectiveCamera()
        perspCamera.position = simd_make_float3(0.0, 0.0, 9.0)
        perspCamera.near = 0.001
        perspCamera.far = 100.0
    }
    
    func setupCameraController() {
        if cameraController == nil {
            cameraController = ArcballCameraController(camera: perspCamera, view: mtkView, defaultPosition: perspCamera.position, defaultOrientation: perspCamera.orientation)
        }
        else {
            cameraController.camera = perspCamera
        }
    }
    
    func setupRenderer() {
        renderer = Satin.Renderer(context: context,
                                  scene: scene,
                                  camera: perspCamera)
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
        perspCamera.aspect = size.width / size.height
        renderer.resize(size)
    }
}
