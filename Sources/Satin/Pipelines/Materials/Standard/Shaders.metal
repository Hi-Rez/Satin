#include "Library/Pbr/Pbr.metal"

typedef struct {
    float4 baseColor;           // color,1,1,1,1
    float4 emissiveColor;       // color,0,0,0,1
    float subsurface;           // slider,0.0,1.0,0.0
    float roughness;            // slider,0.0,1.0,0.0
    float metallic;             // slider,0.0,1.0,0.0
    float specular;             // slider,0.0,1.0,0.5
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
    PixelInfo pixel;
    pixel.view = normalize(in.cameraPos - in.worldPos);
    pixel.position = in.worldPos;
    
    Material material;

    material.baseColor = uniforms.baseColor.rgb;
#if defined(BASE_COLOR_MAP)
    material.baseColor *= baseColorMap.sample(pbrLinearSampler, in.texcoords).rgb;
#endif

    material.emissiveColor = uniforms.emissiveColor.rgb;
#if defined(EMISSIVE_MAP)
    material.emissiveColor *= emissiveMap.sample(pbrLinearSampler, in.texcoords).rgb;
#endif
    
    material.metallic = uniforms.metallic;
#if defined(METALLIC_MAP)
    material.metallic *= metallicMap.sample(pbrLinearSampler, in.texcoords).r;
#endif
    
    material.roughness = uniforms.roughness;
#if defined(ROUGHNESS_MAP)
    material.roughness *= roughnessMap.sample(pbrLinearSampler, in.texcoords).r;
#endif

    material.specular = uniforms.specular;
    
    material.ao = 1.0;
#if defined(AMBIENT_OCCULSION_MAP)
    material.ao *= ambientOcclusionMap.sample(pbrLinearSampler, in.texcoords).r;
#endif
    
    material.alpha = uniforms.baseColor.a;
#if defined(ALPHA_MAP)
    material.alpha *= alphaMap.sample(pbrLinearSampler, in.texcoords).r;
#endif

#if defined(NORMAL_MAP)
    constexpr sampler normalSampler(filter::linear);
    float3 mapNormal = normalMap.sample(normalSampler, in.texcoords).rgb * 2.0 - 1.0;

#if defined(HAS_TANGENT) && defined(HAS_HAS_BITANGENT)
    // mapNormal.y = -mapNormal.y; // Flip normal map Y-axis if necessary
    const float3x3 TBN(in.tangent, in.bitangent, in.normal);
    const float3 N = normalize(TBN * mapNormal);
    pixel.normal = normalize(TBN * mapNormal);
    
#else
    const float3 Q1 = dfdx(in.worldPos);
    const float3 Q2 = dfdy(in.worldPos);
    const float2 st1 = dfdx(in.texcoords);
    const float2 st2 = dfdy(in.texcoords);

    float3 normal = in.normal;
    float3 tangent = normalize(Q1 * st2.y - Q2 * st1.y);
    float3 bitangent = -normalize(cross(normal, tangent));
    const float3x3 TBN = float3x3(tangent, bitangent, normal);

    pixel.normal = normalize(TBN * mapNormal);
#endif

#else
    pixel.normal = normalize(in.normal);
#endif
    
    pixel.material = material;

    pbrInit(pixel);

#if defined(MAX_LIGHTS)
    pbrDirectLighting(pixel, lights);
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
        pixel);

    return float4(pbrTonemap(pixel), material.alpha);
}
