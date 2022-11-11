float geometryNeumann(float NoV, float NoL)
{
    const float numerator = NoL * NoV;
    const float denominator = max(NoL, NoV);
    return numerator / max(denominator, 0.00001);
}
