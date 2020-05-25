//
//  Renderer.swift
//  Obj-macOS
//
//  Created by Reza Ali on 5/23/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit
import ModelIO

import Forge
import Satin

class Renderer: Forge.Renderer {
    lazy var mesh: Mesh = {
        Mesh(geometry: Geometry(), material: NormalColorMaterial())
    }()
    
    lazy var scene: Object = {
        let scene = Object()
        scene.add(mesh)
        return scene
    }()
    
    lazy var context: Context = {
        Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }()
    
    lazy var camera: ArcballPerspectiveCamera = {
        let camera = ArcballPerspectiveCamera()
        camera.position = simd_make_float3(0.0, 0.0, 9.0)
        camera.near = 0.001
        camera.far = 100.0
        return camera
    }()
    
    lazy var cameraController: ArcballCameraController = {
        ArcballCameraController(camera: camera, view: mtkView, defaultPosition: camera.position, defaultOrientation: camera.orientation)
    }()
    
    lazy var renderer: Satin.Renderer = {
        Satin.Renderer(context: context, scene: scene, camera: camera)
    }()
    
    required init?(metalKitView: MTKView) {
        super.init(metalKitView: metalKitView)
    }
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
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
        guard let url = Bundle.main.resourceURL?.appendingPathComponent("Assets/suzanne.obj") else { return }
        
        let asset = MDLAsset(url: url, vertexDescriptor: SatinModelIOVertexDescriptor(), bufferAllocator: MTKMeshBufferAllocator(device: context.device))
        
        let geo = Geometry()
        
        let object0 = asset.object(at: 0)
        
        if let objMesh = object0 as? MDLMesh {
            let vertexData = objMesh.vertexBuffers[0].map().bytes.bindMemory(to: Vertex.self, capacity: objMesh.vertexCount)
            geo.vertexData = Array(UnsafeBufferPointer(start: vertexData, count: objMesh.vertexCount))
            
            guard let submeshes = objMesh.submeshes, let first = submeshes.firstObject, let sub: MDLSubmesh = first as? MDLSubmesh else { return }
            
            let indexData = sub.indexBuffer(asIndexType: .uInt32).map().bytes.bindMemory(to: UInt32.self, capacity: sub.indexCount)
            geo.indexData = Array(UnsafeBufferPointer(start: indexData, count: sub.indexCount))
            
            mesh.geometry = geo
        }
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
