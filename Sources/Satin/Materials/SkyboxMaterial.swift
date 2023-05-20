//
//  SkyboxMaterial.swift
//  Satin
//
//  Created by Reza Ali on 4/19/20.
//

import Metal
import simd

open class SkyboxMaterial: BasicTextureMaterial {
    override public var texture: MTLTexture? {
        willSet {
            if let newTexture = newValue, newTexture.textureType != .typeCube {
                fatalError("SkyboxMaterial expects a Cube Texture")
            }
        }
    }

    public var texcoordTransform: simd_float3x3 = matrix_identity_float3x3 {
        didSet {
            set("Texcoord Transform", texcoordTransform)
        }
    }

    public var environmentIntensity: Float = 1.0 {
        didSet {
            set("Environment Intensity", environmentIntensity)
        }
    }

    public var tonemapping: Tonemapping = .aces {
        didSet {
            if oldValue != tonemapping, let shader = shader as? SkyboxShader {
                shader.tonemapping = tonemapping
            }
        }
    }

    public var gammaCorrection: Float = 1.0 {
        didSet {
            set("Gamma Correction", gammaCorrection)
        }
    }

    public init(tonemapping: Tonemapping = .aces, gammaCorrection: Float = 1.0) {
        super.init()
        depthWriteEnabled = false
        initalizeParameters(tonemapping: tonemapping, gammaCorrection: gammaCorrection)
    }

    public init(texture: MTLTexture, sampler: MTLSamplerState? = nil, tonemapping: Tonemapping = .aces, gammaCorrection: Float = 1.0) {
        super.init()
        if texture.textureType != .typeCube {
            fatalError("SkyboxMaterial expects a Cube texture")
        }
        self.texture = texture
        self.sampler = sampler
        depthWriteEnabled = false
        initalizeParameters(tonemapping: tonemapping, gammaCorrection: gammaCorrection)
    }

    private func initalizeParameters(
        tonemapping: Tonemapping = .aces,
        gammaCorrection: Float = 1.0,
        environmentIntensity: Float = 1.0,
        texcoordTransform: simd_float3x3 = matrix_identity_float3x3
    ) {
        self.tonemapping = tonemapping
        self.gammaCorrection = gammaCorrection
        self.environmentIntensity = environmentIntensity
        self.texcoordTransform = texcoordTransform
    }

    public required init() {
        super.init()
        depthWriteEnabled = false
        initalizeParameters()
    }

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        depthWriteEnabled = false
    }

    override public init(texture: MTLTexture?, sampler: MTLSamplerState? = nil, flipped: Bool = false) {
        super.init(texture: texture, sampler: sampler, flipped: flipped)
        if let texture = texture, texture.textureType != .typeCube {
            fatalError("SkyboxMaterial expects a Cube texture")
        }
        self.texture = texture
        self.sampler = sampler
        depthWriteEnabled = false
        initalizeParameters()
    }

    override open func updateShaderProperties(_ shader: Shader) {
        super.updateShaderProperties(shader)
        guard let skyboxShader = shader as? SkyboxShader else { return }
        skyboxShader.tonemapping = tonemapping
    }

    override open func createShader() -> Shader {
        return SkyboxShader(label, getPipelinesMaterialsURL(label)!.appendingPathComponent("Shaders.metal"))
    }
}
