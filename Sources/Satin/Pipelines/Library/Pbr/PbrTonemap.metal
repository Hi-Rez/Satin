#include "../Gamma.metal"
#include "../Tonemapping/Aces.metal"

float3 pbrTonemap(thread PixelInfo &pixel)
{
    return gamma(aces(pixel.radiance)); // HDR Tonemapping & Gamma Correction
}
