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
    
    
    lazy var material: Material = {
        let material = MatCapMaterial(texture: matcapTexture)
        material.vertexDescriptor = CustomVertexDescriptor()
        return material
    }()
    
    var scene = Object()
    
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
    
    lazy var context: Context = {
        Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }()
    
    lazy var camera: PerspectiveCamera = {
        let camera = PerspectiveCamera()
        camera.position = simd_make_float3(0.0, 0.0, 4.0)
        camera.near = 0.001
        camera.far = 100.0
        return camera
    }()
    
    lazy var cameraController: PerspectiveCameraController = {
        PerspectiveCameraController(camera: camera, view: mtkView)
    }()
    
    lazy var renderer: Satin.Renderer = {
        let renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
        renderer.clearColor = .init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        return renderer
    }()
    
    var mesh: Mesh!
    
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
    
    struct CustomVertex {
        var position: simd_float4
        var normal: simd_float3
        var uv: simd_float2
        var tangent: simd_float3
    }
    
    public func CustomModelIOVertexDescriptor() -> MDLVertexDescriptor {
        let descriptor = MDLVertexDescriptor()
        
        var offset = 0
        descriptor.attributes[0] = MDLVertexAttribute(
            name: MDLVertexAttributePosition,
            format: .float4,
            offset: offset,
            bufferIndex: 0
        )
        offset += MemoryLayout<Float>.size * 4
        
        descriptor.attributes[1] = MDLVertexAttribute(
            name: MDLVertexAttributeNormal,
            format: .float3,
            offset: offset,
            bufferIndex: 0
        )
        offset += MemoryLayout<Float>.size * 4
        
        descriptor.attributes[2] = MDLVertexAttribute(
            name: MDLVertexAttributeTextureCoordinate,
            format: .float2,
            offset: offset,
            bufferIndex: 0
        )
        offset += MemoryLayout<Float>.size * 2
        
        descriptor.attributes[3] = MDLVertexAttribute(
            name: MDLVertexAttributeTangent,
            format: .float3,
            offset: offset,
            bufferIndex: 0
        )
        
        descriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<CustomVertex>.stride)
        
        return descriptor
    }
    
    public func CustomVertexDescriptor() -> MTLVertexDescriptor {
        // position
        let vertexDescriptor = MTLVertexDescriptor()
        var offset = 0
        
        vertexDescriptor.attributes[0].format = MTLVertexFormat.float4
        vertexDescriptor.attributes[0].offset = offset
        vertexDescriptor.attributes[0].bufferIndex = 0
        offset += MemoryLayout<Float>.size * 4
        
        // normal
        vertexDescriptor.attributes[1].format = MTLVertexFormat.float3
        vertexDescriptor.attributes[1].offset = offset
        vertexDescriptor.attributes[1].bufferIndex = 0
        offset += MemoryLayout<Float>.size * 4
        
        // uv
        vertexDescriptor.attributes[2].format = MTLVertexFormat.float2
        vertexDescriptor.attributes[2].offset = offset
        vertexDescriptor.attributes[2].bufferIndex = 0
        offset += MemoryLayout<Float>.size * 2
        
        // tangent
        vertexDescriptor.attributes[3].format = MTLVertexFormat.float3
        vertexDescriptor.attributes[3].offset = offset
        vertexDescriptor.attributes[3].bufferIndex = 0
        offset += MemoryLayout<Float>.size * 4
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<CustomVertex>.stride
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        return vertexDescriptor
    }
    
    func loadModel() {
        print(MDLVertexAttributePosition)
        print(MDLVertexAttributeNormal)
        print(MDLVertexAttributeTextureCoordinate)
        print(MDLVertexAttributeTangent)
        print(MDLVertexAttributeColor)
        
        let customVertexDescriptor = CustomModelIOVertexDescriptor()
        print(customVertexDescriptor)
        
        let asset = MDLAsset(url: modelsURL.appendingPathComponent("suzanne_high.obj"), vertexDescriptor: customVertexDescriptor, bufferAllocator: MTKMeshBufferAllocator(device: context.device))
        
        // MatCapMaterial inspired by @TheSpite
        // https://www.clicktorelease.com/code/spherical-normal-mapping/
        
        mesh = Mesh(geometry: Geometry(), material: material)
        mesh.label = "Suzanne"
        
        let geo = mesh.geometry
        let object0 = asset.object(at: 0)
        if let objMesh = object0 as? MDLMesh {
            objMesh.addNormals(withAttributeNamed: MDLVertexAttributeNormal, creaseThreshold: 0.0)
            objMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate, normalAttributeNamed: MDLVertexAttributeNormal, tangentAttributeNamed: MDLVertexAttributeTangent)
            
            
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
        
        mesh = Mesh(geometry: geometry, material: material)
        mesh.cullMode = .none
        mesh.label = "Knot"
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
        let aspect = size.width / size.height
        camera.aspect = aspect
        renderer.resize(size)
    }
}
