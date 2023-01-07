#include "GeometrySchlickGGX.metal"

float geometrySmith(float NdotV, float NdotL, float roughness)
{
    float alpha = roughness * roughness;
    return geometrySmithGGX(NdotV, alpha) * geometrySmithGGX(NdotL, alpha);
}

float geometryAnisoSmith(float NdotL, float LdotX, float LdotY, float NdotV, float VdotX, float VdotY, float ax, float ay)
{
    return geometryAnisoSmithGGX(NdotL, LdotX, LdotY, ax, ay) *
           geometryAnisoSmithGGX(NdotV, VdotX, VdotY, ax, ay);
}
