#include "Pi.metal"
#include "Hammersley.metal"

// From: https://learnopengl.com/PBR/Theory
// http://graphicrants.blogspot.com/2013/08/specular-brdf-reference.html

// Normal Distribution Functions (NDF)

float distributionBlinnPhong(float NoH, float roughness)
{
    const float alpha = roughness * roughness;
    const float alpha2 = alpha * alpha;
    const float numerator = pow(NoH, (2.0 / alpha2) - 2.0);
    const float denominator = PI * alpha2;
    return numerator / max(denominator, 0.00001);
}

float distributionBeckmann(float NoH, float roughness)
{
    const float alpha = roughness * roughness;
    const float alpha2 = alpha * alpha;
    const float NoH2 = NoH * NoH;
    const float numerator = exp((NoH2)-1.0) / (alpha2 * NoH2);
    const float denominator = PI * alpha2 * NoH2 * NoH2;
    return numerator / max(denominator, 0.00001);
}

float distributionGGX(float NoH, float roughness)
{
    const float alpha = roughness * roughness;
    const float alpha2 = alpha * alpha;
    const float NoH2 = NoH * NoH;
    const float numerator = alpha2;
    float denominator = NoH2 * (alpha2 - 1.0) + 1.0;
    denominator = PI * denominator * denominator;
    return numerator / max(denominator, 0.00001);
}

// Geometric Shadowing

float geometryImplicit(float NoV, float NoL) { return NoL * NoV; }

float geometryNeumann(float NoV, float NoL)
{
    const float numerator = NoL * NoV;
    const float denominator = max(NoL, NoV);
    return numerator / max(denominator, 0.00001);
}

// float geometryCookTorrance(float NdotV, float NdotL, float NdotH, float VdotH) {
//     const float g0 = (2.0 * NdotH * NdotV) / VdotH;
//     const float g1 = (2.0 * NdotH * NdotL) / VdotH;
//     return min(1.0, min(g0, g1));
// }

float geometryKelemen(float NoV, float NoL, float VoH)
{
    const float numerator = NoL * NoV;
    const float denominator = VoH * VoH;
    return numerator / max(denominator, 0.00001);
}

float geometrySchlickGGX(float NoX, float roughness)
{
    const float alpha = roughness * roughness;
    const float k = alpha / 2.0;
    const float numerator = NoX;
    float denominator = NoX * (1.0 - k) + k;
    return numerator / max(denominator, 0.00001);
}

float geometrySmith(float NoV, float NoL, float roughness)
{
    return geometrySchlickGGX(NoV, roughness) * geometrySchlickGGX(NoL, roughness);
}

float3 fresnelSchlick(float HoV, float3 f0)
{
    return f0 + (1.0 - f0) * pow(1.0 - HoV, 5.0);
}

float3 fresnelSchlickRoughness(float cosTheta, float3 f0, float roughness)
{
    return f0 + (max(float3(1.0 - roughness), f0) - f0) * pow(1.0 - cosTheta, 5.0);
}

// Based on Karis 2014
// GGX NDF via importance sampling
float3 importanceSampleGGX(float2 Xi, float3 N, float roughness)
{
    const float alpha = roughness * roughness;
    const float alpha2 = alpha * alpha;

    const float phi = TWO_PI * Xi.x;
    const float cosTheta = sqrt((1.0 - Xi.y) / (1.0 + (alpha2 - 1.0) * Xi.y));
    const float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

    // from spherical coordinates to cartesian coordinates
    const float3 H = float3(cos(phi) * sinTheta, sin(phi) * sinTheta, cosTheta);

    // from tangent-space vector to world-space sample vector
    const float3 up = abs(N.z) < 0.999 ? float3(0.0, 0.0, 1.0) : float3(1.0, 0.0, 0.0);
    const float3 tangent = normalize(cross(up, N));
    const float3 bitangent = cross(N, tangent);

    return tangent * H.x + bitangent * H.y + N * H.z;
}
