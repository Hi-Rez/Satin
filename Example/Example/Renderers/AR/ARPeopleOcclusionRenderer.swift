//
//  ARPeopleOcclusionRenderer.swift
//  AR
//
//  Created by Reza Ali on 9/26/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

#if os(iOS)

import ARKit
import Metal
import MetalKit

import Forge
import Satin

class ARPeopleOcclusionRenderer: BaseRenderer, ARSessionDelegate {
    let session = ARSession()

    let boxGeometry = BoxGeometry(size: (0.1, 0.1, 0.1))
    let boxMaterial = UvColorMaterial()

    var meshAnchorMap: [UUID: Mesh] = [:]

    var scene = Object("Scene")

    lazy var camera = ARPerspectiveCamera(session: session, mtkView: mtkView, near: 0.001, far: 100.0)
    lazy var renderer: Satin.Renderer = {
        let renderer = Satin.Renderer(context: Context(device, sampleCount, colorPixelFormat, .depth32Float))
        renderer.setClearColor(.zero)
        renderer.colorLoadAction = .clear
        renderer.depthLoadAction = .clear
        return renderer
    }()

    var backgroundRenderer: ARBackgroundRenderer!
    var matteRenderer: ARMatteRenderer!

    var backgroundTexture: MTLTexture?
    var _updateTextures = true

    var compositor: ARCompositor!

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .invalid
        metalKitView.preferredFramesPerSecond = 60
    }

    override init() {
        super.init()
        let config = ARWorldTrackingConfiguration()
        config.frameSemantics = [.personSegmentationWithDepth]
        session.run(config)
    }

    override func setup() {
        backgroundRenderer = ARBackgroundRenderer(
            context: Context(device, 1, colorPixelFormat),
            session: session
        )

        matteRenderer = ARMatteRenderer(
            device: device,
            session: session,
            matteResolution: .full,
            near: camera.near,
            far: camera.far
        )

        compositor = ARCompositor(
            context: Context(device, 1, colorPixelFormat),
            session: session
        )
    }

    override func update() {
        if _updateTextures {
            backgroundTexture = createTexture("Background Texture", colorPixelFormat)
            _updateTextures = false
        }
    }

    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }

        matteRenderer.encode(commandBuffer: commandBuffer)

        if let backgroundTexture = backgroundTexture {
            backgroundRenderer.draw(
                renderPassDescriptor: MTLRenderPassDescriptor(),
                commandBuffer: commandBuffer,
                renderTarget: backgroundTexture
            )
        }

        renderer.draw(
            renderPassDescriptor: MTLRenderPassDescriptor(),
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera
        )
        
        compositor.backgroundTexture = backgroundTexture
        compositor.contentTexture = renderer.colorTexture
        compositor.depthTexture = renderer.depthTexture
        compositor.alphaTexture = matteRenderer.alphaTexture
        compositor.dilatedDepthTexture = matteRenderer.dilatedDepthTexture

        compositor.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer
        )
    }

    override func resize(_ size: (width: Float, height: Float)) {
        renderer.resize(size)
        backgroundRenderer.resize(size)
        compositor.resize(size)
        matteRenderer.resize(size)

        _updateTextures = true
    }

    override func cleanup() {
        session.pause()
    }

    override func touchesBegan(_: Set<UITouch>, with _: UIEvent?) {
        if let currentFrame = session.currentFrame {
            let anchor = ARAnchor(transform: simd_mul(currentFrame.camera.transform, translationMatrixf(0.0, 0.0, -0.25)))
            session.add(anchor: anchor)
            let mesh = Mesh(geometry: boxGeometry, material: boxMaterial)
            mesh.worldMatrix = anchor.transform
            meshAnchorMap[anchor.identifier] = mesh
            scene.add(mesh)
        }
    }

    func session(_: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let mesh = meshAnchorMap[anchor.identifier] {
                mesh.worldMatrix = anchor.transform
            }
        }
    }

    func createTexture(_ label: String, _ pixelFormat: MTLPixelFormat) -> MTLTexture? {
        if mtkView.drawableSize.width > 0, mtkView.drawableSize.height > 0 {
            let descriptor = MTLTextureDescriptor()
            descriptor.pixelFormat = pixelFormat
            descriptor.width = Int(mtkView.drawableSize.width)
            descriptor.height = Int(mtkView.drawableSize.height)
            descriptor.sampleCount = 1
            descriptor.textureType = .type2D
            descriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
            descriptor.storageMode = .private
            descriptor.resourceOptions = .storageModePrivate
            guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }
            texture.label = label
            return texture
        }
        return nil
    }
}

#endif
