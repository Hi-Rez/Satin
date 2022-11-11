//
//  Pipelines.swift
//  Satin
//
//  Created by Reza Ali on 9/15/19.
//

import Metal

public func makeRenderPipeline(library: MTLLibrary?,
                               vertex: String,
                               fragment: String,
                               label: String,
                               context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex), let fragmentProgram = library.makeFunction(name: fragment) {
        let device = library.device
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = context.colorPixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = context.depthPixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = context.stencilPixelFormat
        return try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    return nil
}

public func makeRenderPipeline(library: MTLLibrary?,
                               vertex: String,
                               fragment: String,
                               fragmentConstants: MTLFunctionConstantValues,
                               label: String,
                               context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex) {
        let device = library.device
        let fragmentProgram = try library.makeFunction(name: fragment, constantValues: fragmentConstants)
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = context.colorPixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = context.depthPixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = context.stencilPixelFormat
        return try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    return nil
}

public func makeRenderPipeline(library: MTLLibrary?,
                               vertex: String,
                               vertexConstants: MTLFunctionConstantValues,
                               fragment: String,
                               fragmentConstants: MTLFunctionConstantValues,
                               label: String,
                               context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library {
        let device = library.device
        let vertexProgram = try library.makeFunction(name: vertex, constantValues: vertexConstants)
        let fragmentProgram = try library.makeFunction(name: fragment, constantValues: fragmentConstants)
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = context.colorPixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = context.depthPixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = context.stencilPixelFormat
        return try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    return nil
}

public func makeIndirectRenderPipeline(library: MTLLibrary?,
                                       vertex: String,
                                       fragment: String,
                                       label: String,
                                       context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex), let fragmentProgram = library.makeFunction(name: fragment) {
        let device = library.device
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = context.colorPixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = context.depthPixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = context.stencilPixelFormat
        pipelineStateDescriptor.supportIndirectCommandBuffers = true
        return try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    return nil
}

public func makeRenderPipeline(library: MTLLibrary?,
                               vertex: String,
                               fragment: String,
                               label: String,
                               context: Context,
                               sourceRGBBlendFactor: MTLBlendFactor,
                               sourceAlphaBlendFactor: MTLBlendFactor,
                               destinationRGBBlendFactor: MTLBlendFactor,
                               destinationAlphaBlendFactor: MTLBlendFactor,
                               rgbBlendOperation: MTLBlendOperation,
                               alphaBlendOperation: MTLBlendOperation) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex), let fragmentProgram = library.makeFunction(name: fragment) {
        let device = library.device
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = label
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = context.colorPixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = context.depthPixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = context.stencilPixelFormat

        if let colorAttachment = pipelineStateDescriptor.colorAttachments[0] {
            colorAttachment.isBlendingEnabled = true

            colorAttachment.sourceRGBBlendFactor = sourceRGBBlendFactor
            colorAttachment.sourceAlphaBlendFactor = sourceAlphaBlendFactor
            colorAttachment.destinationRGBBlendFactor = destinationRGBBlendFactor
            colorAttachment.destinationAlphaBlendFactor = destinationAlphaBlendFactor
            colorAttachment.rgbBlendOperation = rgbBlendOperation
            colorAttachment.alphaBlendOperation = alphaBlendOperation
        }

        return try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    return nil
}

public func makeAlphaRenderPipeline(library: MTLLibrary?,
                                    vertex: String,
                                    fragment: String,
                                    label: String,
                                    context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex), let fragmentProgram = library.makeFunction(name: fragment) {
        let device = library.device
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = context.colorPixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = context.depthPixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = context.stencilPixelFormat

        if let colorAttachment = pipelineStateDescriptor.colorAttachments[0] {
            colorAttachment.isBlendingEnabled = true
            colorAttachment.rgbBlendOperation = .add
            colorAttachment.alphaBlendOperation = .add
            colorAttachment.sourceRGBBlendFactor = .sourceAlpha
            colorAttachment.sourceAlphaBlendFactor = .sourceAlpha
            colorAttachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
            colorAttachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        }

        return try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    return nil
}

public func makeAlphaRenderPipeline(library: MTLLibrary?,
                                    vertex: String,
                                    fragment: String,
                                    fragmentConstants: MTLFunctionConstantValues,
                                    label: String,
                                    context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex) {
        let device = library.device
        let fragmentProgram = try library.makeFunction(name: fragment, constantValues: fragmentConstants)
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = context.colorPixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = context.depthPixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = context.stencilPixelFormat

        if let colorAttachment = pipelineStateDescriptor.colorAttachments[0] {
            colorAttachment.isBlendingEnabled = true
            colorAttachment.rgbBlendOperation = .add
            colorAttachment.alphaBlendOperation = .add
            colorAttachment.sourceRGBBlendFactor = .sourceAlpha
            colorAttachment.sourceAlphaBlendFactor = .sourceAlpha
            colorAttachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
            colorAttachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        }

        return try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    return nil
}

