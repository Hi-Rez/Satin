#include "Satin/Includes.metal"


kernel void updateCompute(
                          uint2 gid [[thread_position_in_grid]],
    texture2d<float, access::write> tex [[texture( 0 )]] )
{
    
    if(gid.x >= tex.get_width() || gid.y >= tex.get_height()) {
        return;
    }
    const float2 size = float2( tex.get_width(), tex.get_height()) - 1.0;
    const float2 uv = float2( gid ) / size;
    tex.write( float4( 1.0, uv.x, uv.y, 1.0 ), gid );
}
