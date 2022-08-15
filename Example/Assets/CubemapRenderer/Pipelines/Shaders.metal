#include "Library/Fresnel.metal"

typedef struct {
    float4 position [[position]];
    float3 worldPosition;
    float3 cameraPosition;
    float3 worldEyeDirection;
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
    out.worldEyeDirection = normalize( worldPosition - worldCameraPosition );
    return out;
}

fragment float4 customFragment( CustomVertexData in [[stage_in]],
    texturecube<float> cubeTexture [[texture( FragmentTextureCustom0 )]] )
{
    constexpr sampler s( mag_filter::linear, min_filter::linear, mip_filter::linear );

    const float3 normal = in.normal;
    const float3 worldEyeDirection = in.worldEyeDirection;

    float3 reflectUV = reflect( worldEyeDirection, normal );
    reflectUV.z *= -1.0;
    const float4 reflectColor = cubeTexture.sample( s, reflectUV );

    float3 refractUV = refract( worldEyeDirection, normal, 0.925 );
    refractUV.z *= -1.0;
    const float4 refractColor = cubeTexture.sample( s, refractUV );

    const float f = 2.0 * fresnel( worldEyeDirection, normal, 4.0 );

    float4 color = refractColor;
    color.rgb = mix( color.rgb, reflectColor.rgb, f );
    return color;
}
