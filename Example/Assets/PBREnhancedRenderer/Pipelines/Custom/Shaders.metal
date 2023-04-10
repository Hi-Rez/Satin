#include "Library/Pbr/Pbr.metal"

typedef struct {
#include "Chunks/PbrUniforms.metal"
} CustomUniforms;

typedef struct {
    float4 position [[position]];
    float3 normal;
    float2 texcoords;
    float3 worldPosition;
    float3 cameraPosition;
#if defined(HAS_TRANSMISSION)
    float3 thickness;
#endif
    float3 xyz;
} CustomVertexData;


vertex CustomVertexData customVertex(
    Vertex in [[stage_in]],
    // inject instancing args
    constant VertexUniforms &vertexUniforms [[buffer(VertexBufferVertexUniforms)]],
    constant CustomUniforms &uniforms [[buffer(FragmentBufferMaterialUniforms)]])
{
    float3 xyz = 0.0;
#if defined(INSTANCING)
    const float3x3 normalMatrix = instanceUniforms[instanceID].normalMatrix;
    const float4x4 modelMatrix = instanceUniforms[instanceID].modelMatrix;
    int x = instanceID % 11;
    xyz.x = float(x);
    xyz.y = float(instanceID / 11);
    xyz.z = xyz.x / 10.0;
#else
    const float3x3 normalMatrix = vertexUniforms.normalMatrix;
    const float4x4 modelMatrix = vertexUniforms.modelMatrix;
#endif

    CustomVertexData out;
    out.position = vertexUniforms.viewProjectionMatrix * modelMatrix * in.position;
    out.texcoords = in.uv;
    out.normal = normalMatrix * in.normal;
    out.worldPosition = (modelMatrix * in.position).xyz;
    out.cameraPosition = vertexUniforms.worldCameraPosition.xyz;
    out.xyz = xyz;
#if defined(HAS_TRANSMISSION)
    float3 modelScale;
    modelScale.x = length(modelMatrix[0].xyz);
    modelScale.y = length(modelMatrix[1].xyz);
    modelScale.z = length(modelMatrix[2].xyz);
    out.thickness = uniforms.thickness * modelScale;
#endif
    return out;
}

void getTangentAndBitangent(float3 forward, float3 p, float2 uv, thread float3 &T, thread float3 &B)
{
    // get edge vectors of the pixel triangle
    float3 right = dfdx(p);
    float3 up = dfdy(p);

    float2 duv1 = dfdx(uv);
    float2 duv2 = dfdy(uv);

    // solve the linear system
    float3 rightPerp = cross(up, forward); // right = up cross forward
    float3 upPerp = cross(forward, right); // up = forward cross right
    T = rightPerp * length(duv1);
    B = upPerp * length(duv2);

    // construct a scale-invariant frame
    float invmax = rsqrt(max(dot(T, T), dot(B, B)));
    T = normalize(invmax * T);
    B = normalize(invmax * B);

    T = cross(B, forward);
    B = cross(forward, T);
}

