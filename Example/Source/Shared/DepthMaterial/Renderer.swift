//
//  Renderer.swift
//  Example
//
//  Created by Reza Ali on 6/24/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin

class Renderer: Forge.Renderer {
    lazy var depthMaterial: DepthMaterial = {
        let material = DepthMaterial()
        // Options to play with
        // By default the DepthMaterial uses the near and far from the camera's projection matrix (near & far)
        // By setting the Near and Far parameters below you can override this behavior
        // Setting the Near and Far parameters to negative values will revert to using the camera's projection matrix (near & far)
//        material.set("Invert", false)
//        material.set("Color", false)
        material.set("Near", 8.0)
        material.set("Far", 20.0)
        return material
    }()
    
    lazy var container: Mesh = {
        let mesh = Mesh(geometry: BoxGeometry(size: 10), material: depthMaterial)
        mesh.geometry.windingOrder = .clockwise
        return mesh
    }()
    
    lazy var torus: Mesh = {
        let mesh = Mesh(geometry: TorusGeometry(radius: (0.5, 2.0), res: (90, 30)), material: depthMaterial)
        mesh.position = [2, -2, -2]
        mesh.orientation = simd_quatf(angle: Float.pi * 0.25, axis: normalize([1, 1, 1]))
        return mesh
    }()
    
    lazy var cylinder: Mesh = {
        let mesh = Mesh(geometry: CylinderGeometry(size: (0.5, 2.0), res: (60, 1, 1)), material: depthMaterial)
        mesh.position = [-2, 2, 2]
        mesh.orientation = simd_quatf(angle: -Float.pi * 0.25, axis: normalize([0.5, 1, 1]))
        return mesh
    }()
    
    lazy var capsule: Mesh = {
        let mesh = Mesh(geometry: CapsuleGeometry(size: (0.5, 2.0), res: (60, 30, 1)), material: depthMaterial)
        mesh.position = [2, -2, 2]
        mesh.orientation = simd_quatf(angle: -Float.pi * 0.25, axis: normalize([0.5, 0.5, 1]))
        return mesh
    }()
    
    lazy var box: Mesh = {
        let mesh = Mesh(geometry: BoxGeometry(), material: depthMaterial)
        mesh.position = [2.5, 3.0, -3]
        mesh.orientation = simd_quatf(angle: -Float.pi * 0.25, axis: normalize([1.0, -0.25, 0.25]))
        return mesh
    }()
    
    lazy var longBox: Mesh = {
        let mesh = Mesh(geometry: BoxGeometry(size: (0.5, 2.0, 4.0)), material: depthMaterial)
        mesh.position = [-2, -3, 0]
        mesh.orientation = simd_quatf(angle: -Float.pi * 0.25, axis: normalize([0.5, -0.5, 0.25]))
        return mesh
    }()
    
    lazy var cone: Mesh = {
        let mesh = Mesh(geometry: ConeGeometry(size: (1.0, 2.0), res:(30,30,30)), material: depthMaterial)
        mesh.position = [-3, 0, -2]
        mesh.orientation = simd_quatf(angle: Float.pi * 0.25, axis: normalize([1.0, 0.5, 0.25]))
        return mesh
    }()
    
    lazy var scene: Object = {
        let scene = Object()
        scene.add(box)
        scene.add(container)
        scene.add(Mesh(geometry: IcoSphereGeometry(radius: 1.5, res: 0), material: depthMaterial))
        scene.add(torus)
        scene.add(cylinder)
        scene.add(capsule)
        scene.add(longBox)
        scene.add(cone)
        return scene
    }()
    
    lazy var context: Context = {
        Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }()
    
    lazy var camera: ArcballPerspectiveCamera = {
        let camera = ArcballPerspectiveCamera()
        camera.position = simd_make_float3(0.0, 0.0, 13.0)
        camera.near = 0.01
        camera.far = 20.0
        return camera
    }()
    
    lazy var cameraController: ArcballCameraController = {
        ArcballCameraController(camera: camera, view: mtkView, defaultPosition: camera.position, defaultOrientation: camera.orientation)
    }()
    
    lazy var renderer: Satin.Renderer = {
        let renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
        renderer.clearColor = .init(red: 0.137254902, green: 0.09411764706, blue: 0.1058823529, alpha: 1.0)
        return renderer
    }()
    
    required init?(metalKitView: MTKView) {
        super.init(metalKitView: metalKitView)
    }
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.colorPixelFormat = .bgra8Unorm
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
    }
    
    override func setup() {
        // Setup things here
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
