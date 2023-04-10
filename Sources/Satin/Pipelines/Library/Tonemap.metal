#include "Tonemapping/Aces.metal"
#include "Tonemapping/Filmic.metal"
#include "Tonemapping/Lottes.metal"
#include "Tonemapping/Reinhard.metal"
#include "Tonemapping/Reinhard2.metal"
#include "Tonemapping/Uchimura.metal"
#include "Tonemapping/Uncharted2.metal"
#include "Tonemapping/Unreal.metal"

float3 tonemap(float3 color) {
#if defined(TONEMAPPING_NONE)
    return color;
#elif defined(TONEMAPPING_ACES)
    return aces(color);
#elif defined(TONEMAPPING_FILMIC)
    return filmic(color);
#elif defined(TONEMAPPING_LOTTES)
    return lottes(color);
#elif defined(TONEMAPPING_REINHARD)
    return reinhard(color);
#elif defined(TONEMAPPING_REINHARD2)
    return reinhard2(color);
#elif defined(TONEMAPPING_UCHIMURA)
    return uchimura(color);
#elif defined(TONEMAPPING_UNCHARTED2)
    return uncharted2Tonemap(color);
#elif defined(TONEMAPPING_UNREAL)
    return unreal(color);
#endif
}
