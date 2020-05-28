#include "Pi.metal"

float2 gmod( float2 x, float2 y )
{
    return x - y * floor( x / y );
}

float gmod( float x, float y )
{
    return x - y * floor( x / y );
}

int2 repeat( thread float2 &uv, float2 div )
{
    int2 cells = int2( floor( uv * ( 1.0 / div ) ) );
    uv = gmod( uv, div ) / div;
    return cells;
}

float polar( thread float2 &uv, float divisions )
{
    const float angle = 2 * PI / divisions;
    float a = atan2( uv.y, uv.x ) + angle / 2.0;
    const float r = length( uv );
    const float c = floor( a / angle );
    a = gmod( a, angle ) - angle / 2.0;
    uv = float2( cos( a ), sin( a ) ) * r;
    return c;
}
