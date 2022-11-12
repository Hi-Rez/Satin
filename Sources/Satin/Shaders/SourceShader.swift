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

    public internal(set) var source: String?
    public var shaderSource: String? {
        didSet {
            if shaderSource != nil, oldValue != shaderSource {
                sourceNeedsUpdate = true
            }
        }
    }

    open var sourceNeedsUpdate: Bool = true {
        didSet {
            if sourceNeedsUpdate {
                libraryNeedsUpdate = true
            }
        }
    }

    override public var instancing: Bool {
        didSet {
            if oldValue != instancing {
                sourceNeedsUpdate = true
            }
        }
    }

    override public var lighting: Bool {
        didSet {
            if oldValue != lighting {
                sourceNeedsUpdate = true
            }
        }
    }

    override public var maxLights: Int {
        didSet {
            if oldValue != maxLights {
                sourceNeedsUpdate = true
            }
        }
    }

    open var defines: [String: String] {
        var results = [String: String]()

        #if os(iOS)
        results["MOBILE"] = "true"
        #endif

        for attribute in VertexAttribute.allCases {
            switch vertexDescriptor.attributes[attribute.rawValue].format {
            case .invalid:
                continue
            default:
                results[attribute.shaderDefine] = "true"
            }
        }

        if instancing {
            results["INSTANCING"] = "true"
        }
        if lighting {
            results["LIGHTING"] = "true"
            if maxLights > -1 {
                results["MAX_LIGHTS"] = "\(maxLights)"
            }
        }
        return results
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
            error = nil
        }
        catch {
            self.error = error
            print("\(label) Shader: \(error.localizedDescription)")
            library = nil
            pipeline = nil
        }

        libraryNeedsUpdate = false
    }

    open func setupShaderSource() -> String? {
        var result: String?

        if let pipelineURL = pipelineURL {
            do {
                result = try MetalFileCompiler(watch: false).parse(pipelineURL)
                error = nil
            }
            catch {
                self.error = error
                print("\(label) Shader: \(error.localizedDescription)")
            }
        }
        else if let shaderSource = shaderSource {
            do {
                result = try compileMetalSource(shaderSource)
                error = nil
            }
            catch {
                self.error = error
                print("\(label) Shader: \(error.localizedDescription)")
            }
        }
        return result
    }

    open func modifyShaderSource(source: inout String) {
        injectInstancingArgs(source: &source, instancing: instancing)
        injectLightingArgs(source: &source, lighting: lighting)
    }

    open func setupSource() {
        guard let satinURL = getPipelinesSatinUrl(), var compiledShaderSource = setupShaderSource() else { return }
        let includesURL = satinURL.appendingPathComponent("Includes.metal")
        do {
            // create boilerplate shader code
            var source = try MetalFileCompiler(watch: false).parse(includesURL)

            injectDefines(source: &source, defines: defines)
            injectConstants(source: &source)

            injectVertex(source: &source, vertexDescriptor: vertexDescriptor)
            injectVertexData(source: &source)
            injectVertexUniforms(source: &source)

            injectLighting(source: &source, lighting: lighting)
            injectInstanceMatrixUniforms(source: &source, instancing: instancing)

            // modify shader if needed, instancing, etc
            modifyShaderSource(source: &compiledShaderSource)

            source += compiledShaderSource

            injectPassThroughVertex(label: label, source: &source)
            shaderSource = compiledShaderSource
            self.source = source

            error = nil
        }
        catch {
            self.error = error
            print("\(label) Shader: \(error.localizedDescription)")
        }

        sourceNeedsUpdate = false
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
        clone.libraryURL = libraryURL
        clone.library = library
        clone.pipelineURL = pipelineURL
        clone.pipeline = pipeline
        clone.pipelineReflection = pipelineReflection
        clone.source = source

        clone.parameters = parameters.clone()

        clone.blending = blending
        clone.sourceRGBBlendFactor = sourceRGBBlendFactor
        clone.sourceAlphaBlendFactor = sourceAlphaBlendFactor
        clone.destinationRGBBlendFactor = destinationRGBBlendFactor
        clone.destinationAlphaBlendFactor = destinationAlphaBlendFactor
        clone.rgbBlendOperation = rgbBlendOperation
        clone.alphaBlendOperation = alphaBlendOperation

        clone.instancing = instancing
        clone.lighting = lighting
        clone.vertexDescriptor = vertexDescriptor

        clone.vertexFunctionName = vertexFunctionName
        clone.fragmentFunctionName = fragmentFunctionName

        return clone
    }
}
