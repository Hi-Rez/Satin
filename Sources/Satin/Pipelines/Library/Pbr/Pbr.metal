#include "../Pi.metal"
#include "Lighting.metal"
#include "Material.metal"
#include "PixelInfo.metal"
#include "Distribution/DistributionGGX.metal"
#include "Geometry/GeometrySmith.metal"
#include "Visibility/VisibilityKelemen.metal"
#include "Visibility/VisibilitySmithGGXCorrelated.metal"
#include "Fresnel/FresnelSchlick.metal"
#include "../Tonemapping/Aces.metal"
#include "../Gamma.metal"

// From: https://learnopengl.com/PBR/Theory
// http://graphicrants.blogspot.com/2013/08/specular-brdf-reference.html

#if defined(HAS_MAPS)
constexpr sampler pbrLinearSampler(mip_filter::linear, mag_filter::linear, min_filter::linear);
#endif

#if defined(REFLECTION_MAP) && defined(BRDF_MAP)
constexpr sampler pbrMipSampler(min_filter::linear, mag_filter::linear, mip_filter::linear);
#endif

float3 evalDiffuse(thread PixelInfo &pixel, float LdotH, float NdotL, float NdotV) {
    float FD90 = 0.5 + 2.0 * pixel.material.roughness * LdotH * LdotH;
    const float3 FL = fresnelSchlick(NdotL, 1.0, FD90);
    const float3 FV = fresnelSchlick(NdotV, 1.0, FD90);
    return pixel.material.baseColor * INV_PI * FL * FV;
}

float3 evalSpecular(thread PixelInfo &pixel, float3 F, float NdotH, float NdotL, float NdotV) {
    float roughness = pixel.material.roughness;
    // Cook-Torrance BRDF
    const float D = distributionGGX(NdotH, roughness);
    const float Vis = visibilitySmithGGXCorrelated(NdotV, NdotL, roughness);
    return D * Vis * F;
}

void pbrInit(thread PixelInfo &pixel)
{
    pixel.material.roughness = max(0.001, pixel.material.roughness * pixel.material.roughness);
    pixel.radiance = pixel.material.emissiveColor;
}

float3 evalBRDF(thread PixelInfo &pixel, float3 L, float NdotL)
{
    const float3 V = pixel.view;        // View Vector
    const float3 N = pixel.normal;      // Normal Vector
    const float3 H = normalize(V + L);  // H = Half-way Vector of Light (L) and View Vector (V)
    const float NdotV = saturate(dot(N, V));
    const float NdotH = saturate(dot(N, H));
    const float LdotH = saturate(dot(L, H));
    
    const float specular = pixel.material.specular;
    const float metallic = pixel.material.metallic;
    const float3 baseColor = pixel.material.baseColor;

    float3 f0 = 0.16 * specular * specular;
    f0 = mix(f0, baseColor, metallic);
    
    // Fresnel Approximation
    float3 F = fresnelSchlick(LdotH, f0, 1.0);
    
    // Energy Conservation (Ks + Kd = 1.0)
    
    // Specular Energy Contribution
    const float3 Ks = F;
    // Diffuse Energy Contribution
    const float3 Kd = (1.0 - Ks) * (1.0 - metallic);

    // Specular BRDF Component
    const float3 Fs = evalSpecular(pixel, F, NdotH, NdotL, NdotV);
    
    // Disney Diffuse BRDF Component
    const float3 Fd = Kd * evalDiffuse(pixel, LdotH, NdotL, NdotV);
    
    return Fs + Fd;
}

#if defined(LIGHTING) && defined(MAX_LIGHTS)
void pbrDirectLighting(thread PixelInfo &pixel, constant Light *lights)
{
    float3 L;
    float lightDistance;
    for (int i = 0; i < MAX_LIGHTS; i++) {
        const float3 lightRadiance = getLightInfo(lights[i], pixel.position, L, lightDistance);
        const float NdotL = saturate(dot(pixel.normal, L));
        pixel.radiance += evalBRDF(pixel, L, NdotL) * lightRadiance * NdotL * pixel.material.ao;
    }
}
#endif

