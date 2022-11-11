//
//  Renderer.swift
//  LiveCode-macOS
//
//  Created by Reza Ali on 6/1/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//
import Metal
import MetalKit

import Forge
import Satin

class MatcapRenderer: BaseRenderer {
    var assetsURL: URL { Bundle.main.resourceURL!.appendingPathComponent("Assets") }
    var sharedAssetsURL: URL { assetsURL.appendingPathComponent("Shared") }
    var rendererAssetsURL: URL { assetsURL.appendingPathComponent(String(describing: type(of: self))) }
    var pipelinesURL: URL { rendererAssetsURL.appendingPathComponent("Pipelines") }
    var texturesURL: URL { rendererAssetsURL.appendingPathComponent("Textures") }
    var modelsURL: URL { sharedAssetsURL.appendingPathComponent("Models") }
    
    var scene = Object("Scene")
    
    lazy var matcapTexture: MTLTexture? = {
        // from https://github.com/nidorx/matcaps
        let fileName = "8A6565_2E214D_D48A5F_ADA59C.png"
        let loader = MTKTextureLoader(device: device)
        do {
            return try loader.newTexture(URL: self.texturesURL.appendingPathComponent(fileName), options: [
                MTKTextureLoader.Option.SRGB: false,
                MTKTextureLoader.Option.origin: MTKTextureLoader.Origin.flippedVertically,
                MTKTextureLoader.Option.allocateMipmaps: true,
                MTKTextureLoader.Option.generateMipmaps: true
            ])
        }
        catch {
            print(error)
            return nil
        }
    }()
    
    var camera = PerspectiveCamera(position: [0.0, 0.0, 8.0], near: 0.001, far: 100.0, fov: 45)
    
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: mtkView)
    lazy var renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
        
    var mesh: Mesh!
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
        metalKitView.colorPixelFormat = .bgra8Unorm
    }
    
    override func setup() {
        loadModel()
        loadKnot()
    }
    
    func loadModel() {
        let asset = MDLAsset(url: modelsURL.appendingPathComponent("Suzanne").appendingPathComponent("Suzanne.obj"), vertexDescriptor: SatinModelIOVertexDescriptor, bufferAllocator: MTKMeshBufferAllocator(device: context.device))
        
        // MatCapMaterial inspired by @TheSpite
        // https://www.clicktorelease.com/code/spherical-normal-mapping/
        
        mesh = Mesh(geometry: Geometry(), material: MatCapMaterial(texture: matcapTexture!))
        mesh.label = "Suzanne"
        
        let geo = mesh.geometry
        let object0 = asset.object(at: 0)
        if let objMesh = object0 as? MDLMesh {
            objMesh.addNormals(withAttributeNamed: MDLVertexAttributeNormal, creaseThreshold: 0.0)
            
            let vertexData = objMesh.vertexBuffers[0].map().bytes.bindMemory(to: Vertex.self, capacity: objMesh.vertexCount)
            geo.vertexData = Array(UnsafeBufferPointer(start: vertexData, count: objMesh.vertexCount))
            geo.vertexBuffer = (objMesh.vertexBuffers[0] as! MTKMeshBuffer).buffer
            guard let submeshes = objMesh.submeshes, let first = submeshes.firstObject, let sub: MDLSubmesh = first as? MDLSubmesh else { return }
            let indexDataPtr = sub.indexBuffer(asIndexType: .uInt32).map().bytes.bindMemory(to: UInt32.self, capacity: sub.indexCount)
            let indexData = Array(UnsafeBufferPointer(start: indexDataPtr, count: sub.indexCount))
            geo.indexData = indexData
            geo.indexBuffer = (sub.indexBuffer as! MTKMeshBuffer).buffer
        }
        
        scene.add(mesh)
    }
    
    func loadKnot() {
        let twoPi = Float.pi * 2.0
        let geometry = ParametricGeometry(u: (0.0, twoPi), v: (0.0, twoPi), res: (300, 16), generator: { u, v in
            let R: Float = 1.0
            let r: Float = 0.25
            let c: Float = 0.05
            let q: Float = 2.0
            let p: Float = 3.0
            return torusKnotGenerator(u, v, R, r, c, q, p)
        })
        
        // MatCapMaterial inspired by @TheSpite
        // https://www.clicktorelease.com/code/spherical-normal-mapping/
        
        mesh = Mesh(geometry: geometry, material: MatCapMaterial(texture: matcapTexture!))
        mesh.cullMode = .none
        mesh.label = "Knot"
        mesh.scale = .init(repeating: 2.5)
        scene.add(mesh)
    }
    
    override func update() {
        cameraController.update()
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
