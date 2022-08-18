float3 vortexForce( float3 p, float3 startPt, float3 endPt, float radius, float power )
{
	float3 se = startPt - endPt;
	float lenSe = length( se );
	float3 sen = normalize( se );

	float3 centerPt = endPt + sen * lenSe * 0.5;
	float rad = lenSe * 0.5;

	float3 pe = p - endPt;
	float dotPe = dot( pe, sen );

	float3 ptOnWire = dotPe * sen + endPt;

	float dFC = length( centerPt - p );

	if( dFC < rad * radius ) {
		float3 rv = p - ptOnWire;
		float lenRv = length( rv );
		return ( cross( sen, rv ) / pow( lenRv, power ) );
	}
	return float3( 0.0f );
}
