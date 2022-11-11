float3 fresnelSchlick(float HoV, float3 f0)
{
    return f0 + (1.0 - f0) * pow(1.0 - HoV, 5.0);
}
