//
//  MeshShaderRenderer.swift
//  Example
//
//  Created by Reza Ali on 3/17/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin

class MeshShaderRenderer: BaseRenderer {
    var assetsURL: URL { Bundle.main.resourceURL!.appendingPathComponent("Assets") }
    var sharedAssetsURL: URL { assetsURL.appendingPathComponent("Shared") }
    var rendererAssetsURL: URL { assetsURL.appendingPathComponent(String(describing: type(of: self))) }
    var pipelinesURL: URL { rendererAssetsURL.appendingPathComponent("Pipelines") }

    var geometry = IcoSphereGeometry(radius: 1.0, res: 4)
    lazy var mesh = Mesh(geometry: geometry, material: BasicDiffuseMaterial(0.7))
    lazy fileprivate var meshNormals = CustomMesh(geometry: geometry, material: CustomMaterial(pipelinesURL: pipelinesURL))

    lazy var scene = Object("Scene", [mesh])
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var camera = PerspectiveCamera(position: .init(0.0, 0.0, 8.0), near: 0.01, far: 100.0, fov: 45)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: mtkView)
    lazy var renderer = Satin.Renderer(context: context)
    lazy var startTime = getTime()

    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
    }

    override func setup() {
        mesh.triangleFillMode = .lines
        mesh.add(meshNormals)

        renderer.setClearColor(.one)
        renderer.compile(scene: scene, camera: camera)
    }

    override func update() {
        meshNormals.material?.set("Time", Float(getTime() - startTime))
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
}

private class CustomShader: SourceShader {
    public var objectFunctionName = "shaderObject"
    public var meshFunctionName = "shaderMesh"

    var meshFunction: String?

    init(_ label: String,
         _ pipelineURL: URL,
         _ objectFunctionName: String? = nil,
         _ meshFunctionName: String? = nil,
         _: String? = nil)
    {
        super.init(label, pipelineURL)
        self.objectFunctionName = objectFunctionName ?? label.camelCase + "Object"
        self.meshFunctionName = meshFunctionName ?? label.camelCase + "Mesh"
    }

    required init() {
        fatalError("init() has not been implemented")
    }

    required init(label _: String, source _: String, vertexFunctionName _: String? = nil, fragmentFunctionName _: String? = nil) {
        fatalError("init(label:source:vertexFunctionName:fragmentFunctionName:) has not been implemented")
    }

    required init(_ label: String, _ pipelineURL: URL, _ vertexFunctionName: String? = nil, _ fragmentFunctionName: String? = nil) {
        super.init(label, pipelineURL, vertexFunctionName, fragmentFunctionName)
        objectFunctionName = label.camelCase + "Object"
        meshFunctionName = label.camelCase + "Mesh"
    }

    override func createPipeline(_ context: Context, _ library: MTLLibrary) throws -> MTLRenderPipelineState? {
        guard let objectFunction = library.makeFunction(name: objectFunctionName),
              let meshFunction = library.makeFunction(name: meshFunctionName),
              let fragmentFunction = library.makeFunction(name: fragmentFunctionName) else { return nil }

        if #available(macOS 13.0, iOS 16.0, *) {
            let pipelineStateDescriptor = MTLMeshRenderPipelineDescriptor()
            pipelineStateDescriptor.label = label + " Mesh"

            pipelineStateDescriptor.objectFunction = objectFunction
            pipelineStateDescriptor.meshFunction = meshFunction
            pipelineStateDescriptor.fragmentFunction = fragmentFunction

            pipelineStateDescriptor.rasterSampleCount = context.sampleCount
            pipelineStateDescriptor.colorAttachments[0].pixelFormat = context.colorPixelFormat
            pipelineStateDescriptor.depthAttachmentPixelFormat = context.depthPixelFormat
            pipelineStateDescriptor.stencilAttachmentPixelFormat = context.stencilPixelFormat

            if blending != .disabled, let colorAttachment = pipelineStateDescriptor.colorAttachments[0] {
                colorAttachment.isBlendingEnabled = true
                colorAttachment.sourceRGBBlendFactor = sourceRGBBlendFactor
                colorAttachment.sourceAlphaBlendFactor = sourceAlphaBlendFactor
                colorAttachment.destinationRGBBlendFactor = destinationRGBBlendFactor
                colorAttachment.destinationAlphaBlendFactor = destinationAlphaBlendFactor
                colorAttachment.rgbBlendOperation = rgbBlendOperation
                colorAttachment.alphaBlendOperation = alphaBlendOperation
            }

            return try context.device.makeRenderPipelineState(descriptor: pipelineStateDescriptor, options: []).0

        } else {
            fatalError("Mesh Shader's are not supported")
        }
    }
}

