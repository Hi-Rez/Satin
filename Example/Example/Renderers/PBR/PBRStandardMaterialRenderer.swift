//
//  StandardMaterialRenderer.swift
//  Satin
//
//  Created by Reza Ali on 11/11/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//
//  Cube Map Texture from: https://hdrihaven.com/hdri/
//

import Metal
import MetalKit

import Forge
import Satin

class PBRStandardMaterialRenderer: BaseRenderer {

    override var texturesURL: URL { sharedAssetsURL.appendingPathComponent("Textures") }
    override var modelsURL: URL { sharedAssetsURL.appendingPathComponent("Models") }

    lazy var scene = Scene("Scene", [skybox])
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var camera = PerspectiveCamera(position: [0.0, 0.0, 6.0], near: 0.01, far: 1000.0)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: mtkView)
    lazy var renderer: Satin.Renderer = .init(context: context)

    lazy var standardMaterial = StandardMaterial()

    lazy var skyboxMaterial = SkyboxMaterial()
    lazy var skybox: Mesh = {
        let mesh = Mesh(geometry: SkyboxGeometry(size: 250), material: skyboxMaterial)
        mesh.label = "Skybox"
        return mesh
    }()

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
        metalKitView.colorPixelFormat = .bgra8Unorm
    }

    override func setup() {
        loadHdri()
        setupTextures()
        setupLights()
        setupScene()
    }

    deinit {
        cameraController.disable()
    }

    override func update() {
        cameraController.update()
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

    // MARK: - Lights

    func setupLights() {
        let positions = [
            simd_make_float3(0.0, 0.0, -1.0),
            simd_make_float3(0.0, -1.0, 0.0),
            simd_make_float3(0.0, 1.0, 0.0),
            simd_make_float3(0.0, 0.0, 1.0),
        ]

        let ups = [
            Satin.worldUpDirection,
            Satin.worldRightDirection,
            Satin.worldRightDirection,
            Satin.worldUpDirection,
        ]

        for (index, position) in positions.enumerated() {
            let light = DirectionalLight(color: .one, intensity: 0.5)
            light.position = position
            light.lookAt(target: .zero, up: ups[index])
            scene.add(light)
        }
    }

    // MARK: - Scene

    func setupScene() {
        let customVertexDescriptor = CustomModelIOVertexDescriptor()

        let asset = MDLAsset(
            url: modelsURL.appendingPathComponent("Suzanne").appendingPathComponent("Suzanne.obj"),
            vertexDescriptor: customVertexDescriptor,
            bufferAllocator: MTKMeshBufferAllocator(device: context.device)
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
            standardMaterial.vertexDescriptor = descriptor
        }

        let model = Mesh(geometry: geo, material: standardMaterial)
        model.label = "Suzanne"

        scene.add(model)
    }

    // MARK: - Textures

    func setupTextures() {
        let baseURL = modelsURL.appendingPathComponent("Suzanne")
        let maps: [PBRTextureIndex: URL] = [
            .baseColor: baseURL.appendingPathComponent("albedo.png"),
            .ambientOcclusion: baseURL.appendingPathComponent("ao.png"),
            .metallic: baseURL.appendingPathComponent("metallic.png"),
            .normal: baseURL.appendingPathComponent("normal.png"),
            .roughness: baseURL.appendingPathComponent("roughness.png"),
        ]

        let loader = MTKTextureLoader(device: device)
        do {
            for (type, url) in maps {
                let texture = try loader.newTexture(URL: url, options: [
                    MTKTextureLoader.Option.SRGB: false,
                    MTKTextureLoader.Option.origin: MTKTextureLoader.Origin.flippedVertically,
                    MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue),
                ])
                standardMaterial.setTexture(texture, type: type)
            }
        } catch {
            print(error.localizedDescription)
        }
    }

    // MARK: - Environment Textures

    func loadHdri() {
        let filename = "brown_photostudio_02_2k.hdr"
        if let hdr = loadHDR(device: device, url: texturesURL.appendingPathComponent(filename)) {
            scene.setEnvironment(texture: hdr)
        }
    }

    // MARK: - Vertex Generics

    struct VertexGenerics {
        var tangent: simd_float3
        var bitangent: simd_float3
    }

    func CustomModelIOVertexDescriptor() -> MDLVertexDescriptor {
        let descriptor = MDLVertexDescriptor()

        var offset = 0
        descriptor.attributes[VertexAttribute.Position.rawValue] = MDLVertexAttribute(
            name: MDLVertexAttributePosition,
            format: .float4,
            offset: offset,
            bufferIndex: VertexBufferIndex.Vertices.rawValue
        )
        offset += MemoryLayout<Float>.size * 4

        descriptor.attributes[VertexAttribute.Normal.rawValue] = MDLVertexAttribute(
            name: MDLVertexAttributeNormal,
            format: .float3,
            offset: offset,
            bufferIndex: VertexBufferIndex.Vertices.rawValue
        )
        offset += MemoryLayout<Float>.size * 4

        descriptor.attributes[VertexAttribute.Texcoord.rawValue] = MDLVertexAttribute(
            name: MDLVertexAttributeTextureCoordinate,
            format: .float2,
            offset: offset,
            bufferIndex: VertexBufferIndex.Vertices.rawValue
        )

        descriptor.layouts[VertexBufferIndex.Vertices.rawValue] = MDLVertexBufferLayout(stride: MemoryLayout<Vertex>.stride)

        offset = 0

        descriptor.attributes[VertexAttribute.Tangent.rawValue] = MDLVertexAttribute(
            name: MDLVertexAttributeTangent,
            format: .float3,
            offset: offset,
            bufferIndex: VertexBufferIndex.Generics.rawValue
        )

        offset += MemoryLayout<Float>.size * 4

        descriptor.attributes[VertexAttribute.Bitangent.rawValue] = MDLVertexAttribute(
            name: MDLVertexAttributeBitangent,
            format: .float3,
            offset: offset,
            bufferIndex: VertexBufferIndex.Generics.rawValue
        )

        descriptor.layouts[VertexBufferIndex.Generics.rawValue] = MDLVertexBufferLayout(stride: MemoryLayout<VertexGenerics>.stride)

        return descriptor
    }
}
