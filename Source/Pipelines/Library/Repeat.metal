float2 gmod( float2 x, float2 y )
{
    return x - y * floor( x / y );
}

int2 repeat( thread float2 &uv, float2 div )
{
    int2 cells = int2( floor( uv * ( 1.0 / div ) ) );
    uv = gmod( uv, div ) / div;
    return cells;
}
