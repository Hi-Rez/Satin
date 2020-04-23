//
//  ComputeSystem.swift
//  Satin
//
//  Created by Reza Ali on 4/13/20.
//

#if os(iOS) || os(macOS)

import Metal

open class ComputeSystem {
    var _reset: Bool = true
    var _setupBuffers: Bool = false
    var _index: Int = 0
    var _count: Int = 0

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

    public var preUpdate: ((_ computeEncoder: MTLComputeCommandEncoder, _ bufferOffset: Int, _ textureOffset: Int) -> ())?
    public var postUpdate: ((_ computeEncoder: MTLComputeCommandEncoder, _ bufferOffset: Int, _ textureOffset: Int) -> ())?

    public var preReset: ((_ computeEncoder: MTLComputeCommandEncoder, _ bufferOffset: Int, _ textureOffset: Int) -> ())?
    public var postReset: ((_ computeEncoder: MTLComputeCommandEncoder, _ bufferOffset: Int, _ textureOffset: Int) -> ())?

    public var preCompute: ((_ computeEncoder: MTLComputeCommandEncoder, _ bufferOffset: Int, _ textureOffset: Int) -> ())?
    public var postCompute: ((_ computeEncoder: MTLComputeCommandEncoder, _ bufferOffset: Int, _ textureOffset: Int) -> ())?

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
                    let offsets = setBuffers(computeEncoder, i)
                    preReset?(computeEncoder, offsets.buffer, offsets.texture)
                    preCompute?(computeEncoder, offsets.buffer, offsets.texture)
                    dispatch(computeEncoder, pipeline)
                    postCompute?(computeEncoder, offsets.buffer, offsets.texture)
                    postReset?(computeEncoder, offsets.buffer, offsets.texture)
                }
                _reset = false
            }

            if let pipeline = self.updatePipeline {
                computeEncoder.setComputePipelineState(pipeline)
                let offsets = setBuffers(computeEncoder, _index)
                preUpdate?(computeEncoder, offsets.buffer, offsets.texture)
                preCompute?(computeEncoder, offsets.buffer, offsets.texture)
                dispatch(computeEncoder, pipeline)
                postCompute?(computeEncoder, offsets.buffer, offsets.texture)
                postUpdate?(computeEncoder, offsets.buffer, offsets.texture)
                pingPong()
            }

            computeEncoder.endEncoding()
        }
    }

    func setBuffers(_ computeEncoder: MTLComputeCommandEncoder, _ index: Int) -> (buffer: Int, texture: Int) {
        var bufferIndex = 0
        for key in bufferOrder {
            if let buffers = bufferMap[key] {
                let inBuffer = buffers[ping()]
                let outBuffer = buffers[pong()]
                computeEncoder.setBuffer(inBuffer, offset: 0, index: bufferIndex)
                bufferIndex += 1
                computeEncoder.setBuffer(outBuffer, offset: 0, index: bufferIndex)
                bufferIndex += 1
            }
        }
        return (buffer: bufferIndex, texture: 0)
    }

    func dispatch(_ computeEncoder: MTLComputeCommandEncoder, _ pipeline: MTLComputePipelineState) {
        let gridSize = MTLSizeMake(_count, 1, 1)
        var threadGroupSize = pipeline.maxTotalThreadsPerThreadgroup
        threadGroupSize = threadGroupSize > _count ? _count : threadGroupSize
        let threadsPerThreadgroup = MTLSizeMake(threadGroupSize, 1, 1)
        computeEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadsPerThreadgroup)
    }

    func ping() -> Int {
        return _index
    }

    func pong() -> Int {
        return ((_index + 1) % 2)
    }

    func pingPong() {
        _index = (_index + 1) % 2
    }
}

#endif
