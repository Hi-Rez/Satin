//
//  Mesh.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Combine
import Metal
import simd

// consider making a renderable protocol
// consider making a intersectable protocol

open class Mesh: Object {
    let alignedUniformsSize = ((MemoryLayout<VertexUniforms>.size + 255) / 256) * 256
    
    public var triangleFillMode: MTLTriangleFillMode = .fill
    public var cullMode: MTLCullMode = .back
    
    public var instanceCount: Int = 1
    
    public var uniformBufferIndex: Int = 0
    public var uniformBufferOffset: Int = 0
    
    public var vertexUniforms: UnsafeMutablePointer<VertexUniforms>!
    public var vertexUniformsBuffer: MTLBuffer!
    
    public var preDraw: ((_ renderEncoder: MTLRenderCommandEncoder) -> ())?
    
    public var geometry: BaseGeometry = Geometry() {
        didSet {
            setupGeometrySubscriber()
            setupGeometry()
            _localBounds.clear()
        }
    }
    
    public var material: Material? {
        didSet {
            setupMaterial()
        }
    }
    
    internal var geometrySubscriber: AnyCancellable?
    
    public var submeshes: [Submesh] = []
    
    public init(geometry: BaseGeometry, material: Material?) {
        super.init()
        self.geometry = geometry
        self.material = material
        setupGeometrySubscriber()
    }
    
    public required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    deinit {
        cleanupGeometrySubscriber()
    }
    
    override open func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("Mesh", forKey: .type)
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }

    override open func setup() {
        setupUniformBuffer()
        setupGeometry()
        setupSubmeshes()
        setupMaterial()
    }
    
    internal func setupUniformBuffer() {
        guard let context = context else { return }
        let device = context.device
        let uniformBufferSize = alignedUniformsSize * Satin.maxBuffersInFlight
        guard let buffer = device.makeBuffer(length: uniformBufferSize, options: [MTLResourceOptions.storageModeShared]) else { return }
        vertexUniformsBuffer = buffer
        vertexUniformsBuffer.label = "Vertex Uniforms"
        vertexUniforms = UnsafeMutableRawPointer(vertexUniformsBuffer.contents()).bindMemory(to: VertexUniforms.self, capacity: 1)
    }
    
    internal func setupGeometrySubscriber() {
        geometrySubscriber?.cancel()
        geometrySubscriber = geometry.$vertexData.sink { [unowned self] _ in
            self._localBounds.clear()
        }
    }
    
    internal func cleanupGeometrySubscriber() {
        geometrySubscriber?.cancel()
        geometrySubscriber = nil
    }
    
    internal func setupGeometry() {
        guard let context = context else { return }
        geometry.context = context
    }
    
    internal func setupSubmeshes() {
        guard let context = context else { return }
        for submesh in submeshes {
            submesh.context = context
        }
    }

    internal func setupMaterial() {
        guard let context = context, let material = material else { return }
        material.context = context
    }
    
    internal func updateUniforms(camera: Camera, viewport: simd_float4) {
        if vertexUniforms != nil {
            vertexUniforms[0].modelMatrix = worldMatrix
            vertexUniforms[0].viewMatrix = camera.viewMatrix
            vertexUniforms[0].modelViewMatrix = simd_mul(vertexUniforms[0].viewMatrix, vertexUniforms[0].modelMatrix)
            vertexUniforms[0].projectionMatrix = camera.projectionMatrix
            vertexUniforms[0].modelViewProjectionMatrix = simd_mul(camera.viewProjectionMatrix, vertexUniforms[0].modelMatrix)
            vertexUniforms[0].inverseModelViewProjectionMatrix = simd_inverse(vertexUniforms[0].modelViewProjectionMatrix)
            vertexUniforms[0].inverseViewMatrix = camera.worldMatrix
            vertexUniforms[0].normalMatrix = normalMatrix
            vertexUniforms[0].viewport = viewport
            vertexUniforms[0].worldCameraPosition = camera.worldPosition
            vertexUniforms[0].worldCameraViewDirection = camera.viewDirection
        }
    }
    
    internal func updateUniformsBuffer() {
        if vertexUniformsBuffer != nil {
            uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight
            uniformBufferOffset = alignedUniformsSize * uniformBufferIndex
            vertexUniforms = UnsafeMutableRawPointer(vertexUniformsBuffer.contents() + uniformBufferOffset).bindMemory(to: VertexUniforms.self, capacity: 1)
        }
    }
    
    override open func update() {
        geometry.update()
        material?.update()
        updateUniformsBuffer()
        super.update()
    }
    
    open func update(camera: Camera, viewport: simd_float4) {
        updateUniforms(camera: camera, viewport: viewport)
    }
    
    open func draw(renderEncoder: MTLRenderCommandEncoder) {
        draw(renderEncoder: renderEncoder, instanceCount: instanceCount)
    }
    
    open func draw(renderEncoder: MTLRenderCommandEncoder, instanceCount: Int) {
        guard instanceCount > 0, let vertexBuffer = geometry.vertexBuffer else { return }
        
        preDraw?(renderEncoder)
        
        renderEncoder.setFrontFacing(geometry.windingOrder)
        renderEncoder.setCullMode(cullMode)
        renderEncoder.setTriangleFillMode(triangleFillMode)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: VertexBufferIndex.Vertices.rawValue)
        renderEncoder.setVertexBuffer(vertexUniformsBuffer, offset: uniformBufferOffset, index: VertexBufferIndex.VertexUniforms.rawValue)
        
        if !submeshes.isEmpty {
            for submesh in submeshes {
                if submesh.visible, let indexBuffer = submesh.indexBuffer {
                    renderEncoder.drawIndexedPrimitives(
                        type: geometry.primitiveType,
                        indexCount: submesh.indexCount,
                        indexType: submesh.indexType,
                        indexBuffer: indexBuffer,
                        indexBufferOffset: submesh.indexBufferOffset,
                        instanceCount: instanceCount
                    )
                }
            }
        } else if let indexBuffer = geometry.indexBuffer {
            renderEncoder.drawIndexedPrimitives(
                type: geometry.primitiveType,
                indexCount: geometry.indexData.count,
                indexType: geometry.indexType,
                indexBuffer: indexBuffer,
                indexBufferOffset: 0,
                instanceCount: instanceCount
            )
        } else {
            renderEncoder.drawPrimitives(
                type: geometry.primitiveType,
                vertexStart: 0,
                vertexCount: geometry.vertexData.count,
                instanceCount: instanceCount
            )
        }
    }
    
    open func addSubmesh(_ submesh: Submesh) {
        submesh.parent = self
        submeshes.append(submesh)
    }
    
    override open func computeLocalBounds() -> Bounds {
        return transformBounds(geometry.bounds, localMatrix)
    }
    
    override open func computeWorldBounds() -> Bounds {
        var result = transformBounds(geometry.bounds, worldMatrix)
        children.forEach { child in
            result = mergeBounds(result, child.worldBounds)
        }
        return result
    }
}
