#include "Pi.metal"
#include "Hammersley.metal"

// From: https://learnopengl.com/PBR/Theory
// http://graphicrants.blogspot.com/2013/08/specular-brdf-reference.html

// Normal Distribution Functions (NDF)

float distributionBlinnPhong(float NdotH, float roughness) {
    const float a = roughness * roughness;
    const float a2 = a * a;
    const float nom = pow(NdotH, (2.0 / a2) - 2.0);
    const float denom = PI * a2;
    return nom / denom;
}

float distributionBeckmann(float NdotH, float roughness) {
    const float a = roughness * roughness;
    const float a2 = a * a;
    const float NdotH2 = NdotH * NdotH;
    const float nom = exp((NdotH2)-1.0) / (a2 * NdotH2);
    const float denom = PI * a2 * NdotH2 * NdotH2;
    return nom / denom;
}

float distributionGGX(float NdotH, float roughness) {
    const float a = roughness * roughness;
    const float a2 = a * a;
    const float NdotH2 = NdotH * NdotH;
    const float nom = a2;
    float denom = NdotH2 * (a2 - 1.0) + 1.0;
    denom = PI * denom * denom;
    return nom / denom;
}

// Geometric Shadowing

float geometryImplicit(float NdotV, float NdotL) { return NdotL * NdotV; }

float geometryNeumann(float NdotV, float NdotL) {
    const float nom = NdotL * NdotV;
    const float denom = max(NdotL, NdotV);
    return nom / denom;
}

//float geometryCookTorrance(float NdotV, float NdotL, float NdotH, float VdotH) {
//    const float g0 = (2.0 * NdotH * NdotV) / VdotH;
//    const float g1 = (2.0 * NdotH * NdotL) / VdotH;
//    return min(1.0, min(g0, g1));
//}

float geometryKelemen(float NdotV, float NdotL, float VdotH) {
    return (NdotL * NdotV) / (VdotH * VdotH);
}

float geometrySchlickGGX(float NdotV, float roughness) {
//    const float a = roughness * roughness;
//    const float k = a / 2.0;
//    return NdotV / (NdotV * (1.0 - k) + k);
    
    const float r = (roughness + 1.0);
    const float k = (r*r) / 8.0;

    const float nom   = NdotV;
    const float denom = NdotV * (1.0 - k) + k;
    
    return nom / denom;
}

float geometrySmith(float NdotV, float NdotL, float roughness) {
    float ggx2 = geometrySchlickGGX(NdotV, roughness);
    float ggx1 = geometrySchlickGGX(NdotL, roughness);
    return ggx1 * ggx2;
}

float3 fresnelSchlick(float cosTheta, float3 f0) {
    return f0 + (1.0 - f0) * pow(1.0 - cosTheta, 5.0);
}

float3 fresnelSchlickRoughness(float cosTheta, float3 f0, float roughness) {
    return f0 + (max(float3(1.0 - roughness), f0) - f0) * pow(1.0 - cosTheta, 5.0);
}

float3 getNormalFromMap(texture2d<float> normalTex, sampler s, float2 uv, float3 normal,
                        float3 worldPos) {
    float3 tangentNormal = normalTex.sample(s, uv).xyz * 2.0 - 1.0;

    float3 Q1 = dfdx(worldPos);
    float3 Q2 = dfdy(worldPos);
    float2 st1 = dfdx(uv);
    float2 st2 = dfdy(uv);

    float3 N = normalize(normal);
    float3 T = normalize(Q1 * st2.y - Q2 * st1.y);
    float3 B = -normalize(cross(N, T));
    float3x3 TBN = float3x3(T, B, N);

    return normalize(TBN * tangentNormal);
}

// GGX NDF via importance sampling
float3 importanceSampleGGX(float2 Xi, const float3 N, float roughness ) {
    float alpha = roughness * roughness;
    float alpha2 = alpha * alpha;

    float phi = 2.0 * PI * Xi.x;
    float cosTheta = sqrt((1.0 - Xi.y) / (1.0 + (alpha2 - 1.0) * Xi.y));
    float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

    // from spherical coordinates to cartesian coordinates
    float3 H;
    H.x = cos(phi) * sinTheta;
    H.y = sin(phi) * sinTheta;
    H.z = cosTheta;

    // from tangent-space vector to world-space sample vector
    float3 up = abs(N.z) < 0.999 ? float3(0.0, 0.0, 1.0) : float3(1.0, 0.0, 0.0);
    float3 tangent = normalize(cross(up, N));
    float3 bitangent = cross(N, tangent);

    float3 sampleVec = tangent * H.x + bitangent * H.y + N * H.z;
    return normalize(sampleVec);
}
