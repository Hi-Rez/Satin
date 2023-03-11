//
//  SubmeshRenderer.swift
//  Example
//
//  Created by Reza Ali on 3/10/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin

class SubmeshRenderer: BaseRenderer {
    var assetsURL: URL { Bundle.main.resourceURL!.appendingPathComponent("Assets") }
    var sharedAssetsURL: URL { assetsURL.appendingPathComponent("Shared") }
    var rendererAssetsURL: URL { assetsURL.appendingPathComponent(String(describing: type(of: self))) }
    var modelsURL: URL { sharedAssetsURL.appendingPathComponent("Models") }
    var texturesURL: URL { sharedAssetsURL.appendingPathComponent("Textures") }

    var scene = Object("Scene")
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var camera: PerspectiveCamera = {
        let pos = simd_make_float3(125.0, 125.0, 125.0)
        camera  = PerspectiveCamera(position: pos, near: 0.01, far: 1000.0, fov: 45)
        camera.orientation = simd_quatf(from: [0, 0, 1], to: simd_normalize(pos))

        let forward = simd_normalize(camera.forwardDirection)
        let worldUp = Satin.worldUpDirection
        let right = -simd_normalize(simd_cross(forward, worldUp))
        let angle = acos(simd_dot(simd_normalize(camera.rightDirection), right))

        camera.orientation = simd_quatf(angle: angle, axis: forward) * camera.orientation
        return camera
    }()
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: mtkView)
    lazy var renderer = Satin.Renderer(context: context)

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
    }

    // Textures
    var hdriTexture: MTLTexture?
    var cubemapTexture: MTLTexture?
    var diffuseIBLTexture: MTLTexture?
    var specularIBLTexture: MTLTexture?
    var brdfTexture: MTLTexture?

    override func setup() {
//        DispatchQueue.global(qos: .userInitiated).async {
        loadHdri()
        setupCubemap()
        setupDiffuseIBL()
        setupSpecularIBL()
        setupBRDF()
//        }

        let model = loadUSD(url: modelsURL.appendingPathComponent("chair_swan.usdz"))
        let sceneBounds = scene.worldBounds

        model.position.y -= sceneBounds.size.y * 0.5

        let light = DirectionalLight(color: .one, intensity: 2.0)
        light.position = .init(repeating: 5.0)
        light.lookAt(scene.worldBounds.center)
        scene.add(light)
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

    func loadUSD(url: URL) -> Object {
        let asset = MDLAsset(
            url: url,
            vertexDescriptor: SatinModelIOVertexDescriptor,
            bufferAllocator: MTKMeshBufferAllocator(device: context.device)
        )
        asset.loadTextures()

        let model = Object("Model")
        let object = asset.object(at: 0)
        model.label = object.name
        if let transform = object.transform {
            model.localMatrix = transform.matrix
        }
        loadChildren(model, object.children.objects)
        scene.add(model)

        return model
    }

    lazy var textureLoader = MTKTextureLoader(device: device)

    func createPhysicalMaterial(from mdlMaterial: MDLMaterial) -> Material {
        let material = PhysicalMaterial(material: mdlMaterial, textureLoader: textureLoader)
        material.setTexture(specularIBLTexture, type: .reflection)
        material.setTexture(diffuseIBLTexture, type: .irradiance)
        material.setTexture(brdfTexture, type: .brdf)
        return material
    }

    func loadChildren(_ parent: Object, _ children: [MDLObject]) {
        for child in children {
            if let mdlMesh = child as? MDLMesh {
                let geometry = Geometry()
                let mesh = Mesh(geometry: geometry, material: nil)
                mesh.label = child.name
                parent.add(mesh)

                let vertexData = mdlMesh.vertexBuffers[0].map().bytes.bindMemory(to: Vertex.self, capacity: mdlMesh.vertexCount)
                geometry.vertexData = Array(UnsafeBufferPointer(start: vertexData, count: mdlMesh.vertexCount))
                geometry.vertexBuffer = (mdlMesh.vertexBuffers[0] as! MTKMeshBuffer).buffer

                if let mdlSubMeshes = mdlMesh.submeshes {
                    let mdlSubMeshesCount = mdlSubMeshes.count
                    for index in 0 ..< mdlSubMeshesCount {
                        let mdlSubmesh = mdlSubMeshes[index] as! MDLSubmesh
                        if mdlSubmesh.geometryType == .triangles, let mdlMaterial = mdlSubmesh.material {
                            let indexCount = mdlSubmesh.indexCount
                            let indexDataPtr = mdlSubmesh.indexBuffer(asIndexType: .uInt32).map().bytes.bindMemory(to: UInt32.self, capacity: indexCount)
                            let indexData = Array(UnsafeBufferPointer(start: indexDataPtr, count: indexCount))
                            let submesh = Submesh(
                                indexData: indexData,
                                indexBuffer: (mdlSubmesh.indexBuffer as! MTKMeshBuffer).buffer,
                                material: createPhysicalMaterial(from: mdlMaterial)
                            )
                            submesh.label = mdlSubmesh.name
                            mesh.addSubmesh(submesh)
                        }
                    }
                }

                if let transform = mdlMesh.transform {
                    mesh.localMatrix = transform.matrix
                }

                loadChildren(mesh, child.children.objects)
            } else {
                let object = Object()
                object.label = child.name
                parent.add(object)
                loadChildren(object, child.children.objects)
            }
        }
    }

    // MARK: - PBR Env

    func loadHdri() {
        let filename = "brown_photostudio_02_2k.hdr"
        hdriTexture = loadHDR(device, texturesURL.appendingPathComponent(filename))
    }

    func setupCubemap() {
        if let hdriTexture = hdriTexture, let commandBuffer = commandQueue.makeCommandBuffer(), let texture = createCubemapTexture(pixelFormat: .rgba16Float, size: 512, mipmapped: true) {
            CubemapGenerator(device: device)
                .encode(commandBuffer: commandBuffer, sourceTexture: hdriTexture, destinationTexture: texture)
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            cubemapTexture = texture
        }
    }

    func setupDiffuseIBL() {
        if let cubemapTexture = cubemapTexture,
           let commandBuffer = commandQueue.makeCommandBuffer(),
           let texture = createCubemapTexture(pixelFormat: .rgba16Float, size: 64, mipmapped: false)
        {
            DiffuseIBLGenerator(device: device)
                .encode(commandBuffer: commandBuffer, sourceTexture: cubemapTexture, destinationTexture: texture)

            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()

            diffuseIBLTexture = texture
            texture.label = "Diffuse IBL"
        }
    }

    func setupSpecularIBL() {
        if let cubemapTexture = cubemapTexture,
           let commandBuffer = commandQueue.makeCommandBuffer(),
           let texture = createCubemapTexture(pixelFormat: .rgba16Float, size: 512, mipmapped: true)
        {
            SpecularIBLGenerator(device: device)
                .encode(commandBuffer: commandBuffer, sourceTexture: cubemapTexture, destinationTexture: texture)

            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()

            specularIBLTexture = texture
            texture.label = "Specular IBL"
        }
    }

    func setupBRDF() {
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            brdfTexture = BrdfGenerator(device: device, size: 512)
                .encode(commandBuffer: commandBuffer)

            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }

    func createCubemapTexture(pixelFormat: MTLPixelFormat, size: Int, mipmapped: Bool) -> MTLTexture?
    {
        let desc = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: pixelFormat, size: size, mipmapped: mipmapped)
        let texture = device.makeTexture(descriptor: desc)
        texture?.label = "Cubemap"
        return texture
    }
}
