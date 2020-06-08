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

class Renderer: Forge.Renderer {
    var assetsURL: URL {
        let resourcesURL = Bundle.main.resourceURL!
        return resourcesURL.appendingPathComponent("Assets")
    }
    
    var texturesURL: URL {
        return assetsURL.appendingPathComponent("Textures")
    }
    
    var modelsURL: URL {
        return assetsURL.appendingPathComponent("Models")
    }
    
    var scene = Object()
    
    lazy var matcapTexture: MTLTexture? = {
        // from https://github.com/nidorx/matcaps
        let fileName = "8A6565_2E214D_D48A5F_ADA59C.png"
        let loader = MTKTextureLoader(device: device)
        do {
            return try loader.newTexture(URL: self.texturesURL.appendingPathComponent(fileName), options: [
                MTKTextureLoader.Option.SRGB: false,
                MTKTextureLoader.Option.origin: MTKTextureLoader.Origin.flippedVertically
            ])
        }
        catch {
            print(error)
            return nil
        }
    }()
    
    lazy var context: Context = {
        Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }()
    
    lazy var camera: ArcballPerspectiveCamera = {
        let camera = ArcballPerspectiveCamera()
        camera.position = simd_make_float3(0.0, 0.0, 6.0)
        camera.near = 0.001
        camera.far = 100.0
        return camera
    }()
    
    lazy var cameraController: ArcballCameraController = {
        ArcballCameraController(camera: camera, view: mtkView, defaultPosition: camera.position, defaultOrientation: camera.orientation)
    }()
    
    lazy var renderer: Satin.Renderer = {
        let renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
        renderer.clearColor = .init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        return renderer
    }()
    
    var mesh: Mesh!
    
    required init?(metalKitView: MTKView) {
        super.init(metalKitView: metalKitView)
    }
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
        metalKitView.colorPixelFormat = .bgra8Unorm
    }
    
    override func setup() {
        loadModel()
//        loadKnot()
    }
    
    func loadModel() {
        let asset = MDLAsset(url: modelsURL.appendingPathComponent("suzanne_high.obj"), vertexDescriptor: SatinModelIOVertexDescriptor(), bufferAllocator: MTKMeshBufferAllocator(device: context.device))
        
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
            let R: Float = 0.75
            let r: Float = 0.25
            let c: Float = 0.1
            let q: Float = 1.0
            let p: Float = 3.0
            return torusKnotGenerator(u, v, R, r, c, q, p)
        })
        
        // MatCapMaterial inspired by @TheSpite
        // https://www.clicktorelease.com/code/spherical-normal-mapping/
        
        mesh = Mesh(geometry: geometry, material: MatCapMaterial(texture: matcapTexture!))
        mesh.cullMode = .none
        mesh.label = "Knot"
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
        let aspect = size.width / size.height
        camera.aspect = aspect
        renderer.resize(size)
    }
}
