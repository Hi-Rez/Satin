float getSquareFalloffAttenuation(float distanceSquare, float lightInvRadius)
{
    const float factor = distanceSquare * lightInvRadius * lightInvRadius;
    const float smoothFactor = max(1.0 - factor * factor, 0.0);
    return (smoothFactor * smoothFactor) / max(distanceSquare, 1e-4);
}

float getSpotAngleAttenuation(float3 fragmentToLightDir, float3 lightDir, float2 spotInfo)
{
    const float cd = dot(lightDir, fragmentToLightDir);
    const float attenuation = saturate(cd * spotInfo.x + spotInfo.y);
    return attenuation * attenuation;
}

#if defined(LIGHTING)
// Returns light radiance, set L to the light direction
float3 getLightInfo(const Light light, float3 worldPosition, thread float3 &lightDirection, thread float &lightDistance)
{
    float3 lightRadiance = light.color.rgb * light.color.a;
    const float3 lightPosition = light.position.xyz;
    const LightType type = (LightType)light.position.w;

    lightDirection = light.direction.xyz; // L = Vector from Fragment to Light
    lightDistance = INFINITY;

    if (type > LightTypeDirectional) { // We are dealing with a point light
        const float inverseRadius = light.direction.w;
        const float3 worldToLight = lightPosition - worldPosition;
        const float distanceSquare = dot(worldToLight, worldToLight);
        
        lightRadiance *= getSquareFalloffAttenuation(distanceSquare, inverseRadius);
        lightDistance = sqrt(distanceSquare);
        lightDirection = worldToLight / lightDistance;

        if (type > LightTypePoint) {
            // We are dealing with a spot light
            lightRadiance *= getSpotAngleAttenuation(lightDirection, light.direction.xyz, light.spotInfo.xy);
        }
    }

    return lightRadiance;
}
#endif
