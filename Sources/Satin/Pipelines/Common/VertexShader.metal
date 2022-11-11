vertex VertexData satinVertex(Vertex in [[stage_in]],
#if INSTANCING
                              uint instanceID [[instance_id]], constant InstanceMatrixUniforms *instanceUniforms [[buffer(VertexBufferInstanceMatrixUniforms)]],
#endif
                              constant VertexUniforms &vertexUniforms [[buffer(VertexBufferVertexUniforms)]])
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
    return out;
}
