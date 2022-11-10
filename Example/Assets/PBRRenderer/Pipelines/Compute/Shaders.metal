#include "Satin/Includes.metal"
#include "Library/Rotate.metal"
#include "Library/Pi.metal"
#include "Library/Pbr.metal"

static constant float4 rotations[6] = {
    float4( 0.0, 1.0, 0.0, HALF_PI ),
    float4( 0.0, 1.0, 0.0, -HALF_PI ),
    float4( 1.0, 0.0, 0.0, -HALF_PI ),
    float4( 1.0, 0.0, 0.0, HALF_PI ),
    float4( 0.0, 0.0, 1.0, 0.0 ),
    float4( 0.0, 1.0, 0.0, PI )
};

#define SAMPLE_COUNT 1024u
#define worldUp float3( 0.0, 1.0, 0.0 )

#include "Skybox.metal"
#include "Cubemap.metal"
#include "Diffuse.metal"
#include "Specular.metal"
#include "Integration.metal"
