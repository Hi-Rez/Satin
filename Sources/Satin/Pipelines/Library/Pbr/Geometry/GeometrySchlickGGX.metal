float geometrySchlickGGX(float NdotX, float roughness)
{
    float r = roughness + 1.0;
    float k = (r * r) / 8.0;
    return NdotX / (NdotX * (1.0 - k) + k);
}

float geometryAnisoSmithGGX(float NdotV, float VdotX, float VdotY, float ax, float ay)
{
    float x = VdotX * ax;
    float y = VdotY * ay;
    return 1.0 / (NdotV + sqrt(x * x + y * y + NdotV * NdotV));
}

// Microfacet Models for Refraction through Rough Surfaces
// Walter, et al. 2007 (eq. 34)
// https://medium.com/@warrenm/thirty-days-of-metal-day-29-physically-based-rendering-e20e9c1bf984
float geometrySmithGGX(float NdotX, float alpha)
{
    float alpha2 = alpha * alpha;
    float cosThetaSq = NdotX * NdotX;
    float tanThetaSq = (1.0f - cosThetaSq) / max(cosThetaSq, 1e-4);
    return 2.0f / (1.0f + sqrt(1.0f + alpha2 * tanThetaSq));
}
