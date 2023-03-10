typedef enum VertexAttribute {
    VertexAttributePosition = 0,
    VertexAttributeNormal = 1,
    VertexAttributeTexcoord = 2,
    VertexAttributeTangent = 3,
    VertexAttributeBitangent = 4,
    VertexAttributeColor = 5,
    VertexAttributeCustom0 = 6,
    VertexAttributeCustom1 = 7,
    VertexAttributeCustom2 = 8,
    VertexAttributeCustom3 = 9,
    VertexAttributeCustom4 = 10,
    VertexAttributeCustom5 = 11,
    VertexAttributeCustom6 = 12,
    VertexAttributeCustom7 = 13,
    VertexAttributeCustom8 = 14,
    VertexAttributeCustom9 = 15,
    VertexAttributeCustom10 = 16,
    VertexAttributeCustom11 = 17
} VertexAttribute;

typedef enum VertexBufferIndex {
    VertexBufferVertices = 0,
    VertexBufferGenerics = 1,
    VertexBufferVertexUniforms = 2,
    VertexBufferInstanceMatrixUniforms = 3,
    VertexBufferMaterialUniforms = 4,
    VertexBufferShadowMatrices = 5,
    VertexBufferCustom0 = 6,
    VertexBufferCustom1 = 7,
    VertexBufferCustom2 = 8,
    VertexBufferCustom3 = 9,
    VertexBufferCustom4 = 10,
    VertexBufferCustom5 = 11,
    VertexBufferCustom6 = 12,
    VertexBufferCustom7 = 13,
    VertexBufferCustom8 = 14,
    VertexBufferCustom9 = 15,
    VertexBufferCustom10 = 16
} VertexBufferIndex;

typedef enum VertexTextureIndex {
    VertexTextureCustom0 = 0,
    VertexTextureCustom1 = 1,
    VertexTextureCustom2 = 2,
    VertexTextureCustom3 = 3,
    VertexTextureCustom4 = 4,
    VertexTextureCustom5 = 5,
    VertexTextureCustom6 = 6,
    VertexTextureCustom7 = 7,
    VertexTextureCustom8 = 8,
    VertexTextureCustom9 = 9,
    VertexTextureCustom10 = 10,
    VertexTextureCustom11 = 11,
    VertexTextureCustom12 = 12,
    VertexTextureCustom13 = 13,
    VertexTextureCustom14 = 14,
    VertexTextureCustom15 = 15,
    VertexTextureCustom16 = 16
} VertexTextureIndex;

typedef enum FragmentBufferIndex {
    FragmentBufferMaterialUniforms = 0,
    FragmentBufferLighting = 1,
    FragmentBufferShadows = 2,
    FragmentBufferShadowData = 3,
    FragmentBufferCustom0 = 4,
    FragmentBufferCustom1 = 5,
    FragmentBufferCustom2 = 6,
    FragmentBufferCustom3 = 7,
    FragmentBufferCustom4 = 8,
    FragmentBufferCustom5 = 9,
    FragmentBufferCustom6 = 10,
    FragmentBufferCustom7 = 11,
    FragmentBufferCustom8 = 12,
    FragmentBufferCustom9 = 13,
    FragmentBufferCustom10 = 14
} FragmentBufferIndex;

typedef enum FragmentTextureIndex {
    FragmentTextureCustom0 = 0,
    FragmentTextureCustom1 = 1,
    FragmentTextureCustom2 = 2,
    FragmentTextureCustom3 = 3,
    FragmentTextureCustom4 = 4,
    FragmentTextureCustom5 = 5,
    FragmentTextureCustom6 = 6,
    FragmentTextureCustom7 = 7,
    FragmentTextureCustom8 = 8,
    FragmentTextureCustom9 = 9,
    FragmentTextureCustom10 = 10,
    FragmentTextureCustom11 = 11,
    FragmentTextureCustom12 = 12,
    FragmentTextureCustom13 = 13,
    FragmentTextureCustom14 = 14,
    FragmentTextureCustom15 = 15,
    FragmentTextureCustom16 = 16,
    FragmentTextureShadow0 = 17,
    FragmentTextureShadow1 = 18,
    FragmentTextureShadow2 = 19,
    FragmentTextureShadow3 = 20,
    FragmentTextureShadow4 = 21,
    FragmentTextureShadow5 = 22,
    FragmentTextureShadow6 = 23,
    FragmentTextureShadow7 = 24
} FragmentTextureIndex;

typedef enum PBRTextureIndex {
    PBRTextureBaseColor = 0,
    PBRTextureMetallic = 1,
    PBRTextureRoughness = 2,
    PBRTextureNormal = 3,
    PBRTextureEmissive = 4,
    PBRTextureSpecular = 5,
    PBRTextureSheen = 6,
    PBRTextureAnisotropy = 7,
    PBRTextureAnisotropyAngle = 8,
    PBRTextureBump = 9,
    PBRTextureDisplacement = 10,
    PBRTextureAlpha = 11,
    PBRTextureTransmission = 12,
    PBRTextureAmbientOcculsion = 13,
    PBRTextureReflection = 14,
    PBRTextureIrradiance = 15,
    PBRTextureBRDF = 16
} PBRTextureIndex;

typedef enum FragmentSamplerIndex {
    FragmentSamplerCustom0 = 0,
    FragmentSamplerCustom1 = 1,
    FragmentSamplerCustom2 = 2,
    FragmentSamplerCustom3 = 3,
    FragmentSamplerCustom4 = 4,
    FragmentSamplerCustom5 = 5,
    FragmentSamplerCustom6 = 6,
    FragmentSamplerCustom7 = 7,
    FragmentSamplerCustom8 = 8,
    FragmentSamplerCustom9 = 9,
    FragmentSamplerCustom10 = 10
} FragmentSamplerIndex;

typedef enum ComputeBufferIndex {
    ComputeBufferUniforms = 0,
    ComputeBufferCustom0 = 1,
    ComputeBufferCustom1 = 2,
    ComputeBufferCustom2 = 3,
    ComputeBufferCustom3 = 4,
    ComputeBufferCustom4 = 5,
    ComputeBufferCustom5 = 6,
    ComputeBufferCustom6 = 7,
    ComputeBufferCustom7 = 8,
    ComputeBufferCustom8 = 9,
    ComputeBufferCustom9 = 10,
    ComputeBufferCustom10 = 11
} ComputeBufferIndex;

typedef enum ComputeTextureIndex {
    ComputeTextureCustom0 = 0,
    ComputeTextureCustom1 = 1,
    ComputeTextureCustom2 = 2,
    ComputeTextureCustom3 = 3,
    ComputeTextureCustom4 = 4,
    ComputeTextureCustom5 = 5,
    ComputeTextureCustom6 = 6,
    ComputeTextureCustom7 = 7,
    ComputeTextureCustom8 = 8,
    ComputeTextureCustom9 = 9,
    ComputeTextureCustom10 = 10
} ComputeTextureIndex;
