#define worldUp float3( 0.0, 1.0, 0.0 )

kernel void diffuseCompute(
	uint2 gid [[thread_position_in_grid]],
	texturecube<float, access::write> tex [[texture( 0 )]],
	texturecube<float, access::sample> ref [[texture( 1 )]] )
{
	if( gid.x >= tex.get_width() || gid.y >= tex.get_height() ) {
		return;
	}

	const float2 size = float2( tex.get_width(), tex.get_height() ) - 1.0;
	const float2 uv = float2( gid ) / size;

	constexpr sampler s( mag_filter::linear, min_filter::linear );

	float2 ruv = 2.0 * uv - 1.0;
	ruv.y *= -1.0;

	const float4 rotations[6] = {
		float4( 0.0, 1.0, 0.0, HALF_PI ),
		float4( 0.0, 1.0, 0.0, -HALF_PI ),
		float4( 1.0, 0.0, 0.0, -HALF_PI ),
		float4( 1.0, 0.0, 0.0, HALF_PI ),
		float4( 0.0, 0.0, 1.0, 0.0 ),
		float4( 0.0, 1.0, 0.0, PI )
	};

	for( int i = 0; i < 6; i++ ) {
		const float4 rotation = rotations[i];
		float3 dir = float3( ruv, 1.0 ) * rotateAxisAngle( rotation.xyz, rotation.w );
		dir = normalize( dir );
		//        tex.write( ref.sample( s, dir ), gid, i, 0 );

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
				const float3 tangentSample = float3( sinTheta * cosPhi, sinTheta * sinPhi, cos( theta ) );
				// tangent space to world
				const float3 sampleVec = tangentSample.x * right + tangentSample.y * up + tangentSample.z * dir;
				irradiance += ref.sample( s, sampleVec ).rgb * cosTheta * sinTheta;
				nrSamples += 1.0;
			}
		}
		irradiance = PI * irradiance / nrSamples;
		tex.write( float4( irradiance, 1.0 ), gid, i, 0 );
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
