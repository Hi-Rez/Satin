kernel void diffuseCompute(uint2 gid [[thread_position_in_grid]],
                           texture2d<float, access::write> tex0 [[texture( 0 )]],
                           texture2d<float, access::write> tex1 [[texture( 1 )]],
                           texture2d<float, access::write> tex2 [[texture( 2 )]],
                           texture2d<float, access::write> tex3 [[texture( 3 )]],
                           texture2d<float, access::write> tex4 [[texture( 4 )]],
                           texture2d<float, access::write> tex5 [[texture( 5 )]],
                           texturecube<float, access::sample> ref [[texture( 6 )]])
{
	if( gid.x >= tex0.get_width() || gid.y >= tex0.get_height() ) {
		return;
	}

    const texture2d<float, access::write> tex[6] = { tex0, tex1, tex2, tex3, tex4, tex5 };
	const float2 size = float2( tex0.get_width(), tex0.get_height() ) - 1.0;
	const float2 uv = float2( gid ) / size;

	constexpr sampler s( mag_filter::linear, min_filter::linear );

	float2 ruv = 2.0 * uv - 1.0;
	ruv.y *= -1.0;
    
    for(int face = 0; face < 6; face++) {
        const float4 rotation = rotations[face];
        float3 dir = float3( ruv, 1.0 ) * rotateAxisAngle( rotation.xyz, rotation.w );
        dir = normalize( dir );

        float3 irradiance = float3( 0.0, 0.0, 0.0 );
        const float3 right = cross( worldUp, dir );
        const float3 up = cross( dir, right );

        float sampleDelta = 0.025;
        float nrSamples = 0.0;
        for( float phi = 0.0; phi < 2.0 * PI; phi += sampleDelta ) {
            const float sinPhi = sin( phi );
            const float cosPhi = cos( phi );
            for( float theta = 0.0; theta < HALF_PI; theta += sampleDelta ) {
                // spherical to cartesian (in tangent space)
                const float sinTheta = sin( theta );
                const float cosTheta = cos( theta );
                const float3 tangentSample = float3( sinTheta * cosPhi, sinTheta * sinPhi, cosTheta );
                // tangent space to world
                const float3 sampleVec = tangentSample.x * right + tangentSample.y * up + tangentSample.z * dir;
                irradiance += ref.sample( s, sampleVec ).rgb * cosTheta * sinTheta;
                nrSamples += 1.0;
            }
        }
        irradiance = PI * irradiance / nrSamples;
        tex[face].write( float4( irradiance, 1.0 ), gid );
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
