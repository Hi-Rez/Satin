float3 getIBLRadiance(texturecube<float> reflectionMap, float3 dir, float roughness)
{
    const float levels = float(reflectionMap.get_num_mip_levels() - 1);
    const float mipLevel = roughness * levels;
    return reflectionMap.sample(reflectionSampler, dir, level(mipLevel)).rgb;
}

void pbrIndirectLighting(
    texturecube<float> irradianceMap,
    texturecube<float> reflectionMap,
    texture2d<float> brdfMap,
    thread PixelInfo &pixel)
{
    float roughness = pixel.material.roughness;
    float metallic = pixel.material.metallic;
    float3 baseColor = pixel.material.baseColor;

    float3 radiance_s = 0.0;
    float3 radiance_d = 0.0;

    float3 N = pixel.normal;
    float3 V = pixel.view;
    float NdotV = dot(N, V);

    float3 F0 = getMaterialSpecularColor(pixel.material);
    float3 Ks = fresnelSchlickRoughness(NdotV, F0, roughness);
    float3 Kd = (1.0 - Ks) * (1.0 - metallic);
    
    float2 ggxLut = brdfMap.sample(brdfSampler, saturate(float2(NdotV, roughness))).rg;
    float3 Fs = (Ks * ggxLut.x + ggxLut.y);
    
    // Diffuse
    radiance_d += Kd * baseColor * pixel.material.environmentIntensity * irradianceMap.sample(irradianceSampler, N).rgb;

    float3 R = reflect(-V, N);

#if defined(HAS_ANISOTROPIC)
    // https://google.github.io/filament/Filament.md.html#lighting/imagebasedlights/anisotropy
    float anisotropic = pixel.material.anisotropic;
    if (abs(anisotropic) > 0) {
        float3 anisotropyDirection = anisotropic >= 0.0 ? pixel.bitangent : pixel.tangent;
        float3 anisotropicTangent = cross(anisotropyDirection, V);
        float3 anisotropicNormal = cross(anisotropicTangent, anisotropyDirection);
        float3 bentNormal = normalize(mix(N, anisotropicNormal, abs(anisotropic)));
        R = reflect(-V, bentNormal);
    }
#endif

    // Specular
    float3 specularLight = pixel.material.environmentIntensity * getIBLRadiance(reflectionMap, R, roughness);
    radiance_s = Fs * specularLight;

#if defined(HAS_TRANSMISSION)
    // Transmission
    float ior = pixel.material.ior;
    // float3 thickness = pixel.material.thickness;
    float3 transmissionRay = getVolumeTransmissionRay(N, V, 1.0, ior);
    // float3 refractedRayExit = pixel.position + transmissionRay;

    // Since Satin's render isn't ready for multiple passes we are going to default to refract into the cubemap
    // Project refracted vector on the framebuffer, while mapping to normalized device coordinates.
    // float4 ndcPos = projectionMatrix * viewMatrix * float4(refractedRayExit, 1.0);
    // float2 refractionCoords = ndcPos.xy / ndcPos.w;
    // refractionCoords += 1.0;
    // refractionCoords /= 2.0;

    // Sample framebuffer to get pixel the refracted ray hits.
    float3 transmittedLight = pixel.material.environmentIntensity * getIBLRadiance(reflectionMap, transmissionRay, applyIorToRoughness(roughness, ior));

    float3 radiance_t = (1.0 - Fs) * transmittedLight * baseColor;
    radiance_d = mix(radiance_d, radiance_t, pixel.material.transmission);
#endif

    pixel.radiance += (radiance_d + radiance_s) * pixel.material.ambientOcclusion;

#if defined(HAS_CLEARCOAT)
    float clearcoat = pixel.material.clearcoat;
    if (clearcoat > 0) {
        float clearcoatRoughness = pixel.material.clearcoatRoughness;
        float3 clearcoatLight = pixel.material.environmentIntensity * getIBLRadiance(reflectionMap, R, clearcoatRoughness);
        float3 Kc = fresnelSchlickRoughness(NdotV, 0.04, clearcoatRoughness);
        float2 brdfClearcoat = brdfMap.sample(brdfSampler, saturate(float2(NdotV, clearcoatRoughness))).rg;
        float3 Fcc = clearcoatLight * (Kc * brdfClearcoat.x + brdfClearcoat.y);
        pixel.radiance += clearcoat * Fcc * pixel.material.ambientOcclusion;
    }
#endif
}

