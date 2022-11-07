typedef enum LightType {
    LightTypeAmbient = 0,
    LightTypeDirectional = 1,
    LightTypePoint = 2,
    LightTypeSpot = 3
} LightType;

typedef struct {
    float4 color;
    float3 position;
    float3 direction;
    float intensity;
    int type;
} Light;

