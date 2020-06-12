typedef struct {
    float roughness;
    int face;
} SpecularUniforms;

static constant float4 rotations[6] = {
    float4( 0.0, 1.0, 0.0, HALF_PI ),
    float4( 0.0, 1.0, 0.0, -HALF_PI ),
    float4( 1.0, 0.0, 0.0, -HALF_PI ),
    float4( 1.0, 0.0, 0.0, HALF_PI ),
    float4( 0.0, 0.0, 1.0, 0.0 ),
    float4( 0.0, 1.0, 0.0, PI )
};

kernel void specularCompute(
    uint2 gid [[thread_position_in_grid]],
    texture2d<float, access::write> tex [[texture( 0 )]],
    texturecube<float, access::sample> ref [[texture( 1 )]],
    constant SpecularUniforms &uniforms [[buffer( 0 )]] )
{
    if( gid.x >= tex.get_width() || gid.y >= tex.get_height() ) {
        return;
    }

    const int face = uniforms.face;
    const float roughness = uniforms.roughness;
    
    const float2 size = float2( tex.get_width(), tex.get_height() ) - 1.0;
    const float2 uv = float2( gid ) / size;
    // tex.write( float4( uv, 1.0, 1.0 ), gid );

    constexpr sampler s( mag_filter::linear, min_filter::linear, mip_filter::linear );

    float2 ruv = 2.0 * uv - 1.0;
    ruv.y *= -1.0;

    const float4 rotation = rotations[face];
    const float3 normal = normalize( float3( ruv, 1.0 ) * rotateAxisAngle( rotation.xyz, rotation.w ) );
    // tex.write( float4( normal, 1.0 ), gid, i, 0 );
    // make the simplyfying assumption that V equals R equals the normal
    const float3 reflection = normal;
    const float3 view = reflection;

    float3 prefilteredColor = float3( 0.0, 0.0, 0.0 );
    float totalWeight = 0.0;

    const uint SAMPLE_COUNT = 1024u;
    for( uint i = 0u; i < SAMPLE_COUNT; ++i ) {
        // generates a sample vector that's biased towards the preferred alignment direction (importance sampling).
        float2 Xi = hammersley( i, SAMPLE_COUNT );
        float3 halfway = importanceSampleGGX( Xi, normal, roughness );
        float3 light = normalize( 2.0 * dot( view, halfway ) * halfway - view );

        float NdotL = max( dot( normal, light ), 0.0 );
        if( NdotL > 0.0 ) {
            // sample from the environment's mip level based on roughness/pdf

            float NdotH = max( dot( normal, halfway ), 0.0 );
            float HdotV = max( dot( halfway, view ), 0.0 );
            float D = distributionGGX( NdotH, roughness );
            float pdf = D * NdotH / ( 4.0 * HdotV ) + 0.0001;

            float resolution = float( ref.get_width() ); // resolution of source cubemap (per face)
            float saTexel = 4.0 * PI / ( 6.0 * resolution * resolution );
            float saSample = 1.0 / ( float( SAMPLE_COUNT ) * pdf + 0.0001 );

            float mipLevel = roughness == 0.0 ? 0.0 : 0.5 * log2( saSample / saTexel );

            prefilteredColor += ref.sample( s, light, level( mipLevel ) ).rgb * NdotL;
            totalWeight += NdotL;
        }
    }

    prefilteredColor = prefilteredColor / totalWeight;
    tex.write( float4( prefilteredColor, 1.0 ), gid );

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
