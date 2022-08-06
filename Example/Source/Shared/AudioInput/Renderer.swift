//
//  Renderer.swift
//  AudioInput-macOS
//
//  Created by Reza Ali on 8/4/21.
//  Copyright © 2021 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin

class Renderer: Forge.Renderer {
    lazy var audioInput: AudioInput = {
        let audioInput = AudioInput(context: context)
        audioInput.input.value = "Loopback Audio"
        return audioInput
    }()
    
    lazy var audioMaterial: BasicTextureMaterial = {
        let mat = BasicTextureMaterial()
        
        let desc = MTLSamplerDescriptor()
        desc.label = "Audio Texture Sampler"
        desc.minFilter = .nearest
        desc.magFilter = .nearest
        mat.sampler = context.device.makeSamplerState(descriptor: desc)
        
        mat.onUpdate = { [weak self, weak mat] in
            guard let self = self, let mat = mat else { return }
            mat.texture = self.audioInput.texture
        }
        return mat
    }()
    
    lazy var mesh: Mesh = {
        let mesh = Mesh(geometry: PlaneGeometry(size: 700), material: audioMaterial)
        mesh.label = "Quad"
        return mesh
    }()
    
    lazy var scene: Object = {
        let scene = Object()
        scene.add(mesh)
        return scene
    }()
    
    lazy var context: Context = {
        Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }()
    
    lazy var camera: OrthographicCamera = {
        OrthographicCamera()
    }()
    
    lazy var cameraController: OrthographicCameraController = {
        OrthographicCameraController(camera: camera, view: mtkView)
    }()
    
    lazy var renderer: Satin.Renderer = {
        let renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
        renderer.setClearColor([1, 1, 1, 1])
        return renderer
    }()
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .invalid
        metalKitView.preferredFramesPerSecond = 60
    }
    
    override func setup() {
        print(audioInput.inputs)
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
    }
}

