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
    out.roughness = (float) ( (int)instanceID % 10 ) / 10.0;
    out.metallic = (float) ( (int)instanceID / 10 ) / 10.0;
    
    return out;
}

fragment float4 customFragment( CustomVertexData in [[stage_in]],
    // inject lighting args
    texturecube<float> irradianceMap [[texture( PBRTextureIrradiance )]],
    texturecube<float> reflectionMap [[texture( PBRTextureReflection )]],
    texture2d<float> brdfMap [[texture( PBRTextureBRDF )]],
    constant CustomUniforms &uniforms [[buffer(FragmentBufferMaterialUniforms)]])
{
    Material material;

    material.roughness = in.roughness;
    material.metallic = in.metallic;
    material.reflectance = 0.5;
    material.baseColor = uniforms.baseColor.rgb;
    material.ao = 1.0;
    material.emissiveColor = uniforms.emissiveColor.rgb * uniforms.emissiveColor.a;
    material.alpha = uniforms.baseColor.a;
    material.N = normalize(in.normal);
    
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
        material
    );

    return float4(pbrTonemap(material), material.alpha);
}
