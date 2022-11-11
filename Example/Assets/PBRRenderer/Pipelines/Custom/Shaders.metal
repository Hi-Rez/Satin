#define IRRADIANCE_MAP true
#define REFLECTION_MAP true
#define BRDF_MAP true
#define HAS_MAPS true

#include "Library/Pbr/Pbr.metal"

typedef struct {
    float4 color; // color
} CustomUniforms;

typedef struct {
	float4 position [[position]];
    float3 worldPos;
    float3 cameraPos;
	float3 normal;
	float roughness [[flat]];
	float metallic [[flat]];
} CustomVertexData;

vertex CustomVertexData customVertex(
	Vertex v [[stage_in]],
	uint iid [[instance_id]],
	constant VertexUniforms &uniforms [[buffer( VertexBufferVertexUniforms )]] )
{
	float4 position = v.position;
	position.x += ( iid % 7 - 3.0 ) * 2.5;
	position.y += ( iid / 7 - 3.0 ) * 2.5;
	const float4 worldPosition = uniforms.modelMatrix * position;
	const float3 worldCameraPosition = uniforms.worldCameraPosition;

	return {
		.position = uniforms.viewProjectionMatrix * worldPosition,
		.worldPos = worldPosition.xyz,
		.cameraPos = worldCameraPosition,
		.normal = v.normal,
		.roughness = (float)( iid % 7 ) / 7.0,
		.metallic = (float)( iid / 7 ) / 7.0
	};
}

fragment float4 customFragment( CustomVertexData in [[stage_in]],
    // inject lighting args
    texturecube<float> irradianceMap [[texture( PBRTextureIrradiance )]],
    texturecube<float> reflectionMap [[texture( PBRTextureReflection )]],
    texture2d<float> brdfMap [[texture( PBRTextureBRDF )]],
    constant CustomUniforms &uniforms [[buffer(FragmentBufferMaterialUniforms)]])
{
    Material mat;

    mat.roughness = in.roughness;
    mat.metallic = in.metallic;
    mat.baseColor = uniforms.color.rgb;
    mat.ao = 1.0;
    mat.emissiveColor = 0.0;
    mat.alpha = uniforms.color.a;
    mat.N = normalize(in.normal);
    
    pbrInit(mat, in.worldPos, in.cameraPos, 0.04);

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
