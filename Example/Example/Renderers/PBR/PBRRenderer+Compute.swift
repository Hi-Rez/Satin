//
//  Renderer+IBL.swift
//  PBR-macOS
//
//  Created by Reza Ali on 6/12/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

import MetalKit
import Satin

extension PBRRenderer {
    func setupCompute(_ library: MTLLibrary, _ computeSystem: TextureComputeSystem, _ kernel: String) {
        do {
            let pipeline = try makeComputePipeline(library: library, kernel: kernel)
            computeSystem.updatePipeline = pipeline
            
            if let commandQueue = device.makeCommandQueue(), let commandBuffer = commandQueue.makeCommandBuffer() {
                computeSystem.update(commandBuffer)
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()
            }
        }
        catch {
            print(error)
        }
    }
    
    func setupSkyboxCompute(_ library: MTLLibrary) {
        do {
            let pipeline = try makeComputePipeline(library: library, kernel: "skyboxCompute")
            skyboxTextureCompute.updatePipeline = pipeline
            
            guard let cubemapTexture = skyboxCubeTexture else { return }
            let levels = cubemapTexture.mipmapLevelCount
            
            var size = cubemapTexture.width
            // Compute for each mipmap level in the Cubemap
            for level in 0..<levels {
                print("Skybox - Level: \(level) - Size: \(size)")
                
                // Setup Textures
                let desc = MTLTextureDescriptor.texture2DDescriptor(
                    pixelFormat: cubemapTexture.pixelFormat,
                    width: size,
                    height: size,
                    mipmapped: false
                )
                skyboxTextureCompute.textureDescriptors = Array(repeating: desc, count: 6)
                
                // Compute
                if let commandBuffer = commandQueue.makeCommandBuffer() {
                    skyboxTextureCompute.update(commandBuffer)
                    commandBuffer.commit()
                    commandBuffer.waitUntilCompleted()
                }
                
                // Copy textures to Cubemap
                for slice in 0..<6 {
                    if let commandBuffer = commandQueue.makeCommandBuffer() {
                        if let blitEncoder = commandBuffer.makeBlitCommandEncoder() {
                            blitEncoder.copy(
                                from: skyboxTextureCompute.texture[slice],
                                sourceSlice: 0,
                                sourceLevel: 0,
                                to: cubemapTexture,
                                destinationSlice: slice,
                                destinationLevel: level,
                                sliceCount: 1,
                                levelCount: 1
                            )
                            blitEncoder.endEncoding()
                        }
                        commandBuffer.commit()
                        commandBuffer.waitUntilCompleted()
                    }
                }
                size /= 2
            }
            print()
        }
        catch {
            print(error)
        }
    }
    
    func setupCubemapCompute(_ library: MTLLibrary) {
        do {
            let pipeline = try makeComputePipeline(library: library, kernel: "cubemapCompute")
            cubemapTextureCompute.updatePipeline = pipeline
            
            guard let cubemapTexture = hdrCubemapTexture else { return }
            let levels = cubemapTexture.mipmapLevelCount
            
            var size = cubemapTexture.width
            for level in 0..<levels {
                print("Cubemap - Level: \(level) - Size: \(size)")
                
                // Setup Textures
                let desc = MTLTextureDescriptor.texture2DDescriptor(
                    pixelFormat: .rgba16Float,
                    width: size,
                    height: size,
                    mipmapped: false
                )
                cubemapTextureCompute.textureDescriptors = Array(repeating: desc, count: 6)
                
                // Compute
                if let commandBuffer = commandQueue.makeCommandBuffer() {
                    cubemapTextureCompute.update(commandBuffer)
                    commandBuffer.commit()
                    commandBuffer.waitUntilCompleted()
                }
                
                for slice in 0..<6 {
                    if let commandBuffer = commandQueue.makeCommandBuffer() {
                        if let blitEncoder = commandBuffer.makeBlitCommandEncoder() {
                            blitEncoder.copy(
                                from: cubemapTextureCompute.texture[slice],
                                sourceSlice: 0,
                                sourceLevel: 0,
                                to: cubemapTexture,
                                destinationSlice: slice,
                                destinationLevel: level,
                                sliceCount: 1,
                                levelCount: 1
                            )
                            
                            blitEncoder.endEncoding()
                        }
                        commandBuffer.commit()
                        commandBuffer.waitUntilCompleted()
                    }
                }
                size /= 2
            }
            print()
        }
        catch {
            print(error)
        }
    }
    
