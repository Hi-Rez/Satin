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

    private var shadowList = [LightShadow]()
    private var _updateShadowMatricesBuffer = false
    private var shadowMatricesBuffer: StructBuffer<simd_float4x4>?
    private var shadowMatricesSubscriptions = Set<AnyCancellable>()

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
        for light in lightList where light.castShadow {
            light.shadow.draw(commandBuffer: commandBuffer, renderables: renderList)
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
        for renderable in renderables where renderable.drawable {
            _encode(renderEncoder: renderEncoder, renderable: renderable, camera: camera)
        }

        postDraw?(renderEncoder)
        renderEncoder.popDebugGroup()
    }

    func _encode(renderEncoder: MTLRenderCommandEncoder, renderable: Renderable, camera: Camera) {
        renderEncoder.pushDebugGroup(renderable.label)

        // TO DO: Ideally we should set the maxLights & shadowCount before we set the context for the object
        // that way we avoid compiling the material twice

        if let material = renderable.material {
            if material.lighting, let lightBuffer = lightDataBuffer {
                renderEncoder.setFragmentBuffer(
                    lightBuffer.buffer,
                    offset: lightBuffer.offset,
                    index: FragmentBufferIndex.Lighting.rawValue
                )
            }

            if material.receiveShadow, let shadowBuffer = shadowMatricesBuffer {
                renderEncoder.setVertexBuffer(
                    shadowBuffer.buffer,
                    offset: shadowBuffer.offset,
                    index: VertexBufferIndex.ShadowMatrices.rawValue
                )

                for (index, light) in lightList.enumerated() where light.castShadow {
                    material.shader?.shadowArgumentEncoder?.setTexture(light.shadow.texture, index: FragmentTextureIndex.Shadow0.rawValue + index)

                    if let shadowTexture = light.shadow.texture {
                        renderEncoder.useResource(shadowTexture, usage: .read)
                    }
                }

                renderEncoder.setFragmentBuffer(material.shader?.shadowArgumentBuffer, offset: 0, index: FragmentBufferIndex.Shadows.rawValue)
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
        guard !lightList.isEmpty, lightList.count != lightDataBuffer?.count else { return }

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
        setupShadowMatricesBuffer()
        updateShadowMatricesBuffer()
    }

    func setupShadowMatricesBuffer() {
        guard !shadowList.isEmpty, shadowList.count != shadowMatricesBuffer?.count else { return }

        shadowMatricesSubscriptions.removeAll(keepingCapacity: true)

        if shadowList.isEmpty {
            shadowMatricesBuffer = nil
        } else {
            for light in lightList where light.castShadow {
                light.publisher.sink { [weak self] _ in
                    self?._updateShadowMatricesBuffer = true
                }.store(in: &shadowMatricesSubscriptions)
            }

            shadowMatricesBuffer = StructBuffer<simd_float4x4>.init(
                device: context.device,
                count: shadowList.count,
                label: "Shadow Matrices Buffer"
            )
            _updateShadowMatricesBuffer = true
        }
    }

    func updateShadowMatricesBuffer() {
        guard let shadowMatricesBuffer = shadowMatricesBuffer, _updateShadowMatricesBuffer else { return }
        shadowMatricesBuffer.update(data: shadowList.map { $0.camera.viewProjectionMatrix })
        _updateShadowMatricesBuffer = false
    }

    // MARK: - Compile

    public func compile(scene: Object, camera: Camera) {
        _compile(object: scene, camera: camera)
    }

    func _compile(object: Object, camera: Camera) {
        object.context = context
        for child in object.children {
            _compile(object: child, camera: camera)
        }
    }
}
