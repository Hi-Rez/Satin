#include "../Types.metal"

#include "Satin/Includes.metal"
#include "Library/Hammersley.metal"
#include "Library/Random.metal"

typedef struct {
    int count; //input
} ComputeUniforms;

float3 generatePosition( uint index, uint count )
{
    float2 pos = 80.0 * hammersley( index, count ) - 40.0;
    float z = -200.0 + 200.0 * random( float2( float( index ), 0.0 ) );
    return float3( pos, z );
}

kernel void resetCompute( uint index [[thread_position_in_grid]],
    device Particle *inBuffer [[buffer( 0 )]],
    device Particle *outBuffer [[buffer( 1 )]],
    const device ComputeUniforms &uniforms [[buffer( 2 )]] )
{
    Particle out;
    out.position = generatePosition( index, uint( uniforms.count ) );
    out.velocity = float3( 0.0, 0.0, 0.25 + random( float2( float( index ), 0.0 ) ) );
    outBuffer[index] = out;
    inBuffer[index] = out;
}

kernel void updateCompute( uint index [[thread_position_in_grid]],
    const device Particle *inBuffer [[buffer( 0 )]],
    device Particle *outBuffer [[buffer( 1 )]],
    const device ComputeUniforms &uniforms [[buffer( 2 )]] )
{
    Particle in = inBuffer[index];
    Particle out;
    out.position = in.position + in.velocity;
    out.velocity = in.velocity;
    if( out.position.z > 100.0 ) {
        out.position = generatePosition( index, uint( uniforms.count ) );
    }
    outBuffer[index] = out;
}
