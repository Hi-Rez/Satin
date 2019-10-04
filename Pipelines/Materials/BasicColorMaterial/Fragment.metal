#include "../../Library/Shadow.metal"

fragment float4 basicColorFragment(VertexData in [[stage_in]],
                                   constant BasicColorUniforms &uniforms [[buffer( 0 )]],
                                   depth2d<float> shadowTexture [[ texture(0) ]])
{
    float4 color = uniforms.color;
    color.rgb *= calculateShadow(in.shadowPosition, in.position, shadowTexture);    
    return color;
}
