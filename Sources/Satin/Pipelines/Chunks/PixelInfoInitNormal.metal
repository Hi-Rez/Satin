#if defined(NORMAL_MAP)
    constexpr sampler normalSampler(filter::linear);
    float3 mapNormal = normalMap.sample(normalSampler, in.texcoords).rgb * 2.0 - 1.0;

#if defined(HAS_TANGENT) && defined(HAS_HAS_BITANGENT)
    // mapNormal.y = -mapNormal.y; // Flip normal map Y-axis if necessary
    const float3x3 TBN(in.tangent, in.bitangent, in.normal);
    const float3 N = normalize(TBN * mapNormal);
    pixel.normal = normalize(TBN * mapNormal);
    
#else
    const float3 Q1 = dfdx(in.worldPosition);
    const float3 Q2 = dfdy(in.worldPosition);
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

