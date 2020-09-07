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

class CustomMaterial: LiveMaterial {}

class Renderer: Forge.Renderer {
    var assetsURL: URL {
        let resourcesURL = Bundle.main.resourceURL!
        return resourcesURL.appendingPathComponent("Assets")
    }
    
    var texturesURL: URL {
        return assetsURL.appendingPathComponent("Textures")
    }
    
    var pipelinesURL: URL {
        return assetsURL.appendingPathComponent("Pipelines")
    }
    
    var scene = Object()
    
    lazy var context: Context = {
        Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }()
    
    lazy var camera: PerspectiveCamera = {
        let camera = PerspectiveCamera()
        camera.position = simd_make_float3(0.0, 0.0, 6.0)
        camera.near = 0.001
        camera.far = 200.0
        return camera
    }()
    
    lazy var cameraController: PerspectiveCameraController = {
        PerspectiveCameraController(camera: camera, view: mtkView)
    }()
    
    lazy var renderer: Satin.Renderer = {
        let renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
        return renderer
    }()
    
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
        scene.add(mesh)
        return mesh
    }()
    
    lazy var customMaterial: CustomMaterial = {
        CustomMaterial(pipelineURL: pipelinesURL.appendingPathComponent("Shaders.metal"))
    }()
    
    lazy var skybox: Mesh = {
        let mesh = Mesh(geometry: SkyboxGeometry(), material: SkyboxMaterial())
        mesh.label = "Skybox"
        mesh.scale = [50, 50, 50]
        scene.add(mesh)
        return mesh
    }()
    
    lazy var cubeTexture: MTLTexture? = {
        let url = texturesURL.appendingPathComponent("Cubemap")
        
        let texture = makeCubeTexture(
            context,
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
        
        if let texture = texture, let material = skybox.material as? SkyboxMaterial {
            material.texture = texture
        }
        
        return texture
    }()
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
        metalKitView.colorPixelFormat = .bgra8Unorm
    }
    
    override func setup() {
        setupMeshPreDraw()
        #if os(macOS)
        openEditor()
        #endif
    }
    
    override func update() {
        cameraController.update()
        renderer.update()
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
    
    func setupMeshPreDraw() {
        mesh.preDraw = { [unowned self] (renderEncoder: MTLRenderCommandEncoder) in
            renderEncoder.setFragmentTexture(self.cubeTexture, index: FragmentTextureIndex.Custom0.rawValue)
        }
    }
    
    #if os(macOS)
    func openEditor() {
        if let editorPath = UserDefaults.standard.string(forKey: "Editor") {
            NSWorkspace.shared.openFile(assetsURL.path, withApplication: editorPath)
        }
        else {
            let openPanel = NSOpenPanel()
            openPanel.canChooseFiles = true
            openPanel.allowsMultipleSelection = false
            openPanel.canCreateDirectories = false
            openPanel.begin(completionHandler: { [unowned self] (result: NSApplication.ModalResponse) in
                if result == .OK {
                    if let editorUrl = openPanel.url {
                        let editorPath = editorUrl.path
                        UserDefaults.standard.set(editorPath, forKey: "Editor")
                        NSWorkspace.shared.openFile(self.assetsURL.path, withApplication: editorPath)
                    }
                }
                openPanel.close()
            })
        }
    }
    #endif
}
