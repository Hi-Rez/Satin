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
        guard let context = self.context, let pipelinesPath = getPipelinesPath() else { return }
        do {
            if let source = try makePipelineSource(pipelinesPath, label) {
                let library = try context.device.makeLibrary(source: source, options: .none)
                pipeline = try makeRenderPipeline(
                    library: library,
                    vertex: "satinVertex",
                    fragment: label.camelCase + "Fragment",
                    label: label.titleCase,
                    context: context)
            }
        }
        catch {
            print(error)
            return
        }
    }
}
