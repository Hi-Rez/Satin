//
//  SourceShader.swift
//  Pods
//
//  Created by Reza Ali on 2/10/22.
//

import Foundation

open class SourceShader: Shader {
    public var pipelineURL: URL {
        didSet {
            if oldValue != pipelineURL {
                sourceNeedsUpdate = true
            }
        }
    }

    public private(set) var source: String?
    public private(set) var shaderSource: String?

    var sourceNeedsUpdate: Bool = true {
        didSet {
            if sourceNeedsUpdate {
                libraryNeedsUpdate = true
            }
        }
    }

    public required init(_ label: String, _ pipelineURL: URL, _ vertexFunctionName: String? = nil, _ fragmentFunctionName: String? = nil) {
        self.pipelineURL = pipelineURL
        super.init(label, vertexFunctionName, fragmentFunctionName)
        setupSource()
    }

    public required init() {
        fatalError("init() has not been implemented")
    }

    override func setup() {
        setupSource()
        super.setup()
    }

    override func update() {
        updateSource()
        super.update()
    }

    func updateSource() {
        if sourceNeedsUpdate {
            setupSource()
        }
    }

    deinit {
        source = nil
    }

    override func setupParameters() {
        if let shaderSource = shaderSource, let params = parseParameters(source: shaderSource, key: label + "Uniforms") {
            params.label = label.titleCase
            parameters = params
        }
        parametersNeedsUpdate = false
    }

    override func setupLibrary() {
        guard let context = context, let source = source else { return }
        do {
            library = try context.device.makeLibrary(source: source, options: nil)
            libraryNeedsUpdate = false
        }
        catch {
            print("\(label) Shader: \(error.localizedDescription)")
        }
    }

    func setupShaderSource() -> String? {
        do {
            return try MetalFileCompiler().parse(pipelineURL)
        }
        catch {
            print("\(label) Shader: \(error.localizedDescription)")
        }
        return nil
    }

    func setupSource() {
        guard let satinURL = getPipelinesSatinUrl(), let shaderSource = setupShaderSource() else { return }
        let includesURL = satinURL.appendingPathComponent("Includes.metal")
        do {
            let compiler = MetalFileCompiler()
            var source = try compiler.parse(includesURL)

            injectConstants(source: &source)
            injectVertex(source: &source)
            injectVertexData(source: &source)
            injectVertexUniforms(source: &source)

            source += shaderSource

            if !shaderSource.contains(vertexFunctionName) {

            }
            
            injectPassThroughVertex(label: label, source: &source)
            self.shaderSource = shaderSource
            self.source = source
            sourceNeedsUpdate = false
        }
        catch {
            print("\(label) Shader: \(error.localizedDescription)")
        }
    }

    override public func clone() -> Shader {
        let clone: SourceShader = type(of: self).init(label, pipelineURL, vertexFunctionName, fragmentFunctionName)

        clone.label = label
        clone.pipelineURL = pipelineURL
        clone.library = library
        clone.pipeline = pipeline
        clone.source = source

        clone.delegate = delegate
        clone.parameters = parameters.clone()

        clone.blending = blending
        clone.sourceRGBBlendFactor = sourceRGBBlendFactor
        clone.sourceAlphaBlendFactor = sourceAlphaBlendFactor
        clone.destinationRGBBlendFactor = destinationRGBBlendFactor
        clone.destinationAlphaBlendFactor = destinationAlphaBlendFactor
        clone.rgbBlendOperation = rgbBlendOperation
        clone.alphaBlendOperation = alphaBlendOperation

        clone.context = context

        return clone
    }
}
