#include "Lighting.metal"
#include "Material.metal"
#include "Distribution/DistributionGGX.metal"
#include "Geometry/GeometrySmith.metal"
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

void pbrInit(thread Material &mat, float3 worldPos, float3 cameraPos, float3 baseReflectivity)
{
    mat.worldPos = worldPos;
    mat.cameraPos = cameraPos;
    mat.V = normalize(cameraPos - worldPos);
    mat.NoV = max(dot(mat.N, mat.V), 0.00001);
    mat.F0 = mix(baseReflectivity, mat.baseColor, mat.metallic);
    mat.Lo = mat.emissiveColor;
}

#if defined(LIGHTING) && defined(MAX_LIGHTS)
void pbrDirectLighting(thread Material &mat, constant Light *lights)
{
    const float3 diffuseLambert = mat.baseColor / PI;

    for (int i = 0; i < MAX_LIGHTS; i++) {
        const Light light = lights[i];

        float3 L = 0.0; // L = Vector from Fragment to Light
        float3 R = 0.0; // R = Light Radiance
        getLightInfo(light, mat.worldPos, L, R);

        // H = Half-way Vector of Light (L) and View Vector (V)
        const float3 H = normalize(mat.V + L);
        const float NoH = max(dot(mat.N, H), 0.00001);
        const float HoL = max(dot(H, L), 0.00001);
        const float NoL = max(dot(mat.N, L), 0.00001);

        // Cook-Torrance BRDF
        const float D = distributionGGX(NoH, mat.roughness);
        const float3 F = fresnelSchlick(HoL, mat.F0);
        const float G = geometrySmith(mat.NoV, NoL, mat.roughness);

        const float3 cookTorranceNumerator = D * G * F;
        const float3 cookTorranceDenominator = max(4.0 * mat.NoV * NoL, 0.00001);
        const float3 specularCookTorrance = cookTorranceNumerator / cookTorranceDenominator;

        const float3 Ks = F;
        const float3 Kd = (1.0 - Ks) * (1.0 - mat.metallic);

        const float3 BRDF = Kd * diffuseLambert + specularCookTorrance;

        mat.Lo += BRDF * R * NoL;
    }
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
    thread Material &mat)
{
#if defined(IRRADIANCE_MAP) || defined(REFLECTION_MAP)
    const float3 F = fresnelSchlickRoughness(mat.NoV, mat.F0, mat.roughness);
    const float3 Ks = F;
    const float3 Kd = (1.0 - Ks) * (1.0 - mat.metallic);
#endif

#if defined(IRRADIANCE_MAP)
    const float3 irradiance = irradianceMap.sample(pbrLinearSampler, mat.N).rgb;
    const float3 diffuse = Kd * irradiance * mat.baseColor;
#else
    const float3 diffuse = 0.0;
#endif

#if defined(REFLECTION_MAP) && defined(BRDF_MAP)
    // sample both the pre-filter map and the BRDF lut and combine them together as per the Split-Sum approximation to get the IBL specular part.
    const float levels = float(reflectionMap.get_num_mip_levels() - 1);
    const float mipLevel = mat.roughness * levels;
    const float3 prefilteredColor = reflectionMap.sample(pbrMipSampler, reflect(-mat.V, mat.N), level(mipLevel)).rgb;

    const float2 brdf = brdfMap.sample(pbrLinearSampler, float2(mat.NoV, mat.roughness)).rg;
    const float3 specular = prefilteredColor * (F * brdf.x + brdf.y);
#else
    const float3 specular = 0.0;
#endif

    mat.Lo += (diffuse + specular) * mat.ao;
}

float3 pbrTonemap(thread Material &mat)
{
    // HDR Tonemapping & Gamma Correction
    return gamma(aces(mat.Lo));
}
