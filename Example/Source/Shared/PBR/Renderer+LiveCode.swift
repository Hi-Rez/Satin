//
//  Renderer+LiveCode.swift
//  PBR-macOS
//
//  Created by Reza Ali on 6/12/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

import Satin

extension Renderer {
    func setupMetalCompiler() {
        metalFileCompiler.onUpdate = { [unowned self] in
            self.setupLibrary()
        }
    }
    
    // MARK: Setup Library
    
    func setupLibrary() {
        print("Compiling Library")
        do {
            let librarySource = try metalFileCompiler.parse(pipelinesURL.appendingPathComponent("Compute/Shaders.metal"))
            let library = try context.device.makeLibrary(source: librarySource, options: .none)
            setupSkyboxCompute(library)
            setupCubemapCompute(library)
            setupCompute(library, integrationTextureCompute, "integrationCompute")
            setupDiffuseCompute(library)
            setupSpecularCompute(library)
        }
        catch let MetalFileCompilerError.invalidFile(fileURL) {
            print("Invalid File: \(fileURL.absoluteString)")
        }
        catch {
            print("Error: \(error)")
        }
    }
}
