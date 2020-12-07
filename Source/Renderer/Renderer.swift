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
    public var label: String = "Satin Renderer"
    
    public var preDraw: ((_ renderEncoder: MTLRenderCommandEncoder) -> ())?
    public var postDraw: ((_ renderEncoder: MTLRenderCommandEncoder) -> ())?
    
    public var scene = Object()
    {
        didSet
        {
            if let context = self.context
            {
                scene.context = context
            }
        }
    }
    
    public var camera = Camera()
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
    
    public var clearColor: MTLClearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)
    
    public var updateColorTexture: Bool = true
    public var colorTexture: MTLTexture?
    public var colorLoadAction: MTLLoadAction = .clear
    public var colorStoreAction: MTLStoreAction = .store
    
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
    
    public var viewport = MTLViewport()
    
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
    
    public func setClearColor(_ color: simd_float4)
    {
        clearColor = .init(red: Double(color.x), green: Double(color.y), blue: Double(color.z), alpha: Double(color.w))
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
        camera.update()
        scene.update()
        
        guard let context = self.context, scene.visible else { return }
        
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
            if depthPixelFormat == .depth32Float_stencil8
            {
                renderPassDescriptor.stencilAttachment.texture = depthTexture
            }
        }
        
        // Set Stencil Texture
        
        if inStencilTexture?.sampleCount != sampleCount || inStencilTexture?.pixelFormat != stencilPixelFormat
        {
            setupStencilTexture()
            if depthPixelFormat == .depth32Float_stencil8
            {
                renderPassDescriptor.stencilAttachment.texture = depthTexture
            }
            else
            {
                renderPassDescriptor.stencilAttachment.texture = stencilTexture
            }
        }
        
        if sampleCount > 1
        {
            if colorStoreAction == .store || colorStoreAction == .storeAndMultisampleResolve
            {
                renderPassDescriptor.colorAttachments[0].storeAction = .storeAndMultisampleResolve
            }
            else
            {
                renderPassDescriptor.colorAttachments[0].storeAction = .multisampleResolve
            }
        }
        else
        {
            if colorStoreAction == .store || colorStoreAction == .storeAndMultisampleResolve
            {
                renderPassDescriptor.colorAttachments[0].storeAction = .store
            }
            else
            {
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
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        renderEncoder.pushDebugGroup(label + " Pass")
        renderEncoder.label = label + " Encoder"
        renderEncoder.setViewport(viewport)
        
        preDraw?(renderEncoder)
        draw(renderEncoder: renderEncoder, object: scene)
        postDraw?(renderEncoder)        
        
        renderEncoder.popDebugGroup()
        renderEncoder.endEncoding()
        
        renderPassDescriptor.colorAttachments[0].texture = inColorTexture
        renderPassDescriptor.colorAttachments[0].resolveTexture = inColorResolveTexture
        renderPassDescriptor.depthAttachment.texture = inDepthTexture
        renderPassDescriptor.stencilAttachment.texture = inStencilTexture
    }
    
    public func draw(renderEncoder: MTLRenderCommandEncoder, object: Object)
    {
        if object.context == nil
        {
            object.context = context
        }
        
        if object is Mesh, let mesh = object as? Mesh, let material = mesh.material, let pipeline = material.pipeline
        {
            mesh.update(camera: camera)
            renderEncoder.setRenderPipelineState(pipeline)
            material.bind(renderEncoder)
            mesh.draw(renderEncoder: renderEncoder)
        }
        
        for child in object.children
        {
            if child.visible
            {
                let label = child.label
                renderEncoder.pushDebugGroup(label)
                draw(renderEncoder: renderEncoder, object: child)
                renderEncoder.popDebugGroup()
            }
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
            depthTexture?.label = label + " Depth Texture"
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
            stencilTexture?.label = label + " Stencil Texture"
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
        if colorPixelFormat != .invalid, size.width > 1, size.height > 1, sampleCount > 1
        {
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
        }
        else
        {
            colorTexture = nil
        }
    }
}
