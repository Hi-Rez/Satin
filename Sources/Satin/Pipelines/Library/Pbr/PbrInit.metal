void pbrInit(thread PixelInfo &pixel)
{
    pixel.material.roughness = max(0.045, pixel.material.roughness);

#if defined(HAS_CLEARCOAT)
    pixel.material.clearcoat = mix(0.0, 0.25, pixel.material.clearcoat);
    pixel.material.clearcoatRoughness = mix(0.001, 0.1, pixel.material.clearcoatRoughness);
#endif

    pixel.radiance = pixel.material.emissiveColor;
}