public func makeShadowRenderPipeline(library: MTLLibrary?,
                                     vertex: String,
                                     label: String,
                                     context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex) {
        let device = library.device
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = nil
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = context.colorPixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = context.depthPixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = context.stencilPixelFormat
        return try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    return nil
}

public func makeAdditiveRenderPipeline(library: MTLLibrary?,
                                       vertex: String,
                                       fragment: String,
                                       label: String,
                                       context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex), let fragmentProgram = library.makeFunction(name: fragment) {
        let device = library.device
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = context.colorPixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = context.depthPixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = context.stencilPixelFormat

        if let colorAttachment = pipelineStateDescriptor.colorAttachments[0] {
            colorAttachment.isBlendingEnabled = true
            colorAttachment.rgbBlendOperation = .add
            colorAttachment.alphaBlendOperation = .add
            colorAttachment.sourceRGBBlendFactor = .sourceAlpha
            colorAttachment.sourceAlphaBlendFactor = .one
            colorAttachment.destinationRGBBlendFactor = .one
            colorAttachment.destinationAlphaBlendFactor = .one
        }

        return try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    return nil
}

public func makeSubtractRenderPipeline(library: MTLLibrary?,
                                       vertex: String,
                                       fragment: String,
                                       label: String,
                                       context: Context) throws -> MTLRenderPipelineState?
{
    if let library = library, let vertexProgram = library.makeFunction(name: vertex), let fragmentProgram = library.makeFunction(name: fragment) {
        let device = library.device
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = context.sampleCount
        pipelineStateDescriptor.vertexDescriptor = SatinVertexDescriptor
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = context.colorPixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = context.depthPixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = context.stencilPixelFormat

        if let colorAttachment = pipelineStateDescriptor.colorAttachments[0] {
            colorAttachment.isBlendingEnabled = true
            colorAttachment.sourceRGBBlendFactor = .sourceAlpha
            colorAttachment.sourceAlphaBlendFactor = .sourceAlpha
            colorAttachment.destinationRGBBlendFactor = .oneMinusBlendColor
            colorAttachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
            colorAttachment.rgbBlendOperation = .reverseSubtract
            colorAttachment.alphaBlendOperation = .add
        }

        return try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    return nil
}

public func makeComputePipeline(library: MTLLibrary?,
                                kernel: String) throws -> MTLComputePipelineState?
{
    if let library = library, let kernelFunction = library.makeFunction(name: kernel) {
        let device = library.device
        return try device.makeComputePipelineState(function: kernelFunction)
    }
    return nil
}

public func compilePipelineSource(_ label: String) throws -> String? {
    guard let satinURL = getPipelinesSatinUrl(),
          let materialsURL = getPipelinesMaterialsUrl() else { return nil }

    let materialURL = materialsURL.appendingPathComponent(label)

    let includesURL = satinURL.appendingPathComponent("Includes.metal")
    let shadersURL = materialURL.appendingPathComponent("Shaders.metal")

    let compiler = MetalFileCompiler()
    do {
        var source = try compiler.parse(includesURL)
        source += try compiler.parse(shadersURL)
        return source
    }
    catch {
        print(error)
        return nil
    }
}

public func injectConstants(source: inout String) {
    source = source.replacingOccurrences(of: "// inject constants\n", with: (ConstantsSource.get() ?? "\n") + "\n")
}

public func injectDefines(source: inout String, defines: [String: String]) {
    var injection = ""
    for define in defines { injection += "#define \(define.key) \(define.value)\n" }
    source = source.replacingOccurrences(of: "// inject defines\n", with: injection.isEmpty ? "\n" : injection + "\n")
}

public func injectVertex(source: inout String) {
    source = source.replacingOccurrences(of: "// inject vertex\n", with: (VertexSource.get() ?? "\n") + "\n")
}

public func injectVertex(source: inout String, vertexDescriptor: MTLVertexDescriptor) {
    var vertexSource: String?
    if vertexDescriptor == SatinVertexDescriptor {
        vertexSource = VertexSource.get()
    }
    else {
        var vertexDataType: [String] = []
        var vertexName: [String] = []
        var vertexAttributes: [String] = []

        for i in 0..<31 {
            let format = vertexDescriptor.attributes[i].format
            switch format {
            case .invalid:
                break
            case .uchar2:
                vertexDataType.append("uchar2")
            case .uchar3:
                vertexDataType.append("uchar3")
            case .uchar4:
                vertexDataType.append("uchar4")
            case .char2:
                vertexDataType.append("char2")
            case .char3:
                vertexDataType.append("char3")
            case .char4:
                vertexDataType.append("char4")
            case .uchar2Normalized:
                vertexDataType.append("uchar2")
            case .uchar3Normalized:
                vertexDataType.append("uchar3")
            case .uchar4Normalized:
                vertexDataType.append("uchar4")
            case .char2Normalized:
                vertexDataType.append("char2")
            case .char3Normalized:
                vertexDataType.append("char3")
            case .char4Normalized:
                vertexDataType.append("char4")
            case .ushort2:
                vertexDataType.append("ushort2")
            case .ushort3:
                vertexDataType.append("ushort3")
            case .ushort4:
                vertexDataType.append("ushort4")
            case .short2:
                vertexDataType.append("short2")
            case .short3:
                vertexDataType.append("short3")
            case .short4:
                vertexDataType.append("short4")
            case .ushort2Normalized:
                vertexDataType.append("ushort2")
            case .ushort3Normalized:
                vertexDataType.append("ushort3")
            case .ushort4Normalized:
                vertexDataType.append("ushort4")
            case .short2Normalized:
                vertexDataType.append("short2")
            case .short3Normalized:
                vertexDataType.append("short3")
            case .short4Normalized:
                vertexDataType.append("short4")
            case .half2:
                vertexDataType.append("half2")
            case .half3:
                vertexDataType.append("half3")
            case .half4:
                vertexDataType.append("half4")
            case .float:
                vertexDataType.append("float")
            case .float2:
                vertexDataType.append("float2")
            case .float3:
                vertexDataType.append("float3")
            case .float4:
                vertexDataType.append("float4")
            case .int:
                vertexDataType.append("int")
            case .int2:
                vertexDataType.append("int2")
            case .int3:
                vertexDataType.append("int3")
            case .int4:
                vertexDataType.append("int4")
            case .uint:
                vertexDataType.append("uint")
            case .uint2:
                vertexDataType.append("uint2")
            case .uint3:
                vertexDataType.append("uint3")
            case .uint4:
                vertexDataType.append("uint4")
            case .int1010102Normalized:
                vertexDataType.append("long4")
            case .uint1010102Normalized:
                vertexDataType.append("long4")
            case .uchar4Normalized_bgra:
                vertexDataType.append("uchar4")
            case .uchar:
                vertexDataType.append("uchar")
            case .char:
                vertexDataType.append("char")
            case .ucharNormalized:
                vertexDataType.append("uchar")
            case .charNormalized:
                vertexDataType.append("char")
            case .ushort:
                vertexDataType.append("ushort")
            case .short:
                vertexDataType.append("short")
            case .ushortNormalized:
                vertexDataType.append("ushort")
            case .shortNormalized:
                vertexDataType.append("short")
            case .half:
                vertexDataType.append("half")

            @unknown default:
                fatalError("Unknown vertex format: \(format)")
            }

            if let attri = VertexAttribute(rawValue: i) {
                vertexName.append(attri.name)
                vertexAttributes.append(attri.description)
            }
        }

        var structMembers: [String] = []
        for i in 0..<vertexDataType.count {
            structMembers.append("\t\(vertexDataType[i]) \(vertexName[i]) [[attribute(VertexAttribute\(vertexAttributes[i]))]];")
        }

        if !structMembers.isEmpty {
            var generatedVertexSource = "typedef struct {\n"
            generatedVertexSource += structMembers.joined(separator: "\n")
            generatedVertexSource += "\n} Vertex;\n"
            vertexSource = generatedVertexSource
        }
    }

    source = source.replacingOccurrences(of: "// inject vertex\n", with: (vertexSource ?? "\n") + "\n")
}

public func injectVertexData(source: inout String) {
    source = source.replacingOccurrences(of: "// inject vertex data\n", with: (VertexDataSource.get() ?? "\n") + "\n")
}

public func injectVertexUniforms(source: inout String) {
    source = source.replacingOccurrences(of: "// inject vertex uniforms\n", with: VertexUniformsSource.get() ?? "\n")
}

public func injectLighting(source: inout String, lighting: Bool) {
    source = source.replacingOccurrences(of: "// inject lighting\n", with: lighting ? (LightingSource.get() ?? "\n") : "\n")
}

public func injectInstanceMatrixUniforms(source: inout String, instancing: Bool) {
    source = source.replacingOccurrences(of: "// inject instance matrix uniforms\n", with: instancing ? (InstanceMatrixUniformsSource.get() ?? "\n") : "\n")
}

public func injectPassThroughVertex(label: String, source: inout String) {
    let vertexFunctionName = label.camelCase + "Vertex"
    if !source.contains(vertexFunctionName), let passThroughVertexSource = PassThroughVertexPipelineSource.get() {
        let vertexSource = passThroughVertexSource.replacingOccurrences(of: "satinVertex", with: vertexFunctionName)
        source = source.replacingOccurrences(of: "// inject vertex shader\n", with: vertexSource + "\n")
    }
    else {
        source = source.replacingOccurrences(of: "// inject vertex shader\n", with: "\n")
    }
}

public func injectPassThroughVertex(source: inout String) {
    source = source.replacingOccurrences(of: "// inject vertex shader\n", with: (PassThroughVertexPipelineSource.get() ?? "\n") + "\n")
}

public func injectInstancingArgs(source: inout String, instancing: Bool) {
    let injection =
    """
    \tuint instanceID [[instance_id]],
    \tconstant InstanceMatrixUniforms *instanceUniforms [[buffer(VertexBufferInstanceMatrixUniforms)]],\n
    """
    source = source.replacingOccurrences(of: "// inject instancing args\n", with: instancing ? injection : "")
}

public func injectLightingArgs(source: inout String, lighting: Bool) {
    let injection = "\tconstant Light *lights [[buffer(FragmentBufferLighting)]],\n"
    source = source.replacingOccurrences(of: "// inject lighting args\n", with: lighting ? injection : "")
}

class PassThroughVertexPipelineSource {
    static let shared = PassThroughVertexPipelineSource()
    private static var sharedSource: String?

    class func get() -> String? {
        guard PassThroughVertexPipelineSource.sharedSource == nil else {
            return sharedSource
        }
        if let vertexURL = getPipelinesCommonUrl("VertexShader.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(vertexURL)
            }
            catch {
                print(error)
            }
        }
        return sharedSource
    }
}

