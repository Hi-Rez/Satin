//
//  ARPBRRenderer.swift
//  Example
//
//  Created by Reza Ali on 4/25/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

#if os(iOS)
import ARKit
import Metal
import MetalPerformanceShaders
import MetalKit

import Forge
import Satin
import SatinCore
import Youi

fileprivate class ARScene: Object, Environment {
    private var assetsURL: URL { Bundle.main.resourceURL!.appendingPathComponent("Assets") }
    private var sharedAssetsURL: URL { assetsURL.appendingPathComponent("Shared") }
    private var texturesURL: URL { sharedAssetsURL.appendingPathComponent("Textures") }

    var environmentIntensity: Float = 1.0

    var environment: MTLTexture?
    var cubemapTexture: MTLTexture?

    var irradianceTexture: MTLTexture?
    var irradianceTexcoordTransform: simd_float3x3 = matrix_identity_float3x3

    var reflectionTexture: MTLTexture?
    var reflectionTexcoordTransform: simd_float3x3 = matrix_identity_float3x3

    var brdfTexture: MTLTexture?

    unowned var session: ARSession

    public init(_ label: String, _ children: [Object] = [], session: ARSession) {
        self.session = session
        super.init(label, children)
        Task(priority: .background) {
            if let device = MTLCreateSystemDefaultDevice() {
                self.generateBRDFLUT(device: device)
            }
        }
    }

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    func generateBRDFLUT(device: MTLDevice) {
        guard let commandQueue = device.makeCommandQueue(),
              let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        let _brdfTexture = BrdfGenerator(device: device, size: 512).encode(commandBuffer: commandBuffer)

        commandBuffer.addCompletedHandler { [weak self] _ in
            self?.brdfTexture = _brdfTexture
        }
        commandBuffer.commit()
    }

    func getClosestProbe(_ probes: [AREnvironmentProbeAnchor], position: simd_float3) -> AREnvironmentProbeAnchor? {
        var closest: AREnvironmentProbeAnchor? = nil
        var closestDistance: Float = .infinity
        for probe in probes {
            let transform = probe.transform
            let probePosition = simd_make_float3(transform.columns.3)
            let dist = simd_length(probePosition - position)
            if dist < closestDistance {
                closestDistance = dist
                closest = probe
            }
        }
        return closest
    }

    override func update(_ commandBuffer: MTLCommandBuffer) {
        super.update(commandBuffer)
        guard let currentFrame = session.currentFrame else { return }

        if let lightEstimate = currentFrame.lightEstimate {
            environmentIntensity = Float(lightEstimate.ambientIntensity / 2000.0)
        }

        let probes = currentFrame.anchors.compactMap { $0 as? AREnvironmentProbeAnchor }
        if !probes.isEmpty {
            traverse { child in
                if let renderable = child as? Renderable, let material = renderable.material as? StandardMaterial {
                    if let probe = getClosestProbe(probes, position: child.worldPosition),
                       let texture = probe.environmentTexture, texture.textureType == .typeCube
                    {
                        material.setTexture(texture, type: .reflection)
                        material.setTexture(texture, type: .irradiance)

                        let transform = simd_float3x3(
                            simd_make_float3(probe.transform.columns.0),
                            simd_make_float3(probe.transform.columns.1),
                            simd_make_float3(probe.transform.columns.2)
                        ) * matrix_float3x3(simd_quatf(angle: Float.pi, axis: Satin.worldUpDirection))

                        reflectionTexcoordTransform = transform
                        irradianceTexcoordTransform = transform

                        material.setTexcoordTransform(reflectionTexcoordTransform, type: .reflection)
                        material.setTexcoordTransform(irradianceTexcoordTransform, type: .irradiance)
                    }
                }
            }
        }
    }
}

fileprivate class ARObject: Object {
    var anchor: ARAnchor? {
        didSet {
            if let anchor = anchor {
                worldMatrix = anchor.transform
                visible = true
            }
        }
    }

    unowned var session: ARSession

    init(label: String, children: [Object] = [], session: ARSession) {
        self.session = session
        super.init(label, children)
        self.visible = false
    }

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    override func update(_ commandBuffer: MTLCommandBuffer) {
        super.update(commandBuffer)

        if let anchor = anchor,
           let currentFrame = session.currentFrame,
           let index = currentFrame.anchors.firstIndex(of: anchor)
        {
            worldMatrix = currentFrame.anchors[index].transform
        }
    }
}

