#include "Pi.metal"

float3 brightness(float3 color, float brightness) { return color.rgb + brightness; }

float3 contrast(float3 color, float contrast)
{
    const float t = 0.5 - contrast * 0.5;
    return color.rgb * contrast + t;
}

float3 gamma(float3 color, float gamma) { return pow(abs(color), gamma); }

float3 saturation(float3 color, float saturation)
{
    const float3 luminance = float3(0.3086, 0.6094, 0.0820);
    float oneMinusSat = 1.0 - saturation;
    float3 red = float3(luminance.x * oneMinusSat);
    red.r += saturation;
    float3 green = float3(luminance.y * oneMinusSat);
    green.g += saturation;
    float3 blue = float3(luminance.z * oneMinusSat);
    blue.b += saturation;
    return float3x3(red.r, red.g, red.b, green.r, green.g, green.b, blue.r, blue.g, blue.b) * color;
}

int modi(int x, int y) { return x - y * (x / y); }

float modf(float x, float y) { return x - y * floor(x / y); }

int andf(int a, int b)
{
    int result = 0;
    int n = 1;
    const int BIT_COUNT = 32;

    for (int i = 0; i < BIT_COUNT; i++) {
        if ((modi(a, 2) == 1) && (modi(b, 2) == 1)) { result += n; }

        a >>= 1;
        b >>= 1;
        n <<= 1;

        if (!(a > 0 && b > 0)) break;
    }
    return result;
}

float3 vibrance(float3 color, float vibrance)
{
    float3 outCol;
    if (vibrance <= 1.0) {
        float avg = dot(color.rgb, float3(0.3, 0.6, 0.1));
        outCol.rgb = mix(float3(avg), color.rgb, vibrance);
    } else // vibrance > 1.0
    {
        float hue_a, a, f, p1, p2, p3, i, h, s, v, _max, _min, dlt;
        float br1, br2, br3, br4, br2_or_br1, br3_or_br1, br4_or_br1;
        int use;

        _min = min(min(color.r, color.g), color.b);
        _max = max(max(color.r, color.g), color.b);
        dlt = _max - _min + 0.00001 /*Hack to fix divide zero infinities*/;
        h = 0.0;
        v = _max;

        br1 = step(_max, 0.0);
        s = (dlt / _max) * (1.0 - br1);
        h = -1.0 * br1;

        br2 = 1.0 - step(_max - color.r, 0.0);
        br2_or_br1 = max(br2, br1);
        h = ((color.g - color.b) / dlt) * (1.0 - br2_or_br1) + (h * br2_or_br1);

        br3 = 1.0 - step(_max - color.g, 0.0);

        br3_or_br1 = max(br3, br1);
        h = (2.0 + (color.b - color.r) / dlt) * (1.0 - br3_or_br1) + (h * br3_or_br1);

        br4 = 1.0 - br2 * br3;
        br4_or_br1 = max(br4, br1);
        h = (4.0 + (color.r - color.g) / dlt) * (1.0 - br4_or_br1) + (h * br4_or_br1);

        h = h * (1.0 - br1);

        hue_a = abs(h); // between h of -1 and 1 are skin tones
        a = dlt;        // Reducing enhancements on small rgb differences

        // Reduce the enhancements on skin tones.
        a = step(1.0, hue_a) * a * (hue_a * 0.67 + 0.33) + step(hue_a, 1.0) * a;
        a *= (vibrance - 1.0);
        s = (1.0 - a) * s + a * pow(s, 0.25);

        i = floor(h);
        f = h - i;

        p1 = v * (1.0 - s);
        p2 = v * (1.0 - (s * f));
        p3 = v * (1.0 - (s * (1.0 - f)));

        color.rgb = float3(0.0);
        i += 6.0;
        // use = 1 << ((int)i % 6);
        use = int(pow(2.0, modf(i, 6.0)));
        a = float(andf(use, 1)); // i == 0;
        use >>= 1;
        color.rgb += a * float3(v, p3, p1);

        a = float(andf(use, 1)); // i == 1;
        use >>= 1;
        color.rgb += a * float3(p2, v, p1);

        a = float(andf(use, 1)); // i == 2;
        use >>= 1;
        color.rgb += a * float3(p1, v, p3);

        a = float(andf(use, 1)); // i == 3;
        use >>= 1;
        color.rgb += a * float3(p1, p2, v);

        a = float(andf(use, 1)); // i == 4;
        use >>= 1;
        color.rgb += a * float3(p3, p1, v);

        a = float(andf(use, 1)); // i == 5;
        use >>= 1;
        color.rgb += a * float3(v, p1, p2);

        outCol = color;
    }
    return outCol;
}

// remixed from mAlk's https://www.shadertoy.com/view/MsjXRt
float3 hue(float3 col, float hue)
{
    const float3 P = float3(0.55735) * dot(float3(0.55735), col);
    const float3 U = col - P;
    const float3 V = cross(float3(0.55735), U);
    return U * cos(hue * TWO_PI) + V * sin(hue * TWO_PI) + P;
}

half3 brightnessHalf(half3 color, half brightness) { return color.rgb + brightness; }

half3 contrastHalf(half3 color, half contrast)
{
    const half t = 0.5h - contrast * 0.5h;
    return color.rgb * contrast + t;
}

half3 gammaHalf(half3 color, half gamma) { return pow(abs(color), gamma); }

half3 saturationHalf(half3 color, half saturation)
{
    const half3 luminance = half3(0.3086, 0.6094, 0.0820);
    half oneMinusSat = 1.0 - saturation;
    half3 red = half3(luminance.x * oneMinusSat);
    red.r += saturation;
    half3 green = half3(luminance.y * oneMinusSat);
    green.g += saturation;
    half3 blue = half3(luminance.z * oneMinusSat);
    blue.b += saturation;
    return half3x3(red.r, red.g, red.b, green.r, green.g, green.b, blue.r, blue.g, blue.b) * color;
}
