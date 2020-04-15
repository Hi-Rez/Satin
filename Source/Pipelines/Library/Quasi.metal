#include "pi.metal"
float quasi(float2 uv, float freq, float time) {
    float dist = sin(1.0 - length(uv) * PI * freq + 2.0 * time);
    dist += sin(1.0 - length(uv + float2(1.0, 0.0)) * PI * freq + 2.0 * time);
    dist += sin(1.0 - length(uv + float2(-1.0, 0.0)) * PI * freq + 2.0 * time);
    dist += sin(1.0 - length(uv + float2(0.0, 1.0)) * PI * freq + 2.0 * time);
    dist += sin(1.0 - length(uv + float2(0.0, -1.0)) * PI * freq + 2.0 * time);
    dist += sin(1.0 - length(uv + float2(-1.0, -1.0)) * PI * freq + 2.0 * time);
    dist += sin(1.0 - length(uv + float2(1.0, -1.0)) * PI * freq + 2.0 * time);
    dist += sin(1.0 - length(uv + float2(1.0, 1.0)) * PI * freq + 2.0 * time);
    dist += sin(1.0 - length(uv + float2(-1.0, 1.0)) * PI * freq + 2.0 * time);
    dist = 1.0 - smoothstep(1.0, 1.0 - fwidth(dist), dist);
    return dist;
}