//
//  Renderer.swift
//  LiveCode-macOS
//
//  Created by Reza Ali on 6/1/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

// This example shows how to generate custom geometry using C

import Metal
import MetalKit

import Forge
import Satin

open class IcosahedronGeometry: Geometry {
    public init(size: Float = 2, res: Int = 6) {
        super.init()
        setupData(size: size, res: res)
    }
    
    required public init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    func setupData(size: Float, res: Int) {
        primitiveType = .triangle
        var geo = generateIcosahedronGeometryData(size, Int32(res))
        let vCount = Int(geo.vertexCount)
        if vCount > 0, let data = geo.vertexData {
            vertexData = Array(UnsafeBufferPointer(start: data, count: vCount))
        }

        let indexCount = Int(geo.indexCount)*3
        if indexCount > 0, let data = geo.indexData {
            data.withMemoryRebound(to: UInt32.self, capacity: indexCount) { ptr in
                indexData = Array(UnsafeBufferPointer(start: ptr, count: indexCount))
            }
        }
        freeGeometryData(&geo)
    }
}

class CustomGeometryRenderer: BaseRenderer {
    var assetsURL: URL { Bundle.main.resourceURL!.appendingPathComponent("Assets") }
    var texturesURL: URL { assetsURL.appendingPathComponent("Textures") }
    var modelsURL: URL { assetsURL.appendingPathComponent("Models") }
    
    var scene = Object("Scene")
    
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var camera = PerspectiveCamera(position: [0.0, 0.0, 6.0], near: 0.001, far: 100.0)
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
        setupMesh()
    }
    
    func setupMesh() {
        mesh = Mesh(geometry: IcosahedronGeometry(size: 1.0, res: 4), material: NormalColorMaterial(true))
        mesh.label = "Icosahedron"
        mesh.triangleFillMode = .lines
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
