#if defined(BASE_COLOR_MAP)
    const float2 baseColorTexcoord = (uniforms.baseColorTexcoordTransform * float3(in.texcoords, 1.0)).xy;
    pixel.material.baseColor = baseColorMap.sample(baseColorSampler, baseColorTexcoord).rgb;
#else
    pixel.material.baseColor = uniforms.baseColor.rgb;
#endif

#if defined(EMISSIVE_MAP)
    const float2 emissiveTexcoord = (uniforms.emissiveTexcoordTransform * float3(in.texcoords, 1.0)).xy;
    pixel.material.emissiveColor = emissiveMap.sample(emissiveSampler, emissiveTexcoord).rgb;
#else
    pixel.material.emissiveColor = uniforms.emissiveColor.rgb * uniforms.emissiveColor.a;
#endif

#if defined(SPECULAR_MAP)
    const float2 specularTexcoord = (uniforms.specularTexcoordTransform * float3(in.texcoords, 1.0)).xy;
    pixel.material.specular = specularMap.sample(specularSampler, specularTexcoord).r;
#else
    pixel.material.specular = uniforms.specular;
#endif

#if defined(METALLIC_MAP)
    const float2 metallicTexcoord = (uniforms.metallicTexcoordTransform * float3(in.texcoords, 1.0)).xy;
    pixel.material.metallic = metallicMap.sample(metallicSampler, metallicTexcoord).r;
#else
    pixel.material.metallic = uniforms.metallic;
#endif

#if defined(ROUGHNESS_MAP)
    const float2 roughnessTexcoord = (uniforms.roughnessTexcoordTransform * float3(in.texcoords, 1.0)).xy;
    pixel.material.roughness = roughnessMap.sample(roughnessSampler, roughnessTexcoord).r;
#else
    pixel.material.roughness = uniforms.roughness;
#endif

    pixel.material.environmentIntensity = uniforms.environmentIntensity;
    pixel.material.gammaCorrection = uniforms.gammaCorrection; 

#if defined(HAS_SUBSURFACE)
    #if defined(SUBSURFACE_MAP)
        const float2 subsurfaceTexcoord = (uniforms.subsurfaceTexcoordTransform * float3(in.texcoords, 1.0)).xy;
        pixel.material.subsurface = subsurfaceMap.sample(subsurfaceSampler, subsurfaceTexcoord).r;
    #else
        pixel.material.subsurface = uniforms.subsurface;
    #endif
#endif

#if defined(HAS_CLEARCOAT)
    #if defined(CLEARCOAT_MAP)
        const float2 clearcoatTexcoord = (uniforms.clearcoatTexcoordTransform * float3(in.texcoords, 1.0)).xy;
        pixel.material.clearcoat = clearcoatMap.sample(clearcoatSampler, clearcoatTexcoord).r;
    #else
        pixel.material.clearcoat = uniforms.clearcoat;
    #endif

    #if defined(CLEARCOAT_ROUGHNESS_MAP)
        const float2 clearcoatRoughnessTexcoord = (uniforms.clearcoatRoughnessTexcoordTransform * float3(in.texcoords, 1.0)).xy;
        pixel.material.clearcoatRoughness = clearcoatRoughnessMap.sample(clearcoatRoughnessSampler, clearcoatRoughnessTexcoord).r;
    #elseif defined(CLEARCOAT_GLOSS_MAP)
        const float2 clearcoatRoughnessTexcoord = (uniforms.clearcoatRoughnessTexcoordTransform * float3(in.texcoords, 1.0)).xy;
        pixel.material.clearcoatRoughness = 1.0 - clearcoatGlossMap.sample(clearcoatGlossSampler, clearcoatRoughnessTexcoord).r;
    #else
        pixel.material.clearcoatRoughness = uniforms.clearcoatRoughness;
    #endif
#endif

#if defined(HAS_SPECULAR_TINT)
    #if defined(SPECULAR_TINT_MAP)
        const float2 specularTintTexcoord = (uniforms.specularTintTexcoordTransform * float3(in.texcoords, 1.0)).xy;
        pixel.material.specularTint = specularTintMap.sample(specularTintSampler, specularTintTexcoord).r;
    #else
        pixel.material.specularTint = uniforms.specularTint;
    #endif
#endif

 #if defined(HAS_SHEEN)
    #if defined(SHEEN_MAP)
        const float2 sheenTexcoord = (uniforms.sheenTexcoordTransform * float3(in.texcoords, 1.0)).xy;
        pixel.material.sheen = sheenMap.sample(sheenSampler, sheenTexcoord).r;
    #else
        pixel.material.sheen = uniforms.sheen;
    #endif

    #if defined(SHEEN_TINT_MAP)
        const float2 sheenTintTexcoord = (uniforms.sheenTintTexcoordTransform * float3(in.texcoords, 1.0)).xy;
        pixel.material.sheenTint = sheenTintMap.sample(sheenTintSampler, sheenTintTexcoord).r;
    #else
        pixel.material.sheenTint = uniforms.sheenTint;
    #endif
#endif
    
#if defined(AMBIENT_OCCLUSION_MAP)
    const float2 ambientOcclusionTexcoord = (uniforms.ambientOcclusionTexcoordTransform * float3(in.texcoords, 1.0)).xy;
    pixel.material.ambientOcclusion = ambientOcclusionMap.sample(ambientOcclusionSampler, ambientOcclusionTexcoord).r;
#else
    pixel.material.ambientOcclusion = 1.0;
#endif

#if defined(HAS_ANISOTROPIC)
    #if defined(ANISOTROPIC_MAP)
        const float2 anisotropicTexcoord = (uniforms.anisotropicTexcoordTransform * float3(in.texcoords, 1.0)).xy;
        pixel.material.anisotropic = anisotropicMap.sample(anisotropicSampler, anisotropicTexcoord).r;
    #else
        pixel.material.anisotropic = uniforms.anisotropic;
    #endif
    #if defined(ANISOTROPIC_ANGLE_MAP)
        const float2 anisotropicAngleTexcoord = (uniforms.anisotropicAngleTexcoordTransform * float3(in.texcoords, 1.0)).xy;
        pixel.material.anisotropicAngle = anisotropicAngleMap.sample(anisotropicAngleSampler, anisotropicAngleTexcoord).r;
    #else
        pixel.material.anisotropicAngle = uniforms.anisotropicAngle;
    #endif
#endif

#if defined(ALPHA_MAP)
    const float2 alphaTexcoord = (uniforms.alphaTexcoordTransform * float3(in.texcoords, 1.0)).xy;
    pixel.material.alpha = alphaMap.sample(alphaSampler, alphaTexcoord).r;
#else
    pixel.material.alpha = uniforms.baseColor.a;
#endif

#if defined(HAS_TRANSMISSION)
    pixel.material.thickness = in.thickness;

    #if defined(TRANSMISSION_MAP)
        const float2 transmissionTexcoord = (uniforms.transmissionTexcoordTransform * float3(in.texcoords, 1.0)).xy;
        pixel.material.transmission = transmissionMap.sample(transmissionSampler, transmissionTexcoord).r;
    #else
        pixel.material.transmission = uniforms.transmission;
    #endif

    #if defined(IOR_MAP)
        const float2 iorTexcoord = (uniforms.iorTexcoordTransform * float3(in.texcoords, 1.0)).xy;
        pixel.material.ior = iorMap.sample(iorSampler, iorTexcoord).r;
    #else
        pixel.material.ior = uniforms.ior;
    #endif

#endif
