#include "Lighting.metal"
#include "Material.metal"
#include "Distribution/DistributionGGX.metal"
#include "Geometry/GeometrySmith.metal"
#include "Visibility/VisibilityKelemen.metal"
#include "Visibility/VisibilitySmithGGXCorrelated.metal"
#include "Fresnel/FresnelSchlick.metal"
#include "Fresnel/FresnelSchlickRoughness.metal"
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

void pbrInit(thread Material &material, float3 worldPos, float3 cameraPos)
{
    material.worldPos = worldPos;
    material.cameraPos = cameraPos;

    material.V = normalize(cameraPos - worldPos);
    material.NoV = max(dot(material.N, material.V), 0.00001);
    
    material.diffuseColor = (1.0 - material.metallic) * material.baseColor.rgb;

    material.f0 = 0.16 * material.reflectance * material.reflectance;
    material.f0 = mix(material.f0, material.baseColor, material.metallic);
    material.f90 = 1.0;

    material.roughness = material.roughness * material.roughness; //UE5 preceptualRoughness to alpha?
    material.roughness = clamp(material.roughness, 0.045, 1.0);

#if defined(HAS_CLEAR_COAT)
    const float3 sqrtf0 = sqrt(material.f0);
    const float3 nom = 1.0 - 5.0 * sqrtf0;
    const float3 den = 5.0 - sqrtf0;
    const float3 f0Base = (nom * nom) / (den * den);

    material.f0 = mix(material.f0, f0Base, material.clearCoat);

    material.clearCoatf0 = 0.04;
    material.clearCoatf90 = 1.0;
    material.clearCoatRoughness = material.clearCoatRoughness * material.clearCoatRoughness; //UE5 preceptualRoughness to alpha?
    material.clearCoatRoughness = clamp(material.clearCoatRoughness, 0.045, 1.0);
#endif

    material.Lo = material.emissiveColor;
}

float Fd_Lambert()
{
    return M_1_PI_F;
}

float3 Fd_Burley(float NoV, float NoL, float LoH, float roughness)
{
    float f90 = 0.5 + 2.0 * roughness * LoH * LoH;
    float3 lightScatter = fresnelSchlick(NoL, 1.0, f90);
    float3 viewScatter = fresnelSchlick(NoV, 1.0, f90);
    return lightScatter * viewScatter * M_1_PI_F;
}

float3 brdf(thread Material &material, float3 L, float NoL)
{
    const float3 V = material.V;       // View Vector
    const float3 N = material.N;       // Normal Vector
    const float3 H = normalize(V + L); // H = Half-way Vector of Light (L) and View Vector (V)
    const float NoV = material.NoV;
    const float NoH = max(dot(N, H), 0.00001);
    const float LoH = max(dot(L, H), 0.00001);

    // Cook-Torrance BRDF
    const float D = distributionGGX(NoH, material.roughness);
    const float Vis = visibilitySmithGGXCorrelated(NoV, NoL, material.roughness); // Note: Vis = G / (4 * NdotL * NdotV)
    const float3 F = fresnelSchlick(LoH, material.f0, material.f90);

    // Energy Conservation (Ks + Kd = 1.0)
    const float3 Ks = F;                                      // Specular Energy Contribution
    const float3 Kd = (1.0 - Ks) * (1.0 - material.metallic); // Diffuse Energy Contribution

    const float3 Fs = D * Vis * F;                            // Specular BRDF Component
    const float3 Fd = Kd * material.diffuseColor * Fd_Lambert(); // Diffuse BRDF Component

    float3 brdf = Fs + Fd;

#if defined(HAS_CLEAR_COAT)
    const float Dcc = distributionGGX(NoH, material.clearCoatRoughness);
    const float3 Fcc = fresnelSchlick(LoH, material.clearCoatf0, material.clearCoatf90);
    const float Vcc = visibilityKelemen(LoH);

    const float3 Fscc = Dcc * Vcc * Fcc;

    brdf = brdf * (1.0 - material.clearCoat * Fcc) + material.clearCoat * Fscc;
#endif

    return brdf;
}

#if defined(LIGHTING) && defined(MAX_LIGHTS)
void pbrDirectLighting(thread Material &material, constant Light *lights)
{
    for (int i = 0; i < MAX_LIGHTS; i++) {
        float3 L;
        const float3 lightRadiance = getLightInfo(lights[i], material.worldPos, L);
        const float NoL = max(dot(material.N, L), 0.00001);
        material.Lo += brdf(material, L, NoL) * lightRadiance * NoL * material.ao;
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
    thread Material &material)
{
#if defined(IRRADIANCE_MAP) || defined(REFLECTION_MAP)
    const float3 F = fresnelSchlick(material.NoV, material.f0, material.f90);
//    const float3 F = fresnelSchlickRoughness(material.NoV, material.f0, material.roughness);
    const float3 Ks = F;
    const float3 Kd = (1.0 - Ks) * (1.0 - material.metallic);

#endif

#if defined(IRRADIANCE_MAP)
    const float3 irradiance = irradianceMap.sample(pbrLinearSampler, material.N).rgb;
    const float3 Fd = Kd * irradiance * material.diffuseColor; // Diffuse IBL
#else
    const float3 Fd = 0.0;
#endif

    // Specular IBL: samples both the pre-filter map and the BRDF lut
    // Combines them together as per the Split-Sum approximation to get the IBL specular part
    
#if defined(REFLECTION_MAP) && defined(BRDF_MAP)
    const float3 reflectDir = normalize(reflect(-material.V, material.N));
    const float3 prefilteredRadiance = getIBLRadiance(reflectionMap, reflectDir, material.N, material.roughness);
    const float2 brdf = brdfMap.sample(pbrLinearSampler, float2(material.NoV, material.roughness)).rg;
    const float3 Fs = prefilteredRadiance * (F * brdf.x + brdf.y);
    
#if defined(HAS_CLEAR_COAT)
    const float3 prefilteredRadianceClearCoat = getIBLRadiance(reflectionMap, reflectDir, material.N, material.clearCoatRoughness);
    const float3 Fc = fresnelSchlick(material.NoV, material.clearCoatf0, material.clearCoatf90);
    const float2 brdfClearCoat = brdfMap.sample(pbrLinearSampler, float2(material.NoV, material.clearCoatRoughness)).rg;
    const float3 Fsc = prefilteredRadianceClearCoat * (Fc * brdfClearCoat.x + brdfClearCoat.y);
    material.Lo += ((Fd + Fs) * (1.0 - material.clearCoat * Fc) + material.clearCoat * Fsc) * material.ao;
#else
    material.Lo += (Fd + Fs) * material.ao;
#endif

#else
    material.Lo += Fd * material.ao;
#endif
}

float3 pbrTonemap(thread Material &material)
{
    return gamma(aces(material.Lo)); // HDR Tonemapping & Gamma Correction
}
