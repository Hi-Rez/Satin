#include "Library/Pbr/Pbr.metal"

typedef struct {
    float4 baseColor;         // color,1,1,1,1
    float4 emissiveColor;     // color,0,0,0,0
    float subsurface;         // slider,0.0,1.0,0.0
    float roughness;          // slider,0.0,1.0,0.25
    float metallic;           // slider,0.0,1.0,0.0
    float anisotropic;        // slider,-1.0,1.0,0.0
    float specular;           // slider,0.0,1.0,0.5
    float specularTint;       // slider,0.0,1.0,0.0
    float clearcoat;          // slider,0.0,1.0,0.0
    float clearcoatRoughness; // slider,0.0,1.0,0.0
    float sheen;              // slider,0.0,1.0,0.0
    float sheenTint;          // slider,0.0,1.0,0.0
    float transmission;       // slider,0.0,1.0,0.0
    float thickness;          // slider,0.0,5.0,0.0
    float ior;                // slider,1.0,3.0,1.5
} PhysicalUniforms;

typedef struct {
    float4 position [[position]];
    float3 normal;
#if defined(HAS_TANGENTS)
    float3 tangent;
#endif
#if defined(HAS_BITANGENTS)
    float3 bitangent;
#endif
    float2 texcoords;
    float3 worldPos;
    float3 cameraPos;
#if defined(HAS_TRANSMISSION)
    float3 thickness;
#endif
} CustomVertexData;

vertex CustomVertexData physicalVertex(
    Vertex in [[stage_in]],
    // inject instancing args
    constant VertexUniforms &vertexUniforms [[buffer(VertexBufferVertexUniforms)]],
    constant PhysicalUniforms &uniforms [[buffer(FragmentBufferMaterialUniforms)]])
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
#if defined(HAS_TANGENTS)
     out.tangent = normalMatrix * in.tangent;
#endif
#if defined(HAS_BITANGENTS)
    out.bitangent = in.bitangent;
#endif
    out.worldPos = (modelMatrix * in.position).xyz;
    out.cameraPos = vertexUniforms.worldCameraPosition.xyz;
#if defined(HAS_TRANSMISSION)
    float3 modelScale;
    modelScale.x = length(modelMatrix[0].xyz);
    modelScale.y = length(modelMatrix[1].xyz);
    modelScale.z = length(modelMatrix[2].xyz);
    out.thickness = uniforms.thickness * modelScale;
#endif
    return out;
}

fragment float4 physicalFragment(
    CustomVertexData in [[stage_in]],
    // inject lighting args
    // inject texture args
    constant PhysicalUniforms &uniforms [[buffer(FragmentBufferMaterialUniforms)]])
{
#include "Chunks/Pbr/FragInit.metal"

    pbrInit(pixel);

#if defined(MAX_LIGHTS)
    pbrDirectLighting(pixel, lights);
#endif

#if defined(USE_IBL)
    pbrIndirectLighting(irradianceMap, reflectionMap, brdfMap, pixel);
#endif
    
    return float4(pbrTonemap(pixel), material.alpha);
}
