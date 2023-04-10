#include "../Gamma.metal"
#include "../Tonemap.metal"

float3 pbrTonemap(thread PixelInfo &pixel)
{
    float3 result = tonemap(pixel.radiance);
#if defined(TONEMAPPING_UNREAL)
    return result;
#else
    return mix(result, gamma(result), pixel.material.gammaCorrection);
#endif
}
