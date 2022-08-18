float2 boundary( float2 p, const float2 res, float radius )
{
	if( ( p.x - radius ) > res.x ) {
		p.x = -res.x;
	}
	else if( ( p.x + radius ) < -res.x ) {
		p.x = res.x;
	}
	if( ( p.y - radius ) > res.y ) {
		p.y = -res.y;
	}
	else if( ( p.y + radius ) < -res.y ) {
		p.y = res.y;
	}
	return p;
}
