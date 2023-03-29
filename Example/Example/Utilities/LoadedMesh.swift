//
//  LoadedMesh.swift
//
//
//  Created by Reza Ali on 4/21/22.
//

import Combine
import Metal
import MetalKit
import ModelIO
import simd

import Satin

struct VertexGenerics {
    var tangent: simd_float3
    var bitangent: simd_float3
    var color: simd_float3
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

class LoadedMesh: Object, Renderable {
    public var renderOrder = 0
    public var receiveShadow: Bool = false
    public var castShadow: Bool = false

    public var drawable: Bool {
        guard uniforms != nil, vertexBuffer != nil, material?.pipeline != nil else { return false }
        return true
    }

    var uniforms: VertexUniformBuffer?

    var url: URL?
    var material: Material?
    var materials: [Material] {
        var allMaterials = [Material]()
        if let material = material {
            allMaterials.append(material)
        }
        return allMaterials
    }
    
    var cullMode: MTLCullMode = .back
    var windingOrder: MTLWinding = .counterClockwise
    var triangleFillMode: MTLTriangleFillMode = .fill

    var indexBuffer: MTLBuffer?
    var indexCount = 0
    var indexBitDepth: MDLIndexBitDepth = .uInt32
    var vertexBuffer: MTLBuffer?
    var genericsBuffer: MTLBuffer?

    var vertexCount = 0

    init(url: URL, material: Material) {
        self.url = url
        self.material = material
        if let vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(CustomModelIOVertexDescriptor()) {
            material.vertexDescriptor = vertexDescriptor
        }

        super.init("LoadedMesh")
    }

    override func setup() {
        setupUniforms()
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

            objMesh.addTangentBasis(
                forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                tangentAttributeNamed: MDLVertexAttributeTangent,
                bitangentAttributeNamed: MDLVertexAttributeBitangent
            )

            if let firstBuffer = objMesh.vertexBuffers.first as? MTKMeshBuffer {
                vertexBuffer = firstBuffer.buffer
                vertexBuffer?.label = "Vertices"
                vertexCount = objMesh.vertexCount
            }

            if let secondBuffer = objMesh.vertexBuffers[1] as? MTKMeshBuffer {
                genericsBuffer = secondBuffer.buffer
                genericsBuffer?.label = "Generics"
            }

            if let submeshes = objMesh.submeshes, let first = submeshes.firstObject, let sub: MDLSubmesh = first as? MDLSubmesh {
                indexBuffer = (sub.indexBuffer as! MTKMeshBuffer).buffer
                indexBuffer?.label = "Indices"
                indexBitDepth = sub.indexType
                indexCount = sub.indexCount
            }
        }
    }

    func setupMaterial() {
        guard let context = context, let material = material else { return }
        material.context = context
    }

    func setupUniforms() {
        guard let context = context else { return }
        uniforms = VertexUniformBuffer(device: context.device)
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    // MARK: - Update

    override func update(_ commandBuffer: MTLCommandBuffer) {
        material?.update(commandBuffer)
        super.update(commandBuffer)
    }

    override func update(camera: Camera, viewport: simd_float4) {
        material?.update(camera: camera)
        uniforms?.update(object: self, camera: camera, viewport: viewport)
    }

    // MARK: - Draw

    func draw(renderEncoder: MTLRenderCommandEncoder, shadow: Bool) {
        draw(renderEncoder: renderEncoder, instanceCount: 1, shadow: shadow)
    }

    open func draw(renderEncoder: MTLRenderCommandEncoder, instanceCount: Int, shadow: Bool) {
        guard instanceCount > 0 else { return }

        material?.bind(renderEncoder, shadow: shadow)

        renderEncoder.setFrontFacing(windingOrder)
        renderEncoder.setCullMode(cullMode)
        renderEncoder.setTriangleFillMode(triangleFillMode)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: VertexBufferIndex.Vertices.rawValue)
        renderEncoder.setVertexBuffer(genericsBuffer, offset: 0, index: VertexBufferIndex.Generics.rawValue)

        if let uniforms = uniforms {
            renderEncoder.setVertexBuffer(uniforms.buffer, offset: uniforms.offset, index: VertexBufferIndex.VertexUniforms.rawValue)
        }

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

    var updateGeometryBounds = true
    var _geometryBounds = Bounds(min: .init(repeating: .infinity), max: .init(repeating: -.infinity))
    public var geometryBounds: Bounds {
        if updateGeometryBounds {
            _geometryBounds = computeGeometryBounds()
            updateGeometryBounds = false
        }
        return _geometryBounds
    }

    func computeGeometryBounds() -> Bounds {
        var bounds = Bounds(min: .init(repeating: .infinity), max: .init(repeating: -.infinity))
        guard let vertexBuffer = vertexBuffer else { return bounds }
        var vertexPtr = vertexBuffer.contents().bindMemory(to: Vertex.self, capacity: vertexCount)
        for _ in 0 ..< vertexCount {
            bounds = expandBounds(bounds, simd_make_float3(vertexPtr.pointee.position))
            vertexPtr += 1
        }
        return bounds
    }
}
