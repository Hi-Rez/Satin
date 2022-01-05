#define GammaCorrection float3(0.4545454545)

float gamma(float alpha) { return pow(alpha, GammaCorrection.x); }

float3 gamma(float3 color) { return pow(color, GammaCorrection); }

float4 gamma(float4 color) { return float4(gamma(color.rgb), color.a); }
