#include "GeometrySchlickGGX.metal"

float geometrySmith(float NoV, float NoL, float roughness)
{
    return geometrySchlickGGX(NoV, roughness) * geometrySchlickGGX(NoL, roughness);
}
