//
//  Renderer.swift
//  Example Shared
//
//  Created by Reza Ali on 8/22/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import CoreGraphics
import CoreText

import Metal
import MetalKit

import Forge
import Satin

class TextRenderer: BaseRenderer {
    var scene = Object()
    
    lazy var context: Context = {
        Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }()
    
    lazy var camera: PerspectiveCamera = {
        let camera = PerspectiveCamera()
        camera.position = simd_make_float3(0.0, 0.0, 40.0)
        camera.near = 0.001
        camera.far = 1000.0
        return camera
    }()
    
    lazy var cameraController: PerspectiveCameraController = {
        PerspectiveCameraController(camera: camera, view: mtkView)
    }()
    
    lazy var renderer: Satin.Renderer = {
        let renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
        renderer.clearColor = .init(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        return renderer
    }()
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
    }
    
    override func setup() {
        setupText()
    }
    
    func setupText() {
        let input = "BLACK\nLIVES\nMATTER"
        
        /*
         Times
         AvenirNext-UltraLight
         Helvetica
         SFMono-HeavyItalic
         SFProRounded-Thin
         SFProRounded-Heavy
         */
        
        let geo = TextGeometry(text: input, fontName: "SFProRounded-Heavy", fontSize: 8)
        
        let mat = BasicColorMaterial([1.0, 1.0, 1.0, 0.125], .additive)
        mat.depthWriteEnabled = false
        let mesh = Mesh(geometry: geo, material: mat)
        scene.add(mesh)
                
        let pGeo = Geometry()
        pGeo.vertexData = geo.vertexData
        pGeo.primitiveType = .point
        let pmat = BasicPointMaterial([1, 1, 1, 0.5], 6, .alpha)
        pmat.depthWriteEnabled = false
        let pmesh = Mesh(geometry: pGeo, material: pmat)
        scene.add(pmesh)
        
        let fmat = BasicColorMaterial([1, 1, 1, 0.025], .additive)
        fmat.depthWriteEnabled = false
        let fmesh = Mesh(geometry: geo, material: fmat)
        fmesh.triangleFillMode = .lines
        scene.add(fmesh)
    }
    
    override func update() {
        cameraController.update()
    }
    
    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        renderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
    }
    
    override func resize(_ size: (width: Float, height: Float)) {
        camera.aspect = size.width / size.height
        renderer.resize(size)
    }
}
