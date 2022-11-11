float getSquareFalloffAttenuation(float distanceSquare, float lightInvRadius)
{
    const float factor = distanceSquare * lightInvRadius * lightInvRadius;
    const float smoothFactor = max(1.0 - factor * factor, 0.0);
    return (smoothFactor * smoothFactor) / max(distanceSquare, 1e-4);
}

float getSpotAngleAttenuation(float3 l, float3 lightDir, float2 spotInfo)
{
    const float cd = dot(lightDir, l);
    const float attenuation = saturate(cd * spotInfo.x + spotInfo.y);
    return attenuation * attenuation;
}

#if defined(LIGHTING)
void getLightInfo(const Light light, float3 worldPosition, thread float3 &L, thread float3 &R)
{
    const float3 lightRadiance = light.color.rgb * light.color.a;
    const float3 lightPosition = light.position.xyz;
    const LightType type = (LightType)light.position.w;
    const float3 lightDirection = light.direction.xyz;
    const float inverseRadius = light.direction.w;

    R = lightRadiance;       // R = Radiance
    L = light.direction.xyz; // L = Vector from Fragment to Light

    if (type > LightTypeDirectional) {
        const float3 worldToLight = lightPosition - worldPosition;
        const float distanceSquare = dot(worldToLight, worldToLight);
        R *= getSquareFalloffAttenuation(distanceSquare, inverseRadius);
        L = worldToLight / sqrt(distanceSquare);

        if (type > LightTypePoint) {
            R *= getSpotAngleAttenuation(L, lightDirection, light.spotInfo.xy);
        }
    }
}
#endif
