// Inspired by Warren Moore: https://metalbyexample.com/tessellation/

#include "Library/Colors.metal"
#include "Library/Gamma.metal"
#include "Library/Shapes.metal"

typedef struct {
    float4 color;       // color
    float amplitude;    // slider,-1,1,0
} TessellatedUniforms;

struct PatchIn {
    patch_control_point<Vertex> controlPoints;
};


/// Calculate a value by bilinearly interpolating among four control points.
/// The four values c00, c01, c10, and c11 represent, respectively, the
/// upper-left, upper-right, lower-left, and lower-right points of a quad
/// that is parameterized by a normalized space that runs from (0, 0)
/// in the upper left to (1, 1) in the lower right (similar to Metal's texture
/// space). The vector `uv` contains the influence of the points along the
/// x and y axes.
template <typename T>
T bilerp(T c00, T c01, T c10, T c11, float2 uv) {
    T c0 = mix(c00, c01, T(uv[0]));
    T c1 = mix(c10, c11, T(uv[0]));
    return mix(c0, c1, T(uv[1]));
}

//[[patch(quad, 4)]]
//vertex VertexData tessellatedVertex
//(
//    PatchIn patch [[stage_in]],
//    float2 positionInPatch [[position_in_patch]],
//    constant VertexUniforms &vertexUniforms [[buffer(VertexBufferVertexUniforms)]],
//    constant TessellatedUniforms &uniforms [[buffer(VertexBufferMaterialUniforms)]]
//)
//{
//    Vertex p00 = patch.controlPoints[0];
//    Vertex p01 = patch.controlPoints[1];
//    Vertex p10 = patch.controlPoints[3];
//    Vertex p11 = patch.controlPoints[2];
//
//    float4 position = bilerp(p00.position, p01.position, p10.position, p11.position, positionInPatch);
//    float3 normal = bilerp(p00.normal, p01.normal, p10.normal, p11.normal, positionInPatch);
//    float2 uv = bilerp(p00.uv, p01.uv, p10.uv, p11.uv, positionInPatch);
//
//    VertexData out;
//    out.position = vertexUniforms.modelViewProjectionMatrix * position;
//    out.normal = vertexUniforms.normalMatrix * normal;
//    out.uv = uv;
//
//    return out;
//}

typedef struct {
    float4 position [[position]];
    float3 normal;
    float2 uv;
    uint patch;
    float len;
} CustomVertexData;

/// Calculate a value by interpolating among three control points. The
/// vector `bary` contains barycentric weights that sum to 1 and determine
/// the contribution of each control point value to the output value.
template <typename T>
T baryinterp(T c0, T c1, T c2, float3 bary) {
    return c0 * bary[0] + c1 * bary[1] + c2 * bary[2];
}

[[patch(triangle, 3)]]
vertex CustomVertexData tessellatedVertex
(
    PatchIn patch [[stage_in]],
    uint patch_id [[patch_id]],
    float3 positionInPatch [[position_in_patch]],
    constant VertexUniforms &vertexUniforms [[buffer(VertexBufferVertexUniforms)]],
    constant TessellatedUniforms &uniforms [[buffer(VertexBufferMaterialUniforms)]]
)
{
    Vertex p00 = patch.controlPoints[0];
    Vertex p01 = patch.controlPoints[1];
    Vertex p10 = patch.controlPoints[2];


    float4 position = baryinterp(p00.position, p01.position, p10.position, positionInPatch);
    float3 normal = baryinterp(p00.normal, p01.normal, p10.normal, positionInPatch);
    float2 uv = baryinterp(p00.uv, p01.uv, p10.uv, positionInPatch);

    const float sdfx = Line(positionInPatch, float3(1.0, 0.0, 0.0), float3(0.0, 0.0, 0.0));
    const float sdfy = Line(positionInPatch, float3(0.0, 1.0, 0.0), float3(0.0, 0.0, 0.0));
    const float sdfz = Line(positionInPatch, float3(0.0, 0.0, 1.0), float3(0.0, 0.0, 0.0));
    const float len = 1.0 - (sdfx + sdfy + sdfz);
    position.xyz += uniforms.amplitude * pow(len, 2.0) * normal;

    CustomVertexData out;
    out.position = vertexUniforms.modelViewProjectionMatrix * position;
    out.normal = vertexUniforms.normalMatrix * normal;
    out.uv = uv;
    out.patch = patch_id;
    out.len = 1.0 - pow(len, 2.0);

    return out;
}

fragment float4 tessellatedFragment
(
    CustomVertexData in [[stage_in]],
    constant TessellatedUniforms &uniforms [[buffer(FragmentBufferMaterialUniforms)]]
)
{
    float3 color = turbo(fract(in.patch/100.0));
    color = mix(color * in.len, color/(in.len+0.25), (uniforms.amplitude + 0.5));
    return uniforms.color * float4(color, 1.0);
}
