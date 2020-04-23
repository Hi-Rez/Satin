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
    
    lazy var rayBuffer: Buffer = {
        Buffer(context: context, parameters: rayParams)
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
    
    lazy var intersectionBuffer: Buffer = {
        Buffer(context: context, parameters: intersectionParams)
    }()
    
    var context: Context
    var commandQueue: MTLCommandQueue!
    var intersector: MPSRayIntersector!
    var accelerationStructure: MPSTriangleAccelerationStructure!
    
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
        
        // setup acceleration stucture
        setupAccelerationStructure()
    }
    
    func setupCommandQueue() {
        guard let commandQueue = context.device.makeCommandQueue() else { fatalError("Unable to create Raycaster") }
        self.commandQueue = commandQueue
    }
    
    func setupIntersector() {
        intersector = MPSRayIntersector(device: context.device)
        intersector.rayDataType = .originMinDistanceDirectionMaxDistance
        intersector.rayStride = MemoryLayout<MPSRayOriginMinDistanceDirectionMaxDistance>.stride
        intersector.intersectionDataType = .distancePrimitiveIndexCoordinates
        intersector.triangleIntersectionTestType = .default
    }
    
    func setupAccelerationStructure() {
        accelerationStructure = MPSTriangleAccelerationStructure(device: context.device)
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
    
    public func intersect(_ object: Object, _ recursive: Bool = true) -> [RaycastResult] {
        var results: [RaycastResult] = []
        if object.visible {
            if object is Mesh, let mesh = object as? Mesh, let material = mesh.material, let _ = material.pipeline {
                if let result = intersect(object as! Mesh) {
                    results.append(result)
                }
            }
            
            for child in object.children {
                let res = intersect(child, recursive)
                if !res.isEmpty {
                    results.append(contentsOf: res)
                }
            }
        }
        return results
    }
    
    public func intersect(_ mesh: Mesh) -> RaycastResult? {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return nil }
        commandBuffer.label = "Raycaster Command Buffer"
        
        let geometry = mesh.geometry
        if geometry.vertexData.isEmpty || geometry.primitiveType != .triangle {
            return nil
        }
        
        let meshWorldMatrix = mesh.worldMatrix
        let meshWorldMatrixInverse = meshWorldMatrix.inverse
        
        let origin = meshWorldMatrixInverse * simd_make_float4(ray.origin.x, ray.origin.y, ray.origin.z, 1.0)
        let direction = meshWorldMatrixInverse * simd_make_float4(ray.direction)
        
        originParam.value = simd_make_float3(origin)
        directionParam.value = simd_make_float3(direction)
        rayBuffer.update()
        
        let winding: MTLWinding = geometry.windingOrder == .counterClockwise ? .clockwise : .counterClockwise
        intersector.frontFacingWinding = winding
        intersector.cullMode = mesh.cullMode
        
        guard let vertexBuffer = mesh.vertexBuffer else { return nil }
        
        accelerationStructure.vertexBuffer = vertexBuffer
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
        
        accelerationStructure.rebuild()
        
        intersector.label = mesh.label + " Raycaster Intersector"
        intersector.encodeIntersection(
            commandBuffer: commandBuffer,
            intersectionType: .nearest,
            rayBuffer: rayBuffer.buffer,
            rayBufferOffset: 0,
            intersectionBuffer: intersectionBuffer.buffer,
            intersectionBufferOffset: 0,
            rayCount: 1,
            accelerationStructure: accelerationStructure
        )
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        intersectionBuffer.sync()
        
        let distance = distanceParam.value
        if distance >= 0 {
            let primitiveIndex = indexParam.value
            let index = Int(primitiveIndex) * 3
            
            var i0 = 0
            var i1 = 0
            var i2 = 0
            
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
            
            return RaycastResult(
                barycentricCoordinates: simd_make_float3(u, v, w),
                distance: distance,
                normal: hitN,
                position: hitP,
                uv: hitU,
                primitiveIndex: primitiveIndex,
                object: mesh
            )
        }
        else {
            print("no hits")
        }
        return nil
    }
}

#endif
