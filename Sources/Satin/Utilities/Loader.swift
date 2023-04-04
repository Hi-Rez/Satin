//
//  USDZLoader.swift
//  Satin
//
//  Created by Reza Ali on 4/3/23.
//

import Foundation
import Metal
import MetalKit
import ModelIO

func loadAsset(
    device: MTLDevice? = MTLCreateSystemDefaultDevice(),
    url: URL,
    vertexDescriptor: MDLVertexDescriptor = SatinModelIOVertexDescriptor(),
    loadTextures: Bool = true
) -> Object? {
    guard let device = device else { return nil }

    let asset = MDLAsset(
        url: url,
        vertexDescriptor: vertexDescriptor,
        bufferAllocator: MTKMeshBufferAllocator(device: device)
    )

    if loadTextures { asset.loadTextures() }

    let textureLoader = MTKTextureLoader(device: device)
    let fileName = url.lastPathComponent.replacingOccurrences(of: url.pathExtension, with: "")
    let container = Object(fileName)

    for i in 0 ..< asset.count {
        let mdlObject = asset.object(at: i)
        let stnObject = Object(mdlObject.name)
        container.add(stnObject)
        if let transform = mdlObject.transform {
            stnObject.localMatrix = transform.matrix
        }
        loadAssetChildren(device: device, parent: stnObject, children: mdlObject.children.objects, textureLoader: textureLoader)
    }

    return container
}

func loadAssetChildren(device: MTLDevice, parent: Object, children: [MDLObject], textureLoader: MTKTextureLoader) {
    for child in children {
        if let mdlMesh = child as? MDLMesh {
            print("loading: \(child.name)")
            
            let geometry = Geometry()
            
            if let descriptor = MTKMetalVertexDescriptorFromModelIO(mdlMesh.vertexDescriptor) {
                geometry.vertexDescriptor = descriptor
            }

            let mesh = Mesh(geometry: geometry, material: nil)
            mesh.label = child.name

            let vertexData = mdlMesh.vertexBuffers[0].map().bytes.bindMemory(to: Vertex.self, capacity: mdlMesh.vertexCount)
            geometry.vertexData = Array(UnsafeBufferPointer(start: vertexData, count: mdlMesh.vertexCount))

            for i in 0 ..< mdlMesh.vertexBuffers.count {
                geometry.setBuffer((mdlMesh.vertexBuffers[i] as! MTKMeshBuffer).buffer, type: .init(rawValue: i)!)
            }

            if let mdlSubMeshes = mdlMesh.submeshes {
                let mdlSubMeshesCount = mdlSubMeshes.count
                for index in 0 ..< mdlSubMeshesCount {
                    let mdlSubmesh = mdlSubMeshes[index] as! MDLSubmesh
                    if mdlSubmesh.geometryType == .triangles, let mdlMaterial = mdlSubmesh.material {
                        let indexCount = mdlSubmesh.indexCount
                        let indexDataPtr = mdlSubmesh.indexBuffer(asIndexType: .uInt32).map().bytes.bindMemory(to: UInt32.self, capacity: indexCount)
                        let indexData = Array(UnsafeBufferPointer(start: indexDataPtr, count: indexCount))
                        let submesh = Submesh(
                            parent: mesh,
                            indexData: indexData,
                            indexBuffer: (mdlSubmesh.indexBuffer as! MTKMeshBuffer).buffer,
                            material: PhysicalMaterial(material: mdlMaterial, textureLoader: textureLoader)
                        )
                        submesh.label = mdlSubmesh.name
                        mesh.addSubmesh(submesh)
                    }
                    else {
                        print("something went wrong: \(child.name)")
                    }
                }
            }
            else {
                print("doesn't have a submesh: \(child.name)")
            }

            if let transform = mdlMesh.transform {
                mesh.localMatrix = transform.matrix
            }
            parent.add(mesh)
            loadAssetChildren(device: device, parent: mesh, children: child.children.objects, textureLoader: textureLoader)
        } else {
            let object = Object(child.name)
            if let transform = child.transform {
                object.localMatrix = transform.matrix
            }
            parent.add(object)
            loadAssetChildren(device: device, parent: object, children: child.children.objects, textureLoader: textureLoader)
        }
    }
}
