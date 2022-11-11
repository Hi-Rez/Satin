float3 hsv2rgb(float3 c)
{
    const float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float3 hsv2rgb(float h, float s, float v) { return hsv2rgb(float3(h, s, v)); }

// IQ
float3 hsv2rgb_smooth(float3 c)
{
    float3 rgb = clamp(abs(fmod(c.x * 6.0 + float3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    rgb = rgb * rgb * (3.0 - 2.0 * rgb); // cubic smoothing
    return c.z * mix(float3(1.0), rgb, c.y);
}

float3 hsv2rgb_smooth(float h, float s, float v) { return hsv2rgb_smooth(float3(h, s, v)); }
