//
//  BasicDiffuseMaterial.swift
//  Satin
//
//  Created by Reza Ali on 7/26/20.
//

import Metal
import simd

open class BasicDiffuseMaterial: BasicColorMaterial {
    var hardness = FloatParameter("Hardness", .toggle)

    public init(_ hardness: Float = 0.75) {
        super.init()
        self.hardness.value = hardness
        parameters.append(self.hardness)
    }

    open override func compileSource() -> String? {
        return BasicDiffusePipelineSource.setup(label: label)
    }
}

class BasicDiffusePipelineSource {
    static let shared = BasicDiffusePipelineSource()
    private static var sharedSource: String?

    class func setup(label: String) -> String? {
        guard BasicDiffusePipelineSource.sharedSource == nil else { return sharedSource }
        do {
            if let source = try compilePipelineSource(label) {
                BasicDiffusePipelineSource.sharedSource = source
            }
        }
        catch {
            print(error)
        }
        return sharedSource
    }
}
