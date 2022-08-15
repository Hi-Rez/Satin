float geometrySchlickGGXI( float NdotV, float roughness )
{
    const float a = roughness;
    const float k = ( a * a ) / 2.0;
    const float nom = NdotV;
    const float denom = NdotV * ( 1.0 - k ) + k;
    return nom / denom;
}

float geometrySmithI( float NdotV, float NdotL, float roughness )
{
    const float ggx2 = geometrySchlickGGXI( NdotV, roughness );
    const float ggx1 = geometrySchlickGGXI( NdotL, roughness );
    return ggx1 * ggx2;
}

float2 integrate( float NdotV, float Roughness )
{
    const float3 N = float3( 0.0, 0.0, 1.0 );
    float3 V;
    V.x = sqrt( 1.0f - NdotV * NdotV ); // sin
    V.y = 0.0;
    V.z = NdotV; // cos
    float A = 0;
    float B = 0;
    const uint NumSamples = 1024;
    for( uint i = 0; i < NumSamples; i++ ) {
        const float2 Xi = hammersley( i, NumSamples );
        const float3 H = importanceSampleGGX( Xi, N, Roughness );
        const float3 L = 2.0 * dot( V, H ) * H - V;
        float NdotL = saturate( L.z );
        float NdotH = saturate( H.z );
        float VdotH = dot( V, H );
        if( NdotL > 0 ) {
            float G = geometrySmithI( NdotV, NdotL, Roughness );
            float G_Vis = G * VdotH / ( NdotH * NdotV );
            float Fc = pow( 1.0 - VdotH, 5 );
            A += ( 1.0 - Fc ) * G_Vis;
            B += Fc * G_Vis;
        }
    }
    return float2( A, B ) / float( NumSamples );
}

kernel void integrationCompute(
    uint2 gid [[thread_position_in_grid]],
    texture2d<float, access::write> tex [[texture( 0 )]] )
{
    if( gid.x >= tex.get_width() || gid.y >= tex.get_height() ) {
        return;
    }

    const float2 size = float2( tex.get_width(), tex.get_height() );
    const float2 uv = float2( 1 + ( gid ) ) / ( size );

    tex.write( float4( integrate( uv.x, uv.y ), 0.0, 1.0 ), gid );
}
