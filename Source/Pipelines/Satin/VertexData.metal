typedef struct {
    float4 position [[position]];
    float4 shadowPosition;
    float3 normal;
    float2 uv;
    float pointSize [[point_size]];
} VertexData;
