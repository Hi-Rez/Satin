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
        }
    }
    
    public var context: Context!
    
    public lazy var scene: Object = {
        let scene = Object()
        scene.add(mesh)
        return scene
    }()
    
    public lazy var mesh: Mesh = {
        Mesh(geometry: QuadGeometry(), material: nil)
    }()
    
    lazy var camera: OrthographicCamera = {
        OrthographicCamera(left: -1, right: 1, bottom: -1, top: 1, near: -1, far: 1)
    }()
    
    lazy var renderer: Renderer = {
        let renderer = Renderer(context: context, scene: scene, camera: camera)
        renderer.autoClearColor = false
        return renderer
    }()
    
    public init(context: Context, material: Material?) {
        self.context = context
        mesh.material = material
        renderer.label = label + " Processor"
        mesh.label = label + " Mesh"
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
