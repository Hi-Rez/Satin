//
//  Renderer.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal

open class Renderer
{
    public var preDraw: ((_ renderEncoder: MTLRenderCommandEncoder) -> ())?
    public var postDraw: ((_ renderEncoder: MTLRenderCommandEncoder) -> ())?
    
    public var scene: Object = Object()
    public var camera: Camera = Camera()
    
    public var autoClearColor: Bool = true
    public var clearColor: MTLClearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)
    
    public var updateColorTexture: Bool = true
    public var colorPixelFormat: MTLPixelFormat = .bgra8Unorm_srgb
    public var colorTexture: MTLTexture?
    
    public var updateDepthStencilState: Bool = true
    public var depthStencilState: MTLDepthStencilState?
    
    public var updateDepthTexture: Bool = true
    public var depthPixelFormat: MTLPixelFormat = .depth32Float_stencil8
    public var depthTexture: MTLTexture?
    public var depthLoadAction: MTLLoadAction = .clear
    public var depthStoreAction: MTLStoreAction = .store
    public var clearDepth: Double = 1.0
    
    public var updateStencilTexture: Bool = true
    public var stencilPixelFormat: MTLPixelFormat = .depth32Float_stencil8
    public var stencilTexture: MTLTexture?
    public var stencilLoadAction: MTLLoadAction = .clear
    public var stencilStoreAction: MTLStoreAction = .store
    public var clearStencil: UInt32 = 0
    
    public var sampleCount: Int = 1 {
        didSet
        {
            updateColorTexture = true
            updateDepthTexture = true
            updateStencilTexture = true
        }
    }
    
    public var size: (width: Float, height: Float) = (0, 0)
    {
        didSet
        {
            updateColorTexture = true
            updateDepthTexture = true
            updateStencilTexture = true
        }
    }
    
    public var viewport: MTLViewport = MTLViewport()
    
    public init() {}
    
    public init(scene: Object,
                camera: Camera,
                sampleCount: Int = 1,
                colorPixelFormat: MTLPixelFormat = .bgra8Unorm_srgb,
                depthPixelFormat: MTLPixelFormat = .depth32Float_stencil8,
                stencilPixelFormat: MTLPixelFormat = .depth32Float_stencil8)
    {
        self.sampleCount = sampleCount
        self.colorPixelFormat = colorPixelFormat
        self.depthPixelFormat = depthPixelFormat
        self.stencilPixelFormat = stencilPixelFormat
        
        self.scene = scene
        self.camera = camera
    }
    
    public func update(_ commandBuffer: MTLCommandBuffer)
    {
        let device = commandBuffer.device
        
        if updateColorTexture
        {
            setupColorTexture(device)
            updateColorTexture = false
        }
        
        if updateDepthStencilState
        {
            setupDepthStencilState(device)
            updateDepthStencilState = false
        }
        
        if updateDepthTexture
        {
            setupDepthTexture(device)
            updateDepthTexture = false
        }
        
        if updateStencilTexture
        {
            setupStencilTexture(device)
            updateStencilTexture = false
        }
    }
    
    public func update()
    {
        scene.update()
        camera.update()
    }
    
    public func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer)
    {
        update(commandBuffer)
        
        renderPassDescriptor.colorAttachments[0].clearColor = clearColor
        
        if autoClearColor
        {
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
        }
        else
        {
            renderPassDescriptor.colorAttachments[0].loadAction = .load
        }
        
        if sampleCount > 1 {
            renderPassDescriptor.colorAttachments[0].texture = colorTexture
        }
        else
        {
            renderPassDescriptor.colorAttachments[0].resolveTexture = nil
        }
        
        renderPassDescriptor.colorAttachments[0].storeAction = sampleCount > 1 ? .storeAndMultisampleResolve : .store
        
        if let depthTexture = self.depthTexture
        {
            renderPassDescriptor.depthAttachment.texture = depthTexture
            renderPassDescriptor.depthAttachment.loadAction = depthLoadAction
            renderPassDescriptor.depthAttachment.storeAction = depthStoreAction
            renderPassDescriptor.depthAttachment.clearDepth = clearDepth
#if os(macOS)
            if depthPixelFormat == .depth32Float_stencil8
            {
                renderPassDescriptor.stencilAttachment.texture = depthTexture
            }
            else if let stencilTexture = self.stencilTexture
            {
                renderPassDescriptor.stencilAttachment.texture = stencilTexture
                renderPassDescriptor.stencilAttachment.loadAction = stencilLoadAction
                renderPassDescriptor.stencilAttachment.storeAction = stencilStoreAction
                renderPassDescriptor.stencilAttachment.clearStencil = clearStencil
            }
#elseif os(iOS) || os(tvOS)
            if depthPixelFormat == .depth32Float_stencil8
            {
                renderPassDescriptor.stencilAttachment.texture = depthTexture
            }
            else if let stencilTexture = self.stencilTexture
            {
                renderPassDescriptor.stencilAttachment.texture = stencilTexture
                renderPassDescriptor.stencilAttachment.loadAction = stencilLoadAction
                renderPassDescriptor.stencilAttachment.storeAction = stencilStoreAction
                renderPassDescriptor.stencilAttachment.clearStencil = clearStencil
            }
#endif
        }
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
        if let depthStencilState = self.depthStencilState
        {
            renderEncoder.setDepthStencilState(depthStencilState)
        }
        
        renderEncoder.setViewport(viewport)
        
        preDraw?(renderEncoder)
        
        draw(renderEncoder: renderEncoder, commandBuffer: commandBuffer, object: scene)
        
        postDraw?(renderEncoder)
        
        renderEncoder.endEncoding()
    }
    
    public func draw(renderEncoder: MTLRenderCommandEncoder, commandBuffer: MTLCommandBuffer, object: Object)
    {
        if object is Mesh, let mesh = object as? Mesh
        {
            mesh.update(camera: camera)
            mesh.draw(renderEncoder: renderEncoder)
        }
        
        for child in object.children
        {
            draw(renderEncoder: renderEncoder, commandBuffer: commandBuffer, object: child)
        }
    }
    
    public func resize(_ size: (width: Float, height: Float))
    {
        self.size = size
        
        let width = Double(size.width)
        let height = Double(size.height)
        
        viewport = MTLViewport(originX: 0.0, originY: 0.0, width: width, height: height, znear: 0.0, zfar: 1.0)
    }
    
    public func setupDepthStencilState(_ device: MTLDevice)
    {
        if depthPixelFormat != .invalid
        {
            let depthStateDesciptor = MTLDepthStencilDescriptor()
            depthStateDesciptor.depthCompareFunction = MTLCompareFunction.less
            depthStateDesciptor.isDepthWriteEnabled = true
            guard let state = device.makeDepthStencilState(descriptor: depthStateDesciptor) else { return }
            depthStencilState = state
        }
    }
    
    public func setupDepthTexture(_ device: MTLDevice)
    {
        if depthPixelFormat != .invalid, size.width > 1, size.height > 1
        {
            let descriptor = MTLTextureDescriptor()
            descriptor.pixelFormat = depthPixelFormat
            descriptor.width = Int(size.width)
            descriptor.height = Int(size.height)
            descriptor.sampleCount = sampleCount
            descriptor.textureType = sampleCount > 1 ? .type2DMultisample : .type2D
            descriptor.usage = [.renderTarget, .shaderRead]
            descriptor.storageMode = .private
            descriptor.resourceOptions = .storageModePrivate
            depthTexture = device.makeTexture(descriptor: descriptor)
        }
        else
        {
            depthTexture = nil
        }
    }
    
    public func setupStencilTexture(_ device: MTLDevice)
    {
        if stencilPixelFormat != .invalid, size.width > 1, size.height > 1
        {
            let descriptor = MTLTextureDescriptor()
            descriptor.pixelFormat = stencilPixelFormat
            descriptor.width = Int(size.width)
            descriptor.height = Int(size.height)
            descriptor.sampleCount = sampleCount
            descriptor.textureType = sampleCount > 1 ? .type2DMultisample : .type2D
            descriptor.usage = [.renderTarget, .shaderRead]
            descriptor.storageMode = .private
            descriptor.resourceOptions = .storageModePrivate
            stencilTexture = device.makeTexture(descriptor: descriptor)
        }
        else
        {
            stencilTexture = nil
        }
    }
    
    public func setupColorTexture(_ device: MTLDevice)
    {
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
            colorTexture = device.makeTexture(descriptor: descriptor)
        }
        else
        {
            colorTexture = nil
        }
    }
}
