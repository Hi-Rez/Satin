//
//  UVMaterial.swift
//  Satin
//
//  Created by Reza Ali on 4/18/20.
//

import Metal
import simd

open class UvColorMaterial: Material {
    public override init() {
        super.init()
    }

    open override func compileSource() -> String? {
        return UvColorPipelineSource.setup(label: label)
    }
}

class UvColorPipelineSource {
    static let shared = UvColorPipelineSource()
    private static var sharedSource: String?

    class func setup(label: String) -> String? {
        guard UvColorPipelineSource.sharedSource == nil else { return sharedSource }
        do {
            if let source = try compilePipelineSource(label) {
                UvColorPipelineSource.sharedSource = source
            }
        }
        catch {
            print(error)
        }
        return sharedSource
    }
}
