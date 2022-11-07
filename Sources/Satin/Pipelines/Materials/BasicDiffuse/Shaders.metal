#include "../../Library/Dither.metal"

typedef struct {
    float4 position [[position]];
    float3 viewPosition;
    float3 normal;
} DiffuseVertexData;

typedef struct {
    float4 color;       // color
    float hardness;     // slider
    float diffusePower; // slider,0,2,0.5
} BasicDiffuseUniforms;

vertex DiffuseVertexData basicDiffuseVertex(Vertex in [[stage_in]],
// inject instancing args
    constant VertexUniforms &vertexUniforms [[buffer(VertexBufferVertexUniforms)]])
{
#if INSTANCING
    const float3x3 normalMatrix = instanceUniforms[instanceID].normalMatrix;
    const float4x4 modelMatrix = instanceUniforms[instanceID].modelMatrix;
    
    const float4 viewPosition = vertexUniforms.viewMatrix * modelMatrix * in.position;
    const float3 normal = normalMatrix * in.normal;
#else
    const float4 viewPosition = vertexUniforms.modelViewMatrix * in.position;
    const float3 normal = vertexUniforms.normalMatrix * in.normal;
#endif
    
    const float4 screenSpaceNormal = vertexUniforms.viewMatrix * float4(normal, 0.0);
    
    DiffuseVertexData out;
    out.viewPosition = viewPosition.xyz;
    out.position = vertexUniforms.projectionMatrix * viewPosition;
    out.normal = screenSpaceNormal.xyz;
    return out;
}

fragment float4 basicDiffuseFragment(DiffuseVertexData in [[stage_in]],
    constant BasicDiffuseUniforms &uniforms [[buffer(FragmentBufferMaterialUniforms)]])
{
    const float3 pos = in.viewPosition;
    const float3 dx = normalize(dfdx(pos));
    const float3 dy = normalize(dfdy(pos));
    const float3 normal = normalize(cross(dx, dy));
    const float soft = dot(normalize(in.normal), float3(0.0, 0.0, 1.0));
    const float hard = saturate(dot(normal, float3(0.0, 0.0, -1.0)));
    float3 color =
        uniforms.color.rgb * float3(pow(mix(soft, hard, uniforms.hardness), uniforms.diffusePower));
    color = dither8x8(in.position.xy, color);
    return float4(color, uniforms.color.a);
}
