//
//  Renderer.swift
//  Cubemap
//
//  Created by Reza Ali on 6/7/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//
//  Cube Map Texture (quarry_01) from: https://hdrihaven.com/hdri/
//

import Metal
import MetalKit

import Forge
import Satin

class CubemapRenderer: BaseRenderer {
    class CustomMaterial: LiveMaterial {}
    
    var assetsURL: URL { Bundle.main.resourceURL!.appendingPathComponent("Assets") }
    var rendererAssetsURL: URL { assetsURL.appendingPathComponent(String(describing: type(of: self))) }
    var pipelinesURL: URL { rendererAssetsURL.appendingPathComponent("Pipelines") }
    var texturesURL: URL { rendererAssetsURL.appendingPathComponent("Textures") }
    
    var camera = PerspectiveCamera(position: [0.0, 0.0, 6.0], near: 0.001, far: 200.0, fov: 45.0)
    
    lazy var scene = Object("Scene", [skybox, mesh])
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: mtkView)
    lazy var renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
    
    lazy var mesh: Mesh = {
        let twoPi = Float.pi * 2.0
        let geometry = ParametricGeometry(u: (0.0, twoPi), v: (0.0, twoPi), res: (400, 32), generator: { u, v in
            let R: Float = 0.75
            let r: Float = 0.25
            let c: Float = 0.125
            let q: Float = 2.0
            let p: Float = 6.0
            return torusKnotGenerator(u, v, R, r, c, q, p)
        })
        
        let mesh = Mesh(geometry: geometry, material: customMaterial)
        mesh.cullMode = .none
        mesh.label = "Knot"
        mesh.preDraw = { [unowned self] (renderEncoder: MTLRenderCommandEncoder) in
            renderEncoder.setFragmentTexture(self.cubeTexture, index: FragmentTextureIndex.Custom0.rawValue)
        }
        return mesh
    }()
    
    lazy var customMaterial = CustomMaterial(pipelineURL: pipelinesURL.appendingPathComponent("Shaders.metal"))
        
    lazy var skybox: Mesh = {
        let mesh = Mesh(geometry: SkyboxGeometry(), material: SkyboxMaterial())
        mesh.label = "Skybox"
        mesh.scale = [50, 50, 50]
        return mesh
    }()
    
    var cubeTexture: MTLTexture!
    
    override func setup() {
        let url = texturesURL.appendingPathComponent("Cubemap")
        cubeTexture = makeCubeTexture(
            device,
            [
                url.appendingPathComponent("px.png"),
                url.appendingPathComponent("nx.png"),
                url.appendingPathComponent("py.png"),
                url.appendingPathComponent("ny.png"),
                url.appendingPathComponent("pz.png"),
                url.appendingPathComponent("nz.png"),
            ],
            true // <- generates mipmaps
        )
        
        if let texture = cubeTexture, let material = skybox.material as? SkyboxMaterial {
            material.texture = texture
        }
    }
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
        metalKitView.colorPixelFormat = .bgra8Unorm
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
