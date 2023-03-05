float calculateShadow(float4 shadowCoord, depth2d<float> shadowTex, sampler shadowSampler)
{
    shadowCoord.xyz /= shadowCoord.w;
    shadowCoord.y *= -1.0;
    shadowCoord.xy = 0.5 + shadowCoord.xy * 0.5;
    shadowCoord.z += 0.002;

    bool inFrustum = shadowCoord.x >= 0.0 && shadowCoord.x <= 1.0 && shadowCoord.y >= 0.0 && shadowCoord.y <= 1.0;
    bool frustumTest = inFrustum && shadowCoord.z <= 1.0;
    if(frustumTest) {
        return shadowTex.sample_compare(shadowSampler, shadowCoord.xy, shadowCoord.z);
    }

    return 1.0;
}
