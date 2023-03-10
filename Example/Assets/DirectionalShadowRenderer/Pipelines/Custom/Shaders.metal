typedef struct {
    float4 color; //color
} CustomUniforms;

vertex VertexData customVertex
(
    Vertex in [[stage_in]],
    // inject instancing args
    // inject shadow vertex args
    constant VertexUniforms &vertexUniforms [[buffer(VertexBufferVertexUniforms)]]
)
{
    VertexData out;
#if INSTANCING
    out.position = vertexUniforms.viewProjectionMatrix * instanceUniforms[instanceID].modelMatrix * in.position;
    out.normal = instanceUniforms[instanceID].normalMatrix * in.normal;
#else
    out.position = vertexUniforms.modelViewProjectionMatrix * in.position;
    out.normal = vertexUniforms.normalMatrix * in.normal;
#endif
    out.uv = in.uv;
    // inject shadow vertex calc
    return out;
}

fragment float4 customFragment
(
    VertexData in [[stage_in]],
    // inject shadow fragment args
    constant CustomUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]]
)
{
    float4 outColor = uniforms.color;
    // inject shadow fragment calc
    return outColor;
}
