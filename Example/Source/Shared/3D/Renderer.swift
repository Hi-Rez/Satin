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

class Renderer: Forge.Renderer {
    var scene = Object()
    
    lazy var context: Context = {
        Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }()
    
    lazy var camera: ArcballPerspectiveCamera = {
        let camera = ArcballPerspectiveCamera()
//        camera.position = simd_make_float3(35.0, 10.0, 100.0)
        camera.position = simd_make_float3(15.0, 15.0, 60.0)
//        camera.position = simd_make_float3(0.0, 0.0, 10.0)
        camera.near = 0.001
        camera.far = 1000.0
        return camera
    }()
    
    lazy var cameraController: ArcballCameraController = {
        ArcballCameraController(camera: camera, view: mtkView, defaultPosition: camera.position, defaultOrientation: camera.orientation)
    }()
    
    lazy var renderer: Satin.Renderer = {
        let renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
        renderer.clearColor = .init(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        return renderer
    }()
    
    required init?(metalKitView: MTKView) {
        super.init(metalKitView: metalKitView)
    }
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
    }
    
    func setupQuadraticBezier(size: Float) {
        let a = simd_float2(-size * 0.125, size * 0.5)
        let b = simd_float2(0.0, size)
        let c = simd_float2(size * 0.125, 0.0)
        
        let geometry = Geometry()
        geometry.primitiveType = .lineStrip
        
        let times = stride(from: 0.0, through: 1.0, by: 0.0125)
        
        for time in times {
            let p = quadraticBezier2(Float(time), a, b, c)
            geometry.vertexData.append(Vertex(position: [p.x, p.y, 0.0, 1.0], normal: [0.0, 0.0, 1.0], uv: [0.0, 0.0]))
        }
        
        let mesh = Mesh(geometry: geometry, material: BasicPointMaterial([1.0, 0.0, 0.0, 1.0], 4.0, .alpha))
        scene.add(mesh)
        
        let geo = Geometry()
        geo.primitiveType = .point
        
        let points = getPointsAdaptive(a, b, c)
        
        for pt in points {
            geo.vertexData.append(Vertex(position: [pt.x, pt.y, 0.0, 1.0], normal: [0.0, 0.0, 1.0], uv: [0.0, 0.0]))
        }
        
        let pmesh = Mesh(geometry: geo, material: BasicPointMaterial([0.0, 1.0, 0.0, 1.0], 4.0, .alpha))
        scene.add(pmesh)
    }
    
    func setupCubicBezier(_ a: simd_float2, _ b: simd_float2, _ c: simd_float2, _ d: simd_float2, size: Float) {
        let geometry = Geometry()
        geometry.primitiveType = .lineStrip
        
        let times = stride(from: 0.0, through: 1.0, by: 0.005)
        
        for time in times {
            let p = cubicBezier2(Float(time), a, b, c, d)
            geometry.vertexData.append(Vertex(position: [p.x, p.y, 0.0, 1.0], normal: [0.0, 0.0, 1.0], uv: [0.0, 0.0]))
        }
        
        let mesh = Mesh(geometry: geometry, material: BasicPointMaterial([1.0, 0.0, 0.0, 1.0], 4.0, .alpha))
        mesh.label = "bezier"
        scene.add(mesh)
        
        let points = getPointsAdaptive(a, b, c, d)
        
        let geo = Geometry()
        geo.primitiveType = .point
        
        for pt in points {
            geo.vertexData.append(Vertex(position: [pt.x, pt.y, 0.0, 1.0], normal: [0.0, 0.0, 1.0], uv: [0.0, 0.0]))
        }
        let pmesh = Mesh(geometry: geo, material: BasicPointMaterial([0.0, 1.0, 1.0, 1.0], 8.0, .alpha))
        pmesh.label = "bezier points"
        scene.add(pmesh)
        
        let geoLines = Geometry()
        geoLines.primitiveType = .lineStrip
        geoLines.vertexData = geo.vertexData
        let lmesh = Mesh(geometry: geoLines, material: BasicColorMaterial(simd_make_float4(1.0, 1.0, 1.0, 1.0)))
        lmesh.label = "bezier line"
        scene.add(lmesh)
    }
    
    func getPoints(_ a: simd_float2, _ b: simd_float2, _ c: simd_float2) -> [simd_float2] {
        var pts: [simd_float2] = []
        let times = stride(from: 0.0, through: 1.0, by: 0.05)
        for time in times {
            let pt = quadraticBezier2(Float(time), a, b, c)
            pts.append(pt)
        }
        return pts
    }
    
    func getPointsAdaptive(_ a: simd_float2, _ b: simd_float2, _ c: simd_float2) -> [simd_float2] {
        var pts: [simd_float2] = [a]
        adaptiveQuadratic(a, b, c, &pts, 0)
        pts.append(c)
        print(pts)
        return pts
    }
    
