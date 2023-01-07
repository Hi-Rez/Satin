#if defined(HAS_MAPS)
constexpr sampler pbrLinearSampler(mip_filter::linear, mag_filter::linear, min_filter::linear);
#endif

#if defined(REFLECTION_MAP) && defined(BRDF_MAP)
constexpr sampler pbrMipSampler(min_filter::linear, mag_filter::linear, mip_filter::linear);
#endif
