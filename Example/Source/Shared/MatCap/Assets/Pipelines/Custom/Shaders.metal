#include "Library/Shapes.metal"

typedef struct {
    float4 color; //color
} CustomUniforms;

typedef struct {
    float4 position [[attribute(VertexAttributePosition)]];
    float3 normal [[attribute(VertexAttributeNormal)]];
    float2 uv [[attribute(VertexAttributeTexcoord)]];
    float3 tangent [[attribute(VertexAttributeTangent)]];
} CustomVertex;

typedef struct {
    float4 position [[position]];
    float3 normal;
    float2 uv;
    float3 tangent;
} CustomVertexData;

vertex CustomVertexData customVertex(CustomVertex in [[stage_in]],
                              constant VertexUniforms &vertexUniforms
                              [[buffer(VertexBufferVertexUniforms)]]) {
    CustomVertexData out;
    out.position = vertexUniforms.modelViewProjectionMatrix * in.position;
    out.normal = normalize(vertexUniforms.normalMatrix * in.normal);
    out.uv = in.uv;
    out.tangent = in.tangent;
    return out;
}

fragment float4 customFragment( CustomVertexData in [[stage_in]],
    constant CustomUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]] )
{
//    return float4( float3( in.uv, 1.0 ), 1.0 );
    return float4( in.tangent, 1.0 );
}
