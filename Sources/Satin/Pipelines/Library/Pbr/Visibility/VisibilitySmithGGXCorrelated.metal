float visibilitySmithGGXCorrelated(float NdotV, float NdotL, float roughness)
{
    float a2 = roughness * roughness;
    float oneMinusA2 = 1.0 - a2;
    float ggxv = NdotL * sqrt(NdotV * NdotV * oneMinusA2 + a2);
    float ggxl = NdotV * sqrt(NdotL * NdotL * oneMinusA2 + a2);

    float ggx = ggxv + ggxl;
    if (ggx > 0.0) {
        return 0.5 / ggx;
    }
    return 0.0;
}

// Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"
// TODO: lambdaV can be pre-computed for all the lights, it should be moved out of this function
float visibilityAnisoSmithGGXCorrelated(float NdotV, float NdotL, float VdotX, float VdotY, float LdotX, float LdotY, float ax, float ay)
{
    float lambdaV = NdotL * length(float3(ax * VdotX, ay * VdotY, NdotL));
    float lambdaL = NdotV * length(float3(ax * LdotX, ay * LdotY, NdotV));
    float v = 0.5 / (lambdaV + lambdaL);
    return saturate(v);
}
