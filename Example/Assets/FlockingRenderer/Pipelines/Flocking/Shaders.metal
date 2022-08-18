#include "Satin/Includes.metal"
#include "../Types.metal"
#include "../Physics/Flocking.metal"
#include "../Physics/Boundary.metal"
#include "../Physics/Damping.metal"
#include "Library/Random.metal"
#include "Library/Curlnoise.metal"
#include "Library/Pi.metal"
#include "Library/Shapes.metal"

kernel void flockingReset( uint index [[thread_position_in_grid]],
	constant Flocking *inBuffer [[buffer( ComputeBufferCustom0 )]],
	device Flocking *outBuffer [[buffer( ComputeBufferCustom1 )]],
	constant FlockingUniforms &uniforms [[buffer( ComputeBufferUniforms )]] )
{
	const float id = int( index );
	const float2 res = uniforms.resolution.xy;
	const float time = uniforms.time;
	const float fid = float( id );

    Flocking out;
	out.position = 2.0 * res * float2( random( float2( time, fid ) ), random( float2( time, -2.0 * fid ) ) ) - res.xy;
	out.velocity = 2.0 * float2( random( float2( fid, time ) ), random( float2( -2.0 * fid, time ) ) ) - 1.0;
	out.radius = uniforms.radius;
	outBuffer[index] = out;
}

kernel void flockingUpdate( uint index [[thread_position_in_grid]],
	constant Flocking *inBuffer [[buffer( ComputeBufferCustom0 )]],
	device Flocking *outBuffer [[buffer( ComputeBufferCustom1 )]],
	constant FlockingUniforms &uniforms [[buffer( ComputeBufferUniforms )]] )
{
	const int count = uniforms.count;
	const float time = uniforms.time;
	const float2 res = uniforms.resolution.xy;
	const float accelerationMax = uniforms.accelerationMax;
	const float velocityMax = uniforms.velocityMax;

	const Flocking in = inBuffer[index];

    Flocking out;
	float2 p = in.position;
	float2 v = in.velocity;

	float2 a = dampingForce( v, uniforms.damping );
	a += uniforms.flocking * flockingForce( index, p, v, count, uniforms, inBuffer );
	a += uniforms.curl * curlNoise( float3( uniforms.curlScale * p, time * uniforms.curlSpeed ) ).xy;

	const float accelerationMagnitude = length( a );
	if( accelerationMagnitude > accelerationMax ) {
		a /= accelerationMagnitude;
		a *= accelerationMax;
	}

	const float velocityMagnitude = length( v );
	if( velocityMagnitude > velocityMax ) {
		v /= velocityMagnitude;
		v *= velocityMax;
	}

	v += a;
	p += v;
	p = boundary( p, res, uniforms.radius );

	out.position = p;
	out.velocity = v;
	out.radius = uniforms.radius;
	outBuffer[index] = out;
}
