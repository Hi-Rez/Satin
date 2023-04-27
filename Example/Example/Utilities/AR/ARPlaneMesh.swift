//
//  ARPlaneContainer.swift
//  Example
//
//  Created by Reza Ali on 4/26/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

#if os(iOS)

import ARKit
import Foundation
import Metal
import Satin

class ARPlaneMesh: Mesh {
    public var anchor: ARPlaneAnchor {
        didSet {
            updateAnchor()
        }
    }

    public init(label: String, anchor: ARPlaneAnchor, material: Satin.Material) {
        self.anchor = anchor
        super.init(geometry: Geometry(), material: material)
        self.label = label
    }

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    private func updateAnchor() {
        updateTransform()
        updateGeometry()
    }

    private func updateTransform() {
        worldMatrix = anchor.transform
    }

    private func updateGeometry() {
        let vertices = anchor.geometry.vertices
        let uvs = anchor.geometry.textureCoordinates
        var verts = [Vertex]()
        let normal = anchor.alignment == .horizontal ? Satin.worldUpDirection : Satin.worldForwardDirection
        for (vert, uv) in zip(vertices, uvs) {
            verts.append(Vertex(position: .init(vert, 1), normal: normal, uv: uv))
        }
        let indices = anchor.geometry.triangleIndices.map { UInt32($0) }
        geometry.vertexData = verts
        geometry.indexData = indices
    }
}

#endif
