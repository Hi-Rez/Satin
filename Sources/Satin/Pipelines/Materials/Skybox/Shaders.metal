#include "Library/Gamma.metal"
#include "Library/Tonemap.metal"

typedef struct {
    float4 color; // color
    float gammaCorrection; //slider,0.0,1.0,1.0
} SkyboxUniforms;

typedef struct {
    float4 position [[position]];
    float3 uv;
} SkyVertexData;

vertex SkyVertexData skyboxVertex(Vertex v [[stage_in]],
// inject instancing args
    constant VertexUniforms &vertexUniforms [[buffer(VertexBufferVertexUniforms)]])
{
#if INSTANCING
    const float4x4 modelViewProjectionMatrix = vertexUniforms.viewProjectionMatrix * instanceUniforms[instanceID].modelMatrix;
#else
    const float4x4 modelViewProjectionMatrix = vertexUniforms.modelViewProjectionMatrix;
#endif

    const float4 position = v.position;
    SkyVertexData out;
    out.position = modelViewProjectionMatrix * position;
    out.uv = position.xyz;
    return out;
}

fragment float4 skyboxFragment(SkyVertexData in [[stage_in]],
    constant SkyboxUniforms &uniforms [[buffer(FragmentBufferMaterialUniforms)]],
    texturecube<float> cubeTex [[texture(FragmentTextureCustom0)]],
    sampler cubeTexSampler [[sampler(FragmentSamplerCustom0)]])
{
    float4 color = cubeTex.sample(cubeTexSampler, in.uv);

    color.rgb = tonemap(color.rgb);

#ifndef TONEMAPPING_UNREAL
    color.rgb = mix(color.rgb, gamma(color.rgb), uniforms.gammaCorrection);
#endif
    
    return uniforms.color * color;
}
