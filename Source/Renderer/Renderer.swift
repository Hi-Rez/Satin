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
            if let context = self.context
            {
                scene.context = context
            }
            
            updateColorTexture = true
            updateDepthTexture = true
            updateStencilTexture = true
            updateShadowTexture = true
            updateShadowMaterial = true
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
            updateShadowTexture = true
        }
    }
    
    var lightViewMatrix: matrix_float4x4 = matrix_identity_float4x4
    var lightProjectionMatrix: matrix_float4x4 = matrix_identity_float4x4
    
    var light = Object()
    public var lightPosition: simd_float3 = simd_make_float3(0.0, 10.0, 0.0)
    {
        didSet
        {
            setupLight()
        }
    }
    
    public var lightDirection: simd_float3 = simd_make_float3(0.0, -1.0, 0.0)
    {
        didSet
        {
            setupLight()
        }
    }
    
    var shadowMatrix: matrix_float4x4 = matrix_identity_float4x4
    var updateShadowMaterial = true
    var shadowMaterial: ShadowMaterial?
    public var enableShadows: Bool = true
    var updateShadowTexture: Bool = true
    var shadowTexture: MTLTexture?
    var shadowPipelineState: MTLRenderPipelineState?
    let shadowRenderPassDescriptor = MTLRenderPassDescriptor()
    
    var uniformBufferIndex: Int = 0
    var uniformBufferOffset: Int = 0
    var shadowUniforms: UnsafeMutablePointer<ShadowUniforms>!
    var shadowUniformsBuffer: MTLBuffer!
    
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
        
        setup()
    }
    
    public func setup()
    {
        setupLight()
        setupShadowUniformBuffer()
        updateShadowUniforms()
    }
    
    func setupLight()
    {
        light.position = lightPosition
        light.lookat(lightDirection)
        lightViewMatrix = lookAt(light.position, light.position + light.forwardDirection, light.upDirection)
        lightProjectionMatrix = orthographic(left: -10, right: 10, bottom: -10, top: 10, near: -10, far: 20)
        shadowMatrix = lightProjectionMatrix * lightViewMatrix
    }
    
    func setupShadowUniformBuffer()
    {
        guard let context = self.context else { return }
        let device = context.device
        let alignedUniformsSize = ((MemoryLayout<ShadowUniforms>.size + 255) / 256) * 256
        let uniformBufferSize = alignedUniformsSize * Satin.maxBuffersInFlight
        guard let buffer = device.makeBuffer(length: uniformBufferSize, options: [MTLResourceOptions.storageModeShared]) else { return }
        shadowUniformsBuffer = buffer
        shadowUniformsBuffer.label = "Shadow Uniforms"
        shadowUniforms = UnsafeMutableRawPointer(shadowUniformsBuffer.contents()).bindMemory(to: ShadowUniforms.self, capacity: 1)
    }
    
    func updateShadowUniforms()
    {
        if shadowUniforms != nil
        {
            shadowUniforms[0].shadowMatrix = shadowMatrix
        }
    }
    
    func updateShadowUniformsBuffer()
    {
        if shadowUniformsBuffer != nil
        {
            uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight
            let alignedUniformsSize = ((MemoryLayout<ShadowUniforms>.size + 255) / 256) * 256
            uniformBufferOffset = alignedUniformsSize * uniformBufferIndex
            shadowUniforms = UnsafeMutableRawPointer(shadowUniformsBuffer.contents() + uniformBufferOffset).bindMemory(to: ShadowUniforms.self, capacity: 1)
        }
    }
    
    public func setContext(_ context: Context)
    {
        self.context = context
        scene.context = context
    }
    
    public func update()
    {
        setupColorTexture()
        setupDepthTexture()
        setupStencilTexture()
        setupShadowTexture()
        setupShadowMaterial()
        
        scene.update()
        camera.update()
        
        updateShadowUniformsBuffer()
    }
    
    public func drawShadows(parellelRenderEncoder: MTLParallelRenderCommandEncoder, object: Object)
    {
        if object is Mesh, let mesh = object as? Mesh, let material = shadowMaterial
        {
            guard let renderEncoder = parellelRenderEncoder.makeRenderCommandEncoder() else { return }
            
            var pipeline: MTLRenderPipelineState!
            if let meshShadowMaterial = mesh.shadowMaterial, let shadowPipeline = meshShadowMaterial.pipeline
            {
                pipeline = shadowPipeline
            }
            else if let shadowPipeline = material.pipeline
            {
                pipeline = shadowPipeline
            }
            
            let label = mesh.label
            
            renderEncoder.pushDebugGroup(label)
            renderEncoder.label = label
            renderEncoder.setViewport(viewport)
            
            mesh.update(camera: camera)
            
            renderEncoder.setRenderPipelineState(pipeline)
            
            material.bind(renderEncoder)
            
            renderEncoder.setDepthBias(0.01, slopeScale: 1.0, clamp: 0.01)
            renderEncoder.setCullMode(.front)
            renderEncoder.setVertexBuffer(shadowUniformsBuffer, offset: uniformBufferOffset, index: VertexBufferIndex.ShadowUniforms.rawValue)
            
            mesh.draw(renderEncoder: renderEncoder)
            
            renderEncoder.popDebugGroup()
            renderEncoder.endEncoding()
        }
        
        for child in object.children
        {
            drawShadows(parellelRenderEncoder: parellelRenderEncoder, object: child)
        }
    }
    
    public func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer, renderTarget: MTLTexture)
    {
        if let context = self.context, context.sampleCount > 1
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
        
        if enableShadows
        {
            guard let parellelRenderEncoder = commandBuffer.makeParallelRenderCommandEncoder(descriptor: shadowRenderPassDescriptor) else { return }
            
            parellelRenderEncoder.pushDebugGroup("Shadow Pass")
            parellelRenderEncoder.label = "Shadow Encoder"
            
            updateShadowUniforms()
            
            drawShadows(parellelRenderEncoder: parellelRenderEncoder, object: scene)
            
            parellelRenderEncoder.popDebugGroup()
            parellelRenderEncoder.endEncoding()
        }
        
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
        else {
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
        if object is Mesh, let mesh = object as? Mesh, let material = mesh.material, let pipeline = material.pipeline
        {
            mesh.update(camera: camera)
            
            if mesh.visible
            {
                guard let renderEncoder = parellelRenderEncoder.makeRenderCommandEncoder() else { return }
                let label = mesh.label
                
                renderEncoder.pushDebugGroup(label)
                renderEncoder.label = label
                renderEncoder.setViewport(viewport)
                
                renderEncoder.setRenderPipelineState(pipeline)
                
                if enableShadows
                {
                    material.shadowTexture = shadowTexture
                    renderEncoder.setFragmentTexture(shadowTexture, index: FragmentTextureIndex.Shadow.rawValue)
                }
                
                material.bind(renderEncoder)
                
                renderEncoder.setVertexBuffer(shadowUniformsBuffer, offset: uniformBufferOffset, index: VertexBufferIndex.ShadowUniforms.rawValue)
                
                mesh.draw(renderEncoder: renderEncoder)
                
                renderEncoder.popDebugGroup()
                renderEncoder.endEncoding()
            }
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
    
    public func setupShadowMaterial()
    {
        if updateShadowMaterial, enableShadows
        {
            guard let context = self.context else { return }
            let shadowMaterial = ShadowMaterial(simd_make_float4(0.0, 0.0, 0.0, 1.0))
            shadowMaterial.context = Context(context.device, context.sampleCount, .invalid, context.depthPixelFormat, .invalid)
            self.shadowMaterial = shadowMaterial
            updateShadowMaterial = false
        }
    }
    
    public func setupShadowTexture()
    {
        guard let context = self.context, updateShadowTexture else { return }
        let sampleCount = context.sampleCount
        let depthPixelFormat = context.depthPixelFormat
        if depthPixelFormat != .invalid, size.width > 1, size.height > 1
        {
            let descriptor = MTLTextureDescriptor()
            descriptor.pixelFormat = depthPixelFormat
            descriptor.width = Int(size.width)
            descriptor.height = Int(size.height)
            descriptor.sampleCount = 1
            descriptor.textureType = .type2D
            descriptor.usage = [.shaderRead, .renderTarget]
            descriptor.storageMode = .private
            descriptor.resourceOptions = .storageModePrivate
            
            shadowTexture = context.device.makeTexture(descriptor: descriptor)
            shadowTexture?.label = "Shadow Texture"
            
            if sampleCount > 1 {
                let descriptor = MTLTextureDescriptor()
                descriptor.pixelFormat = depthPixelFormat
                descriptor.width = Int(size.width)
                descriptor.height = Int(size.height)
                descriptor.sampleCount = sampleCount
                descriptor.textureType = .type2DMultisample
                descriptor.usage = [.renderTarget]
                descriptor.storageMode = .private
                descriptor.resourceOptions = .storageModePrivate
                let shadowMultisampleTexture = context.device.makeTexture(descriptor: descriptor)
                shadowMultisampleTexture?.label = "Shadow Multisample Texture"
                shadowRenderPassDescriptor.depthAttachment.texture = shadowMultisampleTexture
                shadowRenderPassDescriptor.depthAttachment.resolveTexture = shadowTexture
            }
            else
            {
                shadowRenderPassDescriptor.depthAttachment.texture = shadowTexture
                shadowRenderPassDescriptor.depthAttachment.resolveTexture = nil
            }
            
            shadowRenderPassDescriptor.depthAttachment.loadAction = .clear
            shadowRenderPassDescriptor.depthAttachment.storeAction = sampleCount > 1 ? .storeAndMultisampleResolve : .store
            shadowRenderPassDescriptor.depthAttachment.clearDepth = 1.0
            
            updateShadowTexture = false
        }
        else
        {
            shadowTexture = nil
        }
    }
}
