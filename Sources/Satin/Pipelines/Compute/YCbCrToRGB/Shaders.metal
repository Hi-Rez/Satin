typedef struct {
    bool srgb; //toggle,false
} YCbCrToRGBUniforms;

kernel void ycbcrToRgbUpdate
(
    uint2 gid [[thread_position_in_grid]],
    constant YCbCrToRGBUniforms &uniforms [[buffer(ComputeBufferUniforms)]],
    texture2d<float, access::write> rgbaTex [[texture(ComputeTextureCustom0)]],
    texture2d<float, access::read> yTex [[texture(ComputeTextureCustom1)]],
    texture2d<float, access::read> cbcrTex [[texture(ComputeTextureCustom2)]]
)
{
    const float4x4 ycbcrToRGBTransform = float4x4
    (
        float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
        float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
        float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
        float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
    );

    float4 color = ycbcrToRGBTransform * float4(yTex.read(gid).r, cbcrTex.read(gid).rg, 1.0);
    color.rgb = mix(color.rgb, pow(color.rgb, 2.2), float(uniforms.srgb));
    rgbaTex.write(color, gid);
}
