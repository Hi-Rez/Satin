float visibilitySmithGGXCorrelated(float NoV, float NoL, float roughness)
{
    const float a2 = roughness * roughness;
    const float oneMinusA2 = 1.0 - a2;
    const float ggxv = NoL * sqrt(NoV * NoV * oneMinusA2 + a2);
    const float ggxl = NoV * sqrt(NoL * NoL * oneMinusA2 + a2);
    return 0.5 / max(ggxv + ggxl, 0.00001);
}
