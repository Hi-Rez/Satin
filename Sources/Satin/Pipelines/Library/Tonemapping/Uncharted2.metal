float3 uncharted2Tonemap(float3 x)
{
    const float A = 0.15;
    const float B = 0.50;
    const float C = 0.10;
    const float D = 0.20;
    const float E = 0.02;
    const float F = 0.30;
    const float W = 11.2;
    return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
}

float3 uncharted2(float3 color)
{
    const float W = 11.2;
    const float exposureBias = 2.0;
    const float3 curr = uncharted2Tonemap(exposureBias * color);
    const float3 whiteScale = 1.0 / uncharted2Tonemap(W);
    return curr * whiteScale;
}

float uncharted2Tonemap(float x)
{
    const float A = 0.15;
    const float B = 0.50;
    const float C = 0.10;
    const float D = 0.20;
    const float E = 0.02;
    const float F = 0.30;
    const float W = 11.2;
    return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
}

float uncharted2(float color)
{
    const float W = 11.2;
    const float exposureBias = 2.0;
    const float curr = uncharted2Tonemap(exposureBias * color);
    const float whiteScale = 1.0 / uncharted2Tonemap(W);
    return curr * whiteScale;
}
