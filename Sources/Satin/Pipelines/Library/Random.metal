float random(float2 co) { return fract(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453); }

float random(float3 seed, int i)
{
    float4 seed4 = float4(seed, i);
    float dot_product = dot(seed4, float4(12.9898, 78.233, 45.164, 94.673));
    return fract(sin(dot_product) * 43758.5453);
}
