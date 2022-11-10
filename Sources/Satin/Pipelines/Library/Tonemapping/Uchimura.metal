// Uchimura 2017, "HDR theory and practice"
// Math: https://www.desmos.com/calculator/gslcdxvipg
// Source: https://www.slideshare.net/nikuque/hdr-theory-and-practicce-jp
float3 uchimura(float3 x, float P, float a, float m, float l, float c, float b)
{
    const float l0 = ((P - m) * l) / a;
    const float L0 = m - m / a;
    const float L1 = m + (1.0 - m) / a;
    const float S0 = m + l0;
    const float S1 = m + a * l0;
    const float C2 = (a * P) / (P - S1);
    const float CP = -C2 / P;

    const float3 w0 = float3(1.0 - smoothstep(0.0, m, x));
    const float3 w2 = float3(step(m + l0, x));
    const float3 w1 = float3(1.0 - w0 - w2);

    const float3 T = float3(m * pow(x / m, c) + b);
    const float3 S = float3(P - (P - S1) * exp(CP * (x - S0)));
    const float3 L = float3(m + a * (x - m));

    return T * w0 + L * w1 + S * w2;
}

float3 uchimura(float3 x)
{
    const float P = 1.0;  // max display brightness
    const float a = 1.0;  // contrast
    const float m = 0.22; // linear section start
    const float l = 0.4;  // linear section length
    const float c = 1.33; // black
    const float b = 0.0;  // pedestal

    return uchimura(x, P, a, m, l, c, b);
}

float uchimura(float x, float P, float a, float m, float l, float c, float b)
{
    const float l0 = ((P - m) * l) / a;
    const float L0 = m - m / a;
    const float L1 = m + (1.0 - m) / a;
    const float S0 = m + l0;
    const float S1 = m + a * l0;
    const float C2 = (a * P) / (P - S1);
    const float CP = -C2 / P;

    const float w0 = 1.0 - smoothstep(0.0, m, x);
    const float w2 = step(m + l0, x);
    const float w1 = 1.0 - w0 - w2;

    const float T = m * pow(x / m, c) + b;
    const float S = P - (P - S1) * exp(CP * (x - S0));
    const float L = m + a * (x - m);

    return T * w0 + L * w1 + S * w2;
}

float uchimura(float x)
{
    const float P = 1.0;  // max display brightness
    const float a = 1.0;  // contrast
    const float m = 0.22; // linear section start
    const float l = 0.4;  // linear section length
    const float c = 1.33; // black
    const float b = 0.0;  // pedestal

    return uchimura(x, P, a, m, l, c, b);
}
