#include "Library/Pbr/Pbr.metal"

typedef struct {
    float4 baseColor;           // color,1,1,1,1
    float4 emissiveColor;       // color,0,0,0,1
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
