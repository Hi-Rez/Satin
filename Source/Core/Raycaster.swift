//
//  Raycaster.swift
//  Satin
//
//  Created by Reza Ali on 4/22/20.
//

#if os(iOS) || os(macOS)

import Metal
import MetalPerformanceShaders
import simd

public struct RaycastResult {
    public let barycentricCoordinates: simd_float3
    public let distance: Float
    public let normal: simd_float3
    public let position: simd_float3
    public let uv: simd_float2
    public let primitiveIndex: UInt32
    public let object: Object
}

open class Raycaster {
    public var ray: Ray = Ray() {
        didSet {
            originParam.value = ray.origin
            directionParam.value = ray.direction
        }
    }
    
    public var near: Float = 0.0 {
        didSet {
            nearParam.value = near
        }
    }
    
    public var far: Float = Float.infinity {
        didSet {
            farParam.value = far
        }
    }
    
    public var rebuildStructures: Bool = false {
        didSet {
            _rebuildStructures = rebuildStructures
        }
    }
    
    lazy var originParam: PackedFloat3Parameter = {
        PackedFloat3Parameter("origin", ray.origin)
    }()
    
    lazy var nearParam: FloatParameter = {
        FloatParameter("near", near)
    }()
    
    lazy var directionParam: PackedFloat3Parameter = {
        PackedFloat3Parameter("direction", ray.direction)
    }()
    
    lazy var farParam: FloatParameter = {
        FloatParameter("far", far)
    }()
    
    lazy var rayParams: ParameterGroup = {
        let params = ParameterGroup("Ray")
        params.append(originParam)
        params.append(nearParam)
        params.append(directionParam)
        params.append(farParam)
        return params
    }()
    
    var distanceParam = FloatParameter("distance")
    var indexParam = UInt32Parameter("index")
    var coordinatesParam = Float2Parameter("coordinates")
    
    lazy var intersectionParams: ParameterGroup = {
        let params = ParameterGroup("Intersection")
        params.append(distanceParam)
        params.append(indexParam)
        params.append(coordinatesParam)
        return params
    }()
    
    weak var context: Context?
    var commandQueue: MTLCommandQueue?
    var intersector: MPSRayIntersector?
    var accelerationStructures: [MPSTriangleAccelerationStructure] = []
    
    var _count: Int = -1 {
        didSet {
            setupRayBuffers()
            setupIntersectionBuffers()
            setupAccelerationStructures()
        }
    }
    
    var _rebuildStructures: Bool = true
    var rayBuffer: Buffer!
    var intersectionBuffer: Buffer!
    
    // Ideally you create a raycaster on start up and reuse it over and over
    public init(context: Context) {
        self.context = context
        setup()
    }
    
    public init(context: Context, _ origin: simd_float3, _ direction: simd_float3, _ near: Float = 0.0, _ far: Float = Float.infinity) {
        self.context = context
        ray = Ray(origin, direction)
        self.near = near
        self.far = far
        setup()
    }
    
    public init(context: Context, _ ray: Ray, _ near: Float = 0.0, _ far: Float = Float.infinity) {
        self.context = context
        self.ray = ray
        self.near = near
        self.far = far
        setup()
    }
    
    public init(context: Context, _ camera: Camera, _ coordinate: simd_float2, _ near: Float = 0.0, _ far: Float = Float.infinity) {
        self.context = context
        setFromCamera(camera, coordinate)
        self.near = near
        self.far = far
        setup()
    }
    
    func setup() {
        // setup command queue
        setupCommandQueue()
        
        // setup intersector
        setupIntersector()
    }
    
    func setupCommandQueue() {
        guard let context = self.context, let commandQueue = context.device.makeCommandQueue() else { fatalError("Unable to create Command Queue") }
        self.commandQueue = commandQueue
    }
    
    func setupIntersector() {
        guard let context = self.context else { fatalError("Unable to create Intersector") }
        let intersector = MPSRayIntersector(device: context.device)
        intersector.rayDataType = .originMinDistanceDirectionMaxDistance
        intersector.rayStride = MemoryLayout<MPSRayOriginMinDistanceDirectionMaxDistance>.stride
        intersector.intersectionDataType = .distancePrimitiveIndexCoordinates
        intersector.triangleIntersectionTestType = .default
        self.intersector = intersector
    }
    
