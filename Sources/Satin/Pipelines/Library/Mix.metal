float3 linear(float t, float3 a, float3 b, float3 c, float3 d, float3 e, float3 f)
{
    const float div = 1.0 / 5.0;
    const float da = clamp(div - abs(t - div * 0.0), 0.0, 1.0) / div;
    const float db = clamp(div - abs(t - div * 1.0), 0.0, 1.0) / div;
    const float dc = clamp(div - abs(t - div * 2.0), 0.0, 1.0) / div;
    const float dd = clamp(div - abs(t - div * 3.0), 0.0, 1.0) / div;
    const float de = clamp(div - abs(t - div * 4.0), 0.0, 1.0) / div;
    const float df = clamp(div - abs(t - div * 5.0), 0.0, 1.0) / div;
    return da * a + db * b + dc * c + dd * d + de * e + df * f;
}

float3 linear(float t, float3 a, float3 b, float3 c, float3 d, float3 e)
{
    const float div = 1.0 / 4.0;
    const float da = clamp(div - abs(t - div * 0.0), 0.0, 1.0) / div;
    const float db = clamp(div - abs(t - div * 1.0), 0.0, 1.0) / div;
    const float dc = clamp(div - abs(t - div * 2.0), 0.0, 1.0) / div;
    const float dd = clamp(div - abs(t - div * 3.0), 0.0, 1.0) / div;
    const float de = clamp(div - abs(t - div * 4.0), 0.0, 1.0) / div;
    return da * a + db * b + dc * c + dd * d + de * e;
}

float linear(float t, float a, float b, float c, float d, float e)
{
    const float div = 1.0 / 4.0;
    const float da = clamp(div - abs(t - div * 0.0), 0.0, 1.0) / div;
    const float db = clamp(div - abs(t - div * 1.0), 0.0, 1.0) / div;
    const float dc = clamp(div - abs(t - div * 2.0), 0.0, 1.0) / div;
    const float dd = clamp(div - abs(t - div * 3.0), 0.0, 1.0) / div;
    const float de = clamp(div - abs(t - div * 4.0), 0.0, 1.0) / div;
    return da * a + db * b + dc * c + dd * d + de * e;
}

float3 linear(float t, float3 a, float3 b, float3 c, float3 d)
{
    const float div = 1.0 / 3.0;
    const float da = clamp(div - abs(t - div * 0.0), 0.0, 1.0) / div;
    const float db = clamp(div - abs(t - div * 1.0), 0.0, 1.0) / div;
    const float dc = clamp(div - abs(t - div * 2.0), 0.0, 1.0) / div;
    const float dd = clamp(div - abs(t - div * 3.0), 0.0, 1.0) / div;
    return da * a + db * b + dc * c + dd * d;
}

float3 linear(float t, float3 a, float3 b, float3 c)
{
    const float div = 1.0 / 2.0;
    const float da = clamp(div - abs(t - div * 0.0), 0.0, 1.0) / div;
    const float db = clamp(div - abs(t - div * 1.0), 0.0, 1.0) / div;
    const float dc = clamp(div - abs(t - div * 2.0), 0.0, 1.0) / div;
    return da * a + db * b + dc * c;
}

float3 linear(float t, float3 a, float3 b)
{
    const float div = 1.0;
    const float da = clamp(div - abs(t - div * 0.0), 0.0, 1.0) / div;
    const float db = clamp(div - abs(t - div * 1.0), 0.0, 1.0) / div;
    return da * a + db * b;
}
