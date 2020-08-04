//
//  Renderer.swift
//  Example
//
//  Created by Reza Ali on 7/28/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin

class Renderer: Forge.Renderer {
    var gridInterval: Float = 1.0

    lazy var grid: Object = {
        let object = Object()
        let material = BasicColorMaterial(simd_make_float4(1.0, 1.0, 1.0, 1.0))
        let intervals = 5
        let intervalsf = Float(intervals)
        let geometryX = CapsuleGeometry(size: (0.0125, intervalsf), axis: .x)
        let geometryZ = CapsuleGeometry(size: (0.0125, intervalsf), axis: .z)
        for i in 0...intervals {
            let fi = Float(i)
            let meshX = Mesh(geometry: geometryX, material: material)
            let offset = map(fi, 0.0, Float(intervals), -intervalsf * 0.5, intervalsf * 0.5)
            meshX.position = [0.0, 0.0, offset]
            object.add(meshX)
            
            let meshZ = Mesh(geometry: geometryZ, material: material)
            meshZ.position = [offset, 0.0, 0.0]
            object.add(meshZ)
        }
        return object
    }()
    
    lazy var axisMesh: Object = {
        let object = Object()
        let intervals = 5
        let intervalsf = Float(intervals) * 0.5
        let size = (Float(0.0125), intervalsf)
        object.add(Mesh(geometry: CapsuleGeometry(size: size, axis: .x), material: BasicColorMaterial(simd_make_float4(1.0, 0.0, 0.0, 1.0))))
        object.add(Mesh(geometry: CapsuleGeometry(size: size, axis: .y), material: BasicColorMaterial(simd_make_float4(0.0, 1.0, 0.0, 1.0))))
        object.add(Mesh(geometry: CapsuleGeometry(size: size, axis: .z), material: BasicColorMaterial(simd_make_float4(0.0, 0.0, 1.0, 1.0))))
        return object
    }()
    
    lazy var targetMesh: Mesh = {
        let mesh = Mesh(geometry: BoxGeometry(size: 1.0), material: NormalColorMaterial())
        mesh.label = "Target"
        return mesh
    }()
    
    lazy var scene: Object = {
        let scene = Object()
        scene.add(grid)
        scene.add(axisMesh)
        return scene
    }()
    
    lazy var context: Context = {
        Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }()
    
    lazy var camera: PerspectiveCamera = {
        let camera = PerspectiveCamera()
        camera.label = "Camera"
        camera.position = simd_make_float3(0.0, 0.0, 9.0)
        camera.near = 0.001
        camera.far = 100.0
        return camera
    }()
    
    lazy var cameraController: PerspectiveCameraController = {
        PerspectiveCameraController(camera: camera, view: mtkView)
    }()
    
    lazy var renderer: Satin.Renderer = {
        Satin.Renderer(context: context, scene: scene, camera: camera)
    }()
    
    required init?(metalKitView: MTKView) {
        super.init(metalKitView: metalKitView)
    }
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 4
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
    }
    
    override func setup() {
        scene.add(cameraController.target)
        scene.add(targetMesh)
    }
    
    override func update() {
        targetMesh.position = cameraController.target.position
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
