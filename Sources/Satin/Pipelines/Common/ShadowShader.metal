vertex float4 satinShadowVertex
(
    Vertex in [[stage_in]],
    // inject instancing args
    constant VertexUniforms &vertexUniforms [[buffer(VertexBufferVertexUniforms)]]
)
{
#if INSTANCING
    return vertexUniforms.viewProjectionMatrix * instanceUniforms[instanceID].modelMatrix * in.position;
#else
    return vertexUniforms.modelViewProjectionMatrix * in.position;
#endif
}
