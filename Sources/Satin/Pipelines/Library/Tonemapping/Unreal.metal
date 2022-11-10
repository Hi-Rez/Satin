// Unreal 3, Documentation: "Color Grading"
// Adapted to be close to Tonemap_ACES, with similar range
// Gamma 2.2 correction is baked in, don't use with sRGB conversion!
float3 unreal(float3 x)
{
    return x / (x + 0.155) * 1.019;
}

float unreal(float x)
{
    return x / (x + 0.155) * 1.019;
}
