typedef struct {
    float4 position [[position]];
    float3 uv;
} SkyVertexData;

vertex SkyVertexData skyboxVertex(uint vertexID [[vertex_id]],
                                  constant Vertex *vertices [[buffer(VertexBufferVertices)]],
                                  constant VertexUniforms &vertexUniforms
                                  [[buffer(VertexBufferVertexUniforms)]]) {
    Vertex v = vertices[vertexID];
    float4 position = v.position;
    SkyVertexData out;
    out.position = vertexUniforms.projectionMatrix * vertexUniforms.modelViewMatrix * position;
    out.uv = float3(position.xy, -position.z);
    return out;
}

fragment float4 skyboxFragment(SkyVertexData in [[stage_in]],
                               texturecube<half> cubeTexture [[texture(FragmentTextureCustom0)]]) {
    constexpr sampler s(min_filter::linear, mag_filter::linear);
    const float4 color = float4(cubeTexture.sample(s, in.uv));
    return color;
}
