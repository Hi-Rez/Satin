    float4 baseColor;           // color,1,1,1,1
    float4 emissiveColor;       // color,0,0,0,0
    float roughness;            // slider,0.0,1.0,0.0
    float metallic;             // slider,0.0,1.0,0.0
    float specular;             // slider,0.0,1.0,0.5
    float environmentIntensity;
    float gammaCorrection;
    float3x3 baseColorTexcoordTransform;
    float3x3 emissiveTexcoordTransform;
    float3x3 roughnessTexcoordTransform;
    float3x3 metallicTexcoordTransform;
    float3x3 specularTexcoordTransform;
    float3x3 normalTexcoordTransform;
    float3x3 ambientOcclusionTexcoordTransform;
    float3x3 reflectionTexcoordTransform;
    float3x3 irradianceTexcoordTransform;
