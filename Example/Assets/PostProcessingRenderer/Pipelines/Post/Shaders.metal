#include "Library/Repeat.metal"

typedef struct {
} PostUniforms;

fragment float4 postFragment( VertexData in [[stage_in]],
    constant PostUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]],
    texture2d<float, access::sample> renderTex [[texture( FragmentTextureCustom0 )]] )
{
    constexpr sampler s = sampler( min_filter::linear, mag_filter::linear );

    const float aspect = float(renderTex.get_width()) / float(renderTex.get_height());
    
    float2 uv = in.uv;
    uv.x *= aspect;
    
    float div = 0.01;
    int2 cell = repeat( uv, div );
    
    float2 suv = float2(cell) * div;
    suv.x /= aspect;

    return renderTex.sample( s, suv );
}
