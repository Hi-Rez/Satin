#include "../Pi.metal"
#include "Hammersley.metal"

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
