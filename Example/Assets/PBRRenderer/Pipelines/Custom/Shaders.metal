#define IRRADIANCE_MAP true
#define REFLECTION_MAP true
#define BRDF_MAP true
#define HAS_MAPS true

#include "Library/Pbr/Pbr.metal"

typedef struct {
    float4 baseColor; // color
    float4 emissiveColor; // color
} CustomUniforms;

typedef struct {
	float4 position [[position]];
    float3 worldPos;
    float3 normal;
    float3 cameraPos;
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
    out.worldPos = (instanceUniforms[instanceID].modelMatrix * in.position).xyz;
    out.normal = instanceUniforms[instanceID].normalMatrix * in.normal;
#else
    out.position = vertexUniforms.modelViewProjectionMatrix * in.position;
    out.worldPos = (vertexUniforms.modelMatrix * in.position).xyz;
    out.normal = vertexUniforms.normalMatrix * in.normal;
#endif

    out.cameraPos = vertexUniforms.worldCameraPosition;
    out.roughness = (float) ( (int)instanceID % 11 ) / 10.0;
    out.metallic = (float) ( (int)instanceID / 11 ) / 10.0;
    
    return out;
}

fragment float4 customFragment( CustomVertexData in [[stage_in]],
    // inject lighting args
    texturecube<float> irradianceMap [[texture( PBRTextureIrradiance )]],
    texturecube<float> reflectionMap [[texture( PBRTextureReflection )]],
    texture2d<float> brdfMap [[texture( PBRTextureBRDF )]],
    constant CustomUniforms &uniforms [[buffer(FragmentBufferMaterialUniforms)]])
{
    PixelInfo pixel;
    pixel.view = normalize(in.cameraPos - in.worldPos);
    pixel.position = in.worldPos;
    pixel.normal = normalize(in.normal);
    
    pixel.material.baseColor = uniforms.baseColor.rgb;
    pixel.material.roughness = in.roughness;
    pixel.material.metallic = in.metallic;
    pixel.material.specular = 0.5;
    pixel.material.ambientOcclusion = 1.0;
    pixel.material.emissiveColor = uniforms.emissiveColor.rgb * uniforms.emissiveColor.a;
    pixel.material.alpha = uniforms.baseColor.a;
    
    pbrInit(pixel);

#if defined(MAX_LIGHTS)
    pbrDirectLighting(pixel, &lights);
#endif

#if defined(USE_IBL)
    pbrIndirectLighting(irradianceMap, reflectionMap, brdfMap, pixel);
#endif

    return float4(pbrTonemap(pixel), pixel.material.alpha);
}
