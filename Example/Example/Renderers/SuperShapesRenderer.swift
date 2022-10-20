//
//  SuperShapesRenderer.swift
//  Example
//
//  Created by Reza Ali on 8/18/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import Combine
import Metal
import MetalKit

import Forge
import Satin

class SuperShapesRenderer: BaseRenderer {
    var cancellables = Set<AnyCancellable>()
    
    var updateGeometry = true

    var wireframe: Bool = false {
        didSet {
            mesh.triangleFillMode = wireframe ? .lines : .fill
        }
    }
    
    var resParam = IntParameter("Resolution", 300, 3, 300, .slider)
    var r1Param = FloatParameter("R1", 1.0, 0, 2, .inputfield)
    var a1Param = FloatParameter("A1", 1.0, 0.0, 5.0, .slider)
    var b1Param = FloatParameter("B1", 1.0, 0.0, 5.0, .slider)
    var m1Param = FloatParameter("M1", 10, 0, 20, .slider)
    var n11Param = FloatParameter("N11", 1.087265, 0.0, 100.0, .slider)
    var n21Param = FloatParameter("N21", 0.938007, 0.0, 100.0, .slider)
    var n31Param = FloatParameter("N31", -0.615898, 0.0, 100.0, .slider)
    var r2Param = FloatParameter("R2", 0.984062, 0, 2, .slider)
    var a2Param = FloatParameter("A2", 1.513944, 0.0, 5.0, .slider)
    var b2Param = FloatParameter("B2", 0.642890, 0.0, 5.0, .slider)
    var m2Param = FloatParameter("M2", 5.225158, 0, 20, .slider)
    var n12Param = FloatParameter("N12", 1.0, 0.0, 100.0, .slider)
    var n22Param = FloatParameter("N22", 1.371561, 0.0, 100.0, .slider)
    var n32Param = FloatParameter("N32", 0.651718, 0.0, 100.0, .slider)

    var parameters: ParameterGroup!
    
    var mesh = Mesh(geometry: Geometry(), material: BasicDiffuseMaterial(0.7))
    
    lazy var camera: PerspectiveCamera = {
        let camera = PerspectiveCamera(position: simd_make_float3(2.0, 1.0, 4.0), near: 0.001, far: 200.0)
        camera.lookAt(.zero)
        return camera
    }()
    
    lazy var scene = Object("Scene", [mesh])
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var cameraController = PerspectiveCameraController(camera: camera, view: mtkView)
    lazy var renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
        
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.isPaused = false
        metalKitView.sampleCount = 4
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
    }
    
    override init() {
        super.init()
        setupParameters()
        setupObservers()
    }
    
    override func setup() {
        mesh.cullMode = .none
    }
    
    func setupParameters() {
        parameters = ParameterGroup("Shape Controls", [
            resParam,
            r1Param,
            a1Param,
            b1Param,
            m1Param,
            n11Param,
            n21Param,
            n31Param,
            r2Param,
            a2Param,
            b2Param,
            m2Param,
            n12Param,
            n22Param,
            n32Param
        ])
    }
        
    func setupGeometry() {
        let res = Int32(resParam.value)
        var geoData = generateSuperShapeGeometryData(
            r1Param.value,
            a1Param.value,
            b1Param.value,
            m1Param.value,
            n11Param.value,
            n21Param.value,
            n31Param.value,
            r2Param.value,
            a2Param.value,
            b2Param.value,
            m2Param.value,
            n12Param.value,
            n22Param.value,
            n32Param.value,
            res, res)
        mesh.geometry = Geometry(&geoData)
        freeGeometryData(&geoData)
    }
    
    func setupObservers() {
        for param in parameters.params {
            if let p = param as? FloatParameter {
                p.$value.sink { [weak self] _ in
                    self?.updateGeometry = true
                }.store(in: &cancellables)
            }
            else if let p = param as? IntParameter {
                p.$value.sink { [weak self] _ in
                    self?.updateGeometry = true
                }.store(in: &cancellables)
            }
        }
    }
    
    override func update() {
        if updateGeometry {
            setupGeometry()
            updateGeometry = false
        }
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
