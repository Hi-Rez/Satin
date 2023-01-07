    PixelInfo pixel;
    pixel.view = normalize(in.cameraPos - in.worldPos);
    pixel.position = in.worldPos;
    
    Material material;

    material.baseColor = uniforms.baseColor.rgb;
#if defined(BASE_COLOR_MAP)
    material.baseColor *= baseColorMap.sample(pbrLinearSampler, in.texcoords).rgb;
#endif

    material.emissiveColor = uniforms.emissiveColor.rgb * uniforms.emissiveColor.a;
#if defined(EMISSIVE_MAP)
    material.emissiveColor *= emissiveMap.sample(pbrLinearSampler, in.texcoords).rgb;
#endif
    
    material.metallic = uniforms.metallic;
#if defined(METALLIC_MAP)
    material.metallic *= metallicMap.sample(pbrLinearSampler, in.texcoords).r;
#endif
    
    material.roughness = uniforms.roughness;
#if defined(ROUGHNESS_MAP)
    material.roughness *= roughnessMap.sample(pbrLinearSampler, in.texcoords).r;
#endif

    material.specular = uniforms.specular;
#if defined(HAS_SPECULAR)
    material.specularTint = uniforms.specularTint;
#endif

 #if defined(HAS_CLEARCOAT)
     material.clearcoat = uniforms.clearcoat;
     material.clearcoatRoughness = uniforms.clearcoatRoughness;
 #endif

 #if defined(HAS_SUBSURFACE)
     material.subsurface = uniforms.subsurface;
 #endif

 #if defined(HAS_SHEEN)
     material.sheen = uniforms.sheen;
     material.sheenTint = uniforms.sheenTint;
 #endif
    
    material.ambientOcclusion = 1.0;
#if defined(AMBIENT_OCCULSION_MAP)
    material.ambientOcclusion *= ambientOcclusionMap.sample(pbrLinearSampler, in.texcoords).r;
#endif
    
    material.alpha = uniforms.baseColor.a;
#if defined(ALPHA_MAP)
    material.alpha *= alphaMap.sample(pbrLinearSampler, in.texcoords).r;
#endif

#if defined(NORMAL_MAP)
    constexpr sampler normalSampler(filter::linear);
    float3 mapNormal = normalMap.sample(normalSampler, in.texcoords).rgb * 2.0 - 1.0;

#if defined(HAS_TANGENT) && defined(HAS_HAS_BITANGENT)
    // mapNormal.y = -mapNormal.y; // Flip normal map Y-axis if necessary
    const float3x3 TBN(in.tangent, in.bitangent, in.normal);
    const float3 N = normalize(TBN * mapNormal);
    pixel.normal = normalize(TBN * mapNormal);
    
#else
    const float3 Q1 = dfdx(in.worldPos);
    const float3 Q2 = dfdy(in.worldPos);
    const float2 st1 = dfdx(in.texcoords);
    const float2 st2 = dfdy(in.texcoords);

    float3 normal = in.normal;
    float3 tangent = normalize(Q1 * st2.y - Q2 * st1.y);
    float3 bitangent = -normalize(cross(normal, tangent));
    const float3x3 TBN = float3x3(tangent, bitangent, normal);

    pixel.normal = normalize(TBN * mapNormal);
#endif

#else
    pixel.normal = normalize(in.normal);
#endif
    
    pixel.material = material;
