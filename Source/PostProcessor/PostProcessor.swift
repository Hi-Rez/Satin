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
            mesh.label = label + " Mesh"
        }
    }
    
    public var context: Context!
    
    public lazy var mesh: Mesh = {
        let mesh = Mesh(geometry: QuadGeometry(), material: nil)
        mesh.label = label + " Mesh"
        return mesh
    }()
    
    var camera = OrthographicCamera(left: -1, right: 1, bottom: -1, top: 1, near: -1, far: 1)
    
    public lazy var renderer: Renderer = {
        let renderer = Satin.Renderer(context: context, scene: mesh, camera: camera)
        renderer.autoClearColor = true
        return renderer
    }()
    
    public init(context: Context) {
        self.context = context
    }
    
    public func update() {
        camera.update()
        renderer.update()
    }
    
    public func draw(renderPassDescriptor: MTLRenderPassDescriptor,
                     commandBuffer: MTLCommandBuffer, renderTarget: MTLTexture) {
        renderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer,
                      renderTarget: renderTarget)
    }
    
    public func draw(renderPassDescriptor: MTLRenderPassDescriptor,
                     commandBuffer: MTLCommandBuffer) {
        renderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
    }
    
    public func resize(_ size: (width: Float, height: Float)) {
        renderer.resize(size)
    }
}
