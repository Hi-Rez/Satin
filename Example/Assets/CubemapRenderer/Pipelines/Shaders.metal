#include "Library/Pbr/Fresnel/FresnelSchlick.metal"

typedef struct {
    float4 position [[position]];
    float3 worldPosition;
    float3 cameraPosition;
    float3 normal;
    float2 uv;
} CustomVertexData;

vertex CustomVertexData customVertex( Vertex v [[stage_in]],
    constant VertexUniforms &uniforms
    [[buffer( VertexBufferVertexUniforms )]] )
{
    const float4 position = v.position;
    CustomVertexData out;
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    out.uv = v.uv;
    out.normal = v.normal;

    const float3 worldPosition = ( uniforms.modelMatrix * position ).xyz;
    out.worldPosition = worldPosition;
    const float3 worldCameraPosition = uniforms.worldCameraPosition;
    out.cameraPosition = worldCameraPosition;
    return out;
}

fragment float4 customFragment( CustomVertexData in [[stage_in]],
    texturecube<float> cubeTexture [[texture( FragmentTextureCustom0 )]] )
{
    constexpr sampler s( mag_filter::linear, min_filter::linear, mip_filter::linear );

    const float3 normal = normalize(in.normal);
    const float3 view = normalize(in.cameraPosition - in.worldPosition);

    float3 reflectUV = reflect( -view, normal );
    const float4 reflectColor = cubeTexture.sample( s, reflectUV );

    float3 refractUV = refract( -view, normal, 1.0/1.5 );
    const float4 refractColor = cubeTexture.sample( s, refractUV );

    const float3 f = fresnelSchlick( dot(view, normal), 0.04, 1.0 );

    float4 color = refractColor;
    color.rgb = mix( color.rgb, reflectColor.rgb, f );
    return color;
}
