//
//  InstancingRenderer.swift
//  Example
//
//  Created by Reza Ali on 8/17/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin

class CustomInstancingRenderer: BaseRenderer {
    class InstanceMaterial: LiveMaterial {}
    
    // MARK: - Paths
    
    var assetsURL: URL { Bundle.main.resourceURL!.appendingPathComponent("Assets") }
    var rendererAssetsURL: URL { assetsURL.appendingPathComponent(String(describing: type(of: self))) }
    var dataURL: URL { rendererAssetsURL.appendingPathComponent("Data") }
    var pipelinesURL: URL { rendererAssetsURL.appendingPathComponent("Pipelines") }
    
    var dataBuffer: MTLBuffer?
    
    lazy var instanceMaterial: InstanceMaterial = {
        let material = InstanceMaterial(pipelinesURL: pipelinesURL)
        material.onBind = { [unowned self] renderEncoder in
            renderEncoder.setVertexBuffer(self.dataBuffer, offset: 0, index: VertexBufferIndex.Custom0.rawValue)
        }
        return material
    }()
    
    var camera = OrthographicCamera()
    
    lazy var mesh = Mesh(geometry: QuadGeometry(), material: instanceMaterial)
    lazy var scene = Object("Scene", [mesh])
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var cameraController = OrthographicCameraController(camera: camera, view: mtkView, defaultZoom: 2.0)
    lazy var renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.isPaused = false
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .invalid
        metalKitView.preferredFramesPerSecond = 60
    }
    
    override func setup() {
        setupData()
    }
    
    func setupData() {
        var data: [Bool] = []
        do {
            let sequence = try String(contentsOf: dataURL.appendingPathComponent("SARS-CoV-2.txt"))
            for character in sequence {
                switch character {
                case "a":
                    data.append(false)
                    data.append(false)
                case "c":
                    data.append(false)
                    data.append(true)
                case "g":
                    data.append(true)
                    data.append(false)
                case "t":
                    data.append(true)
                    data.append(true)
                default:
                    break
                }
            }
        }
        catch {
            print(error.localizedDescription)
        }
        guard data.count > 0 else { return }
        dataBuffer = context.device.makeBuffer(bytes: &data, length: MemoryLayout<simd_bool>.stride * data.count)
        // data.count/2 because we are representing each character a = 0 c = 1 g = 2 t = 3 using two bools (00, 01, 10, 11)
        mesh.instanceCount = data.count/2
        instanceMaterial.set("Instance Count", Int(data.count/2))
    }
    
    override func update() {
        cameraController.update()
    }
    
    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        renderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
    }
    
    override func resize(_ size: (width: Float, height: Float)) {
        cameraController.resize(size)
        renderer.resize(size)
        instanceMaterial.set("Resolution", [size.width, size.height, size.width/size.height])
    }
}

