//
//  Renderer.swift
//  LiveCode-macOS
//
//  Created by Reza Ali on 6/1/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin

struct CustomVertex {
    var position: simd_float4
    var normal: simd_float3
    var uv: simd_float2
    var tangent: simd_float3
}

func CustomModelIOVertexDescriptor() -> MDLVertexDescriptor {
    let descriptor = MDLVertexDescriptor()
    
    var offset = 0
    descriptor.attributes[0] = MDLVertexAttribute(
        name: MDLVertexAttributePosition,
        format: .float4,
        offset: offset,
        bufferIndex: 0
    )
    offset += MemoryLayout<Float>.size * 4
    
    descriptor.attributes[1] = MDLVertexAttribute(
        name: MDLVertexAttributeNormal,
        format: .float3,
        offset: offset,
        bufferIndex: 0
    )
    offset += MemoryLayout<Float>.size * 4
    
    descriptor.attributes[2] = MDLVertexAttribute(
        name: MDLVertexAttributeTextureCoordinate,
        format: .float2,
        offset: offset,
        bufferIndex: 0
    )
    offset += MemoryLayout<Float>.size * 2
    
    descriptor.attributes[3] = MDLVertexAttribute(
        name: MDLVertexAttributeTangent,
        format: .float3,
        offset: offset,
        bufferIndex: 0
    )
    
    descriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<CustomVertex>.stride)
    
    return descriptor
}

func CustomVertexDescriptor() -> MTLVertexDescriptor {
    // position
    let vertexDescriptor = MTLVertexDescriptor()
    var offset = 0
    
    vertexDescriptor.attributes[0].format = MTLVertexFormat.float4
    vertexDescriptor.attributes[0].offset = offset
    vertexDescriptor.attributes[0].bufferIndex = 0
    offset += MemoryLayout<Float>.size * 4
    
    // normal
    vertexDescriptor.attributes[1].format = MTLVertexFormat.float3
    vertexDescriptor.attributes[1].offset = offset
    vertexDescriptor.attributes[1].bufferIndex = 0
    offset += MemoryLayout<Float>.size * 4
    
    // uv
    vertexDescriptor.attributes[2].format = MTLVertexFormat.float2
    vertexDescriptor.attributes[2].offset = offset
    vertexDescriptor.attributes[2].bufferIndex = 0
    offset += MemoryLayout<Float>.size * 2
    
    // tangent
    vertexDescriptor.attributes[3].format = MTLVertexFormat.float3
    vertexDescriptor.attributes[3].offset = offset
    vertexDescriptor.attributes[3].bufferIndex = 0
    offset += MemoryLayout<Float>.size * 4
    
    vertexDescriptor.layouts[0].stride = MemoryLayout<CustomVertex>.stride
    vertexDescriptor.layouts[0].stepRate = 1
    vertexDescriptor.layouts[0].stepFunction = .perVertex
    
    return vertexDescriptor
}

class LoadedMesh: Object, Renderable {
    public var uniformBufferIndex: Int = 0
    public var uniformBufferOffset: Int = 0
    
    var vertexUniformParameters = createVertexUniformParameters()
    var vertexUniforms: UniformBuffer!
    
    var url: URL?
    var material: Material?
    
    var indexBuffer: MTLBuffer?
    var vertexBuffer: MTLBuffer?
    var indexCount: Int = 0
    var vertexCount: Int = 0
    
    
    init(url: URL, material: Material) {
        self.url = url
        self.material = material
        super.init("LoadedMesh")
    }
    
    override func setup() {
        setupUniformBuffer()
        setupModel()
        setupMaterial()
    }
    
