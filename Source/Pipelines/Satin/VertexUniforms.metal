typedef struct {
    matrix_float4x4 modelMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 modelViewMatrix;
    matrix_float4x4 projectionMatrix;
    matrix_float3x3 normalMatrix;
    float3 worldCameraPosition;
    float3 worldCameraViewDirection;
} VertexUniforms;
