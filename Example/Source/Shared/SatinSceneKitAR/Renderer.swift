//
//  Renderer.swift
//  SatinSceneKitAR-iOS
//
//  Created by Reza Ali on 6/24/21.
//  Copyright © 2021 Hi-Rez. All rights reserved.
//

import ARKit
import Metal
import MetalKit

import Forge
import Satin

class BackgroundMaterial: LiveMaterial {}

class Renderer: Forge.Renderer, ARSessionDelegate {
    // MARK: - Paths
    
    var assetsURL: URL {
        let resourcesURL = Bundle.main.resourceURL!
        return resourcesURL.appendingPathComponent("Assets")
    }
    
    var pipelineURL: URL {
        return assetsURL.appendingPathComponent("Shaders.metal")
    }
    
    // MARK: SceneKit
        
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
    
    // MARK: - AR
    
    var session: ARSession!
    
    // Background Textures
    var capturedImageTextureY: CVMetalTexture?
    var capturedImageTextureCbCr: CVMetalTexture?
    
    // Captured image texture cache
    var capturedImageTextureCache: CVMetalTextureCache!
    
    // MARK: - 3D
    
    let boxGeometry = BoxGeometry(size: (0.1, 0.1, 0.1))
    let boxMaterial = BasicDiffuseMaterial(0.7)
    
    var scene = Object()
    
    lazy var context: Context = {
        Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }()
    
    lazy var camera: PerspectiveCamera = {
        let camera = PerspectiveCamera()
        camera.fov = 45
        camera.near = 0.01
        camera.far = 100.0
        return camera
    }()
    
    lazy var renderer: Satin.Renderer = {
        let renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
        renderer.colorLoadAction = .load
        return renderer
    }()
    
    // MARK: - Background Renderer
    
    var viewportSize = CGSize(width: 0, height: 0)
    var _updateBackgroundGeometry = true
    
    lazy var backgroundMesh: Mesh = {
        let material = BackgroundMaterial(pipelineURL: pipelineURL)
        material.depthWriteEnabled = false
        material.onBind = { [unowned self] renderEncoder in
            guard let textureY = self.capturedImageTextureY, let textureCbCr = self.capturedImageTextureCbCr else {
                return
            }
            renderEncoder.setFragmentTexture(CVMetalTextureGetTexture(textureY), index: FragmentTextureIndex.Custom0.rawValue)
            renderEncoder.setFragmentTexture(CVMetalTextureGetTexture(textureCbCr), index: FragmentTextureIndex.Custom1.rawValue)
        }
        return Mesh(geometry: QuadGeometry(), material: material)
    }()
    
    lazy var backgroundRenderer: Satin.Renderer = {
        Satin.Renderer(
            context: Context(context.device, 1, context.colorPixelFormat, .invalid, .invalid),
            scene: backgroundMesh,
            camera: OrthographicCamera()
        )
    }()
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.colorPixelFormat = .bgra8Unorm_srgb
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        session.pause()
    }
    
    override func setup() {
        setupScene()
        setupARSession()
        setupBackgroundTextureCache()
        NotificationCenter.default.addObserver(self, selector: #selector(Renderer.rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    func setupScene()
    {
        do
        {
            let scene = try SCNScene(url: assetsURL.appendingPathComponent("ship.scn"), options: nil)
            scnScene = scene
            scnScene.rootNode.childNodes.first?.simdScale = simd_float3(repeating: 0.01)
        }
        catch
        {
            print(error.localizedDescription)
        }
    }    
    
    @objc func rotated() {
        _updateBackgroundGeometry = true
    }
    
    override func update() {
        updateCamera()
        updateBackground()
        scnCamera.projectionTransform = SCNMatrix4(camera.projectionMatrix)
        cameraNode.simdTransform = camera.worldMatrix
    }
    
    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        backgroundRenderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
        renderer.depthStoreAction = .store
        renderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
        
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.depthAttachment.loadAction = .load
        
        scnRenderer.render(atTime: 0, viewport: CGRect(x: 0, y: 0, width: renderer.viewport.width, height: renderer.viewport.height), commandBuffer: commandBuffer, passDescriptor: renderPassDescriptor)
    }
    
    override func resize(_ size: (width: Float, height: Float)) {
        renderer.resize(size)
        backgroundRenderer.resize(size)
        
        _updateBackgroundGeometry = true
        viewportSize = CGSize(width: Int(size.width), height: Int(size.height))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let currentFrame = session.currentFrame {
            // Create a transform with a translation of 0.2 meters in front of the camera
            var translation = matrix_identity_float4x4
            translation.columns.3.z = -0.2
            let transform = simd_mul(currentFrame.camera.transform, translation)
            
            // Add a new anchor to the session
            let anchor = ARAnchor(transform: transform)
            session.add(anchor: anchor)

            let mesh = Mesh(geometry: boxGeometry, material: boxMaterial)
            mesh.onUpdate = {
                mesh.localMatrix = anchor.transform
            }

            scene.add(mesh)
        }
    }
}
