//
//  Renderer.swift
//  VertexAttributes
//
//  Created by Reza Ali on 4/18/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin

class Renderer: Forge.Renderer {
    #if os(macOS) || os(iOS)
    lazy var raycaster: Raycaster = {
        Raycaster(device: device)
    }()
    #endif
    
    var intersectionMesh: Mesh = {
        let mesh = Mesh(geometry: IcoSphereGeometry(radius: 0.01, res: 2), material: BasicColorMaterial([0.0, 1.0, 0.0, 1.0], .disabled))
        mesh.label = "Intersection Mesh"
        mesh.visible = false
        return mesh
    }()
    
    class CustomMaterial: LiveMaterial {}
    
    var assetsURL: URL {
        let resourcesURL = Bundle.main.resourceURL!
        return resourcesURL.appendingPathComponent("Assets")
    }
    
    var modelsURL: URL {
        return assetsURL.appendingPathComponent("Models")
    }
    
    var pipelinesURL: URL {
        return assetsURL.appendingPathComponent("Pipelines")
    }
    
    lazy var scene: Object = {
        Object("Scene", [intersectionMesh])
    }()
    
    lazy var context: Context = {
        Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }()
    
    var camera = PerspectiveCamera(position: [0.0, 0.0, 4.0], near: 0.001, far: 100.0)
    
    lazy var cameraController: PerspectiveCameraController = {
        PerspectiveCameraController(camera: camera, view: mtkView)
    }()
    
    lazy var renderer: Satin.Renderer = {
        let renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
        renderer.clearColor = .init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        return renderer
    }()
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
        metalKitView.colorPixelFormat = .bgra8Unorm
    }
    
    var loadedMesh: LoadedMesh!
    
    override func setup() {
        let material = CustomMaterial(pipelinesURL: pipelinesURL)
        material.vertexDescriptor = CustomVertexDescriptor()
        loadedMesh = LoadedMesh(url: modelsURL.appendingPathComponent("suzanne.obj"), material: material)
        scene.add(loadedMesh)
        
        raycaster.setFromCamera(camera)
        _ = raycaster.intersect(scene, true)
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
    
    #if !targetEnvironment(simulator)
    #if os(macOS)
    override func mouseDown(with event: NSEvent) {
        let m = event.locationInWindow
        let pt = normalizePoint(m, mtkView.frame.size)
        raycaster.setFromCamera(camera, pt)
        let results = raycaster.intersect(scene, true)
        for result in results {
            print(result.object.label)
            print(result.position)
            intersectionMesh.position = result.position
            intersectionMesh.visible = true
        }
    }

    #elseif os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let first = touches.first {
            let point = first.location(in: mtkView)
            let size = mtkView.frame.size
            let pt = normalizePoint(point, size)
            raycaster.setFromCamera(camera, pt)
            let results = raycaster.intersect(scene, true)
            for result in results {
                print(result.object.label)
                print(result.position)
            }
        }
    }
    #endif
    #endif
    
    func normalizePoint(_ point: CGPoint, _ size: CGSize) -> simd_float2 {
        #if os(macOS)
        return 2.0 * simd_make_float2(Float(point.x / size.width), Float(point.y / size.height)) - 1.0
        #else
        return 2.0 * simd_make_float2(Float(point.x / size.width), 1.0 - Float(point.y / size.height)) - 1.0
        #endif
    }
}
