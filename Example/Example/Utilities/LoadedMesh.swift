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
    public var uniformBufferIndex: Int = 0
    public var uniformBufferOffset: Int = 0
    
    var uniforms: VertexUniformBuffer?
    var geometryPublisher = PassthroughSubject<Intersectable, Never>()
    
    var url: URL?
    var material: Material?
    var cullMode: MTLCullMode = .back
    var windingOrder: MTLWinding = .counterClockwise
    var triangleFillMode: MTLTriangleFillMode = .fill
    
    var indexBuffer: MTLBuffer? {
        didSet {
            geometryPublisher.send(self)
        }
    }

    var indexCount: Int = 0
    var indexBitDepth: MDLIndexBitDepth = .uInt32
    var vertexBuffer: MTLBuffer? {
        didSet {
            geometryPublisher.send(self)
        }
    }
    
    var genericsBuffer: MTLBuffer? {
        didSet {
            geometryPublisher.send(self)
        }
    }

    var vertexCount: Int = 0
    
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
    
    override func update() {
        material?.update()
        uniforms?.update()
        super.update()
    }

    override func update(camera: Camera, viewport: simd_float4) {
        material?.update(camera: camera)
        uniforms?.update(object: self, camera: camera, viewport: viewport)
    }
    
    // MARK: - Draw
    
    open func draw(renderEncoder: MTLRenderCommandEncoder) {
        draw(renderEncoder: renderEncoder, instanceCount: 1)
    }
    
    open func draw(renderEncoder: MTLRenderCommandEncoder, instanceCount: Int) {
        guard instanceCount > 0,
              let uniforms = uniforms,
              let vertexBuffer = vertexBuffer,
              let material = material,
              let _ = material.pipeline
        else { return }
        
        material.bind(renderEncoder)
        renderEncoder.setFrontFacing(windingOrder)
        renderEncoder.setCullMode(cullMode)
        renderEncoder.setTriangleFillMode(triangleFillMode)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: VertexBufferIndex.Vertices.rawValue)
        renderEncoder.setVertexBuffer(genericsBuffer, offset: 0, index: VertexBufferIndex.Generics.rawValue)
        renderEncoder.setVertexBuffer(uniforms.buffer, offset: uniforms.offset, index: VertexBufferIndex.VertexUniforms.rawValue)
        
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

extension LoadedMesh: Intersectable {
    var intersectable: Bool {
        vertexBuffer != nil
    }
    
    var intersectionBounds: Bounds {
        geometryBounds
    }
    
    var vertexStride: Int {
        MemoryLayout<Vertex>.stride
    }
    
    func intersects(ray: Ray) -> Bool {
        var times: simd_float2 = .zero
        return rayBoundsIntersection(ray.origin, ray.direction, intersectionBounds, &times)
    }
    
    public func getRaycastResult(ray: Ray, distance: Float, primitiveIndex: UInt32, barycentricCoordinate: simd_float2) -> RaycastResult? {
        let index = Int(primitiveIndex) * 3
            
        var i0 = 0
        var i1 = 0
        var i2 = 0
        
        if let indexBuffer = indexBuffer {
            var indexPtr = indexBuffer.contents().bindMemory(to: UInt32.self, capacity: indexCount)
            indexPtr = indexPtr.advanced(by: index)
            i0 = Int(indexPtr.pointee)
            indexPtr += 1
            i1 = Int(indexPtr.pointee)
            indexPtr += 1
            i2 = Int(indexPtr.pointee)
        } else {
            i0 = index
            i1 = index + 1
            i2 = index + 2
        }
        
        guard i0 < vertexCount, i1 < vertexCount, i2 < vertexCount else { return nil }
        
        let vertexPtr = vertexBuffer!.contents().bindMemory(to: Vertex.self, capacity: vertexCount).advanced(by: i0)
        
        let a: Vertex = (vertexPtr + i0).pointee
        let b: Vertex = (vertexPtr + i1).pointee
        let c: Vertex = (vertexPtr + i2).pointee
            
        let u: Float = barycentricCoordinate.x
        let v: Float = barycentricCoordinate.y
        let w: Float = 1.0 - u - v
            
        let aUv = a.uv * u
        let bUv = b.uv * v
        let cUv = c.uv * w
            
        let aNormal = worldMatrix * simd_make_float4(a.normal) * u
        let bNormal = worldMatrix * simd_make_float4(b.normal) * v
        let cNormal = worldMatrix * simd_make_float4(c.normal) * w
            
        return RaycastResult(
            barycentricCoordinates: simd_make_float3(u, v, w),
            distance: distance,
            normal: simd_normalize(simd_make_float3(aNormal + bNormal + cNormal)),
            position: ray.at(distance),
            uv: simd_make_float2(aUv + bUv + cUv),
            primitiveIndex: primitiveIndex,
            object: self,
            submesh: nil
        )
    }
}
