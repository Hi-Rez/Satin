#include "Library/Pi.metal"

// From: https://learnopengl.com/PBR/Theory

typedef struct {
    float4 position [[position]];
    float3 worldPosition;
    float3 cameraPosition;
    float3 normal;
    float2 uv;
    float roughness;
    float metallic;
} CustomVertexData;

vertex CustomVertexData customVertex(
    Vertex v [[stage_in]],
    uint iid [[instance_id]],
    constant VertexUniforms &uniforms [[buffer( VertexBufferVertexUniforms )]] )
{
    float4 position = v.position;

    // const int id = iid;
    // int x = id;
    // int y = id / 6;
    position.x += ( iid % 7 - 3.0 ) * 2.5;
    position.y += ( iid / 7 - 3.0 ) * 2.5;
    // position.x += x * 1.0;
    // position.y += y * 10.0;

    const float4 worldPosition = uniforms.modelMatrix * position;
    const float3 worldCameraPosition = uniforms.worldCameraPosition;

    return {
        .position = uniforms.projectionMatrix * uniforms.viewMatrix * worldPosition,
        .worldPosition = worldPosition.xyz,
        .cameraPosition = worldCameraPosition,
        .normal = v.normal,
        .uv = v.uv,
        .roughness = (float)( iid % 7 ) / 6.0,
        .metallic = (float)( iid / 7 ) / 7.0
    };
}

// ----------------------------------------------------------------------------
float DistributionGGX( float NdotH, float roughness )
{
    float a = roughness * roughness;
    float a2 = a * a;
    float NdotH2 = NdotH * NdotH;

    float nom = a2;
    float denom = ( NdotH2 * ( a2 - 1.0 ) + 1.0 );
    denom = PI * denom * denom;

    return nom / max( denom, 0.001 );
}

float GeometrySchlickGGX( float NdotV, float roughness )
{
    float r = ( roughness + 1.0 );
    float k = ( r * r ) / 8.0;

    float nom = NdotV;
    float denom = NdotV * ( 1.0 - k ) + k;

    return nom / denom;
}

float GeometrySmith( float NdotV, float NdotL, float roughness )
{
    float ggx2 = GeometrySchlickGGX( NdotV, roughness );
    float ggx1 = GeometrySchlickGGX( NdotL, roughness );
    return ggx1 * ggx2;
}

float3 fresnelSchlick( float cosTheta, float3 f0 )
{
    return f0 + ( 1.0 - f0 ) * pow( 1.0 - cosTheta, 5.0 );
}

float3 fresnelSchlickRoughness( float cosTheta, float3 f0, float roughness )
{
    return f0 + ( max( float3( 1.0 - roughness ), f0 ) - f0 ) * pow( 1.0 - cosTheta, 5.0 );
}

float3 getNormalFromMap( texture2d<float> normalTex, sampler s, float2 uv, float3 normal, float3 worldPos )
{
    float3 tangentNormal = normalTex.sample( s, uv ).xyz * 2.0 - 1.0;

    float3 Q1 = dfdx( worldPos );
    float3 Q2 = dfdy( worldPos );
    float2 st1 = dfdx( uv );
    float2 st2 = dfdy( uv );

    float3 N = normalize( normal );
    float3 T = normalize( Q1 * st2.y - Q2 * st1.y );
    float3 B = -normalize( cross( N, T ) );
    float3x3 TBN = float3x3( T, B, N );

    return normalize( TBN * tangentNormal );
}

fragment float4 customFragment( CustomVertexData in [[stage_in]] )
{
    constexpr sampler s( mag_filter::linear, min_filter::linear );

    const float3 worldPosition = in.worldPosition;
    const float3 cameraPosition = in.cameraPosition;
    const float3 view = normalize( cameraPosition - worldPosition );
    const float2 uv = in.uv;
    const float3 normal = normalize( in.normal ); //getNormalFromMap( normalTex, s, uv, normalize( in.normal ), worldPosition );

    const float NdotV = max( dot( normal, view ), 0.0 );

    const float3 albedo = float3( 0.5, 0.0, 0.0 );
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
        const float NdotL = max( dot( normal, light ), 0.0 );
        const float HdotV = max( dot( halfway, view ), 0.0 );
        const float NdotH = max( dot( normal, halfway ), 0.0 );

        // Cook-Torrance BRDF
        const float NDF = DistributionGGX( NdotH, roughness );
        const float G = GeometrySmith( NdotV, NdotL, roughness );
        const float3 F = fresnelSchlick( HdotV, f0 );

        const float3 nominator = NDF * G * F;
        const float denominator = 4 * NdotV * NdotL;
        const float3 specular = nominator / max( denominator, 0.000001 ); // prevent divide by zero for NdotV=0.0 or NdotL=0.0

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

    const float3 ambient = float3( 0.03 ) * albedo * ao;
    float3 color = ambient + Lo;

    // HDR tonemapping
    color = color / ( color + float3( 1.0 ) );
    // gamma correct
    color = pow( color, float3( 1.0 / 2.2 ) );

    return float4( color, 1.0 );
}
