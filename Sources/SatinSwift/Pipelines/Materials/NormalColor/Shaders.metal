fragment float4 normalColorFragment(VertexData in [[stage_in]],
                                    constant NormalColorUniforms &uniforms
                                    [[buffer(FragmentBufferMaterialUniforms)]]) {
    return float4(uniforms.absolute ? abs(in.normal) : in.normal, 1.0);
}
