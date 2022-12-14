float schlickWeight(float cosTheta)
{
    const float w = saturate(1.0 - cosTheta);
    const float w2 = w * w;
    return w * w2 * w2;
}

float3 fresnelSchlickRoughness(float cosTheta, float3 f0, float roughness)
{
    return f0 + (max(float3(1.0 - roughness), f0) - f0) * schlickWeight(cosTheta);
}
