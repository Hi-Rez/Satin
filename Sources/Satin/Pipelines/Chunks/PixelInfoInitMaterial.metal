#if defined(BASE_COLOR_MAP)
    pixel.material.baseColor = baseColorMap.sample(pbrLinearSampler, in.texcoords).rgb;
#else
    pixel.material.baseColor = uniforms.baseColor.rgb;
#endif

#if defined(EMISSIVE_MAP)
    pixel.material.emissiveColor = emissiveMap.sample(pbrLinearSampler, in.texcoords).rgb;
#else
    pixel.material.emissiveColor = uniforms.emissiveColor.rgb * uniforms.emissiveColor.a;
#endif

#if defined(SPECULAR_MAP)
    pixel.material.specular = specularMap.sample(pbrLinearSampler, in.texcoords).r;
#else
    pixel.material.specular = uniforms.specular;
#endif

#if defined(METALLIC_MAP)
    pixel.material.metallic = metallicMap.sample(pbrLinearSampler, in.texcoords).r;
#else
    pixel.material.metallic = uniforms.metallic;
#endif

#if defined(ROUGHNESS_MAP)
    pixel.material.roughness = roughnessMap.sample(pbrLinearSampler, in.texcoords).r;
#else
    pixel.material.roughness = uniforms.roughness;
#endif

    pixel.material.environmentIntensity = uniforms.environmentIntensity; 

#if defined(HAS_SUBSURFACE)
    #if defined(SUBSURFACE_MAP)
        pixel.material.subsurface = subsurfaceMap.sample(pbrLinearSampler, in.texcoords).r;
    #else
        pixel.material.subsurface = uniforms.subsurface;
    #endif
#endif

#if defined(HAS_CLEARCOAT)
    #if defined(CLEARCOAT_MAP)
        pixel.material.clearcoat = clearcoatMap.sample(pbrLinearSampler, in.texcoords).r;
    #else
        pixel.material.clearcoat = uniforms.clearcoat;
    #endif

    #if defined(CLEARCOAT_ROUGHNESS_MAP)
        pixel.material.clearcoatRoughness = clearcoatRoughnessMap.sample(pbrLinearSampler, in.texcoords).r;
    #elseif defined(CLEARCOAT_GLOSS_MAP)
        pixel.material.clearcoatRoughness = 1.0 - clearcoatGlossMap.sample(pbrLinearSampler, in.texcoords).r;
    #else
        pixel.material.clearcoatRoughness = uniforms.clearcoatRoughness;
    #endif
#endif

#if defined(HAS_SPECULAR_TINT)
    #if defined(SPECULAR_TINT_MAP)
        pixel.material.specularTint = specularTintMap.sample(pbrLinearSampler, in.texcoords).r;
    #else
        pixel.material.specularTint = uniforms.specularTint;
    #endif
#endif

 #if defined(HAS_SHEEN)
    #if defined(SHEEN_MAP)
        pixel.material.sheen = sheenMap.sample(pbrLinearSampler, in.texcoords).r;
    #else
        pixel.material.sheen = uniforms.sheen;
    #endif

    #if defined(SHEEN_TINT_MAP)
        pixel.material.sheen = sheenTintMap.sample(pbrLinearSampler, in.texcoords).r;
    #else
        pixel.material.sheenTint = uniforms.sheenTint;
    #endif
#endif
    
#if defined(AMBIENT_OCCLUSION_MAP)
    pixel.material.ambientOcclusion = ambientOcclusionMap.sample(pbrLinearSampler, in.texcoords).r;
#else
    pixel.material.ambientOcclusion = 1.0;
#endif

#if defined(HAS_ANISOTROPIC)
    #if defined(ANISOTROPIC_MAP)
        pixel.material.anisotropic = anisotropicMap.sample(pbrLinearSampler, in.texcoords).r;
    #else
        pixel.material.anisotropic = uniforms.anisotropic;
    #endif
    #if defined(ANISOTROPIC_ANGLE_MAP)
        pixel.material.anisotropicAngle = anisotropicAngleMap.sample(pbrLinearSampler, in.texcoords).r;
    #else
        pixel.material.anisotropicAngle = uniforms.anisotropicAngle;
    #endif
#endif

#if defined(ALPHA_MAP)
    pixel.material.alpha = alphaMap.sample(pbrLinearSampler, in.texcoords).r;
#else
    pixel.material.alpha = uniforms.baseColor.a;
#endif

#if defined(HAS_TRANSMISSION)
    pixel.material.thickness = in.thickness;

    #if defined(TRANSMISSION_MAP)
        pixel.material.transmission = transmissionMap.sample(pbrLinearSampler, in.texcoords).r;
    #else
        pixel.material.transmission = uniforms.transmission;
    #endif

    #if defined(IOR_MAP)
        pixel.material.ior = iorMap.sample(pbrLinearSampler, in.texcoords).r;
    #else
        pixel.material.ior = uniforms.ior;
    #endif

#endif
