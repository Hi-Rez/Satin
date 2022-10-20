typedef struct {
    float4 color; // color
} SkyboxUniforms;

typedef struct {
    float4 position [[position]];
    float3 uv;
} SkyVertexData;

vertex SkyVertexData skyboxVertex(Vertex v [[stage_in]],
#if INSTANCING
                                  uint instanceID [[instance_id]],
                                  constant InstanceMatrixUniforms *instanceUniforms [[buffer(VertexBufferInstanceMatrixUniforms)]],
#endif
                                  constant VertexUniforms &vertexUniforms [[buffer(VertexBufferVertexUniforms)]]) {
    
#if INSTANCING
    const float4x4 modelViewProjectionMatrix = vertexUniforms.viewProjectionMatrix * instanceUniforms[instanceID].modelMatrix;
#else
    const float4x4 modelViewProjectionMatrix = vertexUniforms.modelViewProjectionMatrix;
#endif

    const float4 position = v.position;
    SkyVertexData out;
    out.position = modelViewProjectionMatrix * position;
    out.uv = float3(position.xy, -position.z);
    return out;
}

fragment float4 skyboxFragment(SkyVertexData in [[stage_in]],
                               constant SkyboxUniforms &uniforms [[buffer(FragmentBufferMaterialUniforms)]],
                               texturecube<half> cubeTex [[texture(FragmentTextureCustom0)]],
                               sampler cubeTexSampler [[sampler(FragmentSamplerCustom0)]]) {
    return uniforms.color * float4(cubeTex.sample(cubeTexSampler, in.uv));
}
