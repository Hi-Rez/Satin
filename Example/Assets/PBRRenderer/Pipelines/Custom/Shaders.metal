#include "Library/Pbr.metal"

typedef struct {
	float4 position [[position]];
	float3 worldPosition;
	float3 cameraPosition [[flat]];
	float3 normal;
	float2 uv;
	float roughness [[flat]];
	float metallic [[flat]];
} CustomVertexData;

vertex CustomVertexData customVertex(
	Vertex v [[stage_in]],
	uint iid [[instance_id]],
	constant VertexUniforms &uniforms [[buffer( VertexBufferVertexUniforms )]] )
{
	float4 position = v.position;
	position.x += ( iid % 7 - 3.0 ) * 2.5;
	position.y += ( iid / 7 - 3.0 ) * 2.5;
	const float4 worldPosition = uniforms.modelMatrix * position;
	const float3 worldCameraPosition = uniforms.worldCameraPosition;

	return {
		.position = uniforms.projectionMatrix * uniforms.viewMatrix * worldPosition,
		.worldPosition = worldPosition.xyz,
		.cameraPosition = worldCameraPosition,
		.normal = v.normal,
		.uv = v.uv,
		.roughness = (float)( iid % 7 ) / 7.0,
		.metallic = (float)( iid / 7 ) / 7.0
	};
}

fragment float4 customFragment( CustomVertexData in [[stage_in]],
	texturecube<float> irradianceTex [[texture( FragmentTextureCustom0 )]],
	texturecube<float> specularTex [[texture( FragmentTextureCustom1 )]],
	texture2d<float> integrationTex [[texture( FragmentTextureCustom2 )]] )
{
	constexpr sampler s( mag_filter::linear, min_filter::linear );

	const float3 worldPosition = in.worldPosition;
	const float3 cameraPosition = in.cameraPosition;
	const float3 view = normalize( cameraPosition - worldPosition );
	const float3 normal = normalize( in.normal ); //getNormalFromMap( normalTex, s, uv, normalize( in.normal ), worldPosition );
	const float3 reflection = reflect( -view, normal );

	const float NdotV = max( dot( normal, view ), 0.00001 );

	const float3 albedo = float3( 1.0, 1.0, 1.0 );
	const float roughness = in.roughness;
	const float metallic = in.metallic;
	const float ao = 1.0;

	const float3 lightPositions[4] = {
		float3( -10.0f, 10.0f, 10.0f ),
		float3( 10.0f, 10.0f, 10.0f ),
		float3( -10.0f, -10.0f, 10.0f ),
		float3( 10.0f, -10.0f, 10.0f ),
	};

	const float3 lightColors[4] = {
		float3( 300.0f, 300.0f, 300.0f ),
		float3( 300.0f, 300.0f, 300.0f ),
		float3( 300.0f, 300.0f, 300.0f ),
		float3( 300.0f, 300.0f, 300.0f )
	};

	// float3 f0 = float3( 1.022, .782, 0.344 );
	float3 f0 = float3( 0.04 );
	f0 = mix( f0, albedo, metallic );

	// reflectance equation
	float3 Lo = float3( 0.0 );
	for( int i = 0; i < 4; i++ ) {
		// calculate per-light radiance
		const float3 light = normalize( lightPositions[i] - worldPosition );
		const float3 halfway = normalize( view + light );
		const float dist = length( lightPositions[i] - worldPosition );
		const float attenuation = 1.0 / ( dist * dist );
		const float3 radiance = lightColors[i] * attenuation;

		// scale light by NdotL
		const float NdotL = max( dot( normal, light ), 0.0001 );
		const float HdotV = max( dot( halfway, view ), 0.0001 );
		const float NdotH = max( dot( normal, halfway ), 0.0001 );

		// Cook-Torrance BRDF
		const float N = distributionGGX( NdotH, roughness );
		const float G = geometrySmith( NdotV, NdotL, roughness );
		const float3 F = fresnelSchlick( HdotV, f0 );

		const float3 nominator = N * G * F;
		const float denominator = 4.0 * NdotV * NdotL;
		const float3 specular = nominator / max( denominator, 0.00001 ); // prevent divide by zero for NdotV=0.0 or NdotL=0.0

		// kS is equal to Fresnel
		const float3 kS = F;
		// for energy conservation, the diffuse and specular light can't
		// be above 1.0 (unless the surface emits light); to preserve this
		// relationship the diffuse component (kD) should equal 1.0 - kS.
		float3 kD = 1.0 - kS;
		// multiply kD by the inverse metalness such that only non-metals
		// have diffuse lighting, or a linear blend if partly metal (pure metals
		// have no diffuse light).
		kD *= 1.0 - metallic;

		// add to outgoing radiance Lo
		Lo += ( kD * albedo / PI + specular ) * radiance * NdotL; // note that we already multiplied the BRDF by the Fresnel (kS) so we won't multiply by kS again
	}

    const float3 F = fresnelSchlickRoughness( NdotV, f0, roughness );
	const float3 kS = F;
	float3 kD = 1.0 - kS;
	kD *= 1.0 - metallic;
	const float3 irradiance = irradianceTex.sample( s, normal ).rgb;
	const float3 diffuse = irradiance * albedo;
//    const float3 diffuse = albedo;

	// sample both the pre-filter map and the BRDF lut and combine them together as per the Split-Sum approximation to get the IBL specular part.
	const float levels = float( specularTex.get_num_mip_levels() - 1 );

	constexpr sampler ss( mag_filter::linear, min_filter::linear, mip_filter::linear, mip_filter::linear );
	const float3 prefilteredColor = specularTex.sample( ss, float3( reflection.xy, -reflection.z ), level( levels * roughness ) ).rgb;

	const float2 brdf = integrationTex.sample( s, float2( NdotV, roughness ) ).rg;
	const float3 specular = prefilteredColor * ( F * brdf.x + brdf.y );

	const float3 ambient = ( kD * diffuse + specular ) * ao;
	float3 color = ambient + Lo;

	// // HDR tonemapping
	color = color / ( color + float3( 1.0 ) );
	// // gamma correct
	color = pow( color, float3( 1.0 / 2.2 ) );

	return float4( color, 1.0 );
}