class Model: Object {
    private var assetsURL: URL { Bundle.main.resourceURL!.appendingPathComponent("Assets") }
    private var sharedAssetsURL: URL { assetsURL.appendingPathComponent("Shared") }
    private var texturesURL: URL { sharedAssetsURL.appendingPathComponent("Textures") }
    private var modelsURL: URL { sharedAssetsURL.appendingPathComponent("Models") }

    var material = PhysicalMaterial()

    override init() {
        super.init("Suzanne")
        Task(priority: .background) {
            self.setupModel()
            await self.setupTextures()
        }
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    private func setupModel() {
        guard let device = MTLCreateSystemDefaultDevice() else { return }

        // we do this to make sure we don't recompile the material multiple times
        let cubeDesc = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .r32Float, size: 1, mipmapped: false)
        let cubeTexture = device.makeTexture(descriptor: cubeDesc)
        material.setTexture(cubeTexture, type: .reflection)
        material.setTexture(cubeTexture, type: .irradiance)

        // we do this to make sure we don't recompile the material multiple times
        let tmpDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r32Float, width: 1, height: 1, mipmapped: false)
        let tmpTexture = device.makeTexture(descriptor: tmpDesc)
        material.setTexture(tmpTexture, type: .brdf)
        material.setTexture(tmpTexture, type: .baseColor)
        material.setTexture(tmpTexture, type: .ambientOcclusion)
        material.setTexture(tmpTexture, type: .metallic)
        material.setTexture(tmpTexture, type: .normal)
        material.setTexture(tmpTexture, type: .roughness)

        let customVertexDescriptor = CustomModelIOVertexDescriptor()

        let asset = MDLAsset(
            url: modelsURL.appendingPathComponent("Suzanne").appendingPathComponent("Suzanne.obj"),
            vertexDescriptor: customVertexDescriptor,
            bufferAllocator: MTKMeshBufferAllocator(device: device)
        )

        let object0 = asset.object(at: 0)
        let geo = Geometry()

        if let objMesh = object0 as? MDLMesh {
            objMesh.addNormals(withAttributeNamed: MDLVertexAttributeNormal, creaseThreshold: 0.0)
            objMesh.addTangentBasis(
                forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                tangentAttributeNamed: MDLVertexAttributeTangent,
                bitangentAttributeNamed: MDLVertexAttributeBitangent
            )

            let vertexData = objMesh.vertexBuffers[0].map().bytes.bindMemory(to: Vertex.self, capacity: objMesh.vertexCount)
            geo.vertexData = Array(UnsafeBufferPointer(start: vertexData, count: objMesh.vertexCount))

            if let firstBuffer = objMesh.vertexBuffers.first as? MTKMeshBuffer {
                geo.setBuffer(firstBuffer.buffer, type: .Vertices)
                firstBuffer.buffer.label = "Vertices"
            }

            if let secondBuffer = objMesh.vertexBuffers[1] as? MTKMeshBuffer {
                geo.setBuffer(secondBuffer.buffer, type: .Generics)
                secondBuffer.buffer.label = "Generics"
            }

            guard let submeshes = objMesh.submeshes, let first = submeshes.firstObject, let sub: MDLSubmesh = first as? MDLSubmesh else { return }
            let indexDataPtr = sub.indexBuffer(asIndexType: .uInt32).map().bytes.bindMemory(to: UInt32.self, capacity: sub.indexCount)
            let indexData = Array(UnsafeBufferPointer(start: indexDataPtr, count: sub.indexCount))
            geo.indexData = indexData
            geo.indexBuffer = (sub.indexBuffer as! MTKMeshBuffer).buffer
        }

        if let descriptor = MTKMetalVertexDescriptorFromModelIO(customVertexDescriptor) {
            geo.vertexDescriptor = descriptor
        }

        let model = Mesh(geometry: geo, material: material)
        model.label = "Suzanne Mesh"
        model.scale = .init(repeating: 0.25)

        let modelBounds = model.localBounds
        model.position.y += modelBounds.size.y * 0.5 + 0.05

