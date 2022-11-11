float map(float value, float inMin, float inMax, float outMin, float outMax)
{
    return ((value - inMin) / (inMax - inMin) * (outMax - outMin)) + outMin;
}

float2 map(float2 value, float2 inMin, float2 inMax, float2 outMin, float2 outMax)
{
    return ((value - inMin) / (inMax - inMin) * (outMax - outMin)) + outMin;
}

float3 map(float3 value, float3 inMin, float3 inMax, float3 outMin, float3 outMax)
{
    return ((value - inMin) / (inMax - inMin) * (outMax - outMin)) + outMin;
}

half hmap(half value, half inMin, half inMax, half outMin, half outMax)
{
    return ((value - inMin) / (inMax - inMin) * (outMax - outMin)) + outMin;
}