#if defined(REFLECTION_MAP) && defined(BRDF_MAP)
float3 getIBLRadiance(texturecube<float> reflectionMap, float3 reflectDir, float3 N, float roughness)
{
    const float levels = float(reflectionMap.get_num_mip_levels() - 1);
    const float mipLevel = roughness * levels;
    reflectDir = normalize(mix(reflectDir, N, roughness * roughness));
    return reflectionMap.sample(pbrMipSampler, reflectDir, level(mipLevel)).rgb;
}
#endif

void pbrIndirectLighting(
#if defined(IRRADIANCE_MAP)
    texturecube<float> irradianceMap,
#endif
#if defined(REFLECTION_MAP)
    texturecube<float> reflectionMap,
#endif
#if defined(BRDF_MAP)
    texture2d<float> brdfMap,
#endif
    thread PixelInfo &pixel)
{
    const float NdotV = saturate(dot(pixel.normal, pixel.view));
    
    const float roughness = pixel.material.roughness;
    const float specular = pixel.material.specular;
    const float metallic = pixel.material.metallic;
    const float3 baseColor = pixel.material.baseColor;
    
    float3 f0 = 0.16 * specular * specular;
    f0 = mix(f0, baseColor, metallic);
    
#if defined(IRRADIANCE_MAP) || defined(REFLECTION_MAP)
    const float3 F = fresnelSchlick(NdotV, f0, 1.0);
    const float3 Ks = F;
    const float3 Kd = (1.0 - Ks) * (1.0 - metallic);

#endif

#if defined(IRRADIANCE_MAP)
    const float3 irradiance = irradianceMap.sample(pbrLinearSampler, pixel.normal).rgb;
    const float3 Fd = Kd * irradiance * baseColor * INV_PI; // Diffuse IBL
#else
    const float3 Fd = 0.0;
#endif

    // Specular IBL: samples both the pre-filter map and the BRDF lut
    // Combines them together as per the Split-Sum approximation to get the IBL specular part
    
#if defined(REFLECTION_MAP) && defined(BRDF_MAP)
    const float3 reflectDir = normalize(reflect(-pixel.view, pixel.normal));
    const float3 prefilteredRadiance = getIBLRadiance(reflectionMap, reflectDir, pixel.normal, roughness);
    const float2 brdf = brdfMap.sample(pbrLinearSampler, float2(NdotV, roughness)).rg;
    const float3 Fs = prefilteredRadiance * (F * brdf.x + brdf.y);
    
#if defined(HAS_CLEAR_COAT)
    
    float clearcoat = pixel.material.clearcoat;
    float clearcoatRoughness = pixel.material.clearcoatRoughness;
    
    const float3 prefilteredRadianceClearCoat = getIBLRadiance(reflectionMap, reflectDir, pixel.normal, pixel.material.clearcoatRoughness);
    const float3 Fc = fresnelSchlick(NdotV, 0.04, 1.0);
    const float2 brdfClearCoat = brdfMap.sample(pbrLinearSampler, float2(NdotV, pixel.material.clearcoatRoughness)).rg;
    const float3 Fsc = prefilteredRadianceClearCoat * (Fc * brdfClearCoat.x + brdfClearCoat.y);
    pixel.radiance += ((Fd + Fs) * (1.0 - pixel.material.clearcoat * Fc) + material.clearcoat * Fsc) * material.ao;
#else
    pixel.radiance += (Fd + Fs) * pixel.material.ao;
#endif

#else
    pixel.radiance += Fd * pixel.material.ao;
#endif
}

float3 pbrTonemap(thread PixelInfo &pixel)
{
    return gamma(aces(pixel.radiance)); // HDR Tonemapping & Gamma Correction
}
