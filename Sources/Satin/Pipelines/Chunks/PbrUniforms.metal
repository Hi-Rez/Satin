    float4 baseColor;           // color,1,1,1,1
    float4 emissiveColor;       // color,0,0,0,0
    float environmentIntensity; // slider,0.0,1.0,1.0
    float roughness;            // slider,0.0,1.0,0.0
    float metallic;             // slider,0.0,1.0,0.0
    float specular;             // slider,0.0,1.0,0.5
#if defined(HAS_SPECULAR_TINT)
    float specularTint;         // slider,0.0,1.0,0.0
#endif
#if defined(HAS_ANISOTROPIC)
    float anisotropic;          // slider,-1.0,1.0,0.0
    float anisotropicAngle;     // slider,-1.0,1.0,0.0
#endif
#if defined(HAS_CLEARCOAT)
    float clearcoat;            // slider,0.0,1.0,0.0
    float clearcoatRoughness;   // slider,0.0,1.0,0.0
#endif
#if defined(HAS_SUBSURFACE)
    float subsurface;           // slider,0.0,1.0,0.0
#endif
#if defined(HAS_SHEEN)
    float sheen;                // slider,0.0,1.0,0.0
    float sheenTint;            // slider,0.0,1.0,0.0
#endif
#if defined(HAS_TRANSMISSION)
    float transmission;         // slider,0.0,1.0,0.0
    float thickness;            // slider,0.0,5.0,0.0
    float ior;                  // slider,1.0,3.0,1.5
#endif

