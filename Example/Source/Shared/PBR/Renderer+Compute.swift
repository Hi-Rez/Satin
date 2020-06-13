//
//  Renderer+IBL.swift
//  PBR-macOS
//
//  Created by Reza Ali on 6/12/20.
//  Copyright © 2020 Hi-Rez. All rights reserved.
//

import MetalKit
import Satin

extension Renderer {
    func setupCompute(_ library: MTLLibrary, _ computeSystem: TextureComputeSystem, _ kernel: String) {
        do {
            let pipeline = try makeComputePipeline(library: library, kernel: kernel)
            computeSystem.updatePipeline = pipeline
            
            if let commandQueue = self.device.makeCommandQueue(), let commandBuffer = commandQueue.makeCommandBuffer() {
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
            
            guard let cubemapTexture = self.skyboxCubeTexture else { return }
            let levels = cubemapTexture.mipmapLevelCount
            
            var size = cubemapTexture.width
            for level in 0..<levels {
                print()
                print("Skybox - Level: \(level)")
                print("Skybox - Size: \(size)")
                skyboxTextureCompute.textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
                    pixelFormat: cubemapTexture.pixelFormat,
                    width: size,
                    height: size,
                    mipmapped: false
                )
                
                for slice in 0..<6 {
                    print("Skybox - Slice: \(slice)")
                    faceParameter.value = slice
                    skyboxTextureComputeUniforms.update()
                    
                    if let commandBuffer = commandQueue.makeCommandBuffer() {
                        skyboxTextureCompute.update(commandBuffer)
                        commandBuffer.commit()
                        commandBuffer.waitUntilCompleted()
                    }
                    
                    if let commandBuffer = commandQueue.makeCommandBuffer() {
                        if let blitEncoder = commandBuffer.makeBlitCommandEncoder() {
                            if let texture = skyboxTextureCompute.texture {
                                blitEncoder.copy(
                                    from: texture,
                                    sourceSlice: 0,
                                    sourceLevel: 0,
                                    to: cubemapTexture,
                                    destinationSlice: slice,
                                    destinationLevel: level,
                                    sliceCount: 1,
                                    levelCount: 1
                                )
                            }
                            blitEncoder.endEncoding()
                        }
                        commandBuffer.commit()
                        commandBuffer.waitUntilCompleted()
                    }
                }
                size /= 2
                print()
            }
        }
        catch {
            print(error)
        }
    }
    
    func setupCubemapCompute(_ library: MTLLibrary) {
        do {
            let pipeline = try makeComputePipeline(library: library, kernel: "cubemapCompute")
            cubemapTextureCompute.updatePipeline = pipeline
            
            guard let cubemapTexture = self.hdrCubemapTexture else { return }
            let levels = cubemapTexture.mipmapLevelCount
            
            var size = cubemapTexture.width
            for level in 0..<levels {
                print()
                print("Cubemap - Level: \(level)")
                print("Cubemap - Size: \(size)")
                cubemapTextureCompute.textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba32Float, width: size, height: size, mipmapped: false)
                
                for slice in 0..<6 {
                    print("Cubemap - Slice: \(slice)")
                    faceParameter.value = slice
                    cubemapTextureComputeUniforms.update()
                    
                    if let commandBuffer = commandQueue.makeCommandBuffer() {
                        cubemapTextureCompute.update(commandBuffer)
                        commandBuffer.commit()
                        commandBuffer.waitUntilCompleted()
                    }
                    
                    if let commandBuffer = commandQueue.makeCommandBuffer() {
                        if let blitEncoder = commandBuffer.makeBlitCommandEncoder() {
                            if let texture = cubemapTextureCompute.texture {
                                blitEncoder.copy(
                                    from: texture,
                                    sourceSlice: 0,
                                    sourceLevel: 0,
                                    to: cubemapTexture,
                                    destinationSlice: slice,
                                    destinationLevel: level,
                                    sliceCount: 1,
                                    levelCount: 1
                                )
                            }
                            blitEncoder.endEncoding()
                        }
                        commandBuffer.commit()
                        commandBuffer.waitUntilCompleted()
                    }
                }
                size /= 2
                print()
            }
        }
        catch {
            print(error)
        }
    }
    
    func setupDiffuseCompute(_ library: MTLLibrary) {
        do {
            let pipeline = try makeComputePipeline(library: library, kernel: "diffuseCompute")
            diffuseTextureCompute.updatePipeline = pipeline
            
            guard let cubemapTexture = self.diffuseCubeTexture else { return }
            let levels = cubemapTexture.mipmapLevelCount
            
            var size = cubemapTexture.width
            for level in 0..<levels {
                print()
                print("Diffuse - Level: \(level)")
                print("Diffuse - Size: \(size)")
                diffuseTextureCompute.textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba32Float, width: size, height: size, mipmapped: false)
                
                for slice in 0..<6 {
                    print("Diffuse - Slice: \(slice)")
                    faceParameter.value = slice
                    diffuseTextureComputeUniforms.update()
                    
                    if let commandBuffer = commandQueue.makeCommandBuffer() {
                        diffuseTextureCompute.update(commandBuffer)
                        commandBuffer.commit()
                        commandBuffer.waitUntilCompleted()
                    }
                    
                    if let commandBuffer = commandQueue.makeCommandBuffer() {
                        if let blitEncoder = commandBuffer.makeBlitCommandEncoder() {
                            if let texture = diffuseTextureCompute.texture {
                                blitEncoder.copy(
                                    from: texture,
                                    sourceSlice: 0,
                                    sourceLevel: 0,
                                    to: cubemapTexture,
                                    destinationSlice: slice,
                                    destinationLevel: level,
                                    sliceCount: 1,
                                    levelCount: 1
                                )
                            }
                            blitEncoder.endEncoding()
                        }
                        commandBuffer.commit()
                        commandBuffer.waitUntilCompleted()
                    }
                }
                size /= 2
                print()
            }
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
                roughnessParameter.value = Float(level) / Float(levels - 1)
                print()
                print("Specular - Level: \(level)")
                print("Specular - Size: \(size)")
                specularTextureCompute.textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba32Float, width: size, height: size, mipmapped: false)
                
                if let commandQueue = self.device.makeCommandQueue() {
                    for slice in 0..<6 {
                        print("Specular - Slice: \(slice)")
                        faceParameter.value = slice
                        specularTextureComputeUniforms.update()
                        
                        if let commandBuffer = commandQueue.makeCommandBuffer() {
                            specularTextureCompute.update(commandBuffer)
                            commandBuffer.commit()
                            commandBuffer.waitUntilCompleted()
                        }
                        
                        if let commandBuffer = commandQueue.makeCommandBuffer() {
                            if let blitEncoder = commandBuffer.makeBlitCommandEncoder() {
                                if let texture = specularTextureCompute.texture {
                                    blitEncoder.copy(
                                        from: texture,
                                        sourceSlice: 0,
                                        sourceLevel: 0,
                                        to: cubeTexture,
                                        destinationSlice: slice,
                                        destinationLevel: level,
                                        sliceCount: 1,
                                        levelCount: 1
                                    )
                                }
                                blitEncoder.endEncoding()
                            }
                            commandBuffer.commit()
                            commandBuffer.waitUntilCompleted()
                        }
                    }
                }
                size /= 2
                print()
            }
        }
        catch {
            print(error)
        }
    }
}
