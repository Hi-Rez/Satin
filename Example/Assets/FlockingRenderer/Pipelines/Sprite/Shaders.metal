#include "../Types.metal"
#include "Library/Shapes.metal"
#include "Library/Colors.metal"
#include "Library/Pi.metal"
#include "Library/Map.metal"

typedef struct {
	float time;
} SpriteUniforms;

float angle2( float2 a )
{
	float theta = atan2( a.y, a.x );
	if( theta < 0 ) {
		theta += PI * 2.0;
	}
	return theta;
}

typedef struct {
    float4 position [[position]];
    float3 normal;
    float pointSize [[point_size]];
} CustomVertexData;

vertex CustomVertexData spriteVertex( uint instanceID [[instance_id]],
	Vertex in [[stage_in]],
	constant VertexUniforms &uniforms [[buffer( VertexBufferVertexUniforms )]],
	constant SpriteUniforms &sprite [[buffer( VertexBufferMaterialUniforms )]],
	const device Flocking *particles [[buffer( VertexBufferCustom0 )]],
	constant FlockingUniforms &compute [[buffer( VertexBufferCustom1 )]] )
{
    Flocking particle = particles[instanceID];
	float4 position = in.position;
	position.xy += particle.position;
    
    const float2 vel = normalize( particle.velocity );
    
    CustomVertexData out;
	out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
	out.normal = turbo( angle2( vel ) / TWO_PI );
	out.pointSize = particle.radius;
	return out;
}

fragment float4 spriteFragment( CustomVertexData in [[stage_in]],
	const float2 puv [[point_coord]],
	constant SpriteUniforms &sprite [[buffer( FragmentBufferMaterialUniforms )]] )
{
	const float2 uv = 2.0 * puv - 1.0;
	const float smoothing = 0.1;
	float result = Circle( uv, 1.0 ) + smoothing;
	result = smoothstep( smoothing, 0.0 - fwidth( result ), result );
	float4 color = float4( in.normal.rgb, 1.0 );
	color.a *= result;
	return color;
}
