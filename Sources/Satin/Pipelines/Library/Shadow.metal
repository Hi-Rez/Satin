float calculateShadow(float4 shadowCoord, depth2d<float> shadowTex, ShadowData data, sampler shadowSampler)
{
    shadowCoord.xyz /= shadowCoord.w;
    shadowCoord.y *= -1.0;
    shadowCoord.xy = 0.5 + shadowCoord.xy * 0.5;

    bool inFrustum = shadowCoord.x >= 0.0 && shadowCoord.x <= 1.0 && shadowCoord.y >= 0.0 && shadowCoord.y <= 1.0;
    bool frustumTest = inFrustum && shadowCoord.z < 1.0;
    if(frustumTest) {
        shadowCoord.z += data.bias;
        const int radius = int(data.radius);
        const float2 texelSize = 1.0/float2(shadowTex.get_width(), shadowTex.get_height());
        float shadow = 0.0;
        float samples = 0.0;
        for (int y = -radius; y <= radius; y++) {
            for (int x = -radius; x <= radius; x++) {
                const float2 offset = float2(x, y) * texelSize;
                shadow += shadowTex.sample_compare(shadowSampler, shadowCoord.xy + offset, shadowCoord.z);
                samples += 1.0;
            }
        }

        return mix(1.0, (shadow / samples), data.strength);
    }

    return 1.0;
}
