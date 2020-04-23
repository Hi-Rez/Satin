//
//  Mesh.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal
import simd

open class Mesh: Object, GeometryDelegate {
    open override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("Mesh", forKey: .type)
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    let alignedUniformsSize = ((MemoryLayout<VertexUniforms>.size + 255) / 256) * 256
    
    public var triangleFillMode: MTLTriangleFillMode = .fill
    public var cullMode: MTLCullMode = .back
    
    public var instanceCount: Int = 1
    
    public var uniformBufferIndex: Int = 0
    public var uniformBufferOffset: Int = 0
    public var vertexUniforms: UnsafeMutablePointer<VertexUniforms>!
    public var vertexUniformsBuffer: MTLBuffer!
    
    public var depthStencilState: MTLDepthStencilState?
    public var depthCompareFunction: MTLCompareFunction = .less {
        didSet {
            if depthCompareFunction != oldValue {
                setupDepthStencilState()
            }
        }
    }
    
    public var depthWriteEnabled: Bool = true {
        didSet {
            if depthWriteEnabled != oldValue {
                setupDepthStencilState()
            }
        }
    }
    
    public var preDraw: ((_ renderEncoder: MTLRenderCommandEncoder) -> ())?
    public var postDraw: ((_ renderEncoder: MTLRenderCommandEncoder) -> ())?
    
    public var geometry: Geometry = Geometry() {
        didSet {
            geometry.delegate = self
            setupVertexBuffer()
            setupIndexBuffer()
        }
    }
    
    public var material: Material? {
        didSet {
            setupMaterial()
        }
    }
    
    public var vertexBuffer: MTLBuffer?
    public var indexBuffer: MTLBuffer?
    
    public init(geometry: Geometry, material: Material?) {
        super.init()
        self.geometry = geometry
        self.material = material
    }
    
    public required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    override func setup() {
        setupVertexBuffer()
        setupIndexBuffer()
        setupUniformBuffer()
        setupDepthStencilState()
        setupMaterial()
    }
    
    func setupVertexBuffer() {
        guard let context = self.context else { return }
        let device = context.device
        if !geometry.vertexData.isEmpty {
            let stride = MemoryLayout<Vertex>.stride
            let verticesSize = geometry.vertexData.count * stride
            vertexBuffer = device.makeBuffer(bytes: geometry.vertexData, length: verticesSize, options: [])
            vertexBuffer?.label = "Vertices"
        }
        else {
            vertexBuffer = nil
        }
    }
    
    func setupIndexBuffer() {
        guard let context = self.context else { return }
        let device = context.device
        if !geometry.indexData.isEmpty {
            let indicesSize = geometry.indexData.count * MemoryLayout.size(ofValue: geometry.indexData[0])
            indexBuffer = device.makeBuffer(bytes: geometry.indexData, length: indicesSize, options: [])
            indexBuffer?.label = "Indices"
        }
        else {
            indexBuffer = nil
        }
    }
    
    func setupUniformBuffer() {
        guard let context = self.context else { return }
        let device = context.device
        let uniformBufferSize = alignedUniformsSize * Satin.maxBuffersInFlight
        guard let buffer = device.makeBuffer(length: uniformBufferSize, options: [MTLResourceOptions.storageModeShared]) else { return }
        vertexUniformsBuffer = buffer
        vertexUniformsBuffer.label = "Vertex Uniforms"
        vertexUniforms = UnsafeMutableRawPointer(vertexUniformsBuffer.contents()).bindMemory(to: VertexUniforms.self, capacity: 1)
    }
    
    func setupDepthStencilState() {
        guard let context = self.context, context.depthPixelFormat != .invalid else { return }
        let device = context.device
        let depthStateDesciptor = MTLDepthStencilDescriptor()
        depthStateDesciptor.depthCompareFunction = depthCompareFunction
        depthStateDesciptor.isDepthWriteEnabled = depthWriteEnabled
        guard let state = device.makeDepthStencilState(descriptor: depthStateDesciptor) else { return }
        depthStencilState = state
    }
    
    func setupMaterial() {
        guard let context = self.context, let material = self.material else { return }
        material.context = context
    }
    
    func updateUniforms(camera: Camera) {
        if vertexUniforms != nil {
            vertexUniforms[0].modelMatrix = worldMatrix
            vertexUniforms[0].viewMatrix = camera.viewMatrix
            vertexUniforms[0].modelViewMatrix = simd_mul(vertexUniforms[0].viewMatrix, vertexUniforms[0].modelMatrix)
            vertexUniforms[0].projectionMatrix = camera.projectionMatrix
            let n = vertexUniforms[0].modelMatrix.inverse.transpose
            let c0 = n.columns.0
            let c1 = n.columns.1
            let c2 = n.columns.2
            vertexUniforms[0].normalMatrix = simd_matrix(simd_make_float3(c0.x, c0.y, c0.z), simd_make_float3(c1.x, c1.y, c1.z), simd_make_float3(c2.x, c2.y, c2.z))
            vertexUniforms[0].worldCameraPosition = camera.worldPosition
            vertexUniforms[0].worldCameraViewDirection = camera.viewDirection
        }
    }
    
    func updateUniformsBuffer() {
        if vertexUniformsBuffer != nil {
            uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight
            uniformBufferOffset = alignedUniformsSize * uniformBufferIndex
            vertexUniforms = UnsafeMutableRawPointer(vertexUniformsBuffer.contents() + uniformBufferOffset).bindMemory(to: VertexUniforms.self, capacity: 1)
        }
    }
    
    public override func update() {
        material?.update()
        updateUniformsBuffer()
        super.update()
    }
    
    public func update(camera: Camera) {
        updateUniforms(camera: camera)
    }
    
    public func draw(renderEncoder: MTLRenderCommandEncoder) {
        draw(renderEncoder: renderEncoder, instanceCount: instanceCount)
    }
    
    public func draw(renderEncoder: MTLRenderCommandEncoder, instanceCount: Int) {
        guard let vertexBuffer = vertexBuffer else { return }
        
        preDraw?(renderEncoder)
        
        if let depthStencilState = self.depthStencilState {
            renderEncoder.setDepthStencilState(depthStencilState)
        }
        renderEncoder.setFrontFacing(geometry.windingOrder)
        renderEncoder.setCullMode(cullMode)
        renderEncoder.setTriangleFillMode(triangleFillMode)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: VertexBufferIndex.Vertices.rawValue)
        renderEncoder.setVertexBuffer(vertexUniformsBuffer, offset: uniformBufferOffset, index: VertexBufferIndex.VertexUniforms.rawValue)
        
        if let indexBuffer = indexBuffer {
            renderEncoder.drawIndexedPrimitives(
                type: geometry.primitiveType,
                indexCount: geometry.indexData.count,
                indexType: geometry.indexType,
                indexBuffer: indexBuffer,
                indexBufferOffset: 0,
                instanceCount: instanceCount
            )
        }
        else {
            renderEncoder.drawPrimitives(
                type: geometry.primitiveType,
                vertexStart: 0,
                vertexCount: geometry.vertexData.count,
                instanceCount: instanceCount
            )
        }
        
        postDraw?(renderEncoder)
    }
    
    deinit {
        vertexBuffer = nil
        indexBuffer = nil
    }
    
    // MARK: - GeometryDelegate Conformance
    
    func indexDataUpdated() {
        setupIndexBuffer()
    }
    
    func vertexDataUpdated() {
        setupVertexBuffer()
    }
}