class ConstantsSource {
    static let shared = ConstantsSource()
    private static var sharedSource: String?

    class func get() -> String? {
        guard ConstantsSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinUrl("Constants.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            }
            catch {
                print(error)
            }
        }
        return sharedSource
    }
}

class VertexSource {
    static let shared = VertexSource()
    private static var sharedSource: String?

    class func get() -> String? {
        guard VertexSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinUrl("Vertex.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            }
            catch {
                print(error)
            }
        }
        return sharedSource
    }
}

class VertexDataSource {
    static let shared = VertexDataSource()
    private static var sharedSource: String?

    class func get() -> String? {
        guard VertexDataSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinUrl("VertexData.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            }
            catch {
                print(error)
            }
        }
        return sharedSource
    }
}

class VertexUniformsSource {
    static let shared = VertexUniformsSource()
    private static var sharedSource: String?

    class func get() -> String? {
        guard VertexUniformsSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinUrl("VertexUniforms.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            }
            catch {
                print(error)
            }
        }
        return sharedSource
    }
}

class InstanceMatrixUniformsSource {
    static let shared = InstanceMatrixUniformsSource()
    private static var sharedSource: String?

    class func get() -> String? {
        guard InstanceMatrixUniformsSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinUrl("InstanceMatrixUniforms.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            }
            catch {
                print(error)
            }
        }
        return sharedSource
    }
}

