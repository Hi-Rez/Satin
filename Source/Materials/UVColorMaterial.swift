//
//  UVMaterial.swift
//  Satin
//
//  Created by Reza Ali on 4/18/20.
//

import Metal
import simd

open class UVColorMaterial: Material {
    public override init() {
        super.init()
    }
    
    override func setup() {
        setupPipeline()
    }
    
    func setupPipeline() {
        UVColorPipeline.setup(context: context)
        if let pipeline = UVColorPipeline.shared.pipeline {
            self.pipeline = pipeline
        }
    }
}

class UVColorPipeline {
    static let shared = UVColorPipeline()
    private static var sharedPipeline: MTLRenderPipelineState?
    let pipeline: MTLRenderPipelineState?

    class func setup(context: Context?) {
        guard UVColorPipeline.sharedPipeline == nil, let context = context, let pipelinesPath = getPipelinesPath() else { return }

        let pipelinesURL = URL(fileURLWithPath: pipelinesPath)
        let materialsURL = pipelinesURL.appendingPathComponent("Materials")
        let commonURL = materialsURL.appendingPathComponent("Common")
        let includesURL = commonURL.appendingPathComponent("Includes.metal")
        let materialURL = materialsURL.appendingPathComponent("UVColor")
        let vertexURL = commonURL.appendingPathComponent("Vertex.metal")
        let fragmentURL = materialURL.appendingPathComponent("Fragment.metal")

        let metalFileCompiler = MetalFileCompiler()
        do {
            var source = try metalFileCompiler.parse(includesURL)
            source += try metalFileCompiler.parse(vertexURL)
            source += try metalFileCompiler.parse(fragmentURL)

            let library = try context.device.makeLibrary(source: source, options: .none)

            let pipeline = try makeRenderPipeline(
                library: library,
                vertex: "vert",
                fragment: "uvColorFragment",
                label: "UV Color",
                context: context)

            UVColorPipeline.sharedPipeline = pipeline
        }
        catch {
            print(error)
            return
        }
    }

    init() {
        pipeline = UVColorPipeline.sharedPipeline
    }
}
