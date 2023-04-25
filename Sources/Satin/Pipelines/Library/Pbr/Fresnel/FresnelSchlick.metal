float schlickWeight(float cosTheta)
{
    const float w = saturate(1.0 - saturate(cosTheta));
    const float w2 = w * w;
    return w * w2 * w2;
}

float3 fresnelSchlick(float cosTheta, float3 f0, float3 f90)
{
    return f0 + (f90 - f0) * schlickWeight(cosTheta);
}

float3 fresnelSchlickRoughness(float cosTheta, float3 f0, float roughness)
{
    return f0 + (max(float3(1.0 - roughness), f0) - f0) * schlickWeight(cosTheta);
}
