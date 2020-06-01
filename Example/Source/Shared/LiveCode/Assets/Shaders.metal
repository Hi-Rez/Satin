#include "Library/Shapes.metal"

typedef struct {
    float time;
    float3 appResolution;
} CustomUniforms;

fragment float4 customFragment( VertexData in [[stage_in]],
    constant CustomUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]] )
{
    float2 uv = 2.0 * in.uv - 1.0;
    uv.x *= uniforms.appResolution.z;
    const float radius = abs( sin( uniforms.time ) );
    float result = Circle( uv, radius );
    result = smoothstep( 0.0, 0.0 - fwidth( result ), result );
    return float4( float3( result ), 1.0 );
}