    func getPointsAdaptive(_ a: simd_float2, _ b: simd_float2, _ c: simd_float2, _ d: simd_float2) -> [simd_float2] {
        var pts: [simd_float2] = [a]
        adaptiveCubic(a, b, c, d, &pts, 0)
        pts.append(d)
        print(pts)
        return pts
    }
    
    override func setup() {
//        print(pointLineDistance2([0.0, -1.0], [0.0, 1.0], [-2.0, 0.0]))
//        print(pointLineDistance2([0.0, -1.0], [0.0, 1.0], [-2.0, 0.0]))
        
//        let a = simd_make_float2(0.0, 0.0)
//        let b = simd_make_float2(1.0, 2.0)
//        let c = simd_make_float2(3.0, 3.0)
//        let d = simd_make_float2(5.0, 2.0)
        
//        let a = simd_make_float2(0.0, 0.0)
//        let b = simd_make_float2(1.0, 0.0)
//        let c = simd_make_float2(3.0, 0.0)
//        let d = simd_make_float2(5.0, 0.0)
        
//        let a = simd_make_float2(0.0, 0.0)
//        let b = simd_make_float2(2.0, -1.0)
//        let c = simd_make_float2(4.0, 0.0)
//        let d = simd_make_float2(6.0, -1.0)
        
//        let a = simd_make_float2(0.0, 0.0)
//        let b = simd_make_float2(20.0, 0.0)
//        let c = simd_make_float2(0.0, 20.0)
//        let d = simd_make_float2(20.0, 20.0)
        
//        let a = simd_make_float2(1.0, 1.0)
//        let b = simd_make_float2(3.0, 2.0)
//        let c = simd_make_float2(2.0, 2.0)
//        let d = simd_make_float2(2.0, 1.0)
        
//        let a = simd_float2(0.86, -1.13)
//        let b = simd_float2(7.01, 0.14)
//        let c = simd_float2(1.47, 8.18)
//        let d = simd_float2(-3.53, -0.85)
        
//        let a = simd_float2(-2.3, -2.8)
//        let b = simd_float2(5.1, 6.92)
//        let c = simd_float2(-5.6, 7.18)
//        let d = simd_float2(3.94, -2.71)
//
//        setupQuadraticBezier(size: 10)
//        setupCubicBezier(a, b, c, d, size: 1)
        setupText()
//        setupTriangulationTest()
//        setupTriangulationHoleTest()
        
//        setupPathTest()
    }
    
    func setupTriangulationHoleTest() {
        var outerPts: [simd_float2] = [
            [0.8506447672843933, -0.6180340051651001], // 0
            [0.8506447672843933, 0.6180340051651001], // 1
            [-0.32492363452911377, 1], // 2
            [-1.0514626502990723, 0], // 3
            [-0.32492363452911377, -1] // 4
        ]
        
        let scale: Float = 0.7
        var innerPts: [simd_float2] = [
            outerPts[0] * scale,
            outerPts[4] * scale,
            outerPts[3] * scale,
            outerPts[2] * scale,
            outerPts[1] * scale
        ]
        
        var dotPts: [simd_float2] = []
        let offset = simd_make_float2(3.0, 0.0)
        for pt in outerPts {
            dotPts.append(pt + offset)
        }
        
        let geo = Geometry()
        geo.primitiveType = .triangle
        for pt in outerPts {
            geo.vertexData.append(Vertex(position: [10.0 * pt.x, 10.0 * pt.y, 0.0, 1.0], normal: [0.0, 0.0, 1.0], uv: [1.0, 1.0]))
        }
        for pt in innerPts {
            geo.vertexData.append(Vertex(position: [10.0 * pt.x, 10.0 * pt.y, 0.0, 1.0], normal: [0.0, 0.0, 1.0], uv: [1.0, 1.0]))
        }
        for pt in dotPts {
            geo.vertexData.append(Vertex(position: [10.0 * pt.x, 10.0 * pt.y, 0.0, 1.0], normal: [0.0, 0.0, 1.0], uv: [1.0, 1.0]))
        }
        
        var paths: [UnsafeMutablePointer<simd_float2>?] = []
        
        outerPts.withUnsafeMutableBufferPointer { ptr in
            paths.append(ptr.baseAddress!)
        }
        
        innerPts.withUnsafeMutableBufferPointer { ptr in
            paths.append(ptr.baseAddress!)
        }
        
        dotPts.withUnsafeMutableBufferPointer { ptr in
            paths.append(ptr.baseAddress!)
        }
        
        var lengths: [Int32] = [Int32(outerPts.count), Int32(innerPts.count), Int32(dotPts.count)]
        var result = GeometryData(vertexCount: 0, vertexData: nil, indexCount: 0, indexData: nil)
        triangulate(&paths, &lengths, Int32(lengths.count), &result)
        
//        let result = triangulateWithHoles(&outerPts, Int32(outerPts.count), &innerPts, Int32(innerPts.count))
        
        print("indexCount: \(Int(result.indexCount))")
        let indexCount = Int(result.indexCount) * 3
        if indexCount > 0, let data = result.indexData {
            data.withMemoryRebound(to: UInt32.self, capacity: indexCount) { ptr in
                geo.indexData = Array(UnsafeBufferPointer(start: ptr, count: indexCount))
            }
        }
        
        freeGeometryData(result)
        
        let pmat = BasicPointMaterial([1, 1, 1, 1], 12, .alpha)
        pmat.depthWriteEnabled = false
        let geoPoints = Geometry()
        geoPoints.primitiveType = .point
        geoPoints.vertexData = geo.vertexData
        let pmesh = Mesh(geometry: geoPoints, material: pmat)
        pmesh.label = "Points"
        scene.add(pmesh)
        
        let fmat = BasicColorMaterial([0, 0, 1, 1], .alpha)
        fmat.depthWriteEnabled = false
        let fmesh = Mesh(geometry: geo, material: fmat)
        fmesh.label = "Triangles"
        scene.add(fmesh)
//
        let mat = BasicColorMaterial([0, 1, 0, 1], .additive)
        mat.depthWriteEnabled = false
        mat.depthStencilState = nil
        let lmesh = Mesh(geometry: geo, material: mat)
        lmesh.triangleFillMode = .lines
        lmesh.label = "Lines"
        scene.add(lmesh)
    }
    
