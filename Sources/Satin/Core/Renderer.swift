//
//  Renderer.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Combine
import Metal
import simd

open class Renderer {
    public var label = "Satin Renderer"

    public var onUpdate: (() -> Void)?
    public var preDraw: ((_ renderEncoder: MTLRenderCommandEncoder) -> Void)?
    public var postDraw: ((_ renderEncoder: MTLRenderCommandEncoder) -> Void)?

    public var sortObjects = false

    public var context: Context {
        didSet {
            if oldValue != context {
                updateColorTexture = true
                updateDepthTexture = true
                updateStencilTexture = true
            }
        }
    }

    public var size: (width: Float, height: Float) = (0, 0) {
        didSet {
            if oldValue.width != size.width || oldValue.height != size.height {
                updateViewport()
                updateColorTexture = true
                updateDepthTexture = true
                updateStencilTexture = true
            }
        }
    }

    public var clearColor: MTLClearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)
    public var clearDepth = 0.0
    public var clearStencil: UInt32 = 0

    public var updateColorTexture = true
    public var colorTexture: MTLTexture?

    public var colorLoadAction: MTLLoadAction = .clear
    public var colorStoreAction: MTLStoreAction = .store

    public var updateDepthTexture = true
    public var depthTexture: MTLTexture?

    public var depthLoadAction: MTLLoadAction = .clear
    public var depthStoreAction: MTLStoreAction = .dontCare

    public var updateStencilTexture = true
    public var stencilTexture: MTLTexture?

    public var stencilLoadAction: MTLLoadAction = .clear
    public var stencilStoreAction: MTLStoreAction = .dontCare

    public var viewport = MTLViewport() {
        didSet {
            _viewport = simd_make_float4(
                Float(viewport.originX),
                Float(viewport.originY),
                Float(viewport.width),
                Float(viewport.height)
            )
        }
    }

    public var invertViewportNearFar = false {
        didSet {
            if invertViewportNearFar != oldValue {
                updateViewport()
            }
        }
    }

    private var _viewport: simd_float4 = .zero

    private var objectList = [Object]()
    private var renderList = [Renderable]()

    private var lightList = [Light]()
    private var _updateLightDataBuffer = false
    private var lightDataBuffer: StructBuffer<LightData>?
    private var lightDataSubscriptions = Set<AnyCancellable>()

    private var shadowCasters = [Renderable]()
    private var shadowReceivers = [Renderable]()
    private var shadowList = [LightShadow]()
    private var _updateShadowMatricesBuffer = false
    private var shadowMatricesBuffer: StructBuffer<simd_float4x4>?
    private var shadowMatricesSubscriptions = Set<AnyCancellable>()

