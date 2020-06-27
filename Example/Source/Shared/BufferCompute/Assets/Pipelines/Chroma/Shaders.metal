// Barrel Blur Chroma: https://www.shadertoy.com/view/XssGz8
#include "Library/Colors.metal"

float2 remap( float2 t, float2 a, float2 b )
{
    return clamp( ( t - a ) / ( b - a ), 0.0, 1.0 );
}

// note: from https://www.shadertoy.com/view/XslGz8
float2 radialdistort( float2 coord, float2 amt )
{
    float2 cc = coord - 0.5;
    return coord + 2.0 * cc * amt;
}

// Given a float2 in [-1,+1], generate a texture coord in [0,+1]
float2 barrelDistortion( float2 p, float2 amt )
{
    p = 2.0 * p - 1.0;
    float maxBarrelPower = sqrt( 5.0 );
    float radius = dot( p, p ); // faster but doesn't match above accurately
    p *= pow( float2( radius ), maxBarrelPower * amt );
    return p * 0.5 + 0.5;
}

// note: from https://www.shadertoy.com/view/MlSXR3
float2 brownConradyDistortion( float2 uv, float dist )
{
    uv = uv * 2.0 - 1.0;
    // positive values of K1 give barrel distortion, negative give pincushion
    float barrelDistortion1 = 0.1 * dist; // K1 in text books
    float barrelDistortion2 = -0.025 * dist; // K2 in text books

    float r2 = dot( uv, uv );
    uv *= 1.0 + barrelDistortion1 * r2 + barrelDistortion2 * r2 * r2;
    return uv * 0.5 + 0.5;
}

float2 distort( float2 uv, float t, float2 min_distort, float2 max_distort )
{
    float2 dist = mix( min_distort, max_distort, t );
    // return radialdistort( uv, 2.0 * dist );
    // return barrelDistortion( uv, 1.75 * dist ); //distortion at center
    return brownConradyDistortion( uv, 75.0 * dist.x );
}

typedef struct {
    float time;
} ChromaUniforms;

fragment float4 chromaFragment( VertexData in [[stage_in]],
    constant ChromaUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]],
    texture2d<float> renderTex [[texture( FragmentTextureCustom0 )]] )
{
    float2 uv = in.uv;
    constexpr sampler s = sampler( min_filter::linear, mag_filter::linear );

    float2 max_distort = 0.05;
    float2 min_distort = 0.5 * max_distort;

    float2 oversiz = distort( float2( 1.0 ), 1.0, min_distort, max_distort );
    uv = remap( uv, 1.0 - oversiz, oversiz );
    const int num_iter = 7;
    const float stepsiz = 1.0 / ( float( num_iter ) - 1.0 );
    float rnd = fract( 1.61803398875 * uniforms.time );
    float t = rnd * stepsiz;

    float3 sumcol = float3( 0.0 );
    float3 sumw = float3( 0.0 );
    for( int i = 0; i < num_iter; ++i ) {
        float3 w = spectrum( t );
        sumw += w;
        const float2 uvd = distort( uv, t, min_distort, max_distort ); // TODO: move out of loop
        sumcol += w * renderTex.sample( s, uvd ).rgb;
        t += stepsiz;
    }
    sumcol.rgb /= sumw;
    return float4( sumcol, 1.0 );
}
