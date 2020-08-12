//
//  BufferComputeSystem.swift
//  Satin
//
//  Created by Reza Ali on 4/13/20.
//

import Metal

open class BufferComputeSystem {
    var _reset: Bool = true
    var _setupBuffers: Bool = false
    var _index: Int = 0
    var _count: Int = 0

    private var _useDispatchThreads: Bool = false

    public var count: Int = 0 {
        didSet {
            _reset = true
            _setupBuffers = true
        }
    }

    public var index: Int {
        return pong()
    }

    public var bufferMap: [String: [MTLBuffer]] = [:]
    public var bufferOrder: [String] = []

    var params: [ParameterGroup] = []

    public var preUpdate: ((_ computeEncoder: MTLComputeCommandEncoder, _ bufferOffset: Int) -> ())?
    public var preReset: ((_ computeEncoder: MTLComputeCommandEncoder, _ bufferOffset: Int) -> ())?
    public var preCompute: ((_ computeEncoder: MTLComputeCommandEncoder, _ bufferOffset: Int) -> ())?

    var context: Context

    public var resetPipeline: MTLComputePipelineState?
    public var updatePipeline: MTLComputePipelineState?

    public init(context: Context,
                resetPipeline: MTLComputePipelineState?,
                updatePipeline: MTLComputePipelineState?,
                params: [ParameterGroup],
                count: Int) {
        if count <= 0 {
            fatalError("Compute System count: \(count) must be greater than zero!")
        }

        self.context = context
        self.resetPipeline = resetPipeline
        self.updatePipeline = updatePipeline
        self.params = params
        self.count = count
        self._count = count
        setupBuffers()
    }

    public init(context: Context, count: Int) {
        if count <= 0 {
            fatalError("Compute System count: \(count) must be greater than zero!")
        }

        self.context = context
        self.count = count
        self._count = count
        setup()
    }

    private func setup() {
        checkFeatures()
    }

    private func checkFeatures() {
        _useDispatchThreads = false
        let device = context.device
        if #available(macOS 10.15, iOS 13, tvOS 13, *) {
            if device.supportsFamily(.common3) || device.supportsFamily(.apple4) || device.supportsFamily(.apple5) || device.supportsFamily(.mac1) || device.supportsFamily(.mac2) {
                _useDispatchThreads = true
            }
        } else {
            #if os(macOS)
            if device.supportsFeatureSet(.macOS_GPUFamily1_v1) || device.supportsFeatureSet(.macOS_GPUFamily2_v1) {
                _useDispatchThreads = true
            }
            #elseif os(iOS)
            if device.supportsFeatureSet(.iOS_GPUFamily4_v1) || device.supportsFeatureSet(.iOS_GPUFamily5_v1) {
                _useDispatchThreads = true
            }
            #endif
        }
    }

    deinit {
        params = []
        bufferMap = [:]
        bufferOrder = []
        resetPipeline = nil
        updatePipeline = nil
    }

    public func setParams(_ params: [ParameterGroup]) {
        self.params = params
        _setupBuffers = true
    }

    func setupBuffers() {
        bufferMap = [:]
        bufferOrder = []
        for param in params {
            let stride = param.stride
            if stride > 0 {
                let label = param.label
                bufferMap[label] = []
                bufferOrder.append(label)
                var buffers: [MTLBuffer] = []
                for i in 0..<2 {
                    if let buffer = context.device.makeBuffer(length: stride * count, options: [.storageModePrivate]) {
                        buffer.label = param.label + " \(i)"
                        buffers.append(buffer)
                    }
                }
                bufferMap[label] = buffers
            }
        }
    }

    public func reset() {
        _reset = true
        _setupBuffers = true
    }

    public func getBuffer(_ label: String) -> MTLBuffer? {
        if let buffers = bufferMap[label] {
            return buffers[pong()]
        }
        return nil
    }

    public func update(_ commandBuffer: MTLCommandBuffer) {
        if _setupBuffers {
            setupBuffers()
            _index = 0
            _setupBuffers = false
            _count = count
        }

        if bufferMap.count > 0, let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
            if _reset, let pipeline = self.resetPipeline {
                computeEncoder.setComputePipelineState(pipeline)
                for i in 0...1 {
                    let offset = setBuffers(computeEncoder, i)
                    preReset?(computeEncoder, offset)
                    preCompute?(computeEncoder, offset)
                    dispatch(computeEncoder, pipeline)
                }
                _reset = false
            }

            if let pipeline = self.updatePipeline {
                computeEncoder.setComputePipelineState(pipeline)
                let offset = setBuffers(computeEncoder)
                preUpdate?(computeEncoder, offset)
                preCompute?(computeEncoder, offset)
                dispatch(computeEncoder, pipeline)
                pingPong()
            }

            computeEncoder.endEncoding()
        }
    }

    func setBuffers(_ computeEncoder: MTLComputeCommandEncoder) -> Int {
        var offset = 0
        for key in bufferOrder {
            if let buffers = bufferMap[key] {
                let inBuffer = buffers[ping()]
                let outBuffer = buffers[pong()]
                computeEncoder.setBuffer(inBuffer, offset: 0, index: offset)
                offset += 1
                computeEncoder.setBuffer(outBuffer, offset: 0, index: offset)
                offset += 1
            }
        }
        return offset
    }

    func setBuffers(_ computeEncoder: MTLComputeCommandEncoder, _ index: Int) -> Int {
        var offset = 0
        for key in bufferOrder {
            if let buffers = bufferMap[key] {
                computeEncoder.setBuffer(buffers[ping(index)], offset: 0, index: offset)
                offset += 1
                computeEncoder.setBuffer(buffers[pong(index)], offset: 0, index: offset)
                offset += 1
            }
        }
        return offset
    }

    private func dispatch(_ computeEncoder: MTLComputeCommandEncoder, _ pipeline: MTLComputePipelineState) {
        #if os(iOS) || os(macOS)
        if _useDispatchThreads {
            _dispatchThreads(computeEncoder, pipeline)
        } else {
            _dispatchThreadgroups(computeEncoder, pipeline)
        }
        #elseif os(tvOS)
        _dispatchThreadgroups(computeEncoder, pipeline)
        #endif
    }

    #if os(iOS) || os(macOS)
    private func _dispatchThreads(_ computeEncoder: MTLComputeCommandEncoder, _ pipeline: MTLComputePipelineState) {
        let gridSize = MTLSizeMake(_count, 1, 1)
        var threadGroupSize = pipeline.maxTotalThreadsPerThreadgroup
        threadGroupSize = threadGroupSize > _count ? _count : threadGroupSize
        let threadsPerThreadgroup = MTLSizeMake(threadGroupSize, 1, 1)
        computeEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadsPerThreadgroup)
    }
    #endif

    private func _dispatchThreadgroups(_ computeEncoder: MTLComputeCommandEncoder, _ pipeline: MTLComputePipelineState) {
        let m = pipeline.maxTotalThreadsPerThreadgroup
        let threadsPerThreadgroup = MTLSizeMake(m, 1, 1)
        let threadgroupsPerGrid = MTLSize(width: (count + m - 1) / m,
                                          height: 1,
                                          depth: 1)
        computeEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
    }

    private func ping() -> Int {
        return _index
    }

    private func pong() -> Int {
        return ((_index + 1) % 2)
    }

    private func pingPong() {
        _index = (_index + 1) % 2
    }

    private func ping(_ index: Int) -> Int {
        return (index % 2)
    }

    private func pong(_ index: Int) -> Int {
        return ((index + 1) % 2)
    }
}
