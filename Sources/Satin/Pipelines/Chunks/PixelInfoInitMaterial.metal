    pixel.material.baseColor = uniforms.baseColor.rgb;
#if defined(BASE_COLOR_MAP)
    pixel.material.baseColor *= baseColorMap.sample(pbrLinearSampler, in.texcoords).rgb;
#endif

    pixel.material.emissiveColor = uniforms.emissiveColor.rgb * uniforms.emissiveColor.a;
#if defined(EMISSIVE_MAP)
    pixel.material.emissiveColor *= emissiveMap.sample(pbrLinearSampler, in.texcoords).rgb;
#endif
    
    pixel.material.metallic = uniforms.metallic;
#if defined(METALLIC_MAP)
    pixel.material.metallic *= metallicMap.sample(pbrLinearSampler, in.texcoords).r;
#endif
    
    pixel.material.roughness = uniforms.roughness;
#if defined(ROUGHNESS_MAP)
    pixel.material.roughness *= roughnessMap.sample(pbrLinearSampler, in.texcoords).r;
#endif

    pixel.material.specular = uniforms.specular;
#if defined(HAS_SPECULAR)
    pixel.material.specularTint = uniforms.specularTint;
#endif

 #if defined(HAS_CLEARCOAT)
    pixel.material.clearcoat = uniforms.clearcoat;
    pixel.material.clearcoatRoughness = uniforms.clearcoatRoughness;
 #endif

 #if defined(HAS_SUBSURFACE)
    pixel.material.subsurface = uniforms.subsurface;
 #endif

 #if defined(HAS_SHEEN)
    pixel.material.sheen = uniforms.sheen;
    pixel.material.sheenTint = uniforms.sheenTint;
 #endif
    
    pixel.material.ambientOcclusion = 1.0;
#if defined(AMBIENT_OCCULSION_MAP)
    pixel.material.ambientOcclusion *= ambientOcclusionMap.sample(pbrLinearSampler, in.texcoords).r;
#endif
    
    pixel.material.alpha = uniforms.baseColor.a;
#if defined(ALPHA_MAP)
    pixel.material.alpha *= alphaMap.sample(pbrLinearSampler, in.texcoords).r;
#endif

#if defined(HAS_TRANSMISSION)
    pixel.material.transmission = uniforms.transmission;
    pixel.material.thickness = in.thickness;
    pixel.material.ior = uniforms.ior;
#endif
