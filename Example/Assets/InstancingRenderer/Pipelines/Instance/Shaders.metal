// You can use any Satin Library file by including it like so
#include "Library/Shapes.metal"

// when you don't specify a UI type, i.e. color, slider, input, toggle, that
// means don't expose the param in the UI... you can still set this parameters
// via material.set("Time", ...), remember to title case the param when setting
// on the CPU side i.e. colorScale os Color Scale, etc

typedef struct {
    float4 aColor; // color,0.2,1,0.5,1
    float4 cColor; // color,0,0.5882352941,1,1
    float4 gColor; // color,1,1,0,1
    float4 tColor; // color,1,0.2,0,1
    float4 backgroundColor;
    float width; //slider,0,100,100
    float height; //slider,0,100,20
    float spacing; //slider,0,10,4.0
    float cornerRadius; //slider,0,1,1.0
    int perRow; //input,80
    float time;
    float3 resolution;
    int instanceCount;
} InstanceUniforms;

typedef struct {
    float4 position [[position]];
    float4 color;
    float2 uv;
} CustomVertexData;

vertex CustomVertexData instanceVertex(
    Vertex in [[stage_in]],
    uint instanceID [[instance_id]],
    constant VertexUniforms &vertexUniforms [[buffer( VertexBufferVertexUniforms )]],
    constant InstanceUniforms &uniforms [[buffer( VertexBufferMaterialUniforms )]],
    constant bool2 *sequence [[buffer( VertexBufferCustom0 )]] )
{
    const float fid = float( instanceID );
    const float4 colors[4] = {
        uniforms.aColor,
        uniforms.cColor,
        uniforms.gColor,
        uniforms.tColor
    };

    const float2 uv = in.uv;

    const int xLimit = uniforms.perRow;
    const int yLimit = uniforms.instanceCount / xLimit;
    const float y = floor( fid / xLimit );
    const float x = instanceID % xLimit;

    const float w = uniforms.width;
    const float h = uniforms.height;
    const float s = uniforms.spacing;

    const float hw = 0.5 * w;
    const float hh = 0.5 * h;

    const float xOffset = ( ( xLimit - 1.0 ) * 0.5 ) * ( w + s );
    const float yOffset = ( yLimit * 0.5 ) * ( h + s );
    float4 position = in.position;

    position.xy *= 0.0;
    position.xy += float2( x * ( w + s ) - xOffset, -y * ( h + s ) + yOffset );

    position.x += mix( -hw, hw, uv.x );
    position.y += mix( hh, -hh, uv.y );

    bool2 data = sequence[instanceID];
    const int colorIndex = data[1] * 2 + data[0];

    CustomVertexData out;
    out.position = vertexUniforms.modelViewProjectionMatrix * position;
    out.color = colors[colorIndex];
    out.uv = in.uv;
    return out;
}

fragment float4 instanceFragment( CustomVertexData in [[stage_in]],
    constant InstanceUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]] )
{
    float aspect = uniforms.width / uniforms.height;
    float2 uv = 2.0 * in.uv - 1.0;
    uv.x *= aspect;
    const float cr = max( min( uniforms.cornerRadius, aspect ), 0.025 );
    const float softness = 0.025;
    float sdf = RoundedRect( uv, float2( aspect - cr, 1.0 - cr ), cr ) + softness;
    sdf = 1.0 - saturate( smoothstep( 0.0, softness + fwidth( sdf ), sdf ) );
    return mix( uniforms.backgroundColor, in.color, sdf );
}
