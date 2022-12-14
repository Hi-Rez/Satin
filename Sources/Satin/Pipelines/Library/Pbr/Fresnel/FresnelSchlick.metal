float3 fresnelSchlick(float VoH, float3 f0, float3 f90)
{
    const float x = saturate(1.0 - VoH);
    const float x2 = x * x;
    const float x5 = x * x2 * x2;
    return f0 + (f90 - f0) * x5;
}
