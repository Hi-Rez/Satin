#include "Library/Pbr/Pbr.metal"

typedef struct {
    float4 baseColor;           // color,1,1,1,1
    float4 emissiveColor;       // color,0,0,0,1
    float roughness;            // slider,0.0,1.0,0.0
    float metallic;             // slider,0.0,1.0,0.0
    float specular;             // slider,0.0,1.0,0.5
    float environmentIntensity; // slider,0.0,1.0,1.0
} StandardUniforms;

typedef struct {
    float4 position [[position]];
    // inject shadow coords
    float3 normal;
    float2 texcoords;
    float3 worldPosition;
    float3 cameraPosition;
} CustomVertexData;

vertex CustomVertexData standardVertex
(
    Vertex in [[stage_in]],
    // inject instancing args
    // inject shadow vertex args
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
    out.position = vertexUniforms.viewProjectionMatrix * modelMatrix * in.position;
    out.texcoords = in.uv;
    out.normal = normalMatrix * in.normal;
    out.worldPosition = (modelMatrix * in.position).xyz;
    out.cameraPosition = vertexUniforms.worldCameraPosition.xyz;

    // inject shadow vertex calc
    
    return out;
}

fragment float4 standardFragment
(
    CustomVertexData in [[stage_in]],
    // inject lighting args
    // inject texture args
    // inject shadow fragment args
    constant StandardUniforms &uniforms [[buffer(FragmentBufferMaterialUniforms)]])
{
    float4 outColor;

#include "Chunks/PixelInfoInit.metal"
#include "Chunks/PbrInit.metal"
#include "Chunks/PbrDirectLighting.metal"
#include "Chunks/PbrInDirectLighting.metal"

#include "Chunks/PbrTonemap.metal"

    // inject shadow fragment calc

    return outColor;
}
