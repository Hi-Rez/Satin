float geometrySchlickGGX(float NoX, float roughness)
{
    const float alpha = roughness * roughness;
    const float k = alpha / 2.0;
    const float denominator = NoX * (1.0 - k) + k;
    return max(NoX, 0.00001) / max(denominator, 0.00001);
}