    func setupDiffuseCompute(_ library: MTLLibrary) {
        do {
            let pipeline = try makeComputePipeline(library: library, kernel: "diffuseCompute")
            diffuseTextureCompute.updatePipeline = pipeline
            
            guard let cubemapTexture = diffuseCubeTexture else { return }
            let levels = cubemapTexture.mipmapLevelCount
            
            var size = cubemapTexture.width
            for level in 0..<levels {
                print("Diffuse - Level: \(level) - Size: \(size)")
                
                // Setup Textures
                let desc = MTLTextureDescriptor.texture2DDescriptor(
                    pixelFormat: .rgba16Float,
                    width: size,
                    height: size,
                    mipmapped: false
                )
                diffuseTextureCompute.textureDescriptors = Array(repeating: desc, count: 6)
                
                // Compute
                if let commandBuffer = commandQueue.makeCommandBuffer() {
                    diffuseTextureCompute.update(commandBuffer)
                    commandBuffer.commit()
                    commandBuffer.waitUntilCompleted()
                }
                
                // Copy textures to cubemap
                for slice in 0..<6 {
                    if let commandBuffer = commandQueue.makeCommandBuffer() {
                        if let blitEncoder = commandBuffer.makeBlitCommandEncoder() {
                            blitEncoder.copy(
                                from: diffuseTextureCompute.texture[slice],
                                sourceSlice: 0,
                                sourceLevel: 0,
                                to: cubemapTexture,
                                destinationSlice: slice,
                                destinationLevel: level,
                                sliceCount: 1,
                                levelCount: 1
                            )
                            blitEncoder.endEncoding()
                        }
                        commandBuffer.commit()
                        commandBuffer.waitUntilCompleted()
                    }
                }
                size /= 2
            }
            print()
        }
        catch {
            print(error)
        }
    }
    
    func setupSpecularCompute(_ library: MTLLibrary) {
        do {
            let pipeline = try makeComputePipeline(library: library, kernel: "specularCompute")
            specularTextureCompute.updatePipeline = pipeline
            
            guard let cubeTexture = specularCubeTexture else { return }
            let levels = cubeTexture.mipmapLevelCount
            
            var size = cubeTexture.width
            for level in 0..<levels {
                print("Specular - Level: \(level) - Size: \(size)")
                
                // Update Uniforms Per Level
                roughnessParameter.value = Float(level) / Float(levels - 1)
                specularTextureComputeUniforms.update()
                
                // Setup Textures
                let desc = MTLTextureDescriptor.texture2DDescriptor(
                    pixelFormat: .rgba16Float,
                    width: size,
                    height: size,
                    mipmapped: false
                )
                specularTextureCompute.textureDescriptors = Array(repeating: desc, count: 6)
                
                // Compute
                if let commandBuffer = commandQueue.makeCommandBuffer() {
                    specularTextureCompute.update(commandBuffer)
                    commandBuffer.commit()
                    commandBuffer.waitUntilCompleted()
                }
                
                // Copy textures to Cubemap
                for slice in 0..<6 {
                    if let commandBuffer = commandQueue.makeCommandBuffer() {
                        if let blitEncoder = commandBuffer.makeBlitCommandEncoder() {
                            blitEncoder.copy(
                                from: specularTextureCompute.texture[slice],
                                sourceSlice: 0,
                                sourceLevel: 0,
                                to: cubeTexture,
                                destinationSlice: slice,
                                destinationLevel: level,
                                sliceCount: 1,
                                levelCount: 1
                            )
                            blitEncoder.endEncoding()
                        }
                        commandBuffer.commit()
                        commandBuffer.waitUntilCompleted()
                    }
                }
                size /= 2
            }
            print()
        }
        catch {
            print(error)
        }
    }
}
