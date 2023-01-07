#include "Library/Luminance.metal"

#if defined(HAS_SHEEN)
float3 getMaterialSheenColor(Material material)
{
    float lum = luminance2(material.baseColor);
    float3 ctint = lum > 0.0 ? material.baseColor / lum : 1.0;
    return mix(1.0, ctint, material.sheenTint);
}
#endif

#if defined(HAS_ANISOTROPIC)
float2 getMaterialAxAy(Material material)
{
    float ax = max(material.roughness * (1.0 + material.anisotropic), 0.001);
    float ay = max(material.roughness * (1.0 - material.anisotropic), 0.001);
    return float2(ax, ay);
}
#endif

float3 getMaterialSpecularColor(Material material)
{
    float3 F0 = 0.16 * material.specular * material.specular;
#if defined(HAS_SPECULAR)
    float lum = luminance(material.baseColor);
    float3 ctint = lum > 0.0 ? material.baseColor / lum : 1.0;
    return mix(F0 * mix(1.0, ctint, material.specularTint), material.baseColor, material.metallic);
#else
    return mix(F0, material.baseColor, material.metallic);
#endif
}

#if defined(HAS_TRANSMISSION)
// https://github.com/KhronosGroup/glTF-Sample-Viewer/blob/315d20e3b91da83659a63719ed26aefeb3579c38/source/Renderer/shaders/functions.glsl
float applyIorToRoughness(float roughness, float ior)
{
    // Scale roughness with IOR so that an IOR of 1.0 results in no microfacet refraction and
    // an IOR of 1.5 results in the default amount of microfacet refraction.
    return roughness * saturate(ior * 2.0 - 2.0);
}

float3 getVolumeTransmissionRay(float3 N, float3 V, float3 thickness, float ior)
{
    // Direction of refracted light.
    float3 refractionVector = refract(-V, N, 1.0 / ior);

    // The thickness is specified in local space.
    return normalize(refractionVector) * thickness;
}

// Compute attenuated light as it travels through a volume.
float3 applyVolumeAttenuation(float3 radiance, float transmissionDistance, float3 attenuationColor, float attenuationDistance)
{
    if (attenuationDistance == 0.0) {
        // Attenuation distance is +∞ (which we indicate by zero), i.e. the transmitted color is not attenuated at all.
        return radiance;
    } else {
        // Compute light attenuation using Beer's law.
        float3 attenuationCoefficient = -log(attenuationColor) / attenuationDistance;
        float3 transmittance = exp(-attenuationCoefficient * transmissionDistance); // Beer's law
        return transmittance * radiance;
    }
}

#endif
