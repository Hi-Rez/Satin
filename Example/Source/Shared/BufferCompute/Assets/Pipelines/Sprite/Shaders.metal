#include "../Types.metal"
#include "Library/Shapes.metal"
#include "Library/Map.metal"

typedef struct {
    float4 position [[position]];
    float3 normal;
    float2 uv;
    float pointSize [[point_size]];
} CustomVertexData;

vertex CustomVertexData spriteVertex( uint instanceID [[instance_id]],
    Vertex in [[stage_in]],
    constant VertexUniforms &uniforms
    [[buffer( VertexBufferVertexUniforms )]],
    const device Particle *particles [[buffer( VertexBufferCustom0 )]] )
{
    Particle particle = particles[instanceID];

    float4 position = in.position;
    position.xyz += particle.position;

    CustomVertexData out;
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    out.uv = in.uv;
    out.normal = normalize( uniforms.normalMatrix * in.normal );

    const float cameraDistance = length( uniforms.worldCameraPosition - position.xyz );
    out.pointSize = map( min( cameraDistance, 100.0 ), 0.0, 100.0, 15.0, 0.0 );

    return out;
}

fragment float4 spriteFragment( CustomVertexData in [[stage_in]],
    const float2 puv [[point_coord]] )
{
    const float2 uv = 2.0 * puv - 1.0;
    float result = Circle( uv, 1.0 );
    result = smoothstep( 0.1, 0.0 - fwidth( result ), result );
    return float4( 1.0, 1.0, 1.0, result );
}
