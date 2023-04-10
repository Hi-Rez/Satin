#include "Library/Pbr/Pbr.metal"

typedef struct {
#include "Chunks/PbrUniforms.metal"
} CustomUniforms;

typedef struct {
	float4 position [[position]];
    float3 worldPosition;
    float3 normal;
    float3 cameraPosition;
	float roughness [[flat]];
	float metallic [[flat]];
} CustomVertexData;

vertex CustomVertexData customVertex(Vertex in [[stage_in]],
#if INSTANCING
    uint instanceID [[instance_id]],
    constant InstanceMatrixUniforms *instanceUniforms [[buffer(VertexBufferInstanceMatrixUniforms)]],
#endif
    constant VertexUniforms &vertexUniforms [[buffer(VertexBufferVertexUniforms)]])
{
    CustomVertexData out;
#if INSTANCING
    out.position = vertexUniforms.viewProjectionMatrix * instanceUniforms[instanceID].modelMatrix * in.position;
    out.worldPosition = (instanceUniforms[instanceID].modelMatrix * in.position).xyz;
    out.normal = instanceUniforms[instanceID].normalMatrix * in.normal;
#else
    out.position = vertexUniforms.modelViewProjectionMatrix * in.position;
    out.worldPosition = (vertexUniforms.modelMatrix * in.position).xyz;
    out.normal = vertexUniforms.normalMatrix * in.normal;
#endif

    out.cameraPosition = vertexUniforms.worldCameraPosition;
    out.roughness = (float) ( (int)instanceID % 11 ) / 10.0;
    out.metallic = (float) ( (int)instanceID / 11 ) / 10.0;
    
    return out;
}

fragment float4 customFragment( CustomVertexData in [[stage_in]],
    // inject lighting args
#include "Chunks/PbrTextures.metal"
    constant CustomUniforms &uniforms [[buffer(FragmentBufferMaterialUniforms)]])
{
#include "Chunks/PixelInfo.metal"
#include "Chunks/PixelInfoInitView.metal"
#include "Chunks/PixelInfoInitPosition.metal"

    pixel.normal = normalize(in.normal);
    
    pixel.material.baseColor = uniforms.baseColor.rgb;
    pixel.material.roughness = in.roughness;
    pixel.material.metallic = in.metallic;
    pixel.material.specular = 0.5;
    pixel.material.ambientOcclusion = 1.0;
    pixel.material.emissiveColor = uniforms.emissiveColor.rgb * uniforms.emissiveColor.a;
    pixel.material.environmentIntensity = uniforms.environmentIntensity;
    pixel.material.gammaCorrection = uniforms.gammaCorrection;
    pixel.material.alpha = uniforms.baseColor.a;

    float4 outColor;

#include "Chunks/PbrInit.metal"
#include "Chunks/PbrDirectLighting.metal"
#include "Chunks/PbrInDirectLighting.metal"
#include "Chunks/PbrTonemap.metal"
    
    return outColor;
}
