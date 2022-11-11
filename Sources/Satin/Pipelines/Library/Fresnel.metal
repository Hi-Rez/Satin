constant float kEtaAir = 1.000277;
constant float kEtaWater = 1.333;
constant float kEtaGlass = 1.5;
constant float kEtaDiamond = 2.42;

float fresnel(float3 eyeVector, float3 worldNormal, float amount = 3.0)
{
    return pow(1.0 + dot(eyeVector, worldNormal), amount);
}
