#if defined(NORMAL_MAP)
    const float2 normalTexcoord = (uniforms.normalTexcoordTransform * float3(in.texcoords, 1.0)).xy;
    float3 mapNormal = normalMap.sample(normalSampler, normalTexcoord).rgb * 2.0 - 1.0;

#if defined(HAS_TANGENT) && defined(HAS_BITANGENT)
    const float3x3 TBN(in.tangent, in.bitangent, in.normal);
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