    func setupModel() {
        guard let url = url, let context = context else { return }
        let customVertexDescriptor = CustomModelIOVertexDescriptor()
        
        let asset = MDLAsset(url: url, vertexDescriptor: customVertexDescriptor, bufferAllocator: MTKMeshBufferAllocator(device: context.device))
        
        let object0 = asset.object(at: 0)
        if let objMesh = object0 as? MDLMesh {
            objMesh.addNormals(withAttributeNamed: MDLVertexAttributeNormal, creaseThreshold: 0.0)
            objMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate, normalAttributeNamed: MDLVertexAttributeNormal, tangentAttributeNamed: MDLVertexAttributeTangent)
            
            if let meshBuffer = objMesh.vertexBuffers.first as? MTKMeshBuffer {
                vertexBuffer = meshBuffer.buffer
                vertexCount = objMesh.vertexCount
            }
            
            if let submeshes = objMesh.submeshes, let first = submeshes.firstObject, let sub: MDLSubmesh = first as? MDLSubmesh {
                indexBuffer = (sub.indexBuffer as! MTKMeshBuffer).buffer
                indexCount = sub.indexCount
            }
        }
    }
    
    func setupMaterial() {
        guard let context = context, let material = material else { return }
        material.context = context
    }
    
    func setupUniformBuffer() {
        guard let context = context else { return }
        vertexUniforms = UniformBuffer(device: context.device, parameters: vertexUniformParameters)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    // MARK: - Update
    
    override func update() {
        updateUniformsBuffer()
        material?.update()
        super.update()
    }

    func update(camera: Camera, viewport: simd_float4) {
        material?.update(camera: camera)
        updateUniforms(camera: camera, viewport: viewport)
    }
    
    func updateUniforms(camera: Camera, viewport: simd_float4) {
        let mvp = simd_mul(camera.viewProjectionMatrix, worldMatrix)
        vertexUniformParameters.set("Model Matrix", worldMatrix)
        vertexUniformParameters.set("View Matrix", camera.viewMatrix)
        vertexUniformParameters.set("Model View Matrix", simd_mul(camera.viewMatrix, worldMatrix))
        vertexUniformParameters.set("Projection Matrix", camera.projectionMatrix)
        vertexUniformParameters.set("Model View Projection Matrix", mvp)
        vertexUniformParameters.set("Inverse Model View Projection Matrix", simd_inverse(mvp))
        vertexUniformParameters.set("Inverse View Matrix", camera.worldMatrix)
        vertexUniformParameters.set("Normal Matrix", normalMatrix)
        vertexUniformParameters.set("Viewport", viewport)
        vertexUniformParameters.set("World Camera Position", camera.worldPosition)
        vertexUniformParameters.set("World Camera View Direction", camera.viewDirection)
    }
    
    func updateUniformsBuffer() {
        vertexUniforms.update()
    }
    
    // MARK: - Draw
    
    open func draw(renderEncoder: MTLRenderCommandEncoder) {
        draw(renderEncoder: renderEncoder, instanceCount: 1)
    }
    
    open func draw(renderEncoder: MTLRenderCommandEncoder, instanceCount: Int) {
        guard instanceCount > 0, let vertexBuffer = vertexBuffer, let material = material, let _ = material.pipeline else { return }
        
        material.bind(renderEncoder)
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setCullMode(.back)
        renderEncoder.setTriangleFillMode(.fill)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: VertexBufferIndex.Vertices.rawValue)
        renderEncoder.setVertexBuffer(vertexUniforms.buffer, offset: vertexUniforms.offset, index: VertexBufferIndex.VertexUniforms.rawValue)
        
        if let indexBuffer = indexBuffer {
            renderEncoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: indexCount,
                indexType: .uint32,
                indexBuffer: indexBuffer,
                indexBufferOffset: 0,
                instanceCount: instanceCount
            )
        } else {
            renderEncoder.drawPrimitives(
                type: .triangle,
                vertexStart: 0,
                vertexCount: vertexCount,
                instanceCount: instanceCount
            )
        }
    }
}

class Renderer: Forge.Renderer {
    class CustomMaterial: LiveMaterial {}
    
    var assetsURL: URL {
        let resourcesURL = Bundle.main.resourceURL!
        return resourcesURL.appendingPathComponent("Assets")
    }
    
    var texturesURL: URL {
        return assetsURL.appendingPathComponent("Textures")
    }
    
    var modelsURL: URL {
        return assetsURL.appendingPathComponent("Models")
    }
    
    var pipelinesURL: URL {
        return assetsURL.appendingPathComponent("Pipelines")
    }
    
    
    lazy var material: Material = {
        let material = MatCapMaterial(texture: matcapTexture)
        material.vertexDescriptor = CustomVertexDescriptor()
        return material
    }()
    
    var scene = Object()
    
    lazy var matcapTexture: MTLTexture? = {
        // from https://github.com/nidorx/matcaps
        let fileName = "8A6565_2E214D_D48A5F_ADA59C.png"
        let loader = MTKTextureLoader(device: device)
        do {
            return try loader.newTexture(URL: self.texturesURL.appendingPathComponent(fileName), options: [
                MTKTextureLoader.Option.SRGB: false,
                MTKTextureLoader.Option.origin: MTKTextureLoader.Origin.flippedVertically,
                MTKTextureLoader.Option.allocateMipmaps: true,
                MTKTextureLoader.Option.generateMipmaps: true
            ])
        }
        catch {
            print(error)
            return nil
        }
    }()
    
    lazy var context: Context = {
        Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }()
    
    lazy var camera: PerspectiveCamera = {
        let camera = PerspectiveCamera()
        camera.position = simd_make_float3(0.0, 0.0, 4.0)
        camera.near = 0.001
        camera.far = 100.0
        return camera
    }()
    
    lazy var cameraController: PerspectiveCameraController = {
        PerspectiveCameraController(camera: camera, view: mtkView)
    }()
    
    lazy var renderer: Satin.Renderer = {
        let renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
        renderer.clearColor = .init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        return renderer
    }()
    
    var loadedMesh: Object!
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
        metalKitView.colorPixelFormat = .bgra8Unorm
    }
    
    override func setup() {
        let material = CustomMaterial(pipelinesURL: pipelinesURL, vertexDescriptor: CustomVertexDescriptor())
        loadedMesh = LoadedMesh(url: modelsURL.appendingPathComponent("suzanne_high.obj"), material: material)
        scene.add(loadedMesh)
    }
    
    var frame: Float = 0.0
    override func update() {
        cameraController.update()
        loadedMesh.position = .init(0.0, 0.25 * sin(frame), 0.0)
        frame += 0.05
    }
    
    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        renderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
    }
    
    override func resize(_ size: (width: Float, height: Float)) {
        let aspect = size.width / size.height
        camera.aspect = aspect
        renderer.resize(size)
    }
}
