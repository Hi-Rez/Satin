//
//  PostProcessor.swift
//  Satin
//
//  Created by Reza Ali on 4/16/20.
//

import Metal

open class PostProcessor {
    public var label: String = "Post" {
        didSet {
            renderer.label = label + " Renderer"
            mesh.label = label + " Mesh"
            scene.label = label + " Scene"
        }
    }
    
    public var context: Context!
    public lazy var scene = Object("Scene", [mesh])
    public var mesh = Mesh(geometry: QuadGeometry(), material: nil)
    public var camera = OrthographicCamera(left: -1, right: 1, bottom: -1, top: 1, near: -1, far: 1)
    
    public lazy var renderer: Renderer = {
        let renderer = Renderer(context: context)
        renderer.setClearColor([1, 1, 1, 0])
        return renderer
    }()
    
    public init(context: Context, material: Material?) {
        self.context = context
        mesh.material = material
        renderer.label = label + " Processor"
        mesh.label = label + " Mesh"
    }
    
    open func draw(renderPassDescriptor: MTLRenderPassDescriptor,
                   commandBuffer: MTLCommandBuffer, renderTarget: MTLTexture)
    {
        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera,
            renderTarget: renderTarget
        )
    }
    
    open func draw(renderPassDescriptor: MTLRenderPassDescriptor,
                   commandBuffer: MTLCommandBuffer)
    {
        renderer.draw(
            renderPassDescriptor: renderPassDescriptor,
            commandBuffer: commandBuffer,
            scene: scene,
            camera: camera
        )
    }
    
    open func resize(_ size: (width: Float, height: Float)) {
        renderer.resize(size)
    }
}
