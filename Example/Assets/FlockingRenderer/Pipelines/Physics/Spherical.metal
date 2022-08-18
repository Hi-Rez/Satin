float3 sphericalForce( float3 p, float3 center, float radius )
{
	float3 d = p - center;
	d = normalize( d );
	d *= radius;
	d += center;
	return ( p - d );
}
