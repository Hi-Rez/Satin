#include "Library/Colors.metal"

typedef struct {
    float time;
} RainbowUniforms;

typedef struct {
    float4 position [[position]];
    float id;
} CustomVertexData;

vertex CustomVertexData rainbowVertex
(
    Vertex in [[stage_in]],
    // inject instancing args
    constant VertexUniforms &vertexUniforms [[buffer(VertexBufferVertexUniforms)]]
)
{
    CustomVertexData out;
#if INSTANCING
    out.position = vertexUniforms.viewProjectionMatrix * instanceUniforms[instanceID].modelMatrix * in.position;
#else
    out.position = vertexUniforms.modelViewProjectionMatrix * in.position;
#endif
    out.id = float(instanceID);
    return out;
}

fragment float4 rainbowFragment
(
    CustomVertexData in [[stage_in]],
    constant RainbowUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]]
)
{
    const float uv = in.id/2000.0 + uniforms.time * 0.0;
    return float4(iridescence(uv), 1.0);
}
