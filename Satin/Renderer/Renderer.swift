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
    public var context: Context?
    {
        didSet
        {
            updateColorTexture = true
            updateDepthTexture = true
            updateStencilTexture = true
            if let context = self.context
            {
                scene.context = context
            }
        }
    }
    
    public var autoClearColor: Bool = true
    public var clearColor: MTLClearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)
    
    public var updateColorTexture: Bool = true
    public var colorTexture: MTLTexture?
    
    public var updateDepthTexture: Bool = true
    public var depthTexture: MTLTexture?
    public var depthLoadAction: MTLLoadAction = .clear
    public var depthStoreAction: MTLStoreAction = .store
    public var clearDepth: Double = 1.0
    
    public var updateStencilTexture: Bool = true
    public var stencilTexture: MTLTexture?
    public var stencilLoadAction: MTLLoadAction = .clear
    public var stencilStoreAction: MTLStoreAction = .store
    public var clearStencil: UInt32 = 0
    
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
    
    public init(context: Context,
                scene: Object,
                camera: Camera)
    {
        self.context = context
        self.scene = scene
        self.camera = camera
        self.scene.context = context
    }
    
    public func update()
    {
        setupColorTexture()
        
        setupDepthTexture()
        
        setupStencilTexture()
        
        scene.update()
        camera.update()
    }
    
    public func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer)
    {
        guard let context = self.context else { return }
        
        let sampleCount = context.sampleCount
        let depthPixelFormat = context.depthPixelFormat
        
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
        
        guard let parellelRenderEncoder = commandBuffer.makeParallelRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
        draw(parellelRenderEncoder: parellelRenderEncoder, renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer, object: scene)
        
        parellelRenderEncoder.endEncoding()
    }
    
    public func draw(parellelRenderEncoder: MTLParallelRenderCommandEncoder, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer, object: Object)
    {
        guard let renderEncoder = parellelRenderEncoder.makeRenderCommandEncoder() else { return }
        renderEncoder.setViewport(viewport)
        
        if object is Mesh, let mesh = object as? Mesh
        {
            preDraw?(renderEncoder)
            mesh.update(camera: camera)
            mesh.draw(renderEncoder: renderEncoder)
            postDraw?(renderEncoder)
        }
        
        renderEncoder.endEncoding()
        
        for child in object.children
        {
            draw(parellelRenderEncoder: parellelRenderEncoder, renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer, object: child)
        }
    }
    
    public func resize(_ size: (width: Float, height: Float))
    {
        self.size = size
        
        let width = Double(size.width)
        let height = Double(size.height)
        
        viewport = MTLViewport(originX: 0.0, originY: 0.0, width: width, height: height, znear: 0.0, zfar: 1.0)
    }
    
    public func setupDepthTexture()
    {
        guard let context = self.context, updateDepthTexture else { return }
        let sampleCount = context.sampleCount
        let depthPixelFormat = context.depthPixelFormat
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
            depthTexture = context.device.makeTexture(descriptor: descriptor)
            updateDepthTexture = false
        }
        else
        {
            depthTexture = nil
        }
    }
    
    public func setupStencilTexture()
    {
        guard let context = self.context, updateStencilTexture else { return }
        let sampleCount = context.sampleCount
        let stencilPixelFormat = context.stencilPixelFormat
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
            stencilTexture = context.device.makeTexture(descriptor: descriptor)
            updateStencilTexture = false
        }
        else
        {
            stencilTexture = nil
        }
    }
    
    public func setupColorTexture()
    {
        guard let context = self.context, updateColorTexture else { return }
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
            updateColorTexture = false
        }
        else
        {
            colorTexture = nil
        }
    }
}
