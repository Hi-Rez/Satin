/*
Basic FXAA implementation based on the code on
https://www.geeks3d.com/20110405/fxaa-fast-approximate-anti-aliasing-demo-glsl-opengl-test-radeon-geforce/3/
Modifications made to work with Metal @Rezaali
*/

typedef struct {
    float2 inverseResolution;
} FxaaUniforms;

#define FXAA_SPAN_MAX 8.0
#define FXAA_REDUCE_MUL 1.0/8.0
#define FXAA_REDUCE_MIN 1.0/128.0

typedef struct {
    float4 position [[position]];
    float2 uv;
} CustomVertexData;

vertex CustomVertexData fxaaVertex( Vertex in [[stage_in]],
                              constant VertexUniforms &vertexUniforms [[buffer(VertexBufferVertexUniforms)]]) {
    CustomVertexData out;
    out.position = vertexUniforms.modelViewProjectionMatrix * in.position;
    out.uv = in.uv;
    return out;
}

fragment float4 fxaaFragment( CustomVertexData in [[stage_in]],
    constant FxaaUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]],
    texture2d<float> renderTex [[texture( FragmentTextureCustom0 )]] )
{
    const float2 uv = in.uv;
    constexpr sampler s = sampler( min_filter::linear, mag_filter::linear );

    const float2 rcpRes = uniforms.inverseResolution;

    const float3 rgbNW = renderTex.sample(s, uv, int2(-1,-1)).xyz;
    const float3 rgbNE = renderTex.sample(s, uv, int2(1,-1)).xyz;
    const float3 rgbSW = renderTex.sample(s, uv, int2(-1,1)).xyz;
    const float3 rgbSE = renderTex.sample(s, uv, int2(-1,-1)).xyz;
    const float3 rgbM  = renderTex.sample(s, uv).xyz;

    const float3 luma = float3(0.299, 0.587, 0.114);
    const float lumaNW = dot(rgbNW, luma);
    const float lumaNE = dot(rgbNE, luma);
    const float lumaSW = dot(rgbSW, luma);
    const float lumaSE = dot(rgbSE, luma);
    const float lumaM  = dot(rgbM,  luma);

    const float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
    const float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

    float2 dir;
    dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
    dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));

    const float dirReduce = max(
        (lumaNW + lumaNE + lumaSW + lumaSE) * (0.25 * FXAA_REDUCE_MUL),
        FXAA_REDUCE_MIN);

    const float rcpDirMin = 1.0/(min(abs(dir.x), abs(dir.y)) + dirReduce);

    dir = min(float2( FXAA_SPAN_MAX,  FXAA_SPAN_MAX),
          max(float2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX),
          dir * rcpDirMin)) * rcpRes.xy;

    const float3 rgbA = 0.5 * (
        renderTex.sample(s, uv + dir * (1.0/3.0 - 0.5)).xyz +
        renderTex.sample(s, uv + dir * (2.0/3.0 - 0.5)).xyz);

    const float3 rgbB = rgbA * 0.5 + 0.25 * (
        renderTex.sample(s, uv + dir * -0.5).xyz +
        renderTex.sample(s, uv + dir * 0.5).xyz);

    const float lumaB = dot(rgbB, luma);

    if((lumaB < lumaMin) || (lumaB > lumaMax)) {
        return float4(rgbA, 1.0);
    }

    return float4(rgbB, 1.0);
}
