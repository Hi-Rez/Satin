#include "Pi.metal"

float gaussian(float x, float sigma, float power)
{
    const float dist = pow(x, power);
    const float a = 1.0 / (sigma * sqrt(TWO_PI));
    const float gau = a * exp(-0.5 * pow((dist / sigma), 2.0));
    return gau;
}

float2 gaussian(float2 xy, float sigma, float power)
{
    const float2 dist = pow(xy, power);
    const float a = 1.0 / (sigma * sqrt(TWO_PI));
    const float2 gau = a * exp(-0.5 * pow((dist / sigma), 2.0));
    return gau;
}

half gaussianHalf(half x, half sigma, half power)
{
    const half dist = pow(x, power);
    const half a = 1.0h / (sigma * sqrt(TWO_PI));
    const half gau = a * exp(-0.5h * pow((dist / sigma), 2.0h));
    return gau;
}

half2 gaussianHalf(half2 xy, half sigma, half power)
{
    const half2 dist = pow(xy, power);
    const half a = 1.0h / (sigma * sqrt(TWO_PI));
    const half2 gau = a * exp(-0.5h * pow((dist / sigma), 2.0h));
    return gau;
}
