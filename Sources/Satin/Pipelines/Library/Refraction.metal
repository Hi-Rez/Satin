float3 refraction(float3 worldPosition, float3 worldCameraPosition, float3 normal, float ior)
{
    const float3 worldEyeDirection = normalize(worldPosition.xyz - worldCameraPosition);
    return refract(worldEyeDirection, normal, ior);
}
