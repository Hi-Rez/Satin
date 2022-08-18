float3 ringForce( float3 p, float3 center, float3 normal, float radius )
{
	float3 deltaPos = p - center;
	float deltaPosLength = length( deltaPos );
	float dotp = dot( ( deltaPos / deltaPosLength ), normal );
	float delta = deltaPosLength * dotp;
	float3 pointOnPlane = p - delta * normal;
	float3 pointOnRing = pointOnPlane - center;
	pointOnRing = normalize( pointOnRing ) * radius + center;
	return ( p - pointOnRing );
}
