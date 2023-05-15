//
//  ARGlowRenderer.swift
//  Example
//
//  Created by Reza Ali on 4/26/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

#if os(iOS)
import ARKit

import Metal
import MetalKit
import MetalPerformanceShaders

import Combine

import Forge
import Satin
import SatinCore

class ARBloomRenderer: BaseRenderer {
    class BloomMaterial: SourceMaterial {
        public var grainIntensity: Float = 0.0 {
            didSet {
                set("Grain Intensity", grainIntensity)
            }
        }

        public var time: Float = 0.0 {
            didSet {
                set("Time", time)
            }
        }

        public var grainTexture: MTLTexture?
        public var backgroundTexture: MTLTexture?
        public var contentTexture: MTLTexture?
        public var bloomTexture: MTLTexture?

        override func bind(_ renderEncoder: MTLRenderCommandEncoder, shadow: Bool) {
            super.bind(renderEncoder, shadow: shadow)
            renderEncoder.setFragmentTexture(backgroundTexture, index: FragmentTextureIndex.Custom0.rawValue)
            renderEncoder.setFragmentTexture(contentTexture, index: FragmentTextureIndex.Custom1.rawValue)
            renderEncoder.setFragmentTexture(bloomTexture, index: FragmentTextureIndex.Custom2.rawValue)
            renderEncoder.setFragmentTexture(grainTexture, index: FragmentTextureIndex.Custom3.rawValue)
        }
    }

    // MARK: - UI

    override var paramKeys: [String] {
        return ["Post Material"]
    }

    override var params: [String: ParameterGroup?] {
        return [
            "Post Material": postMaterial.parameters,
        ]
    }

    // MARK: - Glow Blur

    var blurFilter: MPSImageGaussianBlur!
    var scaleEffect: MPSImageBilinearScale!

    // MARK: - AR

    var session = ARSession()
    lazy var sessionPublisher = ARSessionPublisher(session: session)
    var sessionSubscriptions = Set<AnyCancellable>()

    let geometry = IcoSphereGeometry(radius: 0.1, res: 3)

    var occlusionMaterial = {
        let material = BasicColorMaterial([1, 1, 1, 0], .disabled)
        material.depthBias = DepthBias(bias: 10.0, slope: 10.0, clamp: 10.0)
        return material
    }()

    var objectAnchorMap: [UUID: Object] = [:]
    var scene = Object("Scene")

    lazy var context = Context(device, sampleCount, colorPixelFormat, .depth32Float)
    lazy var camera = ARPerspectiveCamera(session: session, mtkView: mtkView, near: 0.01, far: 100.0)
    lazy var renderer = Satin.Renderer(context: context)

    // handles depth (lidar depth map, lidar mesh & horizontal & vertical planes)
    var backgroundRenderer: ARBackgroundDepthRenderer!

    lazy var bloomRenderer = Satin.Renderer(context: context)
    var bloomedScene = Object("Bloomed Objects")

    var contentTexture: MTLTexture?
    var bloomTexture: MTLTexture?
    var backgroundTexture: MTLTexture?
    var _updateTextures = true
    var bloomTextureScale: Int = 3

    lazy var startTime = getTime()

    lazy var postMaterial: BloomMaterial = {
        let material = BloomMaterial(pipelinesURL: pipelinesURL)
        material.depthWriteEnabled = false
        material.blending = .alpha
        return material
    }()

    lazy var postProcessor = PostProcessor(context: Context(device, 1, colorPixelFormat), material: postMaterial)

    override func setupMtkView(_ mtkView: MTKView) {
        mtkView.sampleCount = 1
        mtkView.depthStencilPixelFormat = .depth32Float
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.preferredFramesPerSecond = 120
    }

    override init() {
        super.init()

        let configuration = ARWorldTrackingConfiguration()
        // ARBackgroundDepthRenderer supports:
        configuration.frameSemantics = .smoothedSceneDepth
        // and/or
//        configuration.planeDetection = [.horizontal, .vertical]
        // and/or
//        configuration.sceneReconstruction = .mesh
        session.run(configuration)
    }

    override func setup() {
        setupBlurFilter()

        setupSessionObservers()

        renderer.label = "Renderer"
        renderer.depthLoadAction = .load
        renderer.setClearColor([1, 1, 1, 0.0])

        bloomRenderer.label = "Bloom Renderer"
        bloomRenderer.depthLoadAction = .load
        bloomRenderer.depthStoreAction = .store
        bloomRenderer.setClearColor([1, 1, 1, 0.0])

        geometry.context = context

        backgroundRenderer = ARBackgroundDepthRenderer(
            context: context,
            session: session,
            sessionPublisher: sessionPublisher,
            mtkView: mtkView,
            near: camera.near,
            far: camera.far
        )

        postProcessor.renderer.setClearColor(.one)
    }

