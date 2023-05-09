#include "Types.metal"
#include "Library/Colors.metal"

typedef struct {
    float4 color; //color
} PointUniforms;

typedef struct {
    float4 position [[position]];
    float3 normal;
} CustomVertexData;

vertex CustomVertexData pointVertex
(
    uint instanceID [[instance_id]],
    Vertex in [[stage_in]],
    constant VertexUniforms &uniforms [[buffer( VertexBufferVertexUniforms )]],
    const device Point *points [[buffer( VertexBufferCustom0 )]]
)
{
    const Point point = points[instanceID];

    float4 position = in.position;
    position.xyz += point.position.xyz;

    CustomVertexData out;
    out.position = uniforms.modelViewProjectionMatrix * position;
    out.normal = uniforms.normalMatrix * in.normal;
    return out;
}

fragment float4 pointFragment
(
    CustomVertexData in [[stage_in]],
    constant PointUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]]
)
{
    return uniforms.color * float4(normalize(in.normal), 1.0);
}
