#include "Library/Shapes.metal"
#include "Library/Noise3D.metal"

typedef struct {
    float time;
    float3 appResolution;
} CustomUniforms;

fragment float4 customFragment( VertexData in [[stage_in]],
                               constant CustomUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]] )
{
    float2 uv = 2.0 * in.uv - 1.0;
    uv.x *= uniforms.appResolution.z;
    float2 norm = normalize( uv );

    const float radius = 0.75 + 0.125 * snoise( 0.5 * float3( norm, uniforms.time ) );
    float result = Circle( uv, radius );
    result /= fwidth( result );
    result = 1.0 - saturate( result );
    return float4( float3( result ), 0.75 );
}