    func setupAccelerationStructures() {
        guard let context = self.context else { fatalError("Unable to create Acceleration Structures") }
        var acount = accelerationStructures.count
        while acount > _count {
            _ = accelerationStructures.popLast()
            acount = accelerationStructures.count
            _rebuildStructures = true
        }
        for _ in acount..<_count {
            accelerationStructures.append(MPSTriangleAccelerationStructure(device: context.device))
            _rebuildStructures = true
        }
    }
    
    // expects a normalize point from -1 to 1 in both x & y directions
    public func setFromCamera(_ camera: Camera, _ coordinate: simd_float2) {
        if camera is PerspectiveCamera {
            let origin = camera.worldPosition
            let unproject = camera.worldMatrix * camera.projectionMatrix.inverse * simd_make_float4(coordinate.x, coordinate.y, camera.near / camera.far, 1.0)
            let direction = normalize(simd_make_float3(unproject.x - origin.x, unproject.y - origin.y, unproject.z - origin.z))
            ray = Ray(origin, direction)
        }
        else if camera is OrthographicCamera {
            let origin = camera.worldMatrix * camera.projectionMatrix.inverse * simd_float4(coordinate.x, coordinate.y, 0.5, 1.0)
            let direction = normalize(simd_make_float3(camera.worldMatrix * simd_float4(0.0, 0.0, -1.0, 0.0)))
            ray = Ray(simd_make_float3(origin), direction)
        }
        else {
            fatalError("Raycaster has not implemented this type of Camera")
        }
    }
    
    func getMeshes(_ object: Object, _ recursive: Bool) -> [Mesh] {
        var results: [Mesh] = []
        if object.visible {
            if object is Mesh, let mesh = object as? Mesh, let material = mesh.material, let _ = material.pipeline {
                let geometry = mesh.geometry
                if !geometry.vertexData.isEmpty, geometry.primitiveType == .triangle {
                    results.append(object as! Mesh)
                }
            }
            
            if recursive {
                let children = object.children
                for child in children {
                    results.append(contentsOf: getMeshes(child, recursive))
                }
            }
        }
        return results
    }
    
    func setupRayBuffers() {
        guard let context = self.context else { fatalError("Unable to create Ray Buffers") }
        rayBuffer = Buffer(context: context, parameters: rayParams, count: _count)
    }
    
    func setupIntersectionBuffers() {
        guard let context = self.context else { fatalError("Unable to create Intersection Buffers") }
        intersectionBuffer = Buffer(context: context, parameters: intersectionParams, count: _count)
    }
    
