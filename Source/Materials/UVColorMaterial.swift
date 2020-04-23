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

    open override func setup() {
        super.setup()
        setupPipeline()
    }

    func setupPipeline() {
        UvColorPipeline.setup(context: context, label: label)
        if let pipeline = UvColorPipeline.shared.pipeline {
            self.pipeline = pipeline
        }
    }
}

class UvColorPipeline {
    static let shared = UvColorPipeline()
    private static var sharedPipeline: MTLRenderPipelineState?
    let pipeline: MTLRenderPipelineState?

    class func setup(context: Context?, label: String) {
        guard UvColorPipeline.sharedPipeline == nil, let context = context, let pipelinesPath = getPipelinesPath() else { return }

        do {
            if let source = try makePipelineSource(pipelinesPath, label) {
                let library = try context.device.makeLibrary(source: source, options: .none)

                let pipeline = try makeRenderPipeline(
                    library: library,
                    vertex: "satinVertex",                    
                    fragment: label.camelCase + "Fragment",
                    label: label.titleCase,
                    context: context)

                UvColorPipeline.sharedPipeline = pipeline
            }
        }
        catch {
            print(error)
            return
        }
    }

    init() {
        pipeline = UvColorPipeline.sharedPipeline
    }
}
