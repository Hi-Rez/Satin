//
//  ARBackgroundDepthRenderer.swift
//  Example
//
//  Created by Reza Ali on 4/11/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

#if os(iOS)

import Combine
import Foundation

import ARKit
import Metal
import MetalKit

import Satin

class ARBackgroundDepthRenderer: ARBackgroundRenderer {
    class BackgroundDepthMaterial: SourceMaterial {
        public var depthTexture: CVMetalTexture?

        required init() {
            super.init(pipelinesURL: Bundle.main.resourceURL!
                .appendingPathComponent("Assets")
                .appendingPathComponent("Shared")
                .appendingPathComponent("Pipelines")
            )
            depthWriteEnabled = true
            blending = .alpha
        }

        required init(from _: Decoder) throws {
            fatalError("init(from:) has not been implemented")
        }

        override func bind(_ renderEncoder: MTLRenderCommandEncoder, shadow: Bool) {
            super.bind(renderEncoder, shadow: shadow)
            if let depthTexture = depthTexture {
                renderEncoder.setFragmentTexture(CVMetalTextureGetTexture(depthTexture), index: FragmentTextureIndex.Custom0.rawValue)
            }
        }
    }

    // Captured image texture cache
    private var capturedImageTextureCache: CVMetalTextureCache!
    private var viewportSize = CGSize(width: 0, height: 0)
    private var _updateGeometry = true

    unowned var sessionPublisher: ARSessionPublisher
    private var sessionSubscriptions = Set<AnyCancellable>()

    private lazy var background = Object("AR Background", [depthMesh, mesh])

    private var depthRenderer: Satin.Renderer
    private var depthAnchorPlaneMeshMap: [UUID: ARPlaneMesh] = [:]
    private var depthAnchorLidarMeshMap: [UUID: ARLidarMesh] = [:]

    private var depthScene = Object("Depth Scene")
    private var depthMesh: Mesh
    private var depthCamera: ARPerspectiveCamera

    private var depthMaterial = {
        let material = BasicColorMaterial([1, 1, 1, 0], .alpha)
        material.depthBias = DepthBias(bias: 5, slope: 5, clamp: 5)
        return material
    }()

    private var depthLidarMaterial = {
        let material = BasicColorMaterial([1, 1, 1, 0], .alpha)
        material.depthBias = DepthBias(bias: 5, slope: 5, clamp: 5)
        return material
    }()

    public init(context: Context, session: ARSession, sessionPublisher: ARSessionPublisher, mtkView: MTKView, near: Float = 0.01, far: Float = 10.0) {
        depthRenderer = Satin.Renderer(context: context)

        depthRenderer.colorLoadAction = .clear
        depthRenderer.colorStoreAction = .store

        depthRenderer.depthLoadAction = .clear
        depthRenderer.depthStoreAction = .store

        depthCamera = ARPerspectiveCamera(session: session, mtkView: mtkView, near: near, far: far)

        self.sessionPublisher = sessionPublisher

        depthMesh = Mesh(geometry: Geometry(), material: BackgroundDepthMaterial())
        depthMesh.label = "AR Depth Mesh"
        depthMesh.visible = false

        super.init(context: context, session: session)

        mesh.label = "AR Color Mesh"
        mesh.material!.depthCompareFunction = .always

        depthMesh.material!.set("Near Far Delta", [near, far, far - near])

        depthCamera.add(background)
        depthScene.attach(background)

        setupSessionSubscriptions()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    override func update() {
        super.update()
        background.scale = [depthCamera.aspect, 1.0, 1.0]
        background.position = [0, 0, -1.0 / tan(degToRad(depthCamera.fov * 0.5))]
    }

    override func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
        update()

        depthRenderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: depthScene,
            camera: depthCamera
        )
    }

    override func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer, renderTarget: MTLTexture) {
        update()

        depthRenderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: depthScene,
            camera: depthCamera,
            renderTarget: renderTarget
        )
    }

    override func resize(_ size: (width: Float, height: Float)) {
        super.resize(size)
        depthRenderer.resize(size)
        _updateGeometry = true
        viewportSize = CGSize(width: Int(size.width), height: Int(size.height))
    }

    // MARK: - Internal Methods

    internal func setupSessionSubscriptions() {
        sessionPublisher.addedAnchorsPublisher.sink { [weak self] anchors in
            self?.addedAnchors(anchors)
        }.store(in: &sessionSubscriptions)

        sessionPublisher.updatedAnchorsPublisher.sink { [weak self] anchors in
            self?.updatedAnchors(anchors)
        }.store(in: &sessionSubscriptions)

        sessionPublisher.removedAnchorsPublisher.sink { [weak self] anchors in
            self?.removedAnchors(anchors)
        }.store(in: &sessionSubscriptions)
    }

    override func updateTextures(_ frame: ARFrame) {
        super.updateTextures(frame)
        updateDepthTexture(frame)
    }

    internal func updateDepthTexture(_ frame: ARFrame) {
        if let material = depthMesh.material as? BackgroundDepthMaterial,
           let sceneDepth = frame.smoothedSceneDepth ?? frame.sceneDepth
        {
            let depthPixelBuffer = sceneDepth.depthMap
            if let depthTexturePixelFormat = getMTLPixelFormat(for: depthPixelBuffer) {
                depthMesh.visible = true
                material.depthTexture = createTexture(
                    fromPixelBuffer: depthPixelBuffer,
                    pixelFormat: depthTexturePixelFormat,
                    planeIndex: 0
                )
            }
        }
    }

    override func updateGeometry(_ frame: ARFrame) {
        super.updateGeometry(frame)
        depthMesh.geometry = mesh.geometry
    }

    internal func getMTLPixelFormat(for pixelBuffer: CVPixelBuffer) -> MTLPixelFormat? {
        if CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_DepthFloat32 {
            return .r32Float
        } else if CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_OneComponent8 {
            return .r8Uint
        } else {
            return nil
        }
    }

    // MARK: - Depth Scene

    internal func addedAnchors(_ anchors: [ARAnchor]) {
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                let planeMesh = ARPlaneMesh(
                    label: anchor.identifier.uuidString,
                    anchor: planeAnchor,
                    material: depthMaterial
                )
                depthAnchorPlaneMeshMap[anchor.identifier] = planeMesh
                depthScene.add(planeMesh)
            }
            else if let meshAnchor = anchor as? ARMeshAnchor {
                let lidarMesh = ARLidarMesh(meshAnchor: meshAnchor, material: depthLidarMaterial)
                depthAnchorLidarMeshMap[anchor.identifier] = lidarMesh
                depthScene.add(lidarMesh)
            }
        }
    }

    internal func updatedAnchors(_ anchors: [ARAnchor]) {
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                if let planeMesh = depthAnchorPlaneMeshMap[anchor.identifier] {
                    planeMesh.anchor = planeAnchor
                }
            }
            else if let meshAnchor = anchor as? ARMeshAnchor {
                if let lidarMesh = depthAnchorLidarMeshMap[anchor.identifier] {
                    lidarMesh.meshAnchor = meshAnchor
                }
            }
        }
    }

    internal func removedAnchors(_ anchors: [ARAnchor]) {
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                if let mesh = depthAnchorPlaneMeshMap.removeValue(forKey: anchor.identifier) {
                    depthScene.remove(mesh)
                }
            }
            else if let meshAnchor = anchor as? ARMeshAnchor {
                if let mesh = depthAnchorLidarMeshMap.removeValue(forKey: anchor.identifier) {
                    depthScene.remove(mesh)
                }
            }
        }
    }
}

#endif
