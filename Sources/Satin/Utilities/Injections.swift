//
//  Injections.swift
//  Satin
//
//  Created by Reza Ali on 3/3/23.
//

import Foundation
import Metal

// MARK: - Constants

func injectConstants(source: inout String) {
    source = source.replacingOccurrences(of: "// inject constants\n", with: (ConstantsSource.get() ?? "\n") + "\n")
}

// MARK: - Defines

func injectDefines(source: inout String, defines: [String: String]) {
    var injection = ""
    for define in defines { injection += "#define \(define.key) \(define.value)\n" }
    source = source.replacingOccurrences(of: "// inject defines\n", with: injection.isEmpty ? "\n" : injection + "\n")
}

// MARK: - Vertex, VertexData, VertexUniforms, Vertex Shader

func injectVertex(source: inout String, vertexDescriptor: MTLVertexDescriptor) {
    var vertexSource: String?
    if vertexDescriptor == SatinVertexDescriptor {
        vertexSource = VertexSource.get()
    } else {
        var vertexDataType: [String] = []
        var vertexName: [String] = []
        var vertexAttributes: [String] = []

        for i in 0 ..< 31 {
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
        for i in 0 ..< vertexDataType.count {
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

func injectVertexData(source: inout String) {
    source = source.replacingOccurrences(of: "// inject vertex data\n", with: (VertexDataSource.get() ?? "\n") + "\n")
}

func injectVertexUniforms(source: inout String) {
    source = source.replacingOccurrences(of: "// inject vertex uniforms\n", with: VertexUniformsSource.get() ?? "\n")
}

func injectPassThroughVertex(label: String, source: inout String) {
    let vertexFunctionName = label.camelCase + "Vertex"
    if !source.contains(vertexFunctionName),
       let passThroughVertexSource = PassThroughVertexPipelineSource.get()
    {
        let vertexSource = passThroughVertexSource.replacingOccurrences(of: "satinVertex", with: vertexFunctionName)
        source = source.replacingOccurrences(of: "// inject vertex shader\n", with: vertexSource + "\n")
    } else {
        source = source.replacingOccurrences(of: "// inject vertex shader\n", with: "\n")
    }
}

// MARK: - PBR

func injectPBRTexturesArgs(source: inout String, maps: Set<PBRTextureIndex>) {
    var injection = ""
    for map in maps {
        injection += "\t\(map.textureType)<float> \(map.textureName) [[texture(\(map.textureIndex))]],\n"
    }
    source = source.replacingOccurrences(of: "// inject texture args\n", with: injection)
}

// MARK: - Instancing

func injectInstanceMatrixUniforms(source: inout String, instancing: Bool) {
    source = source.replacingOccurrences(of: "// inject instance matrix uniforms\n", with: instancing ? (InstanceMatrixUniformsSource.get() ?? "\n") : "\n")
}

func injectInstancingArgs(source: inout String, instancing: Bool) {
    let injection =
        """
        \tuint instanceID [[instance_id]],
        \tconst device InstanceMatrixUniforms *instanceUniforms [[buffer(VertexBufferInstanceMatrixUniforms)]],\n
        """
    source = source.replacingOccurrences(of: "// inject instancing args\n", with: instancing ? injection : "")
}

// MARK: - Lights

func injectLighting(source: inout String, lighting: Bool) {
    source = source.replacingOccurrences(of: "// inject lighting\n", with: lighting ? (LightingSource.get() ?? "\n") : "\n")
}

func injectLightingArgs(source: inout String, lighting: Bool) {
    let injection = "\tconstant LightData *lights [[buffer(FragmentBufferLighting)]],\n"
    source = source.replacingOccurrences(of: "// inject lighting args\n", with: lighting ? injection : "")
}

// MARK: - Shadows

func injectShadowData(source: inout String, receiveShadow: Bool, shadowCount: Int) {
    var injection = ""
    if receiveShadow, shadowCount > 0, let shadowDataSource = ShadowDataSource.get() {
        injection = shadowDataSource
    }
    source = source.replacingOccurrences(of: "// inject shadow data\n", with: injection)
}

func injectShadowBuffer(source: inout String, receiveShadow: Bool, shadowCount: Int) {
    var injection = ""
    if receiveShadow, shadowCount > 0 {
        injection += "struct Shadows {\n"
        injection += "\tconstant ShadowData *data [[buffer(FragmentBufferShadowData)]];\n"
        injection += "\tarray<depth2d<float>, \(shadowCount)> textures [[texture(FragmentTextureShadow0)]];\n"
        injection += "};\n\n"
    }
    source = source.replacingOccurrences(of: "// inject shadow buffer\n", with: injection)
}

func injectShadowFunction(source: inout String, receiveShadow: Bool, shadowCount: Int) {
    var injection = ""
    if receiveShadow, shadowCount > 0, let shadowFunctionSource = ShadowFunctionSource.get() {
        injection = shadowFunctionSource
    }
    source = source.replacingOccurrences(of: "// inject shadow function\n", with: injection)
}

func injectPassThroughShadowVertex(label: String, source: inout String) {
    let shadowFunctionName = label.camelCase + "ShadowVertex"
    if !source.contains(shadowFunctionName),
       let passThroughShadowSource = PassThroughShadowPipelineSource.get()
    {
        let shadowSource = passThroughShadowSource.replacingOccurrences(of: "satinShadowVertex", with: shadowFunctionName)
        source = source.replacingOccurrences(of: "// inject shadow shader\n", with: shadowSource + "\n")
    } else {
        source = source.replacingOccurrences(of: "// inject shadow shader\n", with: "\n")
    }
}

func injectShadowCoords(source: inout String, receiveShadow: Bool, shadowCount: Int) {
    var injection = ""
    if receiveShadow {
        for i in 0 ..< shadowCount {
            if i > 0 {
                injection += "\t"
            }
            injection += "float4 shadowCoord\(i);\n"
        }
    }
    source = source.replacingOccurrences(of: "// inject shadow coords\n", with: injection)
}

func injectShadowVertexArgs(source: inout String, receiveShadow: Bool) {
    let injection = "constant float4x4 *shadowMatrices [[buffer(VertexBufferShadowMatrices)]],\n"
    source = source.replacingOccurrences(of: "// inject shadow vertex args\n", with: receiveShadow ? injection : "")
}

func injectShadowFragmentArgs(source: inout String, receiveShadow: Bool, shadowCount: Int) {
    var injection = ""
    if receiveShadow, shadowCount > 0 {
        injection += "constant Shadows &shadows [[buffer(FragmentBufferShadows)]],\n"
    }

    source = source.replacingOccurrences(of: "// inject shadow fragment args\n", with: injection)
}

func injectShadowVertexCalc(source: inout String, receiveShadow: Bool, shadowCount: Int) {
    var injection = ""
    if receiveShadow {
        for i in 0 ..< shadowCount {
            if i > 0 {
                injection += "\t"
            }
            injection += "out.shadowCoord\(i) = shadowMatrices[\(i)] * vertexUniforms.modelMatrix * in.position;\n"
        }
    }
    source = source.replacingOccurrences(of: "// inject shadow vertex calc\n", with: injection)
}

func injectShadowFragmentCalc(source: inout String, receiveShadow: Bool, shadowCount: Int) {
    var injection = ""

    if receiveShadow, shadowCount > 0 {
        injection += "float shadow = 1.0;\n"
        injection += "\tconstexpr sampler ss(coord::normalized, address::clamp_to_edge, filter::linear, compare_func::greater_equal);\n"
        for i in 0 ..< shadowCount {
            injection += "\tshadow *= calculateShadow(in.shadowCoord\(i), shadows.textures[\(i)], shadows.data[\(i)], ss);\n"
        }
        injection += "\toutColor.rgb *= shadow;\n\n"
    }

    source = source.replacingOccurrences(of: "// inject shadow fragment calc\n", with: injection)
}
