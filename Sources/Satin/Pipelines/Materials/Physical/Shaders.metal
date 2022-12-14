#include "Library/Pbr/Pbr.metal"

typedef struct {
    float4 baseColor;           // color
    float4 emissiveColor;       // color,0,0,0,1
    float metallic;             // slider,0.0,1.0,1.0
    float roughness;            // slider,0.0,1.0,1.0
    float reflectance;          // slider,0.0,1.0,0.5
    float clearCoat;            // slider,0.0,1.0,1.0
    float clearCoatRoughness;   // slider,0.0,1.0,0.8
} PhysicalUniforms;

typedef struct {
    float4 position [[position]];
    float3 normal;
    float2 texcoords;
    float3 worldPos;
    float3 cameraPos;
} CustomVertexData;

vertex CustomVertexData physicalVertex(
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

fragment float4 physicalFragment(
    CustomVertexData in [[stage_in]],
    // inject lighting args
    // inject texture args
    constant PhysicalUniforms &uniforms [[buffer(FragmentBufferMaterialUniforms)]])
{
    Material material;

    material.baseColor = uniforms.baseColor.rgb;
#if defined(BASE_COLOR_MAP)
    material.baseColor *= baseColorMap.sample(pbrLinearSampler, in.texcoords).rgb;
#endif
    
    material.emissiveColor = uniforms.emissiveColor.rgb;
#if defined(EMISSIVE_MAP)
    material.emissiveColor *= emissiveMap.sample(pbrLinearSampler, in.texcoords).rgb;
#endif

    material.roughness = uniforms.roughness;
#if defined(ROUGHNESS_MAP)
    material.roughness *= roughnessMap.sample(pbrLinearSampler, in.texcoords).r;
#endif

    material.metallic = uniforms.metallic;
#if defined(METALLIC_MAP)
    material.metallic *= metallicMap.sample(pbrLinearSampler, in.texcoords).r;
#endif

    material.reflectance = uniforms.reflectance;
    
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
#else
    const float3 Q1 = dfdx(in.worldPos);
    const float3 Q2 = dfdy(in.worldPos);
    const float2 st1 = dfdx(in.texcoords);
    const float2 st2 = dfdy(in.texcoords);

    float3 normal = in.normal;
    float3 tangent = normalize(Q1 * st2.y - Q2 * st1.y);
    float3 bitangent = -normalize(cross(normal, tangent));
    const float3x3 TBN = float3x3(tangent, bitangent, normal);

    material.N = normalize(TBN * mapNormal);
#endif

#else
    material.N = normalize(in.normal);
#endif

#if defined(HAS_CLEAR_COAT)
    material.clearCoat = uniforms.clearCoat;
    material.clearCoatRoughness = uniforms.clearCoatRoughness;
#endif
    
    pbrInit(material, in.worldPos, in.cameraPos);

#if defined(MAX_LIGHTS)
    pbrDirectLighting(material, lights);
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
        material);

    return float4(pbrTonemap(material), material.alpha);
}
