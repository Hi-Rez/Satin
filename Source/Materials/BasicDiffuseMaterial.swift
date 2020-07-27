//
//  BasicDiffuseMaterial.swift
//  Satin
//
//  Created by Reza Ali on 7/26/20.
//

import Metal
import simd

open class BasicDiffuseMaterial: Material {
    var absolute = BoolParameter("Absolute", .toggle)

    public init(_ absolute: Bool = false) {
        super.init()
        self.absolute.value = absolute
        parameters.append(self.absolute)
    }

    open override func compileSource() -> String? {
        return BasicDiffusePipelineSource.setup(label: label, parameters: parameters)
    }
}

class BasicDiffusePipelineSource {
    static let shared = BasicDiffusePipelineSource()
    private static var sharedSource: String?

    class func setup(label: String, parameters: ParameterGroup) -> String? {
        guard BasicDiffusePipelineSource.sharedSource == nil else { return sharedSource }
        do {
            if let source = try compilePipelineSource(label, parameters) {
                BasicDiffusePipelineSource.sharedSource = source
            }
        }
        catch {
            print(error)
        }
        return sharedSource
    }
}
