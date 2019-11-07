#include "../../Library/Shadow.metal"

fragment float4 frag(VertexData in [[stage_in]],
                                   constant BasicShadowUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]],
                                   depth2d<float> shadowTexture [[ texture( FragmentTextureShadow ) ]])
{
    float4 color = uniforms.color;
    color.a *= (1.0 - calculateShadow(in.shadowPosition, in.position, shadowTexture));
    return color;
}
