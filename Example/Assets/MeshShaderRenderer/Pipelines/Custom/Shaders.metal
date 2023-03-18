#include "Library/Rotate.metal"
#include "Library/Noise4D.metal"

// Lets draw a box
#define kVertexCount 8
#define kPrimitiveCount 6 * 2
#define kIndexCount kPrimitiveCount * 3

typedef struct {
    float size; //slider,0,1,0.025
    float height; //slider,0,1,0.125
    float time;
} CustomUniforms;

struct VertexIn {
    float3 position;
    float3 normal;
};

struct Payload {
    VertexIn vertices[kVertexCount];
    uint32_t indices[kIndexCount];
};

// Per-vertex primitive data.
struct PrimOut {
    float3 color;
};

struct FragmentIn {
    VertexData vert;
    PrimOut prim;
};

using TriangleMeshType = metal::mesh<
    VertexData,
    PrimOut,
    kVertexCount, /*vertices*/
    kIndexCount, /*faces*/
    metal::topology::triangle
>;

[[object, max_total_threads_per_threadgroup( 5 ), max_total_threadgroups_per_mesh_grid( kIndexCount )]]
void customObject
(
    object_data Payload &payload [[payload]],
    mesh_grid_properties mgp,

    uint3 gid [[threadgroup_position_in_grid]],
    uint lane [[thread_index_in_threadgroup]],

    constant Vertex *vertices [[buffer( ObjectBufferVertices )]],
    constant uint32_t *indices [[buffer( ObjectBufferIndicies )]],
    constant VertexUniforms &vertexUniforms [[buffer( ObjectBufferVertexUniforms )]],
    constant CustomUniforms &uniforms [[buffer( ObjectBufferMaterialUniforms )]]
)
{
    const float time = uniforms.time;
    const float size = 0.5 * uniforms.size;
    float height = uniforms.height;

    const uint gridOffset = gid.z * (32 * 32) + gid.y * 32 + gid.x;
    // Calculate center of the face
    const uint i = gridOffset * 3;
    const uint i0 = indices[i + 0];
    const uint i1 = indices[i + 1];
    const uint i2 = indices[i + 2];

    float3 center = (vertices[i0].position.xyz + vertices[i1].position.xyz + vertices[i2].position.xyz)/3.0;
    const float3 normal = normalize(center);
    const float3x3 rotation = rotateAlign(normal, float3(0.0, 1.0, 0.0));

    height += height * snoise(float4(normal, time));

    payload.vertices[0] = ( VertexIn ) {
        .position = center + rotation * float3(-size, 0.0, size),
        .normal = normal
//        .normal = normalize(float3(-1.0, -1.0, 1.0))
    };

    payload.vertices[1] = ( VertexIn ) {
        .position = center + rotation * float3(size, 0.0, size),
        .normal = normal
//        .normal = normalize(float3(1.0, -1.0, 1.0))
    };

    payload.vertices[2] = ( VertexIn ) {
        .position = center + rotation * float3(size, height, size),
        .normal = normal
//        .normal = normalize(float3(1.0, 1.0, 1.0))
    };

    payload.vertices[3] = ( VertexIn ) {
        .position = center + rotation * float3(-size, height, size),
        .normal = normal
//        .normal = normalize(float3(-1.0, 1.0, 1.0))
    };

    payload.vertices[4] = ( VertexIn ) {
        .position = center + rotation * float3(-size, 0.0, -size),
        .normal = normal
//        .normal = normalize(float3(-1.0, -1.0, -1.0))
    };

    payload.vertices[5] = ( VertexIn ) {
        .position = center + rotation * float3(size, 0.0, -size),
        .normal = normal
//        .normal = normalize(float3(1.0, -1.0, -1.0))
    };

    payload.vertices[6] = ( VertexIn ) {
        .position = center + rotation * float3(size, height, -size),
        .normal = normal
//        .normal = normalize(float3(1.0, 1.0, -1.0))
    };

    payload.vertices[7] = ( VertexIn ){
        .position = center + rotation * float3(-size, height, -size),
        .normal = normal
//        .normal = normalize(float3(-1.0, 1.0, -1.0))
    };

    uint index = 0;

    // Front Face
    payload.indices[index++] = 0;
    payload.indices[index++] = 1;
    payload.indices[index++] = 2;
    payload.indices[index++] = 0;
    payload.indices[index++] = 2;
    payload.indices[index++] = 3;

    // Back Face
    payload.indices[index++] = 5;
    payload.indices[index++] = 4;
    payload.indices[index++] = 6;
    payload.indices[index++] = 4;
    payload.indices[index++] = 7;
    payload.indices[index++] = 6;

    // Right Face
    payload.indices[index++] = 1;
    payload.indices[index++] = 5;
    payload.indices[index++] = 6;
    payload.indices[index++] = 1;
    payload.indices[index++] = 6;
    payload.indices[index++] = 2;

    // Left Face
    payload.indices[index++] = 4;
    payload.indices[index++] = 0;
    payload.indices[index++] = 3;
    payload.indices[index++] = 4;
    payload.indices[index++] = 3;
    payload.indices[index++] = 7;

    // Top Face
    payload.indices[index++] = 3;
    payload.indices[index++] = 2;
    payload.indices[index++] = 6;
    payload.indices[index++] = 3;
    payload.indices[index++] = 6;
    payload.indices[index++] = 7;

    // Bottom Face
    payload.indices[index++] = 1;
    payload.indices[index++] = 0;
    payload.indices[index++] = 4;
    payload.indices[index++] = 1;
    payload.indices[index++] = 4;
    payload.indices[index++] = 5;

    if( lane == 0 ) {
        mgp.set_threadgroups_per_grid( uint3( 1, 1, 1 ) );
    }
}

/// The mesh stage function that generates a triangle mesh.
[[mesh, max_total_threads_per_threadgroup( kIndexCount )]]
void customMesh
(
    TriangleMeshType output,
    const object_data Payload &payload [[payload]],
    uint lane [[thread_index_in_threadgroup]],
    uint gid [[threadgroup_position_in_grid]],
    constant CustomUniforms &uniforms [[buffer( MeshBufferMaterialUniforms )]],
    constant VertexUniforms &vertexUniforms [[buffer( ObjectBufferVertexUniforms )]]
)
{
    if( lane < kVertexCount ) {
        const VertexIn in = payload.vertices[lane];
        VertexData v {
            .position = vertexUniforms.modelViewProjectionMatrix * float4(in.position, 1.0),
            .normal = vertexUniforms.normalMatrix * in.normal,
            .uv = 0.0
        };

        output.set_vertex( lane, v );
    }

    if( lane < kIndexCount ) {
        output.set_index( lane, payload.indices[lane] );
    }

    if( lane < kPrimitiveCount ) {


        PrimOut p { .color = float3(lane)/float(kPrimitiveCount) };
        output.set_primitive( lane, p );
    }

    // Set the number of primitives for the entire mesh.
    if( lane == 0 ) {
        output.set_primitive_count( kPrimitiveCount );
    }
}

fragment float4 customFragment
(
    FragmentIn in [[stage_in]]
)
{
//    float3 color = normalize(in.vert.normal);
//    color += 1.0;
//    color *= 0.5;
    return float4( in.prim.color, 1.0 );
}
