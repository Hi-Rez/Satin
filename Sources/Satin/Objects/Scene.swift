//
//  Scene.swift
//
//
//  Created by Reza Ali on 3/11/23.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Combine
import Metal
import ModelIO
import simd

open class Scene: Object {
    public var environmentIntensity: Float = 1.0

    public internal(set) var environment: MTLTexture?
    public internal(set) var cubemapTexture: MTLTexture?
    public internal(set) var irradianceTexture: MTLTexture?
    public internal(set) var reflectionTexture: MTLTexture?
    public internal(set) var brdfTexture: MTLTexture?

    private var qos: DispatchQoS.QoSClass = .background
    private var cubemapSize: Int = 512
    private var reflectionSize: Int = 512
    private var irradianceSize: Int = 64
    private var brdfSize: Int = 512

    public func setEnvironment(texture: MTLTexture, qos: DispatchQoS.QoSClass = .background, cubemapSize: Int = 512, reflectionSize: Int = 512, irrandianceSize: Int = 64, brdfSize: Int = 512, progress: Progress? = nil) {
        environment = texture
        self.cubemapSize = cubemapSize
        self.reflectionSize = reflectionSize
        irradianceSize = irrandianceSize
        self.brdfSize = brdfSize
        DispatchQueue.global(qos: qos).async {
            guard let environment = self.environment,
                  let commandQueue = environment.device.makeCommandQueue() else { return }

            let device = environment.device

            progress?.completedUnitCount = 0
            progress?.totalUnitCount = 4

            if let commandBuffer = commandQueue.makeCommandBuffer() {
                self.setupCubemapTexture(device: device, commandBuffer: commandBuffer)
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()
            }
            progress?.completedUnitCount += 1

            if let commandBuffer = commandQueue.makeCommandBuffer() {
                self.setupIrradianceTexture(device: device, commandBuffer: commandBuffer)
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()
            }
            progress?.completedUnitCount += 1

            if let commandBuffer = commandQueue.makeCommandBuffer() {
                self.setupReflectionTexture(device: device, commandBuffer: commandBuffer)
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()
            }
            progress?.completedUnitCount += 1

            if self.brdfTexture == nil, let commandBuffer = commandQueue.makeCommandBuffer() {
                self.setupBrdfTexture(device: device, commandBuffer: commandBuffer)
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()
            }
            progress?.completedUnitCount += 1
        }
    }

    public func setEnvironmentCubemap(texture: MTLTexture,  qos: DispatchQoS.QoSClass = .background, reflectionSize: Int = 512, irrandianceSize: Int = 64, brdfSize: Int = 512, progress: Progress? = nil) {
        cubemapTexture = texture
        self.cubemapSize = texture.width
        self.reflectionSize = reflectionSize
        irradianceSize = irrandianceSize
        self.brdfSize = brdfSize
        DispatchQueue.global(qos: qos).async {
            guard let environment = self.environment,
                  let commandQueue = environment.device.makeCommandQueue() else { return }

            let device = environment.device

            progress?.completedUnitCount = 0
            progress?.totalUnitCount = 3

            if let commandBuffer = commandQueue.makeCommandBuffer() {
                self.setupIrradianceTexture(device: device, commandBuffer: commandBuffer)
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()
            }
            progress?.completedUnitCount += 1

            if let commandBuffer = commandQueue.makeCommandBuffer() {
                self.setupReflectionTexture(device: device, commandBuffer: commandBuffer)
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()
            }
            progress?.completedUnitCount += 1

            if self.brdfTexture == nil, let commandBuffer = commandQueue.makeCommandBuffer() {
                self.setupBrdfTexture(device: device, commandBuffer: commandBuffer)
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()
            }
            progress?.completedUnitCount += 1
        }
    }

    private func setupCubemapTexture(device: MTLDevice, commandBuffer: MTLCommandBuffer) {
        if let hdriTexture = environment,
           let texture = createCubemapTexture(
               device: device,
               pixelFormat: .rgba16Float,
               size: cubemapSize,
               mipmapped: true
           )
        {
            CubemapGenerator(device: device)
                .encode(
                    commandBuffer: commandBuffer,
                    sourceTexture: hdriTexture,
                    destinationTexture: texture
                )
            cubemapTexture = texture
            cubemapTexture?.label = "Environment Cubemap"
        }
    }

    private func setupIrradianceTexture(device: MTLDevice, commandBuffer: MTLCommandBuffer) {
        if let cubemapTexture = cubemapTexture,
           let texture = createCubemapTexture(
               device: device,
               pixelFormat: .rgba16Float,
               size: irradianceSize,
               mipmapped: false
           )
        {
            DiffuseIBLGenerator(device: device)
                .encode(
                    commandBuffer: commandBuffer,
                    sourceTexture: cubemapTexture,
                    destinationTexture: texture
                )

            irradianceTexture = texture
            texture.label = "Diffuse IBL"
        }
    }

    private func setupReflectionTexture(device: MTLDevice, commandBuffer: MTLCommandBuffer) {
        if let cubemapTexture = cubemapTexture,
            let texture = createCubemapTexture(
                device: device,
                pixelFormat: .rgba16Float,
                size: reflectionSize,
                mipmapped: true
            ) {
            SpecularIBLGenerator(device: device)
                .encode(
                    commandBuffer: commandBuffer,
                    sourceTexture: cubemapTexture,
                    destinationTexture: texture
                )

            reflectionTexture = texture
            texture.label = "Specular IBL"
        }
    }

    private func setupBrdfTexture(device: MTLDevice, commandBuffer: MTLCommandBuffer) {
        brdfTexture = BrdfGenerator(device: device, size: brdfSize)
            .encode(commandBuffer: commandBuffer)
    }

    private func createCubemapTexture(device: MTLDevice, pixelFormat: MTLPixelFormat, size: Int, mipmapped: Bool) -> MTLTexture?
    {
        let desc = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: pixelFormat, size: size, mipmapped: mipmapped)
        desc.usage = [.shaderWrite, .shaderRead]
        desc.storageMode = .private
        desc.resourceOptions = .storageModePrivate

        let texture = device.makeTexture(descriptor: desc)
        texture?.label = "Cubemap"
        return texture
    }
}