private class CustomMaterial: SourceMaterial {
    override func createShader() -> Shader {
        let shader = CustomShader(label, pipelineURL)
        shader.live = true
        return shader
    }

    override func bindUniforms(_ renderEncoder: MTLRenderCommandEncoder, shadow: Bool) {
        guard let uniforms = uniforms else { return }
        if #available(macOS 13.0, iOS 16.0, *) {
            renderEncoder.setObjectBuffer(uniforms.buffer, offset: uniforms.offset, index: ObjectBufferIndex.MaterialUniforms.rawValue)
            renderEncoder.setMeshBuffer(uniforms.buffer, offset: uniforms.offset, index: MeshBufferIndex.MaterialUniforms.rawValue)
        }

        if !shadow {
            renderEncoder.setFragmentBuffer(uniforms.buffer, offset: uniforms.offset, index: FragmentBufferIndex.MaterialUniforms.rawValue)
        }
    }
}

private class CustomMesh: Object, Renderable {
    var cullMode: MTLCullMode = .back
    var windingOrder: MTLWinding = .counterClockwise
    var triangleFillMode: MTLTriangleFillMode = .fill

    var renderOrder = 0
    var receiveShadow = false
    var castShadow = false

    private var vertexUniforms: VertexUniformBuffer?

    var drawable: Bool {
        guard #available(macOS 13.0, iOS 16.0, *), material?.pipeline != nil else { return false }
        return true
    }

    var material: Satin.Material? {
        didSet {
            material?.context = context
        }
    }

    var materials: [Satin.Material] {
        if let material = material {
            return [material]
        }
        return []
    }

    public required init(from _: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    var geometry: Geometry

    init(geometry: Geometry, material: Material?) {
        self.geometry = geometry
        self.material = material
        super.init("Custom Mesh")
    }

    override func setup() {
        setupGeometry()
        setupUniforms()
        setupMaterial()
    }

    func setupGeometry() {
        guard let context = context else { return }
        geometry.context = context
    }

    func setupMaterial() {
        guard let context = context, let material = material else { return }
        material.context = context
    }

    func setupUniforms() {
        guard let context = context else { return }
        vertexUniforms = VertexUniformBuffer(device: context.device)
    }

    // MARK: - Update

    override func update() {
        material?.update()
        super.update()
    }

    override func update(camera: Camera, viewport: simd_float4) {
        material?.update(camera: camera)
        vertexUniforms?.update(object: self, camera: camera, viewport: viewport)
    }

    // MARK: - Draw

    open func draw(renderEncoder: MTLRenderCommandEncoder, instanceCount: Int, shadow: Bool) {
        guard #available(macOS 13.0, iOS 16.0, *), instanceCount > 0, let vertexUniforms = vertexUniforms, let material = material else { return }

        material.bind(renderEncoder, shadow: shadow)

        renderEncoder.setFrontFacing(windingOrder)
        renderEncoder.setCullMode(cullMode)
        renderEncoder.setTriangleFillMode(triangleFillMode)

        renderEncoder.setObjectBuffer(
            geometry.vertexBuffer,
            offset: 0,
            index: ObjectBufferIndex.Vertices.rawValue
        )

        renderEncoder.setObjectBuffer(
            geometry.indexBuffer,
            offset: 0,
            index: ObjectBufferIndex.Indicies.rawValue
        )

        renderEncoder.setMeshBuffer(
            vertexUniforms.buffer,
            offset: vertexUniforms.offset,
            index: MeshBufferIndex.VertexUniforms.rawValue
        )

        let maxTotalThreadsPerMeshThreadgroup = material.pipeline!.maxTotalThreadsPerThreadgroup
        let instances = geometry.indexData.count

        renderEncoder.drawMeshThreadgroups(
            MTLSizeMake(instances, 1, 1),
            threadsPerObjectThreadgroup: MTLSizeMake(5, 1, 1),
            threadsPerMeshThreadgroup: MTLSizeMake(36, 1, 1)
        )
    }

    func draw(renderEncoder: MTLRenderCommandEncoder, shadow: Bool) {
        draw(renderEncoder: renderEncoder, instanceCount: 1, shadow: shadow)
    }
}
