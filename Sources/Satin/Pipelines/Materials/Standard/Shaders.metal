#include "Library/Pbr/Pbr.metal"

typedef struct {
    float4 baseColor;        // color
    float4 emissiveColor;    // color,0,0,0,1
    float4 baseReflectivity; // color,0.04,0.04,0.04,1.0
    float metallic;          // slider,0.0,1.0,0.0
    float roughness;         // slider,0.0,1.0,0.0
} StandardUniforms;

typedef struct {
    float4 position [[position]];
    float3 normal;
    float2 texcoords;
    float3 worldPos;
    float3 cameraPos;
} CustomVertexData;

vertex CustomVertexData standardVertex(
    Vertex in [[stage_in]],
    // inject instancing args
    constant VertexUniforms &vertexUniforms [[buffer(VertexBufferVertexUniforms)]])
{
#if defined(INSTANCING)
    const float3x3 normalMatrix = instanceUniforms[instanceID].normalMatrix;
    const float4x4 modelMatrix = instanceUniforms[instanceID].modelMatrix;
#else
    const float3x3 normalMatrix = vertexUniforms.normalMatrix;
    const float4x4 modelMatrix = vertexUniforms.modelMatrix;
#endif

    CustomVertexData out;
    out.position =
        vertexUniforms.viewProjectionMatrix * modelMatrix * in.position;
    out.texcoords = in.uv;
    out.normal = normalMatrix * in.normal;
    out.worldPos = (modelMatrix * in.position).xyz;
    out.cameraPos = vertexUniforms.worldCameraPosition.xyz;
    return out;
}

fragment float4 standardFragment(
    CustomVertexData in [[stage_in]],
    // inject lighting args
    // inject texture args
    constant StandardUniforms &uniforms [[buffer(FragmentBufferMaterialUniforms)]])
{
    Material mat;

#if defined(ROUGHNESS_MAP)
    mat.roughness = roughnessMap.sample(pbrLinearSampler, in.texcoords).r;
#else
    mat.roughness = uniforms.roughness;
#endif

#if defined(METALLIC_MAP)
    mat.metallic = metallicMap.sample(pbrLinearSampler, in.texcoords).r;
#else
    mat.metallic = uniforms.metallic;
#endif

#if defined(BASE_COLOR_MAP)
    mat.baseColor = baseColorMap.sample(pbrLinearSampler, in.texcoords).rgb;
#else
    mat.baseColor = uniforms.baseColor.rgb;
#endif

#if defined(AMBIENT_OCCULSION_MAP)
    mat.ao = ambientOcclusionMap.sample(pbrLinearSampler, in.texcoords).r;
#else
    mat.ao = 1.0;
#endif

#if defined(EMISSIVE_MAP)
    mat.emissiveColor = emissiveMap.sample(pbrLinearSampler, in.texcoords).rgb;
#else
    mat.emissiveColor = uniforms.emissiveColor.rgb;
#endif

#if defined(ALPHA_MAP)
    mat.alpha = alphaMap.sample(pbrLinearSampler, in.texcoords).r;
#else
    mat.alpha = uniforms.baseColor.a;
#endif

#if defined(NORMAL_MAP)
    constexpr sampler normalSampler(filter::linear);
    float3 mapNormal = normalMap.sample(normalSampler, in.texcoords).rgb * 2.0 - 1.0;

#if defined(HAS_TANGENT) && defined(HAS_HAS_BITANGENT)
    // mapNormal.y = -mapNormal.y; // Flip normal map Y-axis if necessary
    const float3x3 TBN(in.tangent, in.bitangent, in.normal);
    const float3 N = normalize(TBN * mapNormal);
#else
    const float3 Q1 = dfdx(in.worldPos);
    const float3 Q2 = dfdy(in.worldPos);
    const float2 st1 = dfdx(in.texcoords);
    const float2 st2 = dfdy(in.texcoords);

    float3 normal = in.normal;
    float3 tangent = normalize(Q1 * st2.y - Q2 * st1.y);
    float3 bitangent = -normalize(cross(normal, tangent));
    const float3x3 TBN = float3x3(tangent, bitangent, normal);

    mat.N = normalize(TBN * mapNormal);
#endif

#else
    mat.N = normalize(in.normal);
#endif

    pbrInit(mat, in.worldPos, in.cameraPos, uniforms.baseReflectivity.rgb);

#if defined(MAX_LIGHTS)
    pbrDirectLighting(mat, lights);
#endif

    pbrIndirectLighting(
#if defined(IRRADIANCE_MAP)
        irradianceMap,
#endif
#if defined(REFLECTION_MAP)
        reflectionMap,
#endif
#if defined(BRDF_MAP)
        brdfMap,
#endif
        mat);

    return float4(pbrTonemap(mat), mat.alpha);
}
