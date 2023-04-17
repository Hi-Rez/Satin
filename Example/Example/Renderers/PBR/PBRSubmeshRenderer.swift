//
//  PBRSubmeshRenderer.swift
//  Example
//
//  Created by Reza Ali on 3/10/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin

class PBRSubmeshRenderer: BaseRenderer {
    override var modelsURL: URL { sharedAssetsURL.appendingPathComponent("Models") }
    override var texturesURL: URL { sharedAssetsURL.appendingPathComponent("Textures") }

    var scene = Scene("Scene", [Mesh(geometry: SkyboxGeometry(size: 250), material: SkyboxMaterial())])

    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var camera: PerspectiveCamera = {
        let pos = simd_make_float3(125.0, 125.0, 125.0)
        camera = PerspectiveCamera(position: pos, near: 0.01, far: 1000.0, fov: 45)
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

    override func setup() {
        start("Setup")

        start("Loading HDRI")
        loadHdri()
        end()

        start("Model Setup")
        let model = loadUSD(url: modelsURL.appendingPathComponent("chair_swan.usdz"))
        end()

        start("Bounds Calculation")
        let sceneBounds = scene.worldBounds
        end()

        model.position.y -= sceneBounds.size.y * 0.25

        start("Light Setup")
        let light = DirectionalLight(color: .one, intensity: 2.0)
        light.position = .init(repeating: 5.0)
        light.lookAt(scene.worldBounds.center)
        end()

        scene.add(light)
    }

    deinit {
        cameraController.disable()
    }
    
    override func update() {
        cameraController.update()
    }

    var firstRender = true
    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        if firstRender {
            start("First Render")
        }
        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera
        )
        if firstRender {
            end()
            firstRender = false
            end()
        }
    }

    override func resize(_ size: (width: Float, height: Float)) {
        camera.aspect = size.width / size.height
        renderer.resize(size)
    }

    func loadUSD(url: URL) -> Object {
        start("Loading Asset")
        let asset = MDLAsset(
            url: url,
            vertexDescriptor: SatinModelIOVertexDescriptor(),
            bufferAllocator: MTKMeshBufferAllocator(device: context.device)
        )
        end()

        start("Loading Textures")
        asset.loadTextures()
        end()

        start("Parsing Model")

        start("Creating Model")
        let model = Object("Model")
        let object = asset.object(at: 0)
        model.label = object.name
        if let transform = object.transform {
            model.localMatrix = transform.matrix
        }
        end()

        loadChildren(model, object.children.objects)

        end()

        scene.add(model)

        return model
    }

    lazy var textureLoader = MTKTextureLoader(device: device)

    func loadChildren(_ parent: Object, _ children: [MDLObject]) {
        start("Loading Children")
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
                                parent: mesh,
                                indexData: indexData,
                                indexBuffer: (mdlSubmesh.indexBuffer as! MTKMeshBuffer).buffer,
                                material: PhysicalMaterial(material: mdlMaterial, textureLoader: textureLoader)
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
        end()
    }

    // MARK: - PBR Env

    func loadHdri() {
        let filename = "brown_photostudio_02_2k.hdr"
        if let hdr = loadHDR(device: device, url: texturesURL.appendingPathComponent(filename)) {
            scene.setEnvironment(texture: hdr)
        }
    }
}