    override func update() {
        if _updateTextures {
            bloomTexture = createTexture("Bloom Texture", colorPixelFormat, bloomTextureScale)
            backgroundTexture = createTexture("Background Texture", colorPixelFormat, 1)
            contentTexture = createTexture("Content Texture", colorPixelFormat, 1)
            _updateTextures = false
        }
    }

    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
              let contentTexture,
              let backgroundTexture,
              var bloomTexture else { return }

        backgroundRenderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            renderTarget: backgroundTexture
        )

        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera,
            renderTarget: contentTexture
        )

        // cache materials for meshes that are not bloomed
        var materialMap: [Mesh: Material?] = [:]
        scene.traverse { child in
            if !bloomedScene.children.contains(child),
               let mesh = child as? Mesh
            {
                materialMap[mesh] = mesh.material
                mesh.material = occlusionMaterial
            }
        }

        let brpd = MTLRenderPassDescriptor()
        brpd.depthAttachment.texture = renderPassDescriptor.depthAttachment.texture
        bloomRenderer.draw(
            renderPassDescriptor: brpd,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera
        )

        if let colorTexture = bloomRenderer.colorTexture {
            // save some gpu compute cycles by scaling to 1/4
            scaleEffect.encode(
                commandBuffer: commandBuffer,
                sourceTexture: colorTexture,
                destinationTexture: bloomTexture
            )

            // blur the texture further
            blurFilter.encode(
                commandBuffer: commandBuffer,
                inPlaceTexture: &bloomTexture
            )
        }

        scene.traverse { child in
            if !bloomedScene.children.contains(child),
               let mesh = child as? Mesh,
               let material = materialMap[mesh]
            {
                mesh.material = material
            }
        }

        postMaterial.backgroundTexture = backgroundTexture
        postMaterial.contentTexture = contentTexture
        postMaterial.bloomTexture = bloomTexture
        postMaterial.grainTexture = session.currentFrame?.cameraGrainTexture
        postMaterial.grainIntensity = session.currentFrame?.cameraGrainIntensity ?? 0
        postMaterial.time = Float(getTime() - startTime)

        postProcessor.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer
        )
    }

    override func resize(_ size: (width: Float, height: Float)) {
        renderer.resize(size)
        backgroundRenderer.resize(size)
        bloomRenderer.resize(size)
        postProcessor.resize(size)
        _updateTextures = true
    }

    override func cleanup() {
        session.pause()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        let location = touch.location(in: mtkView)
        let coordinate = normalizePoint(location, mtkView.frame.size)

        let result = raycast(ray: Ray(camera: camera, coordinate: coordinate), object: scene)
        if let first = result.first?.object {
            if bloomedScene.children.contains(first) {
                bloomedScene.remove(first)
            } else {
                bloomedScene.attach(first)
            }
        } else if let currentFrame = session.currentFrame {
            let anchor = ARAnchor(transform: simd_mul(currentFrame.camera.transform, translationMatrixf(0.0, 0.0, -0.25)))
            session.add(anchor: anchor)

            let mesh = Mesh(
                geometry: geometry,
                material: BasicColorMaterial(simd_float4(.random(in: 0.25 ... 1), 0.8), .alpha)
            )
            mesh.cullMode = .none
            mesh.scale = .init(repeating: .random(in: 0.25 ... 1.0))

            let object = Object(anchor.identifier.uuidString, [mesh])

            scene.attach(object)
            object.worldMatrix = anchor.transform
            objectAnchorMap[anchor.identifier] = object
        }
    }

    // MARK: - Internal Methods

    internal func setupSessionObservers() {
        sessionPublisher.updatedAnchorsPublisher.sink { [weak self] anchors in
            guard let self = self else { return }
            for anchor in anchors {
                if let object = objectAnchorMap[anchor.identifier] {
                    object.worldMatrix = anchor.transform
                }
            }
        }.store(in: &sessionSubscriptions)
    }

    internal func setupBlurFilter() {
        blurFilter = MPSImageGaussianBlur(device: device, sigma: 32)
        blurFilter.edgeMode = .clamp
        scaleEffect = MPSImageBilinearScale(device: device)
    }

    private func normalizePoint(_ point: CGPoint, _ size: CGSize) -> simd_float2 {
#if os(macOS)
        return 2.0 * simd_make_float2(Float(point.x / size.width), Float(point.y / size.height)) - 1.0
#else
        return 2.0 * simd_make_float2(Float(point.x / size.width), 1.0 - Float(point.y / size.height)) - 1.0
#endif
    }

    internal func createTexture(_ label: String, _ pixelFormat: MTLPixelFormat, _ textureScale: Int) -> MTLTexture? {
        if mtkView.drawableSize.width > 0, mtkView.drawableSize.height > 0 {
            let descriptor = MTLTextureDescriptor()
            descriptor.pixelFormat = pixelFormat
            descriptor.width = Int(mtkView.drawableSize.width) / textureScale
            descriptor.height = Int(mtkView.drawableSize.height) / textureScale
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
