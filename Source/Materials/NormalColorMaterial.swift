//
//  BasicColorMaterial.swift
//  Satin
//
//  Created by Reza Ali on 9/25/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal
import simd

open class NormalColorMaterial: Material {
    var absolute = BoolParameter("Absolute", .toggle)

    public init(_ absolute: Bool = false) {
        super.init()
        self.absolute.value = absolute
        parameters.append(self.absolute)
    }

    open override func compileSource() -> String? {
        return NormalColorPipelineSource.setup(label: label)
    }
}

class NormalColorPipelineSource {
    static let shared = NormalColorPipelineSource()
    private static var sharedSource: String?

    class func setup(label: String) -> String? {
        guard NormalColorPipelineSource.sharedSource == nil else { return sharedSource }
        do {
            if let source = try compilePipelineSource(label) {
                NormalColorPipelineSource.sharedSource = source
            }
        }
        catch {
            print(error)
        }
        return sharedSource
    }
}
