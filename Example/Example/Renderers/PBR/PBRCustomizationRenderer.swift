//
//  PBRCustomizationRenderer.swift
//  Example
//
//  Created by Reza Ali on 4/4/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//
//  Cube Map Texture from: https://hdrihaven.com/hdri/
//

import Metal
import MetalKit

import Forge
import Satin

class PBRCustomizationRenderer: BaseRenderer {
    // MARK: - 3D Scene

    override var texturesURL: URL { sharedAssetsURL.appendingPathComponent("Textures") }

    var material = PhysicalMaterial()
    lazy var mesh = Mesh(geometry: BoxGeometry(size: 4.0), material: material)
    lazy var scene = Scene("Scene", [skybox, mesh])
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var camera = PerspectiveCamera(position: .init(repeating: 10.0), near: 0.001, far: 1000.0)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: mtkView)
    lazy var renderer: Satin.Renderer = .init(context: context)

    lazy var skyboxMaterial = SkyboxMaterial()
    lazy var skybox = Mesh(geometry: SkyboxGeometry(size: 50), material: skyboxMaterial)

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
        metalKitView.colorPixelFormat = .bgra8Unorm
    }

    override func setup() {
        camera.lookAt(target: .zero)
        loadHdri()
        generateNoiseTexture()
    }

    deinit {
        cameraController.disable()
    }

    func loadHdri() {
        let filename = "brown_photostudio_02_2k.hdr"
        if let hdr = loadHDR(device: device, url: texturesURL.appendingPathComponent(filename)) {
            scene.setEnvironment(texture: hdr)
        }
    }

    lazy var startTime = getTime()
    override func update() {
        cameraController.update()
        let osc = Float(sin(getTime() - startTime)) * 0.5
        let scale = simd_float2(repeating: osc + 1.0)
        let rotation: Float = osc * Float.pi
        let offset = simd_float2(repeating: -0.5)
        material.setTexcoordTransform(offset: offset, scale: scale, rotation: rotation, type: .roughness)
    }

    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera
        )
    }

    override func resize(_ size: (width: Float, height: Float)) {
        camera.aspect = size.width / size.height
        renderer.resize(size)
    }

    func generateNoiseTexture() {
        let randomNoiseGenerator = RandomNoiseGenerator(device: device, size: (64, 64), range: 0.0 ... 0.5)
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            let noiseTexture = randomNoiseGenerator.encode(commandBuffer: commandBuffer)
            commandBuffer.addCompletedHandler { _ in
                self.material.metallic = 1.0
                self.material.setTexture(noiseTexture, type: .roughness)
                let sampler = MTLSamplerDescriptor()
                sampler.minFilter = .nearest
                sampler.magFilter = .nearest
                sampler.sAddressMode = .repeat
                sampler.tAddressMode = .repeat
                self.material.setSampler(sampler, type: .roughness)
            }
            commandBuffer.commit()
        }
    }
}