class LightingSource {
    static let shared = LightingSource()
    private static var sharedSource: String?

    class func get() -> String? {
        guard LightingSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinUrl("Light.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            }
            catch {
                print(error)
            }
        }
        return sharedSource
    }
}

class InstancingArgsSource {
    static let shared = InstancingArgsSource()
    private static var sharedSource: String?

    class func get() -> String? {
        guard InstancingArgsSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinUrl("InstancingArgs.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            }
            catch {
                print(error.localizedDescription)
            }
        }
        return sharedSource
    }
}

public func injectTexturesArgs(source: inout String, maps: Set<PBRTexture>) {
    var injection: String = ""
    for map in maps {
        injection += "\t\(map.textureType)<float> \(map.textureName) [[texture(\(map.textureIndex))]],\n"
    }
    source = source.replacingOccurrences(of: "// inject texture args\n", with: injection)
}

class TextureArgsSource {
    static let shared = TextureArgsSource()
    private static var sharedSource: String?

    class func get() -> String? {
        guard TextureArgsSource.sharedSource == nil else {
            return sharedSource
        }
        if let url = getPipelinesSatinUrl("TextureArgs.metal") {
            do {
                sharedSource = try MetalFileCompiler(watch: false).parse(url)
            }
            catch {
                print(error.localizedDescription)
            }
        }
        return sharedSource
    }
}
