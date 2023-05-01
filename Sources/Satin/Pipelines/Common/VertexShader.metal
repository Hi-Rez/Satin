vertex VertexData satinVertex
(
    Vertex in [[stage_in]],
    // inject instancing args
    // inject shadow vertex args
    constant VertexUniforms &vertexUniforms [[buffer(VertexBufferVertexUniforms)]]
)
{
    VertexData out;
    
#if INSTANCING
    out.position = vertexUniforms.viewProjectionMatrix * instanceUniforms[instanceID].modelMatrix * float4(in.position.xyz, 1.0);

#if HAS_NORMAL
    out.normal = instanceUniforms[instanceID].normalMatrix * in.normal;
#endif

#else
    out.position = vertexUniforms.modelViewProjectionMatrix * float4(in.position.xyz, 1.0);

#if HAS_NORMAL
    out.normal = vertexUniforms.normalMatrix * in.normal;
#endif

#endif

#if HAS_UV
    out.uv = in.uv;
#endif

    // inject shadow vertex calc
    return out;
}
