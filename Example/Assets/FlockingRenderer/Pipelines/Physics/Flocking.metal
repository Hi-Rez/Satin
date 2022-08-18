float2 flockingForce(
	uint index,
	float2 pos,
	float2 vel,
	int count,
	constant FlockingUniforms &uniforms,
	constant Flocking *particles )
{
	const int id = int( index );
	const float zoneRadius = uniforms.zoneRadius;

	float neighborCount = 0.0;
	float2 alignmentVelocity = 0.0;
	float2 cohesionPosition = 0.0;
	float2 separationForce = 0.0;
	float2 cohesionVelocity = 0.0;

	for( int i = 0; i < count; i++ ) {
		if( i != id ) {
			constant Flocking &other = particles[i];
			float2 otherPos = other.position;
			float2 otherVel = other.velocity;

			float2 direction = otherPos - pos;
			float dist = length( direction );

			if( dist < zoneRadius ) {
				neighborCount += 1.0;
				separationForce += direction;
				cohesionPosition += otherPos;
				alignmentVelocity += otherVel;
			}
		}
	}
	if( neighborCount > 0.0 ) {
		alignmentVelocity /= neighborCount;
		alignmentVelocity = normalize( alignmentVelocity );

		cohesionPosition /= neighborCount;
		cohesionVelocity = cohesionPosition - pos;
		cohesionVelocity = normalize( cohesionVelocity );

		separationForce /= neighborCount;
		separationForce = -1.0 * normalize( separationForce );
	}

	return alignmentVelocity * uniforms.alignment
		+ cohesionVelocity * uniforms.cohesion
		+ separationForce * uniforms.separation;
}
