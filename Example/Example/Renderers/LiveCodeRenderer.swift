//
//  Renderer.swift
//  LiveCode-macOS
//
//  Created by Reza Ali on 6/1/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin

class LiveCodeRenderer: BaseRenderer {
    // Material names must not be the target name, i.e. LiveCodeMaterial won't work
    
    class CustomMaterial: LiveMaterial {}
    
    var startTime: CFAbsoluteTime = 0.0
    
    var assetsURL: URL { Bundle.main.resourceURL!.appendingPathComponent("Assets") }
    var rendererAssetsURL: URL { assetsURL.appendingPathComponent(String(describing: type(of: self))) }
    var pipelinesURL: URL { rendererAssetsURL.appendingPathComponent("Pipelines") }
    
    var camera = OrthographicCamera()
    
    lazy var mesh = Mesh(geometry: QuadGeometry(), material: CustomMaterial(pipelinesURL: pipelinesURL))
    lazy var scene = Object("Scene", [mesh])
    
    lazy var context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    lazy var renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .invalid
        metalKitView.preferredFramesPerSecond = 60
    }
    
    override func setup() {
        copySatinCore()
        copySatinLibrary()
        startTime = getTime()
        #if os(macOS)
        openEditor()
        #endif
    }
    
    func copySatinCore() {
        if let satinCore = getPipelinesSatinUrl() {
            do {
                try FileManager.default.copyItem(at: satinCore, to: assetsURL.appendingPathComponent("Satin"))
            }
            catch {
                print(error)
            }
        }
    }
    
    func copySatinLibrary() {
        if let satinLibrary = Satin.getPipelinesLibraryUrl() {
            do {
                try FileManager.default.copyItem(at: satinLibrary, to: assetsURL.appendingPathComponent("Library"))
            }
            catch {
                print(error)
            }
        }
    }

    override func update() {
        // Uniforms are parsed and title cases, i.e. time -> Time, appResolution -> App Resolution, etc
        if let material = mesh.material {
            material.set("Time", Float(getTime() - startTime))
        }
    }
    
    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        renderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
    }
    
    override func resize(_ size: (width: Float, height: Float)) {
        renderer.resize(size)
        if let material = mesh.material {
            let res = simd_make_float3(size.width, size.height, size.width / size.height)
            material.set("App Resolution", res)
        }
    }
    
    #if os(macOS)
    
    override func keyDown(with event: NSEvent) {
        if event.characters == "e" {
            openEditor()
        }
    }
    
    func openEditor() {
        if let editorURL = UserDefaults.standard.url(forKey: "Editor") {
            openEditor(at: editorURL)
        }
        else {
            let openPanel = NSOpenPanel()
            openPanel.canChooseFiles = true
            openPanel.allowsMultipleSelection = false
            openPanel.canCreateDirectories = false
            openPanel.begin(completionHandler: { [unowned self] (result: NSApplication.ModalResponse) in
                if result == .OK {
                    if let editorUrl = openPanel.url {
                        UserDefaults.standard.set(editorUrl, forKey: "Editor")
                        self.openEditor(at: editorUrl)
                    }
                }
                openPanel.close()
            })
        }
    }

    func openEditor(at editorURL: URL) {
        do {
            try NSWorkspace.shared.open([assetsURL], withApplicationAt: editorURL, options: [], configuration: [:])
        }
        catch {
            print(error)
        }
    }
    
    #endif
    
    func getTime() -> CFAbsoluteTime {
        return CFAbsoluteTimeGetCurrent()
    }
}
