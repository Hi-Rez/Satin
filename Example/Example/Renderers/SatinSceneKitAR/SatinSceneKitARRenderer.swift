//
//  Renderer.swift
//  SatinSceneKitAR-iOS
//
//  Created by Reza Ali on 6/24/21.
//  Copyright © 2021 Hi-Rez. All rights reserved.
//
#if os(iOS)

import ARKit
import Metal
import MetalKit

import Forge
import Satin

class SatinSceneKitARRenderer: BaseRenderer, ARSessionDelegate {
    class BackgroundMaterial: LiveMaterial {}
    
    // MARK: - Paths
    
    var assetsURL: URL { Bundle.main.resourceURL!.appendingPathComponent("Assets") }
    var sharedAssetsURL: URL { assetsURL.appendingPathComponent("Shared") }
    var rendererAssetsURL: URL { assetsURL.appendingPathComponent(String(describing: type(of: self))) }
    var pipelinesURL: URL { rendererAssetsURL.appendingPathComponent("Pipelines") }
    var modelsURL: URL { sharedAssetsURL.appendingPathComponent("Models") }
    
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
    
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    
    lazy var camera = PerspectiveCamera(position: .zero, near: 0.001, far: 100.0, fov: 45)
    
    lazy var renderer: Satin.Renderer = {
        let renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
        renderer.colorLoadAction = .load
        return renderer
    }()
    
    // MARK: - Background Renderer
    
    var viewportSize = CGSize(width: 0, height: 0)
    var _updateBackgroundGeometry = true
    
    lazy var backgroundMesh: Mesh = {
        let material = BackgroundMaterial(pipelinesURL: pipelinesURL)
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
        NotificationCenter.default.addObserver(self, selector: #selector(SatinSceneKitARRenderer.rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    func setupScene() {
        do {
            let scene = try SCNScene(url: modelsURL.appendingPathComponent("Ship").appendingPathComponent("Ship.scn"), options: nil)
            scnScene = scene
            scnScene.rootNode.childNodes.first?.simdScale = simd_float3(repeating: 0.01)
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    @objc func rotated() {
        _updateBackgroundGeometry = true
    }
    
    override func update() {
        updateCamera()
        updateBackground()
    }
    
    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        scnCamera.projectionTransform = SCNMatrix4(camera.projectionMatrix)
        cameraNode.simdTransform = camera.worldMatrix
    
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        backgroundRenderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
        renderer.depthStoreAction = .store
        renderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
        
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.depthAttachment.loadAction = .load
        
        scnRenderer.render(atTime: 0, viewport: CGRect(x: 0, y: 0, width: viewportSize.width, height: viewportSize.height), commandBuffer: commandBuffer, passDescriptor: renderPassDescriptor)
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
            mesh.onUpdate = { [weak mesh, weak anchor] in
                guard let mesh = mesh, let anchor = anchor else { return }
                mesh.localMatrix = anchor.transform
            }

            scene.add(mesh)
        }
    }
}

#endif
