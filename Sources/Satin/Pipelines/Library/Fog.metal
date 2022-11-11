float3 fog(float3 fogcolor, float3 color, float fogfactor)
{
    return mix(fogcolor, color, fogfactor);
}

float getFogFactor(float3 camPos, float3 pos, float fogDistance, float fogDensity, float fogPower, float fogScale)
{
    float3 delta = camPos - pos;
    float fogfactor = fogScale * length(delta) / fogDistance;
    fogfactor = 1.0 / exp(pow(fogfactor * fogDensity, fogPower));
    fogfactor = clamp(fogfactor, 0.0, 1.0);
    return fogfactor;
}
