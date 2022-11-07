fragment float4 uvColorFragment(VertexData in [[stage_in]])
{
    return float4(in.uv, 0.0, 1.0);
}
