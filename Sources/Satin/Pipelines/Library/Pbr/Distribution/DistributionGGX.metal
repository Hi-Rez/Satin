#include "Library/Pi.metal"

float GTR1(float NdotH, float a)
{
    if (a >= 1.0) return INV_PI;
    float a2 = a * a;
    float t = 1.0 + (a2 - 1.0) * NdotH * NdotH;
    return step(0.0, NdotH) * (a2 - 1.0) / (PI * log(a2) * t);
}

float GTR2(float NdotH, float a)
{
    float a2 = a * a;
    float t = 1.0 + (a2 - 1.0) * NdotH * NdotH;
    return step(0.0, NdotH) * a2 / (PI * t * t);
}

float GTR2Aniso(float NdotH, float HdotX, float HdotY, float ax, float ay)
{
    float a = HdotX / ax;
    float b = HdotY / ay;
    float c = a * a + b * b + NdotH * NdotH;
    return step(0.0, NdotH) * 1.0 / (PI * ax * ay * c * c);
}

float distributionGGX(float NdotH, float roughness)
{
    return GTR2(NdotH, roughness * roughness);
}

float distributionAnisoGGX(float NdotH, float HdotX, float HdotY, float ax, float ay)
{
    return GTR2Aniso(NdotH, HdotX, HdotY, ax, ay);
}

float distributionClearcoatGGX(float NdotH, float roughness)
{
    return GTR1(NdotH, roughness * roughness);
}
