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

class AudioInputRenderer: BaseRenderer {
    lazy var audioInput: AudioInput = AudioInput(context: context)
    
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
    
    lazy var mesh: Mesh = Mesh(geometry: PlaneGeometry(size: 700), material: audioMaterial)
    
    var camera = OrthographicCamera()
    
    lazy var scene = Object("Scene", [mesh])
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var cameraController = OrthographicCameraController(camera: camera, view: mtkView)
    lazy var renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
    
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

