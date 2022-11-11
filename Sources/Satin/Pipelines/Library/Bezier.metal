float3 bezier(float t, float3 a, float3 b, float3 c, float3 d, float3 e, float3 f)
{
    const float3 OneMinusT = float3(1.0 - t);
    const float3 a0 = 1.0 * pow(t, 0.0) * pow(OneMinusT, 5.0) * a;
    const float3 b0 = 5.0 * pow(t, 1.0) * pow(OneMinusT, 4.0) * b;
    const float3 c0 = 10.0 * pow(t, 2.0) * pow(OneMinusT, 3.0) * c;
    const float3 d0 = 10.0 * pow(t, 3.0) * pow(OneMinusT, 2.0) * d;
    const float3 e0 = 5.0 * pow(t, 4.0) * pow(OneMinusT, 1.0) * e;
    const float3 f0 = 1.0 * pow(t, 5.0) * pow(OneMinusT, 0.0) * f;
    return a0 + b0 + c0 + d0 + e0 + f0;
}

float3 bezier(float t, float3 a, float3 b, float3 c, float3 d, float3 e)
{
    const float3 OneMinusT = float3(1.0 - t);
    const float3 a0 = 1.0 * pow(t, 0.0) * pow(OneMinusT, 4.0) * a;
    const float3 b0 = 4.0 * pow(t, 1.0) * pow(OneMinusT, 3.0) * b;
    const float3 c0 = 6.0 * pow(t, 2.0) * pow(OneMinusT, 2.0) * c;
    const float3 d0 = 4.0 * pow(t, 3.0) * pow(OneMinusT, 1.0) * d;
    const float3 e0 = 1.0 * pow(t, 4.0) * pow(OneMinusT, 0.0) * e;
    return a0 + b0 + c0 + d0 + e0;
}

float bezier(float t, float a, float b, float c, float d, float e)
{
    const float OneMinusT = (1.0 - t);
    const float a0 = 1.0 * pow(t, 0.0) * pow(OneMinusT, 4.0) * a;
    const float b0 = 4.0 * pow(t, 1.0) * pow(OneMinusT, 3.0) * b;
    const float c0 = 6.0 * pow(t, 2.0) * pow(OneMinusT, 2.0) * c;
    const float d0 = 4.0 * pow(t, 3.0) * pow(OneMinusT, 1.0) * d;
    const float e0 = 1.0 * pow(t, 4.0) * pow(OneMinusT, 0.0) * e;
    return a0 + b0 + c0 + d0 + e0;
}

float3 bezier(float3 t, float3 a, float3 b, float3 c, float3 d, float3 e)
{
    const float3 OneMinusT = float3(1.0 - t);
    const float3 a0 = 1.0 * pow(t, 0.0) * pow(OneMinusT, 4.0) * a;
    const float3 b0 = 4.0 * pow(t, 1.0) * pow(OneMinusT, 3.0) * b;
    const float3 c0 = 6.0 * pow(t, 2.0) * pow(OneMinusT, 2.0) * c;
    const float3 d0 = 4.0 * pow(t, 3.0) * pow(OneMinusT, 1.0) * d;
    const float3 e0 = 1.0 * pow(t, 4.0) * pow(OneMinusT, 0.0) * e;
    return a0 + b0 + c0 + d0 + e0;
}

float2 bezier(float2 t, float2 a, float2 b, float2 c, float2 d, float2 e)
{
    const float2 OneMinusT = float2(1.0 - t);
    const float2 a0 = 1.0 * pow(t, 0.0) * pow(OneMinusT, 4.0) * a;
    const float2 b0 = 4.0 * pow(t, 1.0) * pow(OneMinusT, 3.0) * b;
    const float2 c0 = 6.0 * pow(t, 2.0) * pow(OneMinusT, 2.0) * c;
    const float2 d0 = 4.0 * pow(t, 3.0) * pow(OneMinusT, 1.0) * d;
    const float2 e0 = 1.0 * pow(t, 4.0) * pow(OneMinusT, 0.0) * e;
    return a0 + b0 + c0 + d0 + e0;
}

float3 bezier(float t, float3 a, float3 b, float3 c, float3 d)
{
    const float3 OneMinusT = float3(1.0 - t);
    const float3 a0 = 1.0 * pow(t, 0.0) * pow(OneMinusT, 3.0) * a;
    const float3 b0 = 3.0 * pow(t, 1.0) * pow(OneMinusT, 2.0) * b;
    const float3 c0 = 3.0 * pow(t, 2.0) * pow(OneMinusT, 1.0) * c;
    const float3 d0 = 1.0 * pow(t, 3.0) * pow(OneMinusT, 0.0) * d;
    return a0 + b0 + c0 + d0;
}

float3 bezier(float3 t, float3 a, float3 b, float3 c, float3 d)
{
    const float3 OneMinusT = float3(1.0 - t);
    const float3 a0 = 1.0 * pow(t, 0.0) * pow(OneMinusT, 3.0) * a;
    const float3 b0 = 3.0 * pow(t, 1.0) * pow(OneMinusT, 2.0) * b;
    const float3 c0 = 3.0 * pow(t, 2.0) * pow(OneMinusT, 1.0) * c;
    const float3 d0 = 1.0 * pow(t, 3.0) * pow(OneMinusT, 0.0) * d;
    return a0 + b0 + c0 + d0;
}

float3 bezier(float3 t, float3 a, float3 b, float3 c)
{
    const float3 OneMinusT = float3(1.0 - t);
    const float3 a0 = 1.0 * pow(t, 0.0) * pow(OneMinusT, 2.0) * a;
    const float3 b0 = 2.0 * pow(t, 1.0) * pow(OneMinusT, 1.0) * b;
    const float3 c0 = 1.0 * pow(t, 2.0) * pow(OneMinusT, 0.0) * c;
    return a0 + b0 + c0;
}
