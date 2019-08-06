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
    public var scene: Object = Object()
    public var camera: Camera = Camera()
    
    public var viewport: MTLViewport = MTLViewport()
    
    public init()
    {
        print("Renderer Setup")
    }
    
    public init(scene: Object, camera: Camera)
    {
        self.scene = scene
        self.camera = camera
    }
    
    public func update()
    {
        scene.update()
        camera.update()
    }
    
    public func draw(renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer)
    {
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        renderEncoder.setViewport(viewport)
        draw(renderEncoder: renderEncoder, commandBuffer: commandBuffer, object: scene)
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
        let width = Double(size.width)
        let height = Double(size.height)
        viewport = MTLViewport(originX: 0.0, originY: 0.0, width: width, height: height, znear: 0.0, zfar: 1.0)
    }
}
