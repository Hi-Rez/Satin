//
//  Renderer.swift
//  Example
//
//  Created by Reza Ali on 6/11/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin

class Renderer: Forge.Renderer {
    var metalFileCompiler = MetalFileCompiler()
    lazy var textureCompute: TextureComputeSystem = {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.width = 512
        textureDescriptor.height = 512
        textureDescriptor.depth = 1
        textureDescriptor.pixelFormat = .bgra8Unorm
        textureDescriptor.resourceOptions = .storageModePrivate
        textureDescriptor.sampleCount = 1
        textureDescriptor.textureType = .type2D
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        let textureCompute = TextureComputeSystem(device: device, textureDescriptors: [textureDescriptor])
        return textureCompute
    }()
    
    var assetsURL: URL {
        let resourcesURL = Bundle.main.resourceURL!
        return resourcesURL.appendingPathComponent("Assets")
    }
    
    var pipelinesURL: URL {
        return assetsURL.appendingPathComponent("Pipelines")
    }
    
    lazy var mesh: Mesh = {
        Mesh(geometry: BoxGeometry(), material: nil)
    }()
    
    lazy var scene: Object = {
        let scene = Object()
        scene.add(mesh)
        return scene
    }()
    
    lazy var context: Context = {
        Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }()
    
    lazy var camera: PerspectiveCamera = {
        let camera = PerspectiveCamera()
        camera.position = simd_make_float3(0.0, 0.0, 9.0)
        camera.near = 0.001
        camera.far = 100.0
        return camera
    }()
    
    lazy var cameraController: PerspectiveCameraController = {
        PerspectiveCameraController(camera: camera, view: mtkView)
    }()
    
    lazy var renderer: Satin.Renderer = {
        Satin.Renderer(context: context, scene: scene, camera: camera)
    }()
    
    #if os(macOS) || os(iOS)
    lazy var raycaster: Raycaster = {
        Raycaster(device: device)
    }()
    #endif
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
    }
    
    override func setup() {
        setupMetalCompiler()
        setupLibrary()
    }
    
    func setupTextureCompute(_ library: MTLLibrary) {
        do {
            let pipeline = try makeComputePipeline(library: library, kernel: "updateCompute")
            textureCompute.updatePipeline = pipeline
            if let commandBuffer = commandQueue.makeCommandBuffer() {
                textureCompute.update(commandBuffer)
                commandBuffer.commit()
                mesh.material = BasicTextureMaterial(texture: textureCompute.texture.first)
            }
        }
        catch {
            print(error)
        }
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
    
    func setupMetalCompiler() {
        metalFileCompiler.onUpdate = { [weak self] in
            guard let self = self else { return }
            self.setupLibrary()
        }
    }
    
    // MARK: Setup Library
    
    func setupLibrary() {
        print("Compiling Library")
        do {
            let librarySource = try metalFileCompiler.parse(pipelinesURL.appendingPathComponent("Shaders.metal"))
            let library = try context.device.makeLibrary(source: librarySource, options: .none)
            setupTextureCompute(library)
        }
        catch let MetalFileCompilerError.invalidFile(fileURL) {
            print("Invalid File: \(fileURL.absoluteString)")
        }
        catch {
            print("Error: \(error)")
        }
    }
    
    #if os(macOS)
    func openEditor() {
        if let editorPath = UserDefaults.standard.string(forKey: "Editor") {
            NSWorkspace.shared.openFile(assetsURL.path, withApplication: editorPath)
        }
        else {
            let openPanel = NSOpenPanel()
            openPanel.canChooseFiles = true
            openPanel.allowsMultipleSelection = false
            openPanel.canCreateDirectories = false
            openPanel.begin(completionHandler: { [unowned self] (result: NSApplication.ModalResponse) in
                if result == .OK {
                    if let editorUrl = openPanel.url {
                        let editorPath = editorUrl.path
                        UserDefaults.standard.set(editorPath, forKey: "Editor")
                        NSWorkspace.shared.openFile(self.assetsURL.path, withApplication: editorPath)
                    }
                }
                openPanel.close()
            })
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if event.characters == "e" {
            openEditor()
        }
    }
    #endif
}
