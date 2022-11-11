typedef struct {
    float3 baseColor;
    float3 emissiveColor;
    float3 worldPos;
    float3 cameraPos;
    float3 F0;
    float3 N;
    float3 V;
    float3 Lo;
    float NoV;
    float ao;
    float metallic;
    float roughness;
    float alpha;
} Material;
