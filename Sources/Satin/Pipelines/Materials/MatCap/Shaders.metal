typedef struct {
    float4 position [[position]];
    float3 eye;
    float3 normal;
} MatCapVertexData;

typedef struct {
    float4 color; // color
} MatCapUniforms;

vertex MatCapVertexData matCapVertex(Vertex in [[stage_in]],
// inject instancing args
    constant VertexUniforms &vertexUniforms [[buffer(VertexBufferVertexUniforms)]])
{
#if INSTANCING
    const float4x4 modelViewMatrix = vertexUniforms.viewMatrix * instanceUniforms[instanceID].modelMatrix;
#else
    const float4x4 modelViewMatrix = vertexUniforms.modelViewMatrix;
#endif
    
    const float4 screenSpaceNormal = modelViewMatrix * float4(in.normal, 0.0);
    const float4 worldPosition = modelViewMatrix * in.position;
    const float3 eye = normalize(worldPosition.xyz);
    
    MatCapVertexData out;
    out.position = vertexUniforms.projectionMatrix * worldPosition;
    out.eye = eye;
    out.normal = screenSpaceNormal.xyz;
    return out;
}

fragment float4 matCapFragment(MatCapVertexData in [[stage_in]],
                               constant MatCapUniforms &uniforms
                               [[buffer(FragmentBufferMaterialUniforms)]],
                               texture2d<float> tex [[texture(FragmentTextureCustom0)]],
                               sampler texSampler [[sampler(FragmentSamplerCustom0)]]) {
    const float3 r = reflect(in.eye, normalize(in.normal));
    const float m = 2.0 * sqrt(pow(r.x, 2.0) + pow(r.y, 2.0) + pow(r.z + 1.0, 2.0));
    const float2 uv = r.xy / m + 0.5;
    return uniforms.color * tex.sample(texSampler, uv);
}