        add(model)
    }

    func setupTextures() async {
        Task {
            guard let device = MTLCreateSystemDefaultDevice() else { return }
            let baseURL = modelsURL.appendingPathComponent("Suzanne")
            let maps: [PBRTextureIndex: URL] = [
                .baseColor: baseURL.appendingPathComponent("albedo.png"),
                .ambientOcclusion: baseURL.appendingPathComponent("ao.png"),
                .metallic: baseURL.appendingPathComponent("metallic.png"),
                .normal: baseURL.appendingPathComponent("normal.png"),
                .roughness: baseURL.appendingPathComponent("roughness.png"),
            ]

            let types = maps.compactMap { $0.key }
            let urls = maps.compactMap { $0.value }

            let loader = MTKTextureLoader(device: device)
            do {
                let options: [MTKTextureLoader.Option: Any] = [
                    MTKTextureLoader.Option.SRGB: false,
                    MTKTextureLoader.Option.origin: MTKTextureLoader.Origin.flippedVertically,
                    MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue),
                ]
                let textures = try await loader.newTextures(URLs: urls, options: options)

                DispatchQueue.main.async {
                    for (index, texture) in textures.enumerated() {
                        texture.label = types[index].textureName
                        self.material.setTexture(texture, type: types[index])
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

class ARPBRRenderer: BaseRenderer, MaterialDelegate {
    class PostMaterial: SourceMaterial {
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
        public var depthMaskTexture: MTLTexture?

        override func bind(_ renderEncoder: MTLRenderCommandEncoder, shadow: Bool) {
            super.bind(renderEncoder, shadow: shadow)
            renderEncoder.setFragmentTexture(backgroundTexture, index: FragmentTextureIndex.Custom0.rawValue)
            renderEncoder.setFragmentTexture(contentTexture, index: FragmentTextureIndex.Custom1.rawValue)
            renderEncoder.setFragmentTexture(depthMaskTexture, index: FragmentTextureIndex.Custom2.rawValue)
            renderEncoder.setFragmentTexture(grainTexture, index: FragmentTextureIndex.Custom3.rawValue)
        }
    }

    override var paramKeys: [String] {
        return ["Material"]
    }

    override var params: [String: ParameterGroup?] {
        return [
            "Material": model.material.parameters,
        ]
    }

    var session = ARSession()

    var shadowPlaneMesh = {
        let material = BasicTextureMaterial(texture: nil, flipped: false)
        material.depthBias = DepthBias(bias: 100.0, slope: 100.0, clamp: 100.0)
        let mesh = Mesh(geometry: PlaneGeometry(size: 1.0, plane: .zx), material: material)
        mesh.label = "Shadow Catcher"
        return mesh
    }()

    fileprivate lazy var modelContainer = ARObject(
        label: "Model Container",
        children: [shadowPlaneMesh, model],
        session: session
    )

    var model = Model()

    lazy var shadowRenderer = ObjectShadowRenderer(
        context: context,
        object: model,
        container: modelContainer,
        scene: scene,
        catcher: shadowPlaneMesh,
        blurRadius: 8.0,
        near: 0.01,
        far: 1.0,
        color: [0.0, 0.0, 0.0, 0.9]
    )

    fileprivate lazy var scene = ARScene("Scene", [modelContainer], session: session)
    lazy var context = Context(device, sampleCount, colorPixelFormat, .depth32Float)
    lazy var camera = ARPerspectiveCamera(session: session, mtkView: mtkView, near: 0.01, far: 100.0)
    lazy var renderer = Satin.Renderer(context: context)

    var _updateTextures = true
    var depthMaskTexture: MTLTexture?
    var scaledDepthMaskTexture: MTLTexture?

    var blurFilter: MPSImageGaussianBlur!
    var scaleFilter: MPSImageBilinearScale!
    var backgroundRenderer: ARBackgroundDepthRenderer!

    lazy var postMaterial: PostMaterial = {
        let material = PostMaterial(pipelinesURL: pipelinesURL)
        material.depthWriteEnabled = false
        material.blending = .alpha
        return material
    }()

    lazy var depthMaskGenerator = ARDepthMaskGenerator(device: device, width: Int(mtkView.drawableSize.width), height: Int(mtkView.drawableSize.height))
    lazy var postProcessor = PostProcessor(context: Context(device, 1, colorPixelFormat), material: postMaterial)

    lazy var startTime = getTime()

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .invalid
        metalKitView.preferredFramesPerSecond = 60
        metalKitView.colorPixelFormat = .bgra8Unorm_srgb
    }

    override init() {
        super.init()

        let config = ARWorldTrackingConfiguration()
        config.environmentTexturing = .manual
        config.wantsHDREnvironmentTextures = true
        config.planeDetection = [.horizontal]
        config.frameSemantics = [.sceneDepth]
        config.sceneReconstruction = .mesh
        session.run(config)
    }

    override func setup() {
        model.material.delegate = self

        scaleFilter = MPSImageBilinearScale(device: device)
        blurFilter = MPSImageGaussianBlur(device: device, sigma: 8)
        blurFilter.edgeMode = .clamp

        renderer.setClearColor(.zero)
        renderer.depthStoreAction = .store

        backgroundRenderer = ARBackgroundDepthRenderer(
            context: context,
            session: session,
            sessionPublisher: ARSessionPublisher(session: session),
            mtkView: mtkView,
            near: camera.near,
            far: camera.far,
            upscaleDepth: false,
            usePlaneDepth: false,
            useMeshDepth: false
        )
    }

    override func update() {
        let time = getTime() - startTime
        model.orientation = simd_quatf(angle: Float(time), axis: Satin.worldUpDirection)

        if _updateTextures {
            scaledDepthMaskTexture = createTexture("Scaled Depth Mask Texture", .r16Float, 3)
            _updateTextures = false
        }
    }

    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }

        backgroundRenderer.draw(
            renderPassDescriptor: MTLRenderPassDescriptor(),
            commandBuffer: commandBuffer
        )

        if modelContainer.visible {
            shadowRenderer.update(commandBuffer: commandBuffer)
        }

        renderer.draw(
            renderPassDescriptor: MTLRenderPassDescriptor(),
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera
        )

        // Compare depth

        if let realDepthTexture = backgroundRenderer.depthTexture,
           let virtualDepthTexture = renderer.depthTexture
        {
            depthMaskTexture = depthMaskGenerator.encode(
                commandBuffer: commandBuffer,
                realDepthTexture: realDepthTexture,
                virtualDepthTexture: virtualDepthTexture
            )

            if let depthMaskTexture = depthMaskTexture, var scaledDepthMaskTexture = scaledDepthMaskTexture {
                scaleFilter.encode(
                    commandBuffer: commandBuffer,
                    sourceTexture: depthMaskTexture,
                    destinationTexture: scaledDepthMaskTexture
                )

                blurFilter.encode(
                    commandBuffer: commandBuffer,
                    inPlaceTexture: &scaledDepthMaskTexture
                )
            }
        }

        // Post
        postMaterial.backgroundTexture = backgroundRenderer.colorTexture
        postMaterial.contentTexture = renderer.colorTexture
        postMaterial.depthMaskTexture = scaledDepthMaskTexture
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
        postProcessor.resize(size)
        depthMaskGenerator.resize(size)
    }

    override func cleanup() {
        session.pause()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: mtkView)
        let coordinate = normalizePoint(location, mtkView.frame.size)

        let ray = Ray(camera: camera, coordinate: coordinate)
        let query = ARRaycastQuery(origin: ray.origin, direction: ray.direction, allowing: .estimatedPlane, alignment: .horizontal)

        if let result = session.raycast(query).first {
            let anchor = AREnvironmentProbeAnchor(transform: result.worldTransform, extent: .init(repeating: 1.0))
            session.add(anchor: anchor)

            if let existingAnchor = modelContainer.anchor {
                session.remove(anchor: existingAnchor)
            }

            modelContainer.anchor = anchor
        }
    }

    private func normalizePoint(_ point: CGPoint, _ size: CGSize) -> simd_float2 {
#if os(macOS)
        return 2.0 * simd_make_float2(Float(point.x / size.width), Float(point.y / size.height)) - 1.0
#else
        return 2.0 * simd_make_float2(Float(point.x / size.width), 1.0 - Float(point.y / size.height)) - 1.0
#endif
    }

    func updated(material: Material) {
        print("Material Updated: \(material.label)")
        _updateInspector = true
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