fragment float4 customFragment
(
    CustomVertexData in [[stage_in]],
    // inject lighting args
#include "Chunks/PbrTextures.metal"
    constant CustomUniforms &uniforms [[buffer(FragmentBufferMaterialUniforms)]]
)
{
#include "Chunks/PixelInfo.metal"
#include "Chunks/PixelInfoInitView.metal"
#include "Chunks/PixelInfoInitPosition.metal"

#if 0
    pixel.normal = normalize(in.normal);
    pixel.tangent = normalize(in.tangent);
    pixel.bitangent = normalize(in.bitangent);

#else
    float3 tangent, bitangent, normal = normalize(in.normal);

    getTangentAndBitangent(normal, -pixel.view, in.texcoords, tangent, bitangent);

    pixel.normal = normal;
    pixel.tangent = tangent;
    pixel.bitangent = bitangent;
#endif
    
    Material material;
    material.baseColor = uniforms.baseColor.rgb;
    material.emissiveColor = uniforms.emissiveColor.rgb * uniforms.emissiveColor.a;
    material.subsurface = uniforms.subsurface;
    material.ambientOcclusion = 1.0;
    material.metallic = uniforms.metallic;
    material.roughness = uniforms.roughness;
    material.specular = uniforms.specular;
    material.specularTint = uniforms.specularTint;
    material.anisotropic = uniforms.anisotropic;
    material.alpha = uniforms.baseColor.a;
    material.clearcoat = uniforms.clearcoat;
    material.clearcoatRoughness = uniforms.clearcoatRoughness;
    material.sheen = uniforms.sheen;
    material.sheenTint = uniforms.sheenTint;
    material.transmission = uniforms.transmission;
    material.thickness = in.thickness;
    material.ior = uniforms.ior;
    material.environmentIntensity = uniforms.environmentIntensity;
    material.gammaCorrection = uniforms.gammaCorrection; 

    int row = int(in.xyz.y);
    float value = in.xyz.z;

    if (row == 11) { // Subsurface
        material.baseColor = float3(1.0, 1.0, 1.0);
        material.subsurface = value;
        material.metallic = 0.0;
        material.roughness = 0.25;
        material.specular = 0.0;
        material.specularTint = 0.0;
        material.anisotropic = 0.0;
        material.clearcoat = 0.0;
        material.clearcoatRoughness = 0.0;
        material.sheen = 0.0;
        material.sheenTint = 0.0;
        material.transmission = 0.0;
        material.ior = 1.5;
    } else if (row == 10) { // Metallic
        material.baseColor = float3(1.0, 1.0, 1.0);
        material.subsurface = 0.0;
        material.metallic = value;
        material.roughness = 0.0;
        material.specular = 0.0;
        material.specularTint = 0.0;
        material.anisotropic = 0.0;
        material.clearcoat = 0.0;
        material.clearcoatRoughness = 0.0;
        material.sheen = 0.0;
        material.sheenTint = 0.0;
        material.transmission = 0.0;
        material.ior = 1.5;
    } else if (row == 9) { // Metallic & Roughness
        material.baseColor = float3(0.5);
        material.subsurface = 0.0;
        material.metallic = 1.0;
        material.roughness = value;
        material.specular = 0.5;
        material.specularTint = 0.0;
        material.anisotropic = 0.0;
        material.clearcoat = 0.0;
        material.clearcoatRoughness = 0.0;
        material.sheen = 0.0;
        material.sheenTint = 0.0;
        material.transmission = 0.0;
        material.ior = 1.5;
    } else if (row == 8) { // Specular
        material.baseColor = float3(1.0, 0.0, 0.0);
        material.subsurface = 0.0;
        material.metallic = 0.0;
        material.roughness = 0.0;
        material.specular = value;
        material.specularTint = 0.0;
        material.anisotropic = 0.0;
        material.clearcoat = 0.0;
        material.clearcoatRoughness = 0.0;
        material.sheen = 0.0;
        material.sheenTint = 0.0;
        material.transmission = 0.0;
        material.ior = 1.5;
    } else if (row == 7) { // Specular Tint
        material.baseColor = float3(1.0, 0.0, 0.0);
        material.subsurface = 0.0;
        material.metallic = 0.0;
        material.roughness = 0.0;
        material.specular = 1.0;
        material.specularTint = value;
        material.anisotropic = 0.0;
        material.clearcoat = 0.0;
        material.clearcoatRoughness = 0.0;
        material.sheen = 0.0;
        material.sheenTint = 0.0;
        material.transmission = 0.0;
        material.ior = 1.5;
    } else if (row == 6) { // Anisotropic
        material.baseColor = float3(1.0, 1.0, 1.0);
        material.subsurface = 0.0;
        material.metallic = 1.0;
        material.roughness = 0.25;
        material.specular = 0.5;
        material.specularTint = 0.0;
        material.anisotropic = 1.5 * value - 0.75;
        material.clearcoat = 0.0;
        material.clearcoatRoughness = 0.0;
        material.sheen = 0.0;
        material.sheenTint = 0.0;
        material.transmission = 0.0;
        material.ior = 1.5;
    } else if (row == 5) { // Sheen
        material.baseColor = float3(0.25, 0.0, 0.20);
        material.subsurface = 0.0;
        material.ambientOcclusion = 1.0;
        material.metallic = 0.0;
        material.roughness = 0.5;
        material.specular = 0.5;
        material.specularTint = 0.0;
        material.anisotropic = 0.0;
        material.clearcoat = 0.0;
        material.clearcoatRoughness = 0.0;
        material.sheen = 1.0;
        material.sheenTint = 0.0;
        material.transmission = 0.0;
        material.ior = 1.5;
    } else if (row == 4) { // Sheen Tint
        material.baseColor = float3(0.25, 0.0, 0.20);
        material.subsurface = 0.0;
        material.ambientOcclusion = 1.0;
        material.metallic = 0.0;
        material.roughness = 0.5;
        material.specular = 0.5;
        material.specularTint = 0.0;
        material.anisotropic = 0.0;
        material.clearcoat = 0.0;
        material.clearcoatRoughness = 0.0;
        material.sheen = 1.0;
        material.sheenTint = value;
        material.transmission = 0.0;
        material.ior = 1.5;
    } else if (row == 3) { // Clearcoat
        material.baseColor = float3(0.25);
        material.subsurface = 0.0;
        material.metallic = 0.0;
        material.roughness = 0.125;
        material.specular = 0.5;
        material.specularTint = 0.0;
        material.anisotropic = 0.0;
        material.clearcoat = value;
        material.clearcoatRoughness = 0.0;
        material.sheen = 0.0;
        material.sheenTint = 0.0;
        material.transmission = 0.0;
        material.ior = 1.5;
    } else if (row == 2) { // Clearcoat Roughness
        material.baseColor = float3(0.25);
        material.subsurface = 0.0;
        material.metallic = 0.0;
        material.roughness = 0.125;
        material.specular = 0.5;
        material.specularTint = 0.0;
        material.anisotropic = 0.0;
        material.clearcoat = 1.0;
        material.clearcoatRoughness = value;
        material.sheen = 0.0;
        material.sheenTint = 0.0;
        material.transmission = 0.0;
        material.ior = 1.5;
    } else if (row == 1) { // Transmission
        material.baseColor = float3(1.0, 1.0, 1.0);
        material.subsurface = 0.0;
        material.metallic = 0.0;
        // material.roughness = 0.1;
        material.specular = 0.5;
        material.specularTint = 0.0;
        material.anisotropic = 0.0;
        material.clearcoat = 0.0;
        material.clearcoatRoughness = 0.0;
        material.sheen = 0.0;
        material.sheenTint = 0.0;
        material.transmission = value;
        // material.ior = 1.5;
    } else if (row == 0) { // IOR
        material.baseColor = float3(1.0, 1.0, 1.0);
        material.subsurface = 0.0;
        material.metallic = 0.0;
        // material.roughness = 0.1;
        material.specular = 0.5;
        material.specularTint = 0.0;
        material.anisotropic = 0.0;
        material.clearcoat = 0.0;
        material.clearcoatRoughness = 0.0;
        material.sheen = 0.0;
        material.sheenTint = 0.0;
        material.transmission = 1.0;
        material.ior = 1 + value * 1.33;
    }

    pixel.material = material;

    float4 outColor;
#include "Chunks/PbrInit.metal"
#include "Chunks/PbrDirectLighting.metal"
#include "Chunks/PbrInDirectLighting.metal"
#include "Chunks/PbrTonemap.metal"
    return outColor;
}
