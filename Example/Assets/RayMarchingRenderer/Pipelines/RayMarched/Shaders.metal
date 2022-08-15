#include "../Library/Pi.metal"
#include "../Library/Gamma.metal"
#include "../Library/Dither.metal"
#include "../Library/Shapes.metal"
#include "../Library/Csg.metal"

#define MAX_STEPS 64
#define MIN_DIST 0.0
#define MAX_DIST 100.0
#define SURF_DIST 0.0001
#define EPSILON 0.001

typedef struct {
    float4 color; // color
} RayMarchedUniforms;

typedef struct {
    float4 position [[position]];
    float4 far;
    float3 cameraPosition [[flat]];
    float2 cameraDepth [[flat]];
} RayMarchedData;

struct FragOut {
    float4 color [[color( 0 )]];
    float depth [[depth( any )]];
};

float scene( float3 p )
{
    const float lw = 0.02;
    float line = Line( abs( p ), 1.0, float3( 1.0, 1.0, -1.0 ) ) - lw;
    line = unionHard( line, Line( abs( p ), 1.0, float3( 1.0, -1.0, 1.0 ) ) - lw );
    line = unionHard( line, Line( abs( p ), 1.0, float3( -1.0, 1.0, 1.0 ) ) - lw );
    return line;
}

float3 getNormal( float3 p )
{
    const float d = scene( p );
    const float3 e = float3( EPSILON, 0.0, 0.0 );
    const float3 gradient = d - float3( scene( p - e.xyy ), scene( p - e.yxy ), scene( p - e.yyx ) );
    return normalize( gradient );
}

float render( float3 ro, float3 rd )
{
    float d = 0.0;
    for( int i = 0; i < MAX_STEPS; i++ ) {
        const float3 p = ro + rd * d;
        const float dist = scene( p );
        d += dist;
        if( dist > MAX_DIST || abs( dist ) < SURF_DIST ) {
            break;
        }
    }
    return d;
}


vertex RayMarchedData rayMarchedVertex( Vertex in [[stage_in]],
    constant VertexUniforms &uniforms [[buffer( VertexBufferVertexUniforms )]] )
{
    const float4x4 projectionMatrix = uniforms.projectionMatrix;
    const float4x4 inverseViewMatrix = uniforms.inverseViewMatrix;
    const float4x4 inverseModelViewProjectionMatrix = uniforms.inverseModelViewProjectionMatrix;

    // See https://www.iquilezles.org/www/articles/raypolys/raypolys.htm

    const float c = projectionMatrix[2].z;
    const float d = projectionMatrix[3].z;
    const float near = d / c;
    const float far = d / (1.0 + c);

    const float cameraDelta = far - near;
    const float cameraA = far / cameraDelta;
    const float cameraB = (far * near) / cameraDelta;

    RayMarchedData out;
    out.position = in.position;
    auto pos = out.position.xy / out.position.w;
    out.far = inverseModelViewProjectionMatrix * float4(pos, +1.0, 1.0);
    out.cameraDepth = float2(cameraA, cameraB);
    out.cameraPosition = inverseViewMatrix[3].xyz;

    return out;
}

fragment FragOut rayMarchedFragment( RayMarchedData in [[stage_in]],
    constant RayMarchedUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]],
    constant float4x4 *view [[buffer( FragmentBufferCustom0 )]] )
{
    const float3 ro = in.cameraPosition;
    const float3 rd = normalize( in.far.xyz / in.far.w - ro );

    const float d = render( ro, rd );
    const float3 p = ro + rd * d;

    if( d >= MAX_DIST ) {
        discard_fragment();
    }

    FragOut out;
    const float2 cameraDepth = in.cameraDepth;
    const float a = cameraDepth.x;
    const float b = cameraDepth.y;

    const float4 ep = ( *view ) * float4( p, 1.0 );
    out.depth = ( a + b / ep.z );

    const float3 color = float3( 1.00000, 0.52941, 0.19216 );
    out.color = float4( color, 1.0 );
    return out;
}
