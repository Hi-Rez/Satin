//
//  Scene.swift
//
//
//  Created by Reza Ali on 3/11/23.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Combine
import Metal
import simd

open class Scene: Object {
    public var environmentIntensity: Float = 1.0 {
        didSet {
            self.traverse { object in
                if let renderable = object as? Renderable {
                    let materials = renderable.materials
                    for material in materials {
                        if let standardMaterial = material as? StandardMaterial {
                            standardMaterial.environmentIntensity = environmentIntensity
                        }
                    }
                }
            }
        }
    }
    public var environment: MTLTexture? {
        didSet {
            if oldValue == nil {
                DispatchQueue.global(qos: .background).async {
                    self.setupTextures()
                }
            }
        }
    }

    private var cubemapTexture: MTLTexture?
    private var diffuseIBLTexture: MTLTexture?
    private var specularIBLTexture: MTLTexture?
    private var brdfTexture: MTLTexture?

    private var addedSubscription: AnyCancellable?

    override public init(_ label: String, _ children: [Object] = []) {
        super.init(label, children)

        addedSubscription = childAddedPublisher.sink { [weak self] object in
            self?.updateObjectTextures(object)
        }
    }

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    private func setupTextures() {
        guard let environment = environment,
              let commandQueue = environment.device.makeCommandQueue(),
              let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        let device = environment.device

        setupCubemap(device: device, commandBuffer: commandBuffer)
        setupDiffuseIBL(device: device, commandBuffer: commandBuffer)
        setupSpecularIBL(device: device, commandBuffer: commandBuffer)
        setupBRDF(device: device, commandBuffer: commandBuffer)

        commandBuffer.addCompletedHandler { _ in
            DispatchQueue.main.async {
                self.traverse { object in
                    self.updateObjectTextures(object)
                }
            }
        }
        commandBuffer.commit()
    }

    open func updateObjectTextures(_ object: Object) {
        if let renderable = object as? Renderable {
            let materials = renderable.materials
            for material in materials {
                if let standardMaterial = material as? StandardMaterial {
                    standardMaterial.setTexture(specularIBLTexture, type: .reflection)
                    standardMaterial.setTexture(diffuseIBLTexture, type: .irradiance)
                    standardMaterial.setTexture(brdfTexture, type: .brdf)
                } else if let skyboxMaterial = material as? SkyboxMaterial {
                    skyboxMaterial.texture = cubemapTexture
                }
            }
        }
    }

    private func setupCubemap(device: MTLDevice, commandBuffer: MTLCommandBuffer) {
        if let hdriTexture = environment, let texture = createCubemapTexture(device: device, pixelFormat: .rgba16Float, size: 512, mipmapped: true) {
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

    private func setupDiffuseIBL(device: MTLDevice, commandBuffer: MTLCommandBuffer) {
        if let cubemapTexture = cubemapTexture,
           let texture = createCubemapTexture(device: device, pixelFormat: .rgba16Float, size: 16, mipmapped: false)
        {
            DiffuseIBLGenerator(device: device)
                .encode(
                    commandBuffer: commandBuffer,
                    sourceTexture: cubemapTexture,
                    destinationTexture: texture
                )

            diffuseIBLTexture = texture
            texture.label = "Diffuse IBL"
        }
    }

    private func setupSpecularIBL(device: MTLDevice, commandBuffer: MTLCommandBuffer) {
        if let cubemapTexture = cubemapTexture, let texture = createCubemapTexture(device: device, pixelFormat: .rgba16Float, size: 256, mipmapped: true) {
            SpecularIBLGenerator(device: device)
                .encode(
                    commandBuffer: commandBuffer,
                    sourceTexture: cubemapTexture,
                    destinationTexture: texture
                )

            specularIBLTexture = texture
            texture.label = "Specular IBL"
        }
    }

    private func setupBRDF(device: MTLDevice, commandBuffer: MTLCommandBuffer) {
        brdfTexture = BrdfGenerator(device: device, size: 512)
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
