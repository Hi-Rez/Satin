//
//  TessellatedShader.swift
//  Tesselation
//
//  Created by Reza Ali on 3/31/23.
//  Copyright © 2023 Reza Ali. All rights reserved.
//

import Foundation
import Metal
import Satin

class TessellatedShader: SourceShader {

    unowned var geometry: TessellatedGeometry

    required init(_ label: String, _ pipelineURL: URL, _ geometry: TessellatedGeometry, _ vertexFunctionName: String? = nil, _ fragmentFunctionName: String? = nil) {
        self.geometry = geometry
        super.init(label, pipelineURL, vertexFunctionName, fragmentFunctionName)
    }

    required init(_ label: String, _ pipelineURL: URL, _ vertexFunctionName: String? = nil, _ fragmentFunctionName: String? = nil) {
        fatalError("init(_:_:_:_:) has not been implemented")
    }

    required init(label: String, source: String, vertexFunctionName: String? = nil, fragmentFunctionName: String? = nil) {
        fatalError("init(label:source:vertexFunctionName:fragmentFunctionName:) has not been implemented")
    }

    required init() {
        fatalError("init() has not been implemented")
    }

    override func createPipeline(_ context: Context, _ library: MTLLibrary) throws -> MTLRenderPipelineState? {
        guard let vertexFunction = library.makeFunction(name: vertexFunctionName),
              let fragmentFunction = library.makeFunction(name: fragmentFunctionName)
        else { return nil }

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = label

        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.vertexDescriptor = vertexDescriptor

        pipelineStateDescriptor.tessellationPartitionMode = geometry.partitionMode
        pipelineStateDescriptor.tessellationFactorStepFunction = geometry.stepFunction
        pipelineStateDescriptor.tessellationOutputWindingOrder = geometry.windingOrder
        pipelineStateDescriptor.tessellationControlPointIndexType = geometry.controlPointIndexType

        pipelineStateDescriptor.rasterSampleCount = context.sampleCount

        pipelineStateDescriptor.colorAttachments[0].pixelFormat = context.colorPixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = context.depthPixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = context.stencilPixelFormat

        if blending != .disabled, let colorAttachment = pipelineStateDescriptor.colorAttachments[0] {
            colorAttachment.isBlendingEnabled = true
            colorAttachment.sourceRGBBlendFactor = sourceRGBBlendFactor
            colorAttachment.sourceAlphaBlendFactor = sourceAlphaBlendFactor
            colorAttachment.destinationRGBBlendFactor = destinationRGBBlendFactor
            colorAttachment.destinationAlphaBlendFactor = destinationAlphaBlendFactor
            colorAttachment.rgbBlendOperation = rgbBlendOperation
            colorAttachment.alphaBlendOperation = alphaBlendOperation
        }

        return try context.device.makeRenderPipelineState(
            descriptor: pipelineStateDescriptor,
            options: pipelineOptions,
            reflection: &pipelineReflection
        )
    }
}