    func setupTriangulationTest() {
        var pts: [simd_float2] = [
            [0.8506447672843933, -0.6180340051651001], // 0
            [0.8506447672843933, 0.6180340051651001], // 1
            [-0.32492363452911377, 1], // 2
            [-1.0514626502990723, 0], // 3
            [-0.32492363452911377, -1] // 4
        ]
        
        let geo = Geometry()
        geo.primitiveType = .triangle
        for pt in pts {
            geo.vertexData.append(Vertex(position: [10.0 * pt.x, 10.0 * pt.y, 0.0, 1.0], normal: [0.0, 0.0, 1.0], uv: [1.0, 1.0]))
        }
        
        var paths: [UnsafeMutablePointer<simd_float2>?] = []
        var lengths: [Int32] = []
        
        pts.withUnsafeMutableBufferPointer { ptr in
            paths.append(ptr.baseAddress)
        }
        lengths.append(Int32(pts.count))
        
        var result = GeometryData(vertexCount: 0, vertexData: nil, indexCount: 0, indexData: nil)
        triangulate(&paths, &lengths, Int32(lengths.count), &result)
        
        let indexCount = Int(result.indexCount) * 3
        if indexCount > 0, let data = result.indexData {
            data.withMemoryRebound(to: UInt32.self, capacity: indexCount) { ptr in
                geo.indexData = Array(UnsafeBufferPointer(start: ptr, count: indexCount))
            }
        }
        
        freeGeometryData(result)
        
        let pmat = BasicPointMaterial([0, 1, 0, 1], 8, .additive)
        pmat.depthWriteEnabled = false
        let mesh = Mesh(geometry: geo, material: pmat)
        mesh.triangleFillMode = .lines
        scene.add(mesh)
        
        let fmat = BasicColorMaterial([1, 1, 1, 0.1], .additive)
        fmat.depthWriteEnabled = false
        let fmesh = Mesh(geometry: geo, material: fmat)
        scene.add(fmesh)
    }
    
    func setupText() {
        let geo = TextGeometry()
        
        let mat = BasicColorMaterial([1.0, 1.0, 1.0, 1.0])
        mat.depthWriteEnabled = false
        let mesh = Mesh(geometry: geo, material: mat)
        scene.add(mesh)
                
        let pGeo = Geometry()
        pGeo.vertexData = geo.vertexData
        pGeo.primitiveType = .point
        let pmat = BasicPointMaterial([0, 1, 1, 1.0], 5, .alpha)
        pmat.depthWriteEnabled = false
        let pmesh = Mesh(geometry: pGeo, material: pmat)
        scene.add(pmesh)
        
        let fmat = BasicColorMaterial([1, 0, 1, 0.125], .alpha)
        fmat.depthWriteEnabled = false
        let fmesh = Mesh(geometry: geo, material: fmat)
        fmesh.triangleFillMode = .lines
        scene.add(fmesh)
    }
    
    override func update() {
        cameraController.update()
        renderer.update()
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
