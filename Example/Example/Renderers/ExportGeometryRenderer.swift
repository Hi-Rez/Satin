//
//  Renderer.swift
//  Example
//
//  Created by Reza Ali on 10/2/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit
import ModelIO

import Forge
import Satin

class ExportGeometryRenderer: BaseRenderer {
    lazy var material = BasicDiffuseMaterial(0.9)
    
    lazy var metal: Mesh = {
        let geo = ExtrudedTextGeometry(text: "SATIN", fontSize: 1, distance: 0.5)
        let mesh = Mesh(geometry: geo, material: material)
        mesh.position = [0, 0.25, 0]
        return mesh
    }()
    
    lazy var rocks: Mesh = {
        let mesh = Mesh(geometry: ExtrudedTextGeometry(text: "ROCKS", fontSize: 1, distance: 0.5),
                        material: material)
        mesh.position = [0, -0.75, 0]
        return mesh
    }()
    
    lazy var scene: Object = {
        let scene = Object()
        scene.add(metal)
        scene.add(rocks)
        scene.localMatrix = lookAtMatrix3f([0, 0, -1], [0, 1, 1], worldUpDirection)
        return scene
    }()
    
    lazy var context: Context = {
        Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }()
    
    var camera = PerspectiveCamera(position: [0, 0, 5], near: 0.001, far: 100.0)
    
    lazy var cameraController: PerspectiveCameraController = {
        PerspectiveCameraController(camera: camera, view: mtkView)
    }()
    
    lazy var renderer: Satin.Renderer = {
        Satin.Renderer(context: context, scene: scene, camera: camera)
    }()
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
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
    
    func exportObj(_ url: URL) {
        let allocator = MDLMeshBufferDataAllocator()
        let asset = MDLAsset(bufferAllocator: allocator)
        
        let meshes = getMeshes(scene, true, false)
        
        for mesh in meshes {
            guard let indexBuffer = mesh.geometry.indexBuffer else { continue }

            let geometry = mesh.geometry
    
            let vertexCount = geometry.vertexData.count
            let vertexStride = MemoryLayout<Vertex>.stride
    
            let indexCount = geometry.indexData.count
            let bytesPerIndex = MemoryLayout<UInt32>.size
    
            let byteCountVertices = vertexCount * vertexStride
            let byteCountFaces = indexCount * bytesPerIndex
    
            var vertexData: [Vertex] = []
            for var vertex in geometry.vertexData {
                vertex.position = mesh.worldMatrix * vertex.position
                vertexData.append(vertex)
            }
    
            vertexData.withUnsafeMutableBufferPointer { vertexPointer in
                let mdlVertexBuffer = allocator.newBuffer(with: Data(bytesNoCopy: vertexPointer.baseAddress!, count: byteCountVertices, deallocator: .none), type: .vertex)
                let mdlIndexBuffer = allocator.newBuffer(with: Data(bytesNoCopy: indexBuffer.contents(), count: byteCountFaces, deallocator: .none), type: .index)
    
                let submesh = MDLSubmesh(indexBuffer: mdlIndexBuffer, indexCount: geometry.indexData.count, indexType: .uInt32, geometryType: .triangles, material: nil)
    
                let mesh = MDLMesh(vertexBuffer: mdlVertexBuffer, vertexCount: geometry.vertexData.count, descriptor: SatinModelIOVertexDescriptor, submeshes: [submesh])
                asset.add(mesh)
            }
        }
        
        if MDLAsset.canExportFileExtension("obj") {
            print("can export objs")
            do {
                try asset.export(to: url)
            } catch {
                print(error.localizedDescription)
            }
        } else {
            fatalError("Can't export OBJ")
        }
    }

    #if os(macOS)
    override func keyDown(with event: NSEvent) {
        if event.characters == "s" {
            exportObj()
        }
    }
    
    func exportObj() {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.showsTagField = false
        panel.nameFieldStringValue = "test.obj"
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
        panel.begin { result in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue, let url = panel.url {
                self.exportObj(url)
            }
        }
    }
    #endif
}
