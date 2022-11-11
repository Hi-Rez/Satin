//
//  FlockingRenderer.swift
//  Example
//
//  Created by Reza Ali on 8/17/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import Combine
import Metal
import MetalKit

import Forge
import Satin

class FlockingRenderer: BaseRenderer {
    class FlockingComputeSystem: LiveBufferComputeSystem {}
    class InstanceMaterial: LiveMaterial {}
    class SpriteMaterial: LiveMaterial {}

    // MARK: - Paths
    
    var assetsURL: URL { Bundle.main.resourceURL!.appendingPathComponent("Assets") }
    var rendererAssetsURL: URL { assetsURL.appendingPathComponent(String(describing: type(of: self))) }
    var pipelinesURL: URL { rendererAssetsURL.appendingPathComponent("Pipelines") }
    
    lazy var startTime = CFAbsoluteTimeGetCurrent()
    
    // MARK: - Controls
    
    var cancellables = Set<AnyCancellable>()
    #if os(macOS)
    var particleCountParam = IntParameter("Particle Count", 16384, .inputfield)
    #elseif os(iOS)
    var particleCountParam = IntParameter("Particle Count", 4096, .inputfield)
    #endif
    
    var resetParam = BoolParameter("Reset", false)
    var pauseParam = BoolParameter("Pause", false)
    
    lazy var params = ParameterGroup("Controls", [pauseParam, resetParam, particleCountParam])
    
    lazy var scene = Object("Scene", [sprite])
    var camera = OrthographicCamera()
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
    lazy var particleSystem = FlockingComputeSystem(device: device, pipelinesURL: pipelinesURL, count: particleCountParam.value, feedback: true)
        
    lazy var spriteMaterial: SpriteMaterial = {
        let material = SpriteMaterial(pipelinesURL: pipelinesURL)
        material.depthWriteEnabled = false
        return material
    }()
    
    lazy var sprite: Mesh = {
        let mesh = Mesh(geometry: PointGeometry(), material: spriteMaterial)
        mesh.label = "Sprite"
        mesh.cullMode = .none
        mesh.instanceCount = particleCountParam.value
        mesh.preDraw = { [unowned self] (renderEncoder: MTLRenderCommandEncoder) in
            if let buffer = self.particleSystem.getBuffer("Flocking") {
                renderEncoder.setVertexBuffer(
                    buffer,
                    offset: 0,
                    index: VertexBufferIndex.Custom0.rawValue
                )
            }
            if let uniforms = self.particleSystem.uniforms {
                renderEncoder.setVertexBuffer(
                    uniforms.buffer,
                    offset: uniforms.offset,
                    index: VertexBufferIndex.Custom1.rawValue
                )
            }
        }
        return mesh
    }()
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.isPaused = false
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .invalid
        metalKitView.preferredFramesPerSecond = 60
    }
    
    override func setup() {
        setupObservers()
    }
    
    func setupObservers() {
        particleCountParam.$value.sink { [weak self] value in
            guard let self = self else { return }
            self.particleSystem.count = value
            self.sprite.instanceCount = value
        }.store(in: &cancellables)
        
        resetParam.$value.sink { [weak self] value in
            guard let self = self, value == true else { return }
            self.particleSystem.reset()
            self.resetParam.value = false
        }.store(in: &cancellables)
    }
    
    override func update() {
        let time = Float(CFAbsoluteTimeGetCurrent() - startTime)
        particleSystem.set("Time", time)
        spriteMaterial.set("Time", time)
    }
    
    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        if !pauseParam.value {
            particleSystem.update(commandBuffer)
        }
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        renderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
    }
    
    override func resize(_ size: (width: Float, height: Float)) {
        let hw = size.width
        let hh = size.height
        camera.update(left: -hw, right: hw, bottom: -hh, top: hh, near: -100.0, far: 100.0)
        
        renderer.resize(size)
        let res: simd_float3 = [size.width, size.height, size.width / size.height]
        spriteMaterial.set("Resolution", res)
        particleSystem.set("Resolution", res)
    }
}
