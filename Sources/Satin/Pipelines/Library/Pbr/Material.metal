typedef struct {
    float3 baseColor;
    float3 diffuseColor; 
    float3 emissiveColor;
    float3 worldPos;
    float3 cameraPos;
    float3 f0;
    float3 f90;
    float3 N;
    float3 V;
    float3 Lo;
    float NoV;
    float ao;
    float metallic;
    float roughness;
    float reflectance;
    float alpha;
#if defined(HAS_CLEAR_COAT)
    float clearCoat;
    float clearCoatRoughness;
    float3 clearCoatf0;
    float clearCoatf90;
#endif
} Material;
