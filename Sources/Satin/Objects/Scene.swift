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

            var _brdfTexture: MTLTexture? = nil
            var _reflectionTexture: MTLTexture? = nil
            var _irradianceTexture: MTLTexture? = nil

            progress?.completedUnitCount = 0
            progress?.totalUnitCount = 4

            if let commandBuffer = commandQueue.makeCommandBuffer() {
                commandBuffer.addCompletedHandler { _ in
                    progress?.completedUnitCount += 1
                }
                self.cubemapTexture = self.setupCubemapTexture(device: device, commandBuffer: commandBuffer)
                commandBuffer.commit()
            }

            if let commandBuffer = commandQueue.makeCommandBuffer() {
                _irradianceTexture = self.setupIrradianceTexture(device: device, commandBuffer: commandBuffer)
                commandBuffer.addCompletedHandler { [weak self] _ in
                    progress?.completedUnitCount += 1
                    self?.irradianceTexture = _irradianceTexture
                }
                commandBuffer.commit()
            }

            if let commandBuffer = commandQueue.makeCommandBuffer() {
                _reflectionTexture = self.setupReflectionTexture(device: device, commandBuffer: commandBuffer)
                commandBuffer.addCompletedHandler { [weak self] _ in
                    progress?.completedUnitCount += 1
                    self?.reflectionTexture = _reflectionTexture
                }
                commandBuffer.commit()
            }

            if self.brdfTexture == nil, let commandBuffer = commandQueue.makeCommandBuffer() {
                _brdfTexture = self.setupBrdfTexture(device: device, commandBuffer: commandBuffer)
                commandBuffer.addCompletedHandler { [weak self] _ in
                    progress?.completedUnitCount += 1
                    self?.brdfTexture = _brdfTexture
                }
                commandBuffer.commit()
            }
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

            var _brdfTexture: MTLTexture? = nil
            var _reflectionTexture: MTLTexture? = nil
            var _irradianceTexture: MTLTexture? = nil

            progress?.completedUnitCount = 0
            progress?.totalUnitCount = 3

            if let commandBuffer = commandQueue.makeCommandBuffer() {
                _irradianceTexture = self.setupIrradianceTexture(device: device, commandBuffer: commandBuffer)
                commandBuffer.addCompletedHandler { [weak self] _ in
                    progress?.completedUnitCount += 1
                    self?.irradianceTexture = _irradianceTexture
                }
                commandBuffer.commit()
            }

            if let commandBuffer = commandQueue.makeCommandBuffer() {
                _reflectionTexture = self.setupReflectionTexture(device: device, commandBuffer: commandBuffer)
                commandBuffer.addCompletedHandler { [weak self] _ in
                    progress?.completedUnitCount += 1
                    self?.reflectionTexture = _reflectionTexture
                }
                commandBuffer.commit()
            }

            if self.brdfTexture == nil, let commandBuffer = commandQueue.makeCommandBuffer() {
                _brdfTexture = self.setupBrdfTexture(device: device, commandBuffer: commandBuffer)
                commandBuffer.addCompletedHandler { [weak self] _ in
                    progress?.completedUnitCount += 1
                    self?.brdfTexture = _brdfTexture
                }
                commandBuffer.commit()
            }
        }
    }

    private func setupCubemapTexture(device: MTLDevice, commandBuffer: MTLCommandBuffer) -> MTLTexture? {
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
            texture.label = "Environment Cubemap"
            return texture
        }
        return nil
    }

    private func setupIrradianceTexture(device: MTLDevice, commandBuffer: MTLCommandBuffer) -> MTLTexture? {
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
            texture.label = "Irradiance IBL"
            return texture
        }
        return nil
    }

    private func setupReflectionTexture(device: MTLDevice, commandBuffer: MTLCommandBuffer) -> MTLTexture? {
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
            texture.label = "Reflection IBL"
            return texture
        }
        return nil
    }

    private func setupBrdfTexture(device: MTLDevice, commandBuffer: MTLCommandBuffer) -> MTLTexture? {
        return BrdfGenerator(device: device, size: brdfSize).encode(commandBuffer: commandBuffer)
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
