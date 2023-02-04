#include "Distribution/DistributionGGX.metal"
#include "Fresnel/FresnelSchlick.metal"
#include "Geometry/GeometrySmith.metal"
#include "Visibility/VisibilitySmithGGXCorrelated.metal"

float3 evalDiffuse(thread PixelInfo &pixel, float NdotL, float NdotV, float LdotH)
{
    float roughness = pixel.material.roughness;

    // Diffuse
    float FL = schlickWeight(NdotL);
    float FV = schlickWeight(NdotV);

    float Fd90 = 0.5 + 2.0 * LdotH * LdotH * roughness;
    float Fd = mix(1.0, Fd90, FL) * mix(1.0, Fd90, FV);

    float3 f = Fd;

#if defined(HAS_SUBSURFACE)
    float Fss90 = LdotH * LdotH * roughness;
    float Fss = mix(1.0, Fss90, FL) * mix(1.0, Fss90, FV);
    float ss = 1.25 * (Fss * ((1.0 / (NdotL + NdotV)) - 0.5) + 0.5);
    f = mix(f, ss, pixel.material.subsurface);
#endif

    f *= pixel.material.baseColor * INV_PI;

#if defined(HAS_SHEEN)
    f += pixel.material.sheen * getMaterialSheenColor(pixel.material) * schlickWeight(LdotH);
#endif

    return f;
}
#if defined(HAS_ANISOTROPIC)
float3 evalAnisotropicSpecular(thread PixelInfo &pixel, float3 F, float3 H, float3 L, float NdotL, float NdotV, float NdotH)
{
    float3 V = pixel.view, X = pixel.tangent, Y = pixel.bitangent;
    float HdotX = dot(H, X), HdotY = dot(H, Y);
    float LdotX = dot(L, X), LdotY = dot(L, Y);
    float VdotX = dot(V, X), VdotY = dot(V, Y);

    float2 a = getMaterialAxAy(pixel.material);
    float D = distributionAnisoGGX(NdotH, HdotX, HdotY, a.x, a.y);
    float Vis = visibilityAnisoSmithGGXCorrelated(NdotV, NdotL, VdotX, VdotY, LdotX, LdotY, a.x, a.y);
    return (F * D * Vis);
}
#endif

float3 evalIsotropicSpecular(thread PixelInfo &pixel, float3 F, float3 H, float3 L, float NdotL, float NdotV, float NdotH)
{
    float D = distributionGGX(NdotH, pixel.material.roughness);
    float remappedRoughness = 0.5 + pixel.material.roughness / 2.0;
    float G = step(0.0, NdotL / NdotV) * geometrySmith(NdotV, NdotL, remappedRoughness);
    return (D * G * F) / max(0.0001, 4.0 * NdotL * NdotV);
}

float3 evalSpecular(thread PixelInfo &pixel, float3 F, float3 H, float3 L, float NdotL, float NdotV, float NdotH)
{
#if defined(HAS_ANISOTROPIC)
    if (abs(pixel.material.anisotropic) > 0.0) {
        return evalAnisotropicSpecular(pixel, F, H, L, NdotL, NdotV, NdotH);
    } else {
        return evalIsotropicSpecular(pixel, F, H, L, NdotL, NdotV, NdotH);
    }
#else
    return evalIsotropicSpecular(pixel, F, H, L, NdotL, NdotV, NdotH);
#endif
}

#if defined(HAS_CLEARCOAT)
float3 evalClearcoat(thread PixelInfo &pixel, float NdotH, float NdotL, float NdotV)
{
    float3 F = fresnelSchlick(NdotV, 0.04, 1.0); // ior = 1.5
    float D = distributionClearcoatGGX(NdotH, pixel.material.clearcoatRoughness);
    float G = geometrySmith(NdotV, NdotL, 0.25);
    float denom = 4.0 * saturate(NdotL) * saturate(NdotV) + 0.1;
    return pixel.material.clearcoat * F * D * G / denom;
}
#endif

#if defined(HAS_TRANSMISSION)
float3 evalTransmission(thread PixelInfo &pixel, float3 F, float3 L, float NdotV)
{
    float3 N = pixel.normal;
    float3 V = pixel.view;

    float ior = pixel.material.ior;

    // If the light ray travels through the geometry, use the point it exits the geometry again.
    // That will change the angle to the light source, if the material refracts the light ray.

    // float3 transmissionRay = getVolumeTransmissionRay(N, V, 1.0, ior);
    // use the transmission ray to change the L vector?

    float transmissionRoughness = applyIorToRoughness(pixel.material.roughness, ior);

    float3 L_mirror = normalize(L + 2.0 * N * dot(-L, N));
    float3 H = normalize(L_mirror + V);

    float D = distributionGGX(saturate(dot(N, H)), transmissionRoughness);
    float Vis = visibilitySmithGGXCorrelated(saturate(dot(N, L_mirror)), NdotV, transmissionRoughness);

    // Transmission BTDF
    return (1.0 - F) * pixel.material.baseColor * D * Vis;
}
#endif

float3 evalBRDF(thread PixelInfo &pixel, float3 L, float NdotL, float NdotV)
{
    // View Vector
    float3 V = pixel.view;
    // Normal Vector
    float3 N = pixel.normal;
    // H = Half-way Vector of Light (L) and View Vector (V)
    float3 H = normalize(V + L);

    float NdotH = dot(N, H);
    float LdotH = dot(L, H);

    // Fresnel Approximation
    float3 F = fresnelSchlickRoughness(LdotH, getMaterialSpecularColor(pixel.material), pixel.material.roughness);

    // Specular Energy Contribution
    float3 Ks = F;

    // Diffuse Energy Contribution
    float3 Kd = (1.0 - Ks) * (1.0 - pixel.material.metallic);

    // Specular BRDF Component
    float3 Fs = evalSpecular(pixel, F, H, L, NdotL, NdotV, NdotH);

    // Diffuse BRDF Component
    float3 Fd = evalDiffuse(pixel, NdotL, NdotV, LdotH);

#if defined(HAS_TRANSMISSION)
    if (pixel.material.transmission > 0) {
        // Specular BTDF Component
        float3 Ft = evalTransmission(pixel, F, L, NdotV);
        Fd = mix(Fd, Ft, pixel.material.transmission);
    }
#endif

    float3 brdf = Kd * Fd + Fs;

#if defined(HAS_CLEARCOAT)
    if (pixel.material.clearcoat > 0) {
        brdf += evalClearcoat(pixel, NdotH, NdotL, NdotV);
    }
#endif

    return brdf;
}
