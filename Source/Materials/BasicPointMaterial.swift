//
//  BasicPointMaterial.swift
//  Satin
//
//  Created by Reza Ali on 6/28/20.
//

import Metal
import simd

open class BasicPointMaterial: Material {
    public var color = Float4Parameter("Color", .colorpicker)
    public var pointSize = FloatParameter("Point Size", 2, .inputfield)

    public init(_ color: simd_float4 = simd_float4(repeating: 1.0), _ size: Float = 2.0, _ blending: Blending = .alpha) {
        super.init()
        self.blending = blending
        self.color.value = color
        self.pointSize.value = size
        parameters.append(self.color)
        parameters.append(self.pointSize)
    }

    open override func compileSource() -> String? {
        return BasicPointPipelineSource.setup(label: label)
    }
}

class BasicPointPipelineSource {
    static let shared = BasicPointPipelineSource()
    private static var sharedSource: String?

    class func setup(label: String) -> String? {
        guard BasicPointPipelineSource.sharedSource == nil else { return sharedSource }
        do {
            if let source = try compilePipelineSource(label) {
                BasicPointPipelineSource.sharedSource = source
            }
        }
        catch {
            print(error)
        }
        return sharedSource
    }
}
