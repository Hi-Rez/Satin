//
//  Raycaster.swift
//  Satin
//
//  Created by Reza Ali on 4/22/20.
//

#if os(iOS) || os(macOS)

import Combine
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
    public let submesh: Submesh?
    
    public init(barycentricCoordinates: simd_float3, distance: Float, normal: simd_float3, position: simd_float3, uv: simd_float2, primitiveIndex: UInt32, object: Object, submesh: Submesh?) {
        self.barycentricCoordinates = barycentricCoordinates
        self.distance = distance
        self.normal = normal
        self.position = position
        self.uv = uv
        self.primitiveIndex = primitiveIndex
        self.object = object
        self.submesh = submesh
    }
}

open class Raycaster {
    public var ray = Ray() {
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
    
    public var far = Float.infinity {
        didSet {
            farParam.value = far
        }
    }

    internal lazy var originParam: PackedFloat3Parameter = {
        PackedFloat3Parameter("origin", ray.origin)
    }()
    
    internal lazy var nearParam: FloatParameter = {
        FloatParameter("near", near)
    }()
    
    internal lazy var directionParam: PackedFloat3Parameter = {
        PackedFloat3Parameter("direction", ray.direction)
    }()
    
    internal lazy var farParam: FloatParameter = {
        FloatParameter("far", far)
    }()
    
    internal lazy var rayParams: ParameterGroup = {
        let params = ParameterGroup("Ray")
        params.append(originParam)
        params.append(nearParam)
        params.append(directionParam)
        params.append(farParam)
        return params
    }()
    
    internal var distanceParam = FloatParameter("distance", 0.0)
    internal var primitiveIndexParam = UInt32Parameter("index", 0)
    internal var barycentricCoordinatesParam = Float2Parameter("coordinates", .zero)
    
    internal lazy var intersectionParams: ParameterGroup = {
        let params = ParameterGroup("Intersection")
        params.append(distanceParam)
        params.append(primitiveIndexParam)
        params.append(barycentricCoordinatesParam)
        return params
    }()
    
    internal weak var device: MTLDevice?
    internal var commandQueue: MTLCommandQueue?
    internal var intersector: MPSRayIntersector?
    internal var accelerationStructures: [String: MPSTriangleAccelerationStructure] = [:]
    internal var subscriptions: [String: AnyCancellable] = [:]
    
    var _count: Int = -1 {
        didSet {
            if _count != oldValue {
                setupRayBuffers()
                setupIntersectionBuffers()
            }
        }
    }
    
    var rayBuffer: Buffer!
    var intersectionBuffer: Buffer!
    
    // Ideally you create a raycaster on start up and reuse it over and over
    public init(device: MTLDevice) {
        self.device = device
        setup()
    }
    
    public init(device: MTLDevice, _ origin: simd_float3, _ direction: simd_float3, _ near: Float = 0.0, _ far: Float = Float.infinity) {
        self.device = device
        ray = Ray(origin, direction)
        self.near = near
        self.far = far
        setup()
    }
    
    public init(device: MTLDevice, _ ray: Ray, _ near: Float = 0.0, _ far: Float = Float.infinity) {
        self.device = device
        self.ray = ray
        self.near = near
        self.far = far
        setup()
    }
    
    public init(device: MTLDevice, _ camera: Camera, _ coordinate: simd_float2, _ near: Float = 0.0, _ far: Float = Float.infinity) {
        self.device = device
        setFromCamera(camera, coordinate)
        self.near = near
        self.far = far
        setup()
    }
    
    deinit {
        accelerationStructures = [:]
        intersector = nil
        commandQueue = nil
        device = nil
    }
    
    func setup() {
        setupCommandQueue()
        setupIntersector()
    }
    
    func setupCommandQueue() {
        guard let device = device, let commandQueue = device.makeCommandQueue() else { fatalError("Unable to create Command Queue") }
        self.commandQueue = commandQueue
    }
    
    func setupIntersector() {
        guard let device = device else { fatalError("Unable to create Intersector") }
        let intersector = MPSRayIntersector(device: device)
        intersector.rayDataType = .originMinDistanceDirectionMaxDistance
        intersector.rayStride = MemoryLayout<MPSRayOriginMinDistanceDirectionMaxDistance>.stride
        intersector.intersectionDataType = .distancePrimitiveIndexCoordinates
        intersector.triangleIntersectionTestType = .default
        self.intersector = intersector
    }
    
    // expects a normalize point from -1 to 1 in both x & y directions
    public func setFromCamera(_ camera: Camera, _ coordinate: simd_float2 = .zero) {
        ray = Ray(camera, coordinate)
    }
    
    private func setupRayBuffers() {
        guard let device = device, _count > 0 else { return }
        rayBuffer = Buffer(device: device, parameters: rayParams, count: _count)
    }
    
    private func setupIntersectionBuffers() {
        guard let device = device, _count > 0 else { return }
        intersectionBuffer = Buffer(device: device, parameters: intersectionParams, count: _count)
    }
    
    public func intersect(_ object: Object, _ recursive: Bool = true, _ invisible: Bool = false, _ callback: @escaping (_ results: [RaycastResult]) -> ()) {
        let intersectables = _getIntersectables([object], recursive, invisible)
        guard let commandBuffer = _intersect(intersectables) else { return callback([]) }
        commandBuffer.addCompletedHandler { [weak self] _ in
            if let self = self {
                callback(self.getResults(intersectables))
            }
        }
        commandBuffer.commit()
    }
    
    public func intersect(_ object: Object, _ recursive: Bool = true, _ invisible: Bool = false) -> [RaycastResult] {
        let intersectables = _getIntersectables([object], recursive, invisible)
        guard let commandBuffer = _intersect(intersectables) else { return [] }
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        return getResults(intersectables)
    }
    
    public func intersect(_ objects: [Object], _ recursive: Bool = true, _ invisible: Bool = false) -> [RaycastResult] {
        let intersectables = _getIntersectables(objects, recursive, invisible)
        guard let commandBuffer = _intersect(intersectables) else { return [] }
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        return getResults(intersectables)
    }
    
    private func _getIntersectables(_ objects: [Object], _ recursive: Bool = true, _ invisible: Bool = false) -> [Intersectable] {
        var results: [Intersectable] = []
        for object in objects {
            let intersectables: [Intersectable] = getIntersectables(object, recursive, invisible).filter { $0.intersects(ray: ray) }
            for intersectable in intersectables {
                if let mesh = intersectable as? Mesh, !mesh.submeshes.isEmpty {
                    let submeshes = mesh.submeshes.filter { $0.intersectable }
                    for submesh in submeshes {
                        results.append(submesh)
                    }
                }
                else {
                    results.append(intersectable)
                }
            }
        }
        
        _count = results.count
        return results
    }
    
    private func _intersect(_ intersectables: [Intersectable]) -> MTLCommandBuffer? {
        guard let commandBuffer = commandQueue?.makeCommandBuffer() else { return nil }
        commandBuffer.label = "Raycaster Command Buffer"
        
        for (index, intersectable) in intersectables.enumerated() {
            intersect(commandBuffer, rayBuffer, intersectionBuffer, intersectable, index)
        }
        
        return commandBuffer
    }
    
    private func intersect(_ commandBuffer: MTLCommandBuffer,
                           _ rayBuffer: Buffer,
                           _ intersectionBuffer: Buffer,
                           _ intersectable: Intersectable,
                           _ index: Int)
    {
        let worldMatrix = intersectable.worldMatrix
        let worldMatrixInverse = worldMatrix.inverse
        
        let origin = worldMatrixInverse * simd_make_float4(ray.origin, 1.0)
        let direction = worldMatrixInverse * simd_make_float4(ray.direction)
        
        originParam.value = simd_make_float3(origin)
        directionParam.value = simd_make_float3(direction)
        rayBuffer.update(index)
        
        var accelerationStructure: MPSAccelerationStructure?
        if let structure = accelerationStructures[intersectable.id] {
            accelerationStructure = structure
        }
        else if let device = device {
            let newAccelerationStructure = MPSTriangleAccelerationStructure(device: device)
            newAccelerationStructure.vertexBuffer = intersectable.vertexBuffer
            newAccelerationStructure.vertexStride = intersectable.vertexStride
            newAccelerationStructure.label = intersectable.label + " Acceleration Structure"
            
            if let indexBuffer = intersectable.indexBuffer {
                newAccelerationStructure.indexBuffer = indexBuffer
                newAccelerationStructure.indexType = .uInt32
                newAccelerationStructure.triangleCount = intersectable.indexCount / 3
            }
            else {
                newAccelerationStructure.triangleCount = intersectable.vertexCount / 3
            }
            
            newAccelerationStructure.rebuild()
            accelerationStructure = newAccelerationStructure
            accelerationStructures[intersectable.id] = newAccelerationStructure
            
            let subscription = intersectable.geometryPublisher.sink { [weak self] _ in
                guard let self = self else { return }
                self.accelerationStructures[intersectable.id] = nil
                self.subscriptions[intersectable.id]?.cancel()
                self.subscriptions[intersectable.id] = nil
            }
            subscriptions[intersectable.id] = subscription
        }
        
        intersector!.frontFacingWinding = (intersectable.windingOrder == .counterClockwise) ? .clockwise : .counterClockwise
        intersector!.cullMode = intersectable.cullMode
        intersector!.label = intersectable.label + " Raycaster Intersector"
        intersector!.encodeIntersection(
            commandBuffer: commandBuffer,
            intersectionType: .nearest,
            rayBuffer: rayBuffer.buffer,
            rayBufferOffset: index * rayParams.stride,
            intersectionBuffer: intersectionBuffer.buffer,
            intersectionBufferOffset: index * intersectionParams.stride,
            rayCount: 1,
            accelerationStructure: accelerationStructure!
        )
    }
    
    private func getResults(_ intersectables: [Intersectable]) -> [RaycastResult] {
        var results: [RaycastResult] = []
        for (index, intersectable) in intersectables.enumerated() {
            intersectionBuffer.sync(index)
            
            if distanceParam.value >= 0, let result = intersectable.getRaycastResult(ray: ray, distance: distanceParam.value, primitiveIndex: primitiveIndexParam.value, barycentricCoordinate: barycentricCoordinatesParam.value) {
                results.append(result)
            }
        }
        results.sort {
            $0.distance < $1.distance
        }
        return results
    }
    
    public func reset() {
        accelerationStructures = [:]
    }
}

#endif
