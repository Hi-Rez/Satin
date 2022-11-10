typedef struct {
    float roughness;
} SpecularUniforms;

kernel void specularCompute(
    uint2 gid [[thread_position_in_grid]],
    texture2d<float, access::write> tex0 [[texture( 0 )]],
    texture2d<float, access::write> tex1 [[texture( 1 )]],
    texture2d<float, access::write> tex2 [[texture( 2 )]],
    texture2d<float, access::write> tex3 [[texture( 3 )]],
    texture2d<float, access::write> tex4 [[texture( 4 )]],
    texture2d<float, access::write> tex5 [[texture( 5 )]],
    texturecube<float, access::sample> ref [[texture( 6 )]],
    constant SpecularUniforms &uniforms [[buffer( 0 )]] )
{
    if( gid.x >= tex0.get_width() || gid.y >= tex0.get_height() ) {
        return;
    }

    constexpr sampler s( mag_filter::linear, min_filter::linear, mip_filter::linear );
    const texture2d<float, access::write> tex[6] = { tex0, tex1, tex2, tex3, tex4, tex5 };
    const float2 size = float2( tex0.get_width(), tex0.get_height() ) - 1.0;
    const float2 uv = float2( gid ) / size;
    const float roughness = uniforms.roughness;
    const float alpha = roughness * roughness;
    // tex.write( float4( uv, 1.0, 1.0 ), gid );

    float2 ruv = 2.0 * uv - 1.0;
    ruv.y *= -1.0;

    for(int face = 0; face < 6; face++) {
        const float4 rotation = rotations[face];
        const float3 N = normalize( float3( ruv, 1.0 ) * rotateAxisAngle( rotation.xyz, rotation.w ) );
        // tex.write( float4( normal, 1.0 ), gid, i, 0 );
        // make the simplyfying assumption that V equals R equals the normal
        const float3 R = N;
        const float3 V = R;

        float3 prefilteredColor = float3( 0.0, 0.0, 0.0 );
        float totalWeight = 0.0;
        
        for( uint i = 0u; i < SAMPLE_COUNT; ++i ) {
            // generates a sample vector that's biased towards the preferred alignment direction (importance sampling).
            float2 Xi = hammersley( i, SAMPLE_COUNT );
            float3 H = importanceSampleGGX( Xi, N, alpha );
            float3 L = normalize( 2.0 * dot( V, H ) * H - V );

            const float NdotL = max( dot( N, L ), 0.0 );
            if( NdotL > 0.0 ) {
                // sample from the environment's mip level based on roughness/pdf

                const float NdotH = max( dot( N, H ), 0.0 );
                const float HdotV = max( dot( H, V ), 0.0 );
                const float D = distributionGGX( NdotH, alpha );
                const float pdf = ( D * NdotH / ( 4.0 * HdotV ) ) + 0.0001;

                const float resolution = float( ref.get_width() ); // resolution of source cubemap (per face)
                const float saTexel = 4.0 * PI / ( 6.0 * resolution * resolution );
                const float saSample = 1.0 / ( float( SAMPLE_COUNT ) * pdf + 0.0001 );

                const float mipLevel = roughness == 0.0 ? 0.0 : 0.5 * log2( saSample / saTexel );

                prefilteredColor += ref.sample( s, L, level( mipLevel ) ).rgb * NdotL;
                totalWeight += NdotL;
            }
        }

        prefilteredColor = prefilteredColor / totalWeight;
        tex[face].write( float4( prefilteredColor, 1.0 ), gid );
    }
    // int scale = ref.get_width() / tex.get_width();
    // tex.write( ref.read( scale * gid, 0, 0 ), gid, 0, 0 );
    // tex.write( ref.read( scale * gid, 1, 0 ), gid, 1, 0 );
    // tex.write( ref.read( scale * gid, 2, 0 ), gid, 2, 0 );
    // tex.write( ref.read( scale * gid, 3, 0 ), gid, 3, 0 );
    // tex.write( ref.read( scale * gid, 4, 0 ), gid, 4, 0 );
    // tex.write( ref.read( scale * gid, 5, 0 ), gid, 5, 0 );

    // tex.write( float4( 0.0 ), gid, 0, 0 );
    // tex.write( float4( 0.0 ), gid, 1, 0 );
    // tex.write( float4( 0.0 ), gid, 2, 0 );
    // tex.write( float4( 0.0 ), gid, 3, 0 );
    // tex.write( float4( 0.0 ), gid, 4, 0 );
    // tex.write( float4( 0.0 ), gid, 5, 0 );
}
