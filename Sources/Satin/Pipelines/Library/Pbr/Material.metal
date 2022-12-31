typedef struct {
    float3 baseColor;
    float3 emissiveColor;
    float ao;
    float metallic;
    float roughness;
    float specular;
    float alpha;
#if defined(HAS_CLEAR_COAT)
    float clearcoat;
    float clearcoatRoughness;
#endif
} Material;
