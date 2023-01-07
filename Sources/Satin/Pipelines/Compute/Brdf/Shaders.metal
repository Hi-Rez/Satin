#include "Library/Pbr/ImportanceSampling.metal"
#include "Library/Pbr/Visibility/VisibilitySmithGGXCorrelated.metal"

#define SAMPLE_COUNT 1024u

// https://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf
// Karis 2014
float2 integrate(float NdotV, float roughness)
{
    float3 V;
    V.x = sqrt(1.0 - NdotV * NdotV); // sin
    V.y = 0.0;
    V.z = NdotV; // cos

    // N points straight upwards for this integration
    const float3 N = float3(0.0, 0.0, 1.0);

    float A = 0.0;
    float B = 0.0;

    for (uint i = 0u; i < SAMPLE_COUNT; i++) {
        float2 Xi = hammersley(i, SAMPLE_COUNT);
        float3 H = importanceSampleGGX(Xi, N, roughness);
        float3 L = 2.0 * dot(V, H) * H - V;

        float NdotL = saturate(L.z);
        float NdotH = saturate(H.z);
        float VdotH = saturate(dot(V, H));
        
        if (NdotL > 0.0) {
            float V_pdf = visibilitySmithGGXCorrelated(NdotV, NdotL, roughness) * VdotH * NdotL / NdotH;
            float Fc = pow(1.0 - VdotH, 5.0);
            A += (1.0 - Fc) * V_pdf;
            B += Fc * V_pdf;
        }
    }

    return 4.0 * float2(A, B) / float(SAMPLE_COUNT);
}

kernel void brdfUpdate(uint2 gid [[thread_position_in_grid]], texture2d<float, access::write> tex [[texture(ComputeTextureCustom0)]])
{
    if (gid.x >= tex.get_width() || gid.y >= tex.get_height()) { return; }
    const float2 size = float2(tex.get_width(), tex.get_height()) - 1.0;
    const float2 uv = float2(gid) / size;
    tex.write(float4(integrate(uv.x, uv.y), 0.0, 1.0), gid);
}
