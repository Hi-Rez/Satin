#include "../../Library/Shapes.metal"

typedef struct {
    float4 color;    // color
    float pointSize; // slider,0,64,2
} BasicPointUniforms;

typedef struct {
    float4 position [[position]];
    float3 normal;
    float2 uv;
    float pointSize [[point_size]];
} CustomVertexData;

vertex CustomVertexData basicPointVertex(Vertex in [[stage_in]],
// inject instancing args
    constant VertexUniforms &vertexUniforms [[buffer(VertexBufferVertexUniforms)]],
    constant BasicPointUniforms &uniforms [[buffer(VertexBufferMaterialUniforms)]]) {
    CustomVertexData out;
#if INSTANCING
    const float4x4 modelMatrix = instanceUniforms[instanceID].modelMatrix;
    out.position = vertexUniforms.viewProjectionMatrix * modelMatrix * in.position;
#else
    out.position = vertexUniforms.modelViewProjectionMatrix * in.position;
#endif
    out.pointSize = uniforms.pointSize;
    return out;
}

struct FragOut {
    float4 color [[color(0)]];
    float depth [[depth(any)]];
};

fragment FragOut basicPointFragment(CustomVertexData in [[stage_in]], const float2 puv [[point_coord]],
                                    constant BasicPointUniforms &uniforms
                                    [[buffer(FragmentBufferMaterialUniforms)]]) {
    const float2 uv = 2.0 * puv - 1.0;
    float result = Circle(uv, 1.0);
    result = smoothstep(0.05, 0.0 - fwidth(result), result);
    if (result < 0.05) { discard_fragment(); }
    FragOut out;
    out.color = float4(uniforms.color.rgb, uniforms.color.a * result);
    out.depth = mix(0.0, in.position.z, result);
    return out;
}
