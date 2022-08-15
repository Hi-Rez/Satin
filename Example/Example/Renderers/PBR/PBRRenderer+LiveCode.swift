//
//  Renderer+LiveCode.swift
//  PBR-macOS
//
//  Created by Reza Ali on 6/12/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

import Satin

extension PBRRenderer {
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
            var librarySource = try metalFileCompiler.parse(pipelinesURL.appendingPathComponent("Compute/Shaders.metal"))
            injectConstants(source: &librarySource)
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
