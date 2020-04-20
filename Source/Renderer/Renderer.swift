//
//  Renderer.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal
import simd

open class Renderer
{
    public var preDraw: ((_ renderEncoder: MTLParallelRenderCommandEncoder) -> ())?
    public var postDraw: ((_ renderEncoder: MTLParallelRenderCommandEncoder) -> ())?
    
    public var scene: Object = Object()
    public var camera: Camera = Camera()
    public var context: Context?
    {
        didSet
        {
            scene.context = context
            updateColorTexture = true
            updateDepthTexture = true
            updateStencilTexture = true
        }
    }
    
    public var size: (width: Float, height: Float) = (0, 0)
    {
        didSet
        {
            let width = Double(size.width)
            let height = Double(size.height)
            viewport = MTLViewport(originX: 0.0, originY: 0.0, width: width, height: height, znear: 0.0, zfar: 1.0)
            
            updateColorTexture = true
            updateDepthTexture = true
            updateStencilTexture = true
        }
    }
    
    public var autoClearColor: Bool = true
    public var clearColor: MTLClearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)
    
    public var updateColorTexture: Bool = true
    public var colorTexture: MTLTexture?
    
    public var updateDepthTexture: Bool = true
    public var depthTexture: MTLTexture?
    
    public var depthLoadAction: MTLLoadAction = .clear
    public var depthStoreAction: MTLStoreAction = .dontCare
    public var clearDepth: Double = 1.0
    
    public var updateStencilTexture: Bool = true
    public var stencilTexture: MTLTexture?
    
    public var stencilLoadAction: MTLLoadAction = .clear
    public var stencilStoreAction: MTLStoreAction = .dontCare
    public var clearStencil: UInt32 = 0
    
    public var viewport: MTLViewport = MTLViewport()
    
    public init(context: Context,
                scene: Object,
                camera: Camera)
    {
        self.scene = scene
        self.camera = camera
        
        setContext(context)
    }
    
    public func setContext(_ context: Context)
    {
        self.context = context
    }
    
    public func update()
    {
        setupColorTexture()
        setupDepthTexture()
        setupStencilTexture()
        
        scene.update()
        camera.update()
    }
    
    public func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer, renderTarget: MTLTexture)
    {
        guard let context = self.context else { return }
        
        if context.sampleCount > 1
        {
            let resolveTexture = renderPassDescriptor.colorAttachments[0].resolveTexture
            renderPassDescriptor.colorAttachments[0].resolveTexture = renderTarget
            draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
            renderPassDescriptor.colorAttachments[0].resolveTexture = resolveTexture
        }
        else
        {
            let renderTexture = renderPassDescriptor.colorAttachments[0].texture
            renderPassDescriptor.colorAttachments[0].texture = renderTarget
            draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
            renderPassDescriptor.colorAttachments[0].texture = renderTexture
        }
    }
    
    public func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer)
    {
        guard let context = self.context else { return }
        
        let sampleCount = context.sampleCount
        let depthPixelFormat = context.depthPixelFormat
        
        renderPassDescriptor.colorAttachments[0].clearColor = clearColor
        renderPassDescriptor.colorAttachments[0].loadAction = autoClearColor ? .clear : .load
        renderPassDescriptor.colorAttachments[0].texture = sampleCount > 1 ? colorTexture : renderPassDescriptor.colorAttachments[0].texture
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
        else
        {
            renderPassDescriptor.depthAttachment.texture = nil
            renderPassDescriptor.stencilAttachment.texture = nil
        }
        
        guard let parellelRenderEncoder = commandBuffer.makeParallelRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
        parellelRenderEncoder.pushDebugGroup("Main Pass")
        parellelRenderEncoder.label = "Main Encoder"
        
        preDraw?(parellelRenderEncoder)
        draw(parellelRenderEncoder: parellelRenderEncoder, object: scene)
        postDraw?(parellelRenderEncoder)
        
        parellelRenderEncoder.popDebugGroup()
        parellelRenderEncoder.endEncoding()
    }
    
    public func draw(parellelRenderEncoder: MTLParallelRenderCommandEncoder, object: Object)
    {
        if object.context == nil
        {
            object.context = context
        }
                
        guard object.visible else { return }
        
        if object is Mesh, let mesh = object as? Mesh, let material = mesh.material, let pipeline = material.pipeline
        {
            mesh.update(camera: camera)
            
            guard let renderEncoder = parellelRenderEncoder.makeRenderCommandEncoder() else { return }
            let label = mesh.label
            
            renderEncoder.pushDebugGroup(label)
            
            renderEncoder.label = label
            renderEncoder.setViewport(viewport)
            renderEncoder.setRenderPipelineState(pipeline)
            
            material.bind(renderEncoder)
            
            mesh.draw(renderEncoder: renderEncoder)
            
            renderEncoder.popDebugGroup()
            
            renderEncoder.endEncoding()
        }
        
        for child in object.children
        {
            draw(parellelRenderEncoder: parellelRenderEncoder, object: child)
        }
    }
    
    public func resize(_ size: (width: Float, height: Float))
    {
        self.size = size
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
            depthTexture?.label = "Depth Texture"
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
            stencilTexture?.label = "Stencil Texture"
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
            colorTexture?.label = "Color Texture"
            updateColorTexture = false
        }
        else
        {
            colorTexture = nil
        }
    }
}