//    to do: fix this so we actually listen to texture updates and update the arg encoder
    private var _updateShadowArgumentEncoder = false
    private var shadowArgumentEncoder: MTLArgumentEncoder?
    private var shadowArgumentBuffer: MTLBuffer?
    private var shadowTextureSubscriptions = Set<AnyCancellable>()

    // MARK: - Init

    public init(context: Context) {
        self.context = context
    }

    public func setClearColor(_ color: simd_float4) {
        clearColor = .init(red: Double(color.x), green: Double(color.y), blue: Double(color.z), alpha: Double(color.w))
    }

    // MARK: - Drawing

    public func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer, scene: Object, camera: Camera, renderTarget: MTLTexture)
    {
        if context.sampleCount > 1 {
            let resolveTexture = renderPassDescriptor.colorAttachments[0].resolveTexture
            renderPassDescriptor.colorAttachments[0].resolveTexture = renderTarget
            draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer, scene: scene, camera: camera)
            renderPassDescriptor.colorAttachments[0].resolveTexture = resolveTexture
        } else {
            let renderTexture = renderPassDescriptor.colorAttachments[0].texture
            renderPassDescriptor.colorAttachments[0].texture = renderTarget
            draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer, scene: scene, camera: camera)
            renderPassDescriptor.colorAttachments[0].texture = renderTexture
        }
    }

    public func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer, scene: Object, camera: Camera)
    {
        update(scene: scene, camera: camera)

        let inColorTexture = renderPassDescriptor.colorAttachments[0].texture
        let inColorResolveTexture = renderPassDescriptor.colorAttachments[0].resolveTexture
        let inDepthTexture = renderPassDescriptor.depthAttachment.texture
        let inStencilTexture = renderPassDescriptor.stencilAttachment.texture

        let sampleCount = context.sampleCount
        let colorPixelFormat = context.colorPixelFormat
        let depthPixelFormat = context.depthPixelFormat
        let stencilPixelFormat = context.stencilPixelFormat

        // Set Color Texture

        if sampleCount > 1, inColorTexture?.sampleCount != sampleCount || inColorTexture?.pixelFormat != colorPixelFormat
        {
            setupColorTexture()
            renderPassDescriptor.colorAttachments[0].texture = colorTexture
        }

        // Set Depth Texture

        if inDepthTexture?.sampleCount != sampleCount || inDepthTexture?.pixelFormat != depthPixelFormat
        {
            setupDepthTexture()
            renderPassDescriptor.depthAttachment.texture = depthTexture
            if depthPixelFormat == .depth32Float_stencil8 {
                renderPassDescriptor.stencilAttachment.texture = depthTexture
            }
        }

        // Set Stencil Texture

        if inStencilTexture?.sampleCount != sampleCount || inStencilTexture?.pixelFormat != stencilPixelFormat
        {
            setupStencilTexture()
            if depthPixelFormat == .depth32Float_stencil8 {
                renderPassDescriptor.stencilAttachment.texture = depthTexture
            } else {
                renderPassDescriptor.stencilAttachment.texture = stencilTexture
            }
        }

        if sampleCount > 1 {
            if colorStoreAction == .store || colorStoreAction == .storeAndMultisampleResolve {
                renderPassDescriptor.colorAttachments[0].storeAction = .storeAndMultisampleResolve
            } else {
                renderPassDescriptor.colorAttachments[0].storeAction = .multisampleResolve
            }
        } else {
            if colorStoreAction == .store || colorStoreAction == .storeAndMultisampleResolve {
                renderPassDescriptor.colorAttachments[0].storeAction = .store
            } else {
                renderPassDescriptor.colorAttachments[0].storeAction = .dontCare
            }
        }

        renderPassDescriptor.colorAttachments[0].clearColor = clearColor
        renderPassDescriptor.colorAttachments[0].loadAction = colorLoadAction

        renderPassDescriptor.depthAttachment.loadAction = depthLoadAction
        renderPassDescriptor.depthAttachment.storeAction = depthStoreAction
        renderPassDescriptor.depthAttachment.clearDepth = clearDepth

        renderPassDescriptor.stencilAttachment.loadAction = stencilLoadAction
        renderPassDescriptor.stencilAttachment.storeAction = stencilStoreAction
        renderPassDescriptor.stencilAttachment.clearStencil = clearStencil

        // render objects that cast shadows into the depth textures
        if !shadowCasters.isEmpty, !shadowReceivers.isEmpty {
            for light in lightList where light.castShadow {
                light.shadow.draw(commandBuffer: commandBuffer, renderables: renderList)
            }
        }

        if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
            renderEncoder.label = label + " Encoder"
            renderEncoder.setViewport(viewport)
            encode(renderEncoder: renderEncoder, scene: scene, camera: camera)
            renderEncoder.endEncoding()
        }

        renderPassDescriptor.colorAttachments[0].texture = inColorTexture
        renderPassDescriptor.colorAttachments[0].resolveTexture = inColorResolveTexture
        renderPassDescriptor.depthAttachment.texture = inDepthTexture
        renderPassDescriptor.stencilAttachment.texture = inStencilTexture
    }

    public func draw(renderEncoder: MTLRenderCommandEncoder, scene: Object, camera: Camera) {
        update(scene: scene, camera: camera)
        encode(renderEncoder: renderEncoder, scene: scene, camera: camera)
    }

    // MARK: - Internal Update

    func update(scene: Object, camera: Camera) {
        onUpdate?()

        objectList.removeAll(keepingCapacity: true)
        renderList.removeAll(keepingCapacity: true)
        lightList.removeAll(keepingCapacity: true)

        shadowList.removeAll(keepingCapacity: true)
        shadowCasters.removeAll(keepingCapacity: true)
        shadowReceivers.removeAll(keepingCapacity: true)

        camera.update() // FIXME: - traverse children and make sure you update everything

        updateLists(object: scene)

        updateScene()
        updateLights()
        updateShadows()
    }

    func updateLists(object: Object, visible: Bool = true) {
        objectList.append(object)

        let isVisible = visible && object.visible
        if isVisible {
            if let light = object as? Light {
                lightList.append(light)
                if light.castShadow {
                    shadowList.append(light.shadow)
                }
            }
            if let renderable = object as? Renderable {
                renderList.append(renderable)
                if renderable.receiveShadow {
                    shadowReceivers.append(renderable)
                }
                if renderable.castShadow {
                    shadowCasters.append(renderable)
                }
            }
        }

        for child in object.children {
            updateLists(object: child, visible: isVisible)
        }
    }

    func updateScene() {
        let maxLights = lightList.count
        let shadowCount = shadowList.count

        for object in objectList {
            if let renderable = object as? Renderable {
                renderable.material?.maxLights = maxLights
                if renderable.receiveShadow {
                    renderable.material?.shadowCount = shadowCount
                }
            }

            object.context = context
            object.update()
        }
    }

    // MARK: - Internal Encoding

    func encode(renderEncoder: MTLRenderCommandEncoder, scene _: Object, camera: Camera) {
        renderEncoder.pushDebugGroup(label + " Pass")
        preDraw?(renderEncoder)

        let renderables = sortObjects ? renderList.sorted { $0.renderOrder < $1.renderOrder } : renderList


        if !renderables.isEmpty {
            for shadow in shadowList {
                if let shadowTexture = shadow.texture {
                    renderEncoder.useResource(shadowTexture, usage: .read, stages: .fragment)
                }
            }

            for renderable in renderables where renderable.drawable {
                _encode(renderEncoder: renderEncoder, renderable: renderable, camera: camera)
            }
        }

        postDraw?(renderEncoder)
        renderEncoder.popDebugGroup()
    }

    func _encode(renderEncoder: MTLRenderCommandEncoder, renderable: Renderable, camera: Camera) {
        renderEncoder.pushDebugGroup(renderable.label)

        if let material = renderable.material {

            if material.lighting, let lightBuffer = lightDataBuffer {
                renderEncoder.setFragmentBuffer(
                    lightBuffer.buffer,
                    offset: lightBuffer.offset,
                    index: FragmentBufferIndex.Lighting.rawValue
                )
            }

            if material.receiveShadow {
                if let shadowBuffer = shadowMatricesBuffer {
                    renderEncoder.setVertexBuffer(
                        shadowBuffer.buffer,
                        offset: shadowBuffer.offset,
                        index: VertexBufferIndex.ShadowMatrices.rawValue
                    )
                }

                if let shadowArgumentBuffer = shadowArgumentBuffer {
                    renderEncoder.setFragmentBuffer(
                        shadowArgumentBuffer,
                        offset: 0,
                        index: FragmentBufferIndex.Shadows.rawValue
                    )
                }
            }
        }

        renderable.update(camera: camera, viewport: _viewport)
        renderable.draw(renderEncoder: renderEncoder, shadow: false)

        renderEncoder.popDebugGroup()
    }

    // MARK: - Resizing

    public func resize(_ size: (width: Float, height: Float)) {
        self.size = size
    }

    func updateViewport() {
        viewport = MTLViewport(
            originX: 0.0,
            originY: 0.0,
            width: Double(size.width),
            height: Double(size.height),
            znear: invertViewportNearFar ? 1.0 : 0.0,
            zfar: invertViewportNearFar ? 0.0 : 1.0
        )

        viewport = MTLViewport(
            originX: 0.0,
            originY: 0.0,
            width: Double(size.width),
            height: Double(size.height),
            znear: invertViewportNearFar ? 1.0 : 0.0,
            zfar: invertViewportNearFar ? 0.0 : 1.0
        )
    }

    // MARK: - Textures

    func setupDepthTexture() {
        guard updateDepthTexture else { return }

        let sampleCount = context.sampleCount
        let depthPixelFormat = context.depthPixelFormat
        if depthPixelFormat != .invalid, size.width > 1, size.height > 1 {
            let descriptor = MTLTextureDescriptor()
            descriptor.pixelFormat = depthPixelFormat
            descriptor.width = Int(size.width)
            descriptor.height = Int(size.height)
            descriptor.sampleCount = sampleCount
            descriptor.textureType = sampleCount > 1 ? .type2DMultisample : .type2D
            descriptor.usage = [.renderTarget, .shaderRead]
            descriptor.storageMode = .private
            descriptor.resourceOptions = .storageModePrivate
            depthTexture = context.device.makeTexture(descriptor: descriptor)
            depthTexture?.label = label + " Depth Texture"
            updateDepthTexture = false
        } else {
            depthTexture = nil
        }
    }

    func setupStencilTexture() {
        guard updateStencilTexture else { return }

        let sampleCount = context.sampleCount
        let stencilPixelFormat = context.stencilPixelFormat
        if stencilPixelFormat != .invalid, size.width > 1, size.height > 1 {
            let descriptor = MTLTextureDescriptor()
            descriptor.pixelFormat = stencilPixelFormat
            descriptor.width = Int(size.width)
            descriptor.height = Int(size.height)
            descriptor.sampleCount = sampleCount
            descriptor.textureType = sampleCount > 1 ? .type2DMultisample : .type2D
            descriptor.usage = [.renderTarget, .shaderRead]
            descriptor.storageMode = .private
            descriptor.resourceOptions = .storageModePrivate
            stencilTexture = context.device.makeTexture(descriptor: descriptor)
            stencilTexture?.label = label + " Stencil Texture"
            updateStencilTexture = false
        } else {
            stencilTexture = nil
        }
    }

    func setupColorTexture() {
        guard updateColorTexture else { return }

        let sampleCount = context.sampleCount
        let colorPixelFormat = context.colorPixelFormat
        if colorPixelFormat != .invalid, size.width > 1, size.height > 1, sampleCount > 1 {
            let descriptor = MTLTextureDescriptor()
            descriptor.pixelFormat = colorPixelFormat
            descriptor.width = Int(size.width)
            descriptor.height = Int(size.height)
            descriptor.sampleCount = sampleCount
            descriptor.textureType = .type2DMultisample
            descriptor.usage = [.renderTarget, .shaderRead]
            descriptor.storageMode = .private
            descriptor.resourceOptions = .storageModePrivate
            colorTexture = context.device.makeTexture(descriptor: descriptor)
            colorTexture?.label = label + " Color Texture"
            updateColorTexture = false
        } else {
            colorTexture = nil
        }
    }

    // MARK: - Lights

    func updateLights() {
        setupLightDataBuffer()
        updateLightDataBuffer()
    }

    func setupLightDataBuffer() {
        guard lightList.count != lightDataBuffer?.count else { return }
        lightDataSubscriptions.removeAll(keepingCapacity: true)

        if lightList.isEmpty {
            lightDataBuffer = nil
        } else {
            for light in lightList {
                light.publisher.sink { [weak self] _ in
                    self?._updateLightDataBuffer = true
                }.store(in: &lightDataSubscriptions)
            }
            lightDataBuffer = StructBuffer<LightData>.init(
                device: context.device,
                count: lightList.count,
                label: "Light Data Buffer"
            )

            _updateLightDataBuffer = true
        }
    }

    func updateLightDataBuffer() {
        guard let lightBuffer = lightDataBuffer, _updateLightDataBuffer else { return }
        lightBuffer.update(data: lightList.map { $0.data })
        _updateLightDataBuffer = false
    }

    // MARK: - Shadows

    func updateShadows() {
        setupShadows()
        updateShadowMatricesBuffer()
        updateShadowArgumentEncoder()
    }

    func setupShadows() {
        guard shadowList.count != shadowMatricesBuffer?.count else { return }

        shadowMatricesSubscriptions.removeAll(keepingCapacity: true)
        shadowTextureSubscriptions.removeAll(keepingCapacity: true)

        if shadowList.isEmpty {
            shadowMatricesBuffer = nil
            shadowArgumentEncoder = nil
            shadowArgumentBuffer = nil
        } else {

            shadowMatricesBuffer = StructBuffer<simd_float4x4>.init(
                device: context.device,
                count: shadowList.count,
                label: "Shadow Matrices Buffer"
            )

            for light in lightList where light.castShadow {
                light.publisher.sink { [weak self] _ in
                    self?._updateShadowMatricesBuffer = true
                }.store(in: &shadowMatricesSubscriptions)
            }

            _updateShadowMatricesBuffer = true


            let desc = MTLArgumentDescriptor()
            desc.index = FragmentTextureIndex.Shadow0.rawValue
            desc.access = .readOnly
            desc.arrayLength = shadowList.count
            desc.dataType = .texture
            desc.textureType = .type2D
            if let shadowArgumentEncoder = context.device.makeArgumentEncoder(arguments: [desc]) {
                let shadowArgumentBuffer = context.device.makeBuffer(length: shadowArgumentEncoder.encodedLength, options: .storageModeShared)
                shadowArgumentBuffer?.label = "Shadow Argument Buffer"
                shadowArgumentEncoder.setArgumentBuffer(shadowArgumentBuffer, offset: 0)

                self.shadowArgumentBuffer = shadowArgumentBuffer
                self.shadowArgumentEncoder = shadowArgumentEncoder

                for (index, shadow) in shadowList.enumerated() {
                    shadowArgumentEncoder.setTexture(shadow.texture, index: FragmentTextureIndex.Shadow0.rawValue + index)
                }
            }

            for shadow in shadowList {
                shadow.publisher.sink { [weak self] _ in
                    self?._updateShadowArgumentEncoder = true
                }.store(in: &shadowTextureSubscriptions)
            }

            _updateShadowArgumentEncoder = true
        }
    }

    func updateShadowMatricesBuffer() {
        guard let shadowMatricesBuffer = shadowMatricesBuffer, _updateShadowMatricesBuffer else { return }
        shadowMatricesBuffer.update(data: shadowList.map { $0.camera.viewProjectionMatrix })
        _updateShadowMatricesBuffer = false
    }

    func updateShadowArgumentEncoder() {
        guard let shadowArgumentEncoder = shadowArgumentEncoder, _updateShadowArgumentEncoder else { return }
        for (index, shadow) in shadowList.enumerated() {
            shadowArgumentEncoder.setTexture(shadow.texture, index: FragmentTextureIndex.Shadow0.rawValue + index)
        }
        _updateShadowArgumentEncoder = false
    }
}
