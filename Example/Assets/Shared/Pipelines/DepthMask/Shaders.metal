kernel void depthMaskUpdate
(
    uint2 gid [[thread_position_in_grid]],
    texture2d<float, access::write> depthMaskTexture [[texture(ComputeTextureCustom0)]],
    depth2d<float, access::read> realDepthTexture [[texture(ComputeTextureCustom1)]],
    depth2d<float, access::read> virtualDepthTexture [[texture(ComputeTextureCustom2)]]
)
{
    const float realDepth = realDepthTexture.read(gid);
    const float virtualDepth = virtualDepthTexture.read(gid);
    depthMaskTexture.write(step(realDepth, virtualDepth), gid);
}
