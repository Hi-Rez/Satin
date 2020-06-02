typedef struct {
    float4 position [[position]];
    float3 eye;
    float3 normal;
    float2 uv;
    float pointSize [[point_size]];
} MatCapVertexData;

vertex MatCapVertexData matCapVertex(Vertex in [[stage_in]],
                                     constant VertexUniforms &vertexUniforms
                                     [[buffer(VertexBufferVertexUniforms)]]) {
    const float4 screenSpaceNormal = vertexUniforms.modelViewMatrix * float4(in.normal, 0.0);
    const float4 worldPosition = vertexUniforms.modelViewMatrix * in.position;
    const float3 eye = normalize(worldPosition.xyz);
    MatCapVertexData out { .position = vertexUniforms.projectionMatrix * worldPosition,
                           .eye = eye,
                           .normal = normalize(screenSpaceNormal.xyz),
                           .uv = in.uv };
    return out;
}

fragment float4 matCapFragment(MatCapVertexData in [[stage_in]],
                               constant MatCapUniforms &uniforms
                               [[buffer(FragmentBufferMaterialUniforms)]],
                               texture2d<float> tex [[texture(FragmentTextureCustom0)]],
                               sampler texSampler [[sampler(FragmentSamplerCustom0)]]) {
    const float3 r = reflect(in.eye, in.normal);
    const float m = 2.0 * sqrt(pow(r.x, 2.0) + pow(r.y, 2.0) + pow(r.z + 1.0, 2.0));
    const float2 uv = r.xy / m + 0.5;
    return uniforms.color * tex.sample(texSampler, uv);
}
