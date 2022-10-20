//
//  InstancedMeshRenderer.swift
//  Example
//
//  Created by Reza Ali on 10/19/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit
import ModelIO

import Forge
import Satin

class InstancedMeshRenderer: BaseRenderer {
    // MARK: - Paths
    var assetsURL: URL { Bundle.main.resourceURL!.appendingPathComponent("Assets") }
    var rendererAssetsURL: URL { assetsURL.appendingPathComponent(String(describing: type(of: self))) }
    var texturesURL: URL { rendererAssetsURL.appendingPathComponent("Textures") }
    var modelsURL: URL { rendererAssetsURL.appendingPathComponent("Models") }
    
    // MARK: - Satin
    
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    var camera = PerspectiveCamera(position: [10.0, 10.0, 10.0], near: 0.001, far: 100.0)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: mtkView)
    var scene = Object("Scene")
    var instancedMesh: InstancedMesh!
    lazy var renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
    
    // MARK: - Properties
    lazy var startTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    let dim: Int = 7
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.colorPixelFormat = .bgra8Unorm_srgb
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
    }

    override func setup() {
        setupScene()
        setupCamera()
    }
    
    func setupScene() {
        guard let geo = loadOBJ(url: modelsURL.appendingPathComponent("spot_triangulated.obj")) else { return }
        instancedMesh = InstancedMesh(geometry: geo, material: BasicDiffuseMaterial(0.1), count: dim * dim * dim)
        instancedMesh.label = "Spot"
        scene.add(instancedMesh)
        updateInstances(getTime())
    }
    
    func setupCamera()
    {
        cameraController.target.lookAt([5.0, 5.0, 5.0])
    }
    
    func updateInstances(_ time: Float) {
        let halfDim: Int = dim/2
        let object = Object()
        object.scale = .init(repeating: 0.66)
        var index = 0
        for z in -halfDim...halfDim {
            for y in -halfDim...halfDim {
                for x in -halfDim...halfDim {
                    object.position = simd_make_float3(Float(x), Float(y), Float(z))
                    let axis = simd_normalize(object.position)
                    object.orientation = .init(angle: 2.0 * time + simd_length(object.position), axis: axis)
                    
                    instancedMesh.setMatrixAt(index: index, matrix: object.localMatrix)
                    index += 1
                }
            }
        }
    }
    
    func getTime() -> Float {
        return Float(CFAbsoluteTimeGetCurrent() - startTime)
    }

    override func update() {
        cameraController.update()
        updateInstances(getTime())
    }
    
    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        renderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
    }
    
    override func resize(_ size: (width: Float, height: Float)) {
        cameraController.resize(size)
        renderer.resize(size)
    }
    
    func loadOBJ(url: URL) -> Geometry? {
        let asset = MDLAsset(url: url, vertexDescriptor: SatinModelIOVertexDescriptor, bufferAllocator: MTKMeshBufferAllocator(device: context.device))
    
        let geo = Geometry()
        let object0 = asset.object(at: 0)
        if let objMesh = object0 as? MDLMesh {
            objMesh.addNormals(withAttributeNamed: MDLVertexAttributeNormal, creaseThreshold: 0)
            let vertexData = objMesh.vertexBuffers[0].map().bytes.bindMemory(to: Vertex.self, capacity: objMesh.vertexCount)
            geo.vertexData = Array(UnsafeBufferPointer(start: vertexData, count: objMesh.vertexCount))
            geo.vertexBuffer = (objMesh.vertexBuffers[0] as! MTKMeshBuffer).buffer
            guard let submeshes = objMesh.submeshes, let first = submeshes.firstObject, let sub: MDLSubmesh = first as? MDLSubmesh else { return nil }
            let indexDataPtr = sub.indexBuffer(asIndexType: .uInt32).map().bytes.bindMemory(to: UInt32.self, capacity: sub.indexCount)
            let indexData = Array(UnsafeBufferPointer(start: indexDataPtr, count: sub.indexCount))
            geo.indexData = indexData
            geo.indexBuffer = (sub.indexBuffer as! MTKMeshBuffer).buffer
        }
        return geo
    }
}
