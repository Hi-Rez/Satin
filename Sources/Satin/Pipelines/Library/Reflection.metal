float3 reflection(float3 worldPosition, float3 worldCameraPosition, float3 normal)
{
    const float3 worldEyeDirection = normalize(worldPosition.xyz - worldCameraPosition);
    return reflect(worldEyeDirection, normal);
}
