#include "Library/Repeat.metal"
#include "Library/Shapes.metal"
#include "Library/Luminance.metal"

typedef struct {
} PostUniforms;

fragment float4 postFragment( VertexData in [[stage_in]],
    constant PostUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]],
    texture2d<float, access::sample> renderTex [[texture( FragmentTextureCustom0 )]] )
{
    constexpr sampler s = sampler( min_filter::linear, mag_filter::linear );

    float2 uv = in.position.xy;
    float div = 15.0;
    repeat( uv, div );

    uv = 2.0 * uv - 1.0;

    const float4 color = renderTex.sample( s, in.uv );

    float red = Circle( uv + 0.25, luminance( color.rgb ) * 0.5 );
    red = 1.0 - smoothstep( 0.0, 0.05, red );

    float green = Circle( uv - 0.25, luminance2( color.rgb ) * 0.5 );
    green = 1.0 - smoothstep( 0.0, 0.05, green );

    float blue = Circle( uv + float2( 0.25, -0.25 ), luminance3( color.rgb ) * 0.5 );
    blue = 1.0 - smoothstep( 0.0, 0.05, blue );

    return float4( 1.0 - saturate( float3( red, green, blue ) ), 1.0 );
}
