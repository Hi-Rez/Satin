//
//  Renderer.swift
//  Scenekit-macOS
//
//  Created by Reza Ali on 6/23/21.
//  Copyright © 2021 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit
import SceneKit

import Forge
import Satin

class SatinSceneKitRenderer: BaseRenderer {
    var assetsURL: URL { Bundle.main.resourceURL!.appendingPathComponent("Assets") }
    var sharedAssetsURL: URL { assetsURL.appendingPathComponent("Shared") }
    var rendererAssetsURL: URL { assetsURL.appendingPathComponent(String(describing: type(of: self))) }
    var modelsURL: URL { sharedAssetsURL.appendingPathComponent("Models") }
    
    lazy var cameraNode: SCNNode = {
        let node = SCNNode()
        node.camera = scnCamera
        return node
    }()
    
    lazy var scnCamera: SCNCamera = {
        let scnCamera = SCNCamera()
        scnCamera.fieldOfView = CGFloat(camera.fov)
        scnCamera.zNear = Double(camera.near)
        scnCamera.zFar = Double(camera.far)
        return scnCamera
    }()

    var scnScene = SCNScene()
    
    lazy var scnRenderer: SCNRenderer = {
        let renderer = SCNRenderer(device: context.device, options: nil)
        renderer.scene = scnScene
        renderer.autoenablesDefaultLighting = true
        renderer.pointOfView = cameraNode
        return renderer
    }()
    
    lazy var mesh: Mesh = {
        Mesh(geometry: ExtrudedTextGeometry(text: "Satin + SceneKit :D", fontName: "", fontSize: 3, distance: 0.25, pivot: [0.0, 0.0]), material: BasicDiffuseMaterial(0.7))
    }()
    
    lazy var scene: Object = {
        let scene = Object("Scene", [mesh])
        mesh.position = [0, 12, 0]
        return scene
    }()
    
    var camera = PerspectiveCamera(position: [0.0, 0.0, 50.0], near: 0.001, far: 100.0, fov: 45)
    
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: mtkView)
    lazy var renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.colorPixelFormat = .bgra8Unorm_srgb
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
    }
    
    override func setup() {
        setupScene()
    }
    
    func setupScene() {
        do {
            let scene = try SCNScene(
                url: modelsURL.appendingPathComponent("Ship").appendingPathComponent("Ship.scn"),
                options: nil
            )
            scnScene = scene
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    override func update() {
        cameraController.update()
        scnCamera.projectionTransform = SCNMatrix4(camera.projectionMatrix)
        cameraNode.simdTransform = camera.worldMatrix
    }
    
    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        renderer.depthStoreAction = .store
        renderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
        
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.depthAttachment.loadAction = .load
        
        scnRenderer.render(atTime: 0, viewport: CGRect(x: 0, y: 0, width: renderer.viewport.width, height: renderer.viewport.height), commandBuffer: commandBuffer, passDescriptor: renderPassDescriptor)
    }
    
    override func resize(_ size: (width: Float, height: Float)) {
        camera.aspect = size.width / size.height
        renderer.resize(size)
    }
}
