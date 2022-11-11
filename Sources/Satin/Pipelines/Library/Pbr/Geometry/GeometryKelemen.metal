float geometryKelemen(float NoV, float NoL, float VoH)
{
    const float numerator = NoL * NoV;
    const float denominator = VoH * VoH;
    return numerator / max(denominator, 0.00001);
}
