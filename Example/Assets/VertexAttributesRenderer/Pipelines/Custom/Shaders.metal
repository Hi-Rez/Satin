typedef struct {
    float4 color; //color
} CustomUniforms;

typedef struct {
    float4 position [[position]];
    float3 normal;
    float2 uv;
    float3 tangent;
    float3 bitangent;
} CustomVertexData;

vertex CustomVertexData customVertex(
    Vertex in [[stage_in]],
    constant VertexUniforms &vertexUniforms [[buffer(VertexBufferVertexUniforms)]])
{
    CustomVertexData out;
    out.position = vertexUniforms.modelViewProjectionMatrix * in.position;
    out.normal = normalize(vertexUniforms.normalMatrix * in.normal);
    out.uv = in.uv;
    out.tangent = in.tangent;
    out.bitangent = in.bitangent;
    return out;
}

fragment float4 customFragment(
    CustomVertexData in [[stage_in]],
    constant CustomUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]])
{
    return float4(normalize(in.bitangent), 1.0);
}
