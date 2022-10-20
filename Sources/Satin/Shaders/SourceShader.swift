//
//  SourceShader.swift
//  Pods
//
//  Created by Reza Ali on 2/10/22.
//

import Foundation
import Metal

open class SourceShader: Shader {
    public var pipelineURL: URL? {
        didSet {
            if pipelineURL != nil, oldValue != pipelineURL {
                sourceNeedsUpdate = true
            }
        }
    }

    public private(set) var source: String?
    public var shaderSource: String? {
        didSet {
            if shaderSource != nil, oldValue != shaderSource {
                sourceNeedsUpdate = true
            }
        }
    }

    var sourceNeedsUpdate: Bool = true {
        didSet {
            if sourceNeedsUpdate {
                libraryNeedsUpdate = true
            }
        }
    }
    
    public override var instancing: Bool {
        didSet {
            if oldValue != instancing {
                sourceNeedsUpdate = true
            }
        }
    }

    public required init(_ label: String, _ pipelineURL: URL, _ vertexFunctionName: String? = nil, _ fragmentFunctionName: String? = nil) {
        self.pipelineURL = pipelineURL
        super.init(label, vertexFunctionName, fragmentFunctionName, nil)
    }

    public required init(label: String, source: String, vertexFunctionName: String? = nil, fragmentFunctionName: String? = nil) {
        self.shaderSource = source
        super.init(label, vertexFunctionName, fragmentFunctionName, nil)
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
        if let pipelineURL = pipelineURL {
            do {
                return try MetalFileCompiler().parse(pipelineURL)
            }
            catch {
                print("\(label) Shader: \(error.localizedDescription)")
            }
        }
        else if let shaderSource = shaderSource {
            do {
                return try compileMetalSource(shaderSource)
            }
            catch {
                print("\(label) Shader: \(error.localizedDescription)")
            }
        }
        return nil
    }

    func setupSource() {
        guard let satinURL = getPipelinesSatinUrl(), let compiledShaderSource = setupShaderSource() else { return }
        let includesURL = satinURL.appendingPathComponent("Includes.metal")
        do {
            let compiler = MetalFileCompiler()
            var source = try compiler.parse(includesURL)

            injectConstants(source: &source)
            injectVertex(source: &source, vertexDescriptor: vertexDescriptor)
            injectVertexData(source: &source)
            injectVertexUniforms(source: &source)
            if instancing {
                injectInstanceMatrixUniforms(source: &source)
            }
            
            source += compiledShaderSource

            injectPassThroughVertex(label: label, source: &source)
            self.shaderSource = compiledShaderSource
            self.source = source
            sourceNeedsUpdate = false
        }
        catch {
            print("\(label) Shader: \(error.localizedDescription)")
        }
    }

    override public func clone() -> Shader {
        var clone: SourceShader!

        if let pipelineURL = pipelineURL {
            clone = type(of: self).init(label, pipelineURL, vertexFunctionName, fragmentFunctionName)
        }
        else if let shaderSource = shaderSource {
            clone = type(of: self).init(
                label: label,
                source: shaderSource,
                vertexFunctionName: vertexFunctionName,
                fragmentFunctionName: fragmentFunctionName
            )
        }
        else {
            fatalError("Source Shader improperly constructed")
        }

        clone.label = label
        clone.pipelineURL = pipelineURL
        clone.library = library
        clone.pipeline = pipeline
        clone.source = source

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
