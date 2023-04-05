    float4 baseColor;           // color,1,1,1,1
    float4 emissiveColor;       // color,0,0,0,0
    float environmentIntensity; // slider,0.0,1.0,1.0
    float roughness;            // slider,0.0,1.0,0.0
    float metallic;             // slider,0.0,1.0,0.0
    float specular;             // slider,0.0,1.0,0.5
    float specularTint;         // slider,0.0,1.0,0.0
    float anisotropic;          // slider,-1.0,1.0,0.0
    float anisotropicAngle;     // slider,-1.0,1.0,0.0
    float clearcoat;            // slider,0.0,1.0,0.0
    float clearcoatRoughness;   // slider,0.0,1.0,0.0
    float subsurface;           // slider,0.0,1.0,0.0
    float sheen;                // slider,0.0,1.0,0.0
    float sheenTint;            // slider,0.0,1.0,0.0
    float transmission;         // slider,0.0,1.0,0.0
    float thickness;            // slider,0.0,5.0,0.0
    float ior;                  // slider,1.0,3.0,1.5
    float3x3 baseColorTexcoordTransform;
    float3x3 emissiveTexcoordTransform;
    float3x3 roughnessTexcoordTransform;
    float3x3 metallicTexcoordTransform;
    float3x3 specularTexcoordTransform;
    float3x3 normalTexcoordTransform;
    float3x3 ambientOcclusionTexcoordTransform;
    float3x3 specularTintTexcoordTransform;
    float3x3 anisotropicTexcoordTransform;
    float3x3 anisotropicAngleTexcoordTransform;
    float3x3 clearcoatTexcoordTransform;
    float3x3 clearcoatRoughnessTexcoordTransform;
    float3x3 subsurfaceTexcoordTransform;
    float3x3 sheenTexcoordTransform;
    float3x3 sheenTintTexcoordTransform;
    float3x3 transmissionTexcoordTransform;
    float3x3 iorTexcoordTransform;
