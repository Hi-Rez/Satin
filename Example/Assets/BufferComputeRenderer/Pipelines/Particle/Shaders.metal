#include "../Types.metal"

#include "Library/Pbr/Hammersley.metal"
#include "Library/Random.metal"

typedef struct {
    int count; //input
} ParticleUniforms;

float3 generatePosition( uint index, uint count )
{
    float2 pos = 80.0 * hammersley( index, count ) - 40.0;
    float z = -200.0 + 200.0 * random( float2( float( index ), 0.0 ) );
    return float3( pos, z );
}

kernel void particleReset( uint index [[thread_position_in_grid]],
    device Particle *outBuffer [[buffer( ComputeBufferCustom0 )]],
    const device ParticleUniforms &uniforms [[buffer( ComputeBufferUniforms )]] )
{
    Particle out;
    out.position = generatePosition( index, uint( uniforms.count ) );
    out.velocity = float3( 0.0, 0.0, 0.25 + random( float2( float( index ), 0.0 ) ) );
    outBuffer[index] = out;
}

kernel void particleUpdate( uint index [[thread_position_in_grid]],
    device Particle *outBuffer [[buffer( ComputeBufferCustom0 )]],
    const device ParticleUniforms &uniforms [[buffer( ComputeBufferUniforms )]] )
{
    Particle in = outBuffer[index];
    Particle out;
    out.position = in.position + in.velocity;
    out.velocity = in.velocity;
    if( out.position.z > 100.0 ) {
        out.position = generatePosition( index, uint( uniforms.count ) );
    }
    outBuffer[index] = out;
}
