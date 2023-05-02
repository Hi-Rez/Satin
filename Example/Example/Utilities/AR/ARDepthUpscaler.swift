//
//  ARDepthUpscaler.swift
//  Example
//
//  Created by Reza Ali on 5/2/23.
//  Copyright © 2023 Hi-Rez. All rights reserved.
//

import Foundation
import Metal
import MetalPerformanceShaders

import Satin

class ARDepthUpscaler {
    // Based on ARKit
    let origDepthWidth = 256
    let origDepthHeight = 192

    // Based on ARKit's Default Captured Image Size
    let origColorWidth = 1920
    let origColorHeight = 1440

    private var colorConverter: YCbCrToRGBConverter
    private var guidedFilter: MPSImageGuidedFilter
    private var scaleFilter: MPSImageBilinearScale

    private var rgbColorDownscaledTexture: MTLTexture?
    private var rgbColorDownscaledLowResTexture: MTLTexture?

    private var coefficientsTexture: MTLTexture?
    private var upscaledDepthTexture: MTLTexture?

    init(device: MTLDevice,
         upscaledWidth: Int = 960,
         upscaledHeight: Int = 760,
         kernelDiameter: Int = 5,
         epsilon: Float = 0.004
    ) {
        colorConverter = YCbCrToRGBConverter(device: device, width: origColorWidth, height: origColorHeight)

        guidedFilter = MPSImageGuidedFilter(device: device, kernelDiameter: kernelDiameter)
        guidedFilter.epsilon = epsilon

        scaleFilter = MPSImageBilinearScale(device: device)

        rgbColorDownscaledTexture = createTexture(
            device: device,
            label: "RGB Color Downscaled Texture",
            pixelFormat: .rgba32Float,
            width: upscaledWidth,
            height: upscaledHeight
        )

        rgbColorDownscaledLowResTexture = createTexture(
            device: device,
            label: "RGB Color Downscaled Low Res Texture",
            pixelFormat: .rgba32Float,
            width: origDepthWidth,
            height: origDepthHeight
        )

        coefficientsTexture = createTexture(
            device: device,
            label: "Coefficients Texture",
            pixelFormat: .rgba32Float,
            width: origDepthWidth,
            height: origDepthHeight
        )

        upscaledDepthTexture = createTexture(
            device: device,
            label: "Upscaled Depth Texture",
            pixelFormat: .r32Float,
            width: upscaledWidth,
            height: upscaledHeight
        )
    }

    func update(
        commandBuffer: MTLCommandBuffer,
        yTexture: MTLTexture,
        cbcrTexture: MTLTexture,
        depthTexture: MTLTexture
    ) -> MTLTexture? {
        guard
            let rgbColorTexture = colorConverter.encode(commandBuffer: commandBuffer, yTexture: yTexture, cbcrTexture: cbcrTexture),
            let rgbColorDownscaledTexture = rgbColorDownscaledTexture,
            let rgbColorDownscaledLowResTexture = rgbColorDownscaledLowResTexture,
            let coefficientsTexture = coefficientsTexture,
            let upscaledDepthTexture = upscaledDepthTexture
        else { return nil }

        // Downscale the RGB data. Pass in the target resoultion.
        scaleFilter.encode(
            commandBuffer: commandBuffer,
            sourceTexture: rgbColorTexture,
            destinationTexture: rgbColorDownscaledTexture
        )

        // Match the input depth resolution.
        scaleFilter.encode(
            commandBuffer: commandBuffer,
            sourceTexture: rgbColorTexture,
            destinationTexture: rgbColorDownscaledLowResTexture
        )

        guidedFilter.encodeRegression(
            to: commandBuffer,
            sourceTexture: depthTexture,
            guidanceTexture: rgbColorDownscaledLowResTexture,
            weightsTexture: nil,
            destinationCoefficientsTexture: coefficientsTexture
        )

        guidedFilter.encodeReconstruction(
            to: commandBuffer,
            guidanceTexture: rgbColorDownscaledTexture,
            coefficientsTexture: coefficientsTexture,
            destinationTexture: upscaledDepthTexture
        )

        return upscaledDepthTexture
    }

    func createTexture(
        device: MTLDevice,
        label: String,
        pixelFormat: MTLPixelFormat,
        width: Int,
        height: Int,
        usage: MTLTextureUsage = [.shaderRead, .shaderWrite]
    ) -> MTLTexture? {

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: width, height: height, mipmapped: false)
        descriptor.usage = usage
        descriptor.storageMode = .private
        descriptor.resourceOptions = .storageModePrivate
        guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }
        texture.label = label
        return texture
    }
}
