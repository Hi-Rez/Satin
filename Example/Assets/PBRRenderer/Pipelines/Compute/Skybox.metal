kernel void skyboxCompute(
    uint2 gid [[thread_position_in_grid]],
    texture2d<float, access::write> tex0 [[texture( 0 )]],
    texture2d<float, access::write> tex1 [[texture( 1 )]],
    texture2d<float, access::write> tex2 [[texture( 2 )]],
    texture2d<float, access::write> tex3 [[texture( 3 )]],
    texture2d<float, access::write> tex4 [[texture( 4 )]],
    texture2d<float, access::write> tex5 [[texture( 5 )]],
    texture2d<float, access::sample> ref [[texture( 6 )]])
{
    if( gid.x >= tex0.get_width() || gid.y >= tex0.get_height() ) {
        return;
    }
    
    constexpr sampler s( mag_filter::linear, min_filter::linear );
    const texture2d<float, access::write> tex[6] = { tex0, tex1, tex2, tex3, tex4, tex5 };
    const float2 size = float2( tex0.get_width(), tex0.get_height() ) - 1.0;
    const float2 uv = float2( gid ) / size;
    // tex.write( float4( uv, float( face ) / 6.0, 1.0 ), gid );

    float2 ruv = 2.0 * uv - 1.0;
    ruv.y *= -1.0;

    for(int face = 0; face < 6; face++) {
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
        tex[face].write( float4( color, 1.0 ), gid );
    }
}
