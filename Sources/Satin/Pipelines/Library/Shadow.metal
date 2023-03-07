float calculateShadow(float4 shadowCoord, depth2d<float> shadowTex, sampler shadowSampler)
{
    shadowCoord.xyz /= shadowCoord.w;
    shadowCoord.y *= -1.0;
    shadowCoord.xy = 0.5 + shadowCoord.xy * 0.5;
    shadowCoord.z += 0.0001;

    bool inFrustum = shadowCoord.x >= 0.0 && shadowCoord.x <= 1.0 && shadowCoord.y >= 0.0 && shadowCoord.y <= 1.0;
    bool frustumTest = inFrustum && shadowCoord.z <= 1.0;
    if(frustumTest) {
        const float2 texelSize = 1.0/float2(shadowTex.get_width(), shadowTex.get_height());
        float2 offset = 0.0;
        float shadow = 0.0;
        // PCF
        for (int y = -1 ; y <= 1 ; y++) {
            for (int x = -1 ; x <= 1 ; x++) {
                offset = float2(x, y) * texelSize;
                shadow += shadowTex.sample_compare(shadowSampler, shadowCoord.xy + offset, shadowCoord.z);
            }
        }
        return saturate(0.75 + shadow / 9.0);
    }

    return 1.0;
}