    public func intersect(_ object: Object, _ recursive: Bool = true) -> [RaycastResult] {
        let meshes: [Mesh] = getMeshes(object, recursive)
        
        let count = meshes.count
        if count != _count {
            _count = count
        }
        
        guard let commandBuffer = commandQueue?.makeCommandBuffer() else { return [] }
        commandBuffer.label = "Raycaster Command Buffer"
        
        for (index, mesh) in meshes.enumerated() {
            intersect(commandBuffer, rayBuffer, intersectionBuffer, mesh, index)
        }
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        if _rebuildStructures {
            _rebuildStructures = false
        }
        
        var results: [RaycastResult] = []
        for (index, mesh) in meshes.enumerated() {
            intersectionBuffer.sync(index)
            let distance = distanceParam.value
            if distance >= 0 {
                let primitiveIndex = indexParam.value
                let index = Int(primitiveIndex) * 3
                
                var i0 = 0
                var i1 = 0
                var i2 = 0
                let geometry = mesh.geometry
                if geometry.indexData.isEmpty {
                    i0 = index
                    i1 = index + 1
                    i2 = index + 2
                }
                else {
                    i0 = Int(geometry.indexData[index])
                    i1 = Int(geometry.indexData[index + 1])
                    i2 = Int(geometry.indexData[index + 2])
                }
                
                let a: Vertex = geometry.vertexData[i0]
                let b: Vertex = geometry.vertexData[i1]
                let c: Vertex = geometry.vertexData[i2]
                
                let coords = coordinatesParam.value
                let u: Float = coords.x
                let v: Float = coords.y
                let w: Float = 1.0 - u - v
                
                let meshWorldMatrix = mesh.worldMatrix
                
                let aP = meshWorldMatrix * a.position * u
                let bP = meshWorldMatrix * b.position * v
                let cP = meshWorldMatrix * c.position * w
                
                let aU = a.uv * u
                let bU = b.uv * v
                let cU = c.uv * w
                
                let aN = meshWorldMatrix * simd_make_float4(a.normal) * u
                let bN = meshWorldMatrix * simd_make_float4(b.normal) * v
                let cN = meshWorldMatrix * simd_make_float4(c.normal) * w
                
                let hitP = simd_make_float3(aP + bP + cP)
                let hitU = simd_make_float2(aU + bU + cU)
                let hitN = normalize(simd_make_float3(aN + bN + cN))
                
                //            print("")
                //            print("origin: \(origin)")
                //            print("direction: \(direction)")
                //            print("hit Pos: \(hitP)")
                //            print("hit UV: \(hitU)")
                //            print("hit Normal: \(hitN)")
                //            print("coordinates: (\(u), \(v), \(w))")
                //            print("distance: \(distance)")
                //            print("primitive index: \(primitiveIndex)")
                //            print("")
                
                results.append(RaycastResult(
                    barycentricCoordinates: simd_make_float3(u, v, w),
                    distance: distance,
                    normal: hitN,
                    position: hitP,
                    uv: hitU,
                    primitiveIndex: primitiveIndex,
                    object: mesh
                ))
            }
        }
        results.sort {
            $0.distance < $1.distance
        }
        return results
    }
    
    func intersect(_ commandBuffer: MTLCommandBuffer,
                   _ rayBuffer: Buffer,
                   _ intersectionBuffer: Buffer,
                   _ mesh: Mesh,
                   _ index: Int) {
        let meshWorldMatrix = mesh.worldMatrix
        let meshWorldMatrixInverse = meshWorldMatrix.inverse
        
        let origin = meshWorldMatrixInverse * simd_make_float4(ray.origin.x, ray.origin.y, ray.origin.z, 1.0)
        let direction = meshWorldMatrixInverse * simd_make_float4(ray.direction)
        
        originParam.value = simd_make_float3(origin)
        directionParam.value = simd_make_float3(direction)
        rayBuffer.update(index)
        
        let geometry = mesh.geometry
        let winding: MTLWinding = geometry.windingOrder == .counterClockwise ? .clockwise : .counterClockwise
        intersector!.frontFacingWinding = winding
        intersector!.cullMode = mesh.cullMode
        
        let accelerationStructure = accelerationStructures[index]        
        accelerationStructure.vertexBuffer = mesh.vertexBuffer!
        accelerationStructure.vertexStride = MemoryLayout<Vertex>.stride
        accelerationStructure.label = mesh.label + " Acceleration Structure"
        
        if let indexBuffer = mesh.indexBuffer {
            accelerationStructure.indexBuffer = indexBuffer
            accelerationStructure.indexType = .uInt32
            accelerationStructure.triangleCount = geometry.indexData.count / 3
        }
        else {
            accelerationStructure.triangleCount = mesh.geometry.vertexData.count / 3
        }
        
        if _rebuildStructures {
            accelerationStructure.rebuild()
        }
        
        intersector!.label = mesh.label + " Raycaster Intersector"
        intersector!.encodeIntersection(
            commandBuffer: commandBuffer,
            intersectionType: .nearest,
            rayBuffer: rayBuffer.buffer,
            rayBufferOffset: index * rayParams.stride,
            intersectionBuffer: intersectionBuffer.buffer,
            intersectionBufferOffset: index * intersectionParams.stride,
            rayCount: 1,
            accelerationStructure: accelerationStructure
        )
    }
    
    deinit {
        accelerationStructures = []
        intersector = nil
        commandQueue = nil
        context = nil
    }
}

#endif
