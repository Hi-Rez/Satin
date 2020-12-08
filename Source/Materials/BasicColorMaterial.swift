//
//  BasicColorMaterial.swift
//  Satin
//
//  Created by Reza Ali on 9/25/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal
import simd

open class BasicColorMaterial: Material {
    public var color = Float4Parameter("Color", .colorpicker)

    public init(_ color: simd_float4 = simd_float4(repeating: 1.0), _ blending: Blending = .alpha) {
        super.init()
        self.blending = blending
        self.color.value = color
        parameters.append(self.color)
    }

    open override func compileSource() -> String? {
        return BasicColorPipelineSource.setup(label: label)
    }
}

class BasicColorPipelineSource {
    static let shared = BasicColorPipelineSource()
    private static var sharedSource: String?

    class func setup(label: String) -> String? {
        guard BasicColorPipelineSource.sharedSource == nil else { return sharedSource }
        do {
            if let source = try compilePipelineSource(label) {
                BasicColorPipelineSource.sharedSource = source
            }
        }
        catch {
            print(error)
        }
        return sharedSource
    }
}
