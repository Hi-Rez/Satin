typedef struct {
    int face;
} SkyboxUniforms;

kernel void skyboxCompute(
    uint2 gid [[thread_position_in_grid]],
    texture2d<float, access::write> tex [[texture( 0 )]],
    texture2d<float, access::sample> ref [[texture( 1 )]],
    constant SkyboxUniforms &uniforms [[buffer( 0 )]] )
{
    if( gid.x >= tex.get_width() || gid.y >= tex.get_height() ) {
        return;
    }
    constexpr sampler s( mag_filter::linear, min_filter::linear );

    const int face = uniforms.face;
    const float2 size = float2( tex.get_width(), tex.get_height() ) - 1.0;
    const float2 uv = float2( gid ) / size;
    // tex.write( float4( uv, float( face ) / 6.0, 1.0 ), gid );

    float2 ruv = 2.0 * uv - 1.0;
    ruv.y *= -1.0;

    const float4 rotation = rotations[face];
    const float3 dir = normalize( float3( ruv, 1.0 ) * rotateAxisAngle( rotation.xyz, rotation.w ) );
    // tex.write( float4( dir, 1.0 ), gid );

    float theta = atan2( dir.x, dir.z );
    theta = ( theta > 0 ? theta : ( TWO_PI + theta ) ) / TWO_PI;
    const float phi = asin( dir.y );

    const float2 suv = float2( fract( theta + 0.5 ), 1.0 - ( phi + HALF_PI ) / PI );

    float3 color = ref.sample( s, suv ).rgb;
     
    // HDR tonemapping
     color = color / ( color + float3( 1.0 ) );
     // gamma correct
     color = pow( color, float3( 1.0 / 2.2 ) );
    tex.write( float4( color, 1.0 ), gid );
}
