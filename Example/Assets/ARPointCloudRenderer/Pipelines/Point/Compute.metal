#include "Types.metal"

typedef struct {
    float4x4 localToWorld;
    float3x3 intrinsicsInversed;
    float2 resolution;
    int count; //input
} PointUniforms;


static float4 worldPosition
(
    float2 cameraPoint,
    float depth,
    float4x4 localToWorld,
    float3x3 intrinsicsInversed
)
{
    const auto localPoint = intrinsicsInversed * float3( cameraPoint, 1.0 ) * depth;
    const auto worldPoint = localToWorld * float4(localPoint, 1.0);
    return worldPoint / worldPoint.w;
}

float4 getWorldPosition
(
    uint id,
    texture2d<float, access::read> depthTexture,
    float4x4 localToWorld,
    float3x3 intrinsicsInversed,
    float2 resolution
)
{
    const uint imageWidth = depthTexture.get_width();
    const uint imageHeight = depthTexture.get_height();

    const uint2 gid = uint2( id % imageWidth, id / imageWidth );
    const float2 uv = float2( float2(gid - 1) / float2( imageWidth, imageHeight ) );

    const float depth = depthTexture.read( gid ).r;

    float4 pos = worldPosition
    (
        uv * resolution,
        depth,
        localToWorld,
        intrinsicsInversed
    );

    return float4( pos.xyz, depth );
}

kernel void pointUpdate
(
    uint index [[thread_position_in_grid]],
    device Point *outBuffer [[buffer( ComputeBufferCustom0 )]],
    const device PointUniforms &uniforms [[ buffer( ComputeBufferUniforms ) ]],
    texture2d<float, access::read> depthTex [[ texture( ComputeTextureCustom0 ) ]]
)
{
    const float4 position = getWorldPosition
    (
        index,
        depthTex,
        uniforms.localToWorld,
        uniforms.intrinsicsInversed,
        uniforms.resolution
     );

    outBuffer[index] = (Point) {
        .position = position
    };
}
