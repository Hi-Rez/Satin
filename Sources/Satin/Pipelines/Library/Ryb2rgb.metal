#include "Hsv2rgb.metal"
#include "Rgb2hsv.metal"
#include "Bezier.metal"
#include "CubicSmooth.metal"
#include "Mix.metal"

// https://sighack.com/post/procedural-color-algorithms-hsb-vs-ryb
float3 ryb2rgb(float3 c) { return hsv2rgb(float3(pow(c.x, 1.6), c.yz)); }
float3 ryb2rgb_smooth(float3 c) { return hsv2rgb_smooth(float3(pow(c.x, 1.6), c.yz)); }
float3 ryb2rgb(float h, float s, float v) { return hsv2rgb(float3(pow(h, 1.6), s, v)); }
float3 ryb2rgb_smooth(float h, float s, float v)
{
    return hsv2rgb_smooth(float3(pow(h, 1.6), s, v));
}

/*
Bezier
*/

float3 blendRYB2Bezier(float x, float offset)
{
    const int divs = 2.0;
    const float intervals = 1.0 / float(divs);
    const float mx = cubicSmooth(1.0 - pow(abs(2.0 * x - 1.0), 1.0));
    const float3 c0 = ryb2rgb_smooth(fract(offset), 1.0, 1.0);
    const float3 c1 = ryb2rgb_smooth(fract(offset + intervals), 1.0, 1.0);
    return mix(c0, c1, mx);
}

float3 blendRYB3Bezier(float x, float offset)
{
    const int divs = 3.0;
    const float intervals = 1.0 / float(divs);
    const float mx = cubicSmooth(1.0 - pow(abs(2.0 * x - 1.0), 1.0));
    const float3 c0 = ryb2rgb_smooth(fract(offset), 1.0, 1.0);
    const float3 c1 = ryb2rgb_smooth(fract(offset + intervals), 1.0, 1.0);
    const float3 c2 = ryb2rgb_smooth(fract(offset + 2.0 * intervals), 1.0, 1.0);
    return bezier(mx, c0, c1, c2);
}

float3 blendRYB4Bezier(float x, float offset)
{
    const int divs = 4.0;
    const float intervals = 1.0 / float(divs);
    const float mx = cubicSmooth(1.0 - pow(abs(2.0 * x - 1.0), 1.0));
    const float3 c0 = ryb2rgb_smooth(fract(offset), 1.0, 1.0);
    const float3 c1 = ryb2rgb_smooth(fract(offset + intervals), 1.0, 1.0);
    const float3 c2 = ryb2rgb_smooth(fract(offset + 2.0 * intervals), 1.0, 1.0);
    const float3 c3 = ryb2rgb_smooth(fract(offset + 3.0 * intervals), 1.0, 1.0);
    return bezier(mx, c0, c1, c2, c3);
}

float3 blendRYB5Bezier(float x, float offset)
{
    const int divs = 5.0;
    const float intervals = 1.0 / float(divs);
    const float mx = cubicSmooth(1.0 - pow(abs(2.0 * x - 1.0), 1.0));
    const float3 c0 = ryb2rgb_smooth(fract(offset), 1.0, 1.0);
    const float3 c1 = ryb2rgb_smooth(fract(offset + intervals), 1.0, 1.0);
    const float3 c2 = ryb2rgb_smooth(fract(offset + 2.0 * intervals), 1.0, 1.0);
    const float3 c3 = ryb2rgb_smooth(fract(offset + 3.0 * intervals), 1.0, 1.0);
    const float3 c4 = ryb2rgb_smooth(fract(offset + 4.0 * intervals), 1.0, 1.0);
    return bezier(mx, c0, c1, c2, c3, c4);
}

float3 blendRYB2BezierIncrement(float x, float offset, float increment)
{
    const float mx = cubicSmooth(1.0 - pow(abs(2.0 * x - 1.0), 1.0));
    const float3 c0 = ryb2rgb_smooth(fract(offset), 1.0, 1.0);
    const float3 c1 = ryb2rgb_smooth(fract(offset + increment), 1.0, 1.0);
    return mix(c0, c1, mx);
}

float3 blendRYB3BezierIncrement(float x, float offset, float increment)
{
    const float mx = cubicSmooth(1.0 - pow(abs(2.0 * x - 1.0), 1.0));
    const float3 c0 = ryb2rgb_smooth(fract(offset), 1.0, 1.0);
    const float3 c1 = ryb2rgb_smooth(fract(offset + increment), 1.0, 1.0);
    const float3 c2 = ryb2rgb_smooth(fract(offset + increment * 2.0), 1.0, 1.0);
    return bezier(mx, c0, c1, c2);
}

float3 blendRYB4BezierIncrement(float x, float offset, float increment)
{
    const float mx = cubicSmooth(1.0 - pow(abs(2.0 * x - 1.0), 1.0));
    const float3 c0 = ryb2rgb_smooth(fract(offset), 1.0, 1.0);
    const float3 c1 = ryb2rgb_smooth(fract(offset + increment), 1.0, 1.0);
    const float3 c2 = ryb2rgb_smooth(fract(offset + increment * 2.0), 1.0, 1.0);
    const float3 c3 = ryb2rgb_smooth(fract(offset + increment * 3.0), 1.0, 1.0);
    return bezier(mx, c0, c1, c2, c3);
}

float3 blendRYB5BezierIncrement(float x, float offset, float increment)
{
    const float mx = cubicSmooth(1.0 - pow(abs(2.0 * x - 1.0), 1.0));
    const float3 c0 = ryb2rgb_smooth(fract(offset), 1.0, 1.0);
    const float3 c1 = ryb2rgb_smooth(fract(offset + increment), 1.0, 1.0);
    const float3 c2 = ryb2rgb_smooth(fract(offset + increment * 2.0), 1.0, 1.0);
    const float3 c3 = ryb2rgb_smooth(fract(offset + increment * 3.0), 1.0, 1.0);
    const float3 c4 = ryb2rgb_smooth(fract(offset + increment * 4.0), 1.0, 1.0);
    return bezier(mx, c0, c1, c2, c3, c4);
}

float3 blendRYB3BezierTriad(float x, float offset)
{
    const float intervals = 1.0 / 3.0;
    const float mx = cubicSmooth(1.0 - pow(abs(2.0 * fract(x) - 1.0), 1.0));
    const float3 c0 = ryb2rgb_smooth(fract(offset - intervals), 1.0, 1.0);
    const float3 c1 = ryb2rgb_smooth(fract(offset), 1.0, 1.0);
    const float3 c2 = ryb2rgb_smooth(fract(offset + intervals), 1.0, 1.0);
    return bezier(mx, c0, c1, c2);
}

float3 blendRYB4BezierQuad(float x, float offset)
{
    const float mx = cubicSmooth(1.0 - pow(abs(2.0 * x - 1.0), 1.0));
    const float3 c0 = ryb2rgb_smooth(fract(offset), 1.0, 1.0);
    const float3 c1 = ryb2rgb_smooth(fract(offset + 0.25), 1.0, 1.0);
    const float3 c2 = ryb2rgb_smooth(fract(offset + 0.5), 1.0, 1.0);
    const float3 c3 = ryb2rgb_smooth(fract(offset + 0.75), 1.0, 1.0);
    return bezier(mx, c0, c1, c2, c3);
}

/*
Linear
*/

float3 blendRYB2Linear(float x, float offset)
{
    const int divs = 2.0;
    const float intervals = 1.0 / float(divs);
    const float mx = 1.0 - pow(abs(2.0 * x - 1.0), 1.0);
    const float3 c0 = ryb2rgb_smooth(fract(offset), 1.0, 1.0);
    const float3 c1 = ryb2rgb_smooth(fract(offset + intervals), 1.0, 1.0);
    return mix(c0, c1, mx);
}

float3 blendRYB3Linear(float x, float offset)
{
    const int divs = 3.0;
    const float intervals = 1.0 / float(divs);
    const float mx = 1.0 - pow(abs(2.0 * x - 1.0), 1.0);
    const float3 c0 = ryb2rgb_smooth(fract(offset), 1.0, 1.0);
    const float3 c1 = ryb2rgb_smooth(fract(offset + intervals), 1.0, 1.0);
    const float3 c2 = ryb2rgb_smooth(fract(offset + 2.0 * intervals), 1.0, 1.0);
    return linear(mx, c0, c1, c2);
}

float3 blendRYB4Linear(float x, float offset)
{
    const int divs = 4.0;
    const float intervals = 1.0 / float(divs);
    const float mx = 1.0 - pow(abs(2.0 * x - 1.0), 1.0);
    const float3 c0 = ryb2rgb_smooth(fract(offset), 1.0, 1.0);
    const float3 c1 = ryb2rgb_smooth(fract(offset + intervals), 1.0, 1.0);
    const float3 c2 = ryb2rgb_smooth(fract(offset + 2.0 * intervals), 1.0, 1.0);
    const float3 c3 = ryb2rgb_smooth(fract(offset + 3.0 * intervals), 1.0, 1.0);
    return linear(mx, c0, c1, c2, c3);
}

float3 blendRYB5Linear(float x, float offset)
{
    const int divs = 5.0;
    const float intervals = 1.0 / float(divs);
    const float mx = 1.0 - pow(abs(2.0 * x - 1.0), 1.0);
    const float3 c0 = ryb2rgb_smooth(fract(offset), 1.0, 1.0);
    const float3 c1 = ryb2rgb_smooth(fract(offset + intervals), 1.0, 1.0);
    const float3 c2 = ryb2rgb_smooth(fract(offset + 2.0 * intervals), 1.0, 1.0);
    const float3 c3 = ryb2rgb_smooth(fract(offset + 3.0 * intervals), 1.0, 1.0);
    const float3 c4 = ryb2rgb_smooth(fract(offset + 4.0 * intervals), 1.0, 1.0);
    return linear(mx, c0, c1, c2, c3, c4);
}

float3 blendRYB2LinearIncrement(float x, float offset, float increment)
{
    const float mx = 1.0 - pow(abs(2.0 * fract(x) - 1.0), 1.0);
    const float3 A = ryb2rgb_smooth(fract(offset), 1.0, 1.0);
    const float3 B = ryb2rgb_smooth(fract(offset + increment), 1.0, 1.0);
    return linear(mx, A, B);
}

float3 blendRYB3LinearIncrement(float x, float offset, float increment)
{
    const float mx = 1.0 - pow(abs(2.0 * fract(x) - 1.0), 1.0);
    const float3 A = ryb2rgb_smooth(fract(offset), 1.0, 1.0);
    const float3 B = ryb2rgb_smooth(fract(offset + increment), 1.0, 1.0);
    const float3 C = ryb2rgb_smooth(fract(offset + 2.0 * increment), 1.0, 1.0);
    return linear(mx, A, B, C);
}

float3 blendRYB4LinearIncrement(float x, float offset, float increment)
{
    const float mx = 1.0 - pow(abs(2.0 * fract(x) - 1.0), 1.0);
    const float3 A = ryb2rgb_smooth(fract(offset), 1.0, 1.0);
    const float3 B = ryb2rgb_smooth(fract(offset + increment), 1.0, 1.0);
    const float3 C = ryb2rgb_smooth(fract(offset + 2.0 * increment), 1.0, 1.0);
    const float3 D = ryb2rgb_smooth(fract(offset + 3.0 * increment), 1.0, 1.0);
    return linear(mx, A, B, C, D);
}

float3 blendRYB5LinearIncrement(float x, float offset, float increment)
{
    const float mx = 1.0 - pow(abs(2.0 * fract(x) - 1.0), 1.0);
    const float3 A = ryb2rgb_smooth(fract(offset), 1.0, 1.0);
    const float3 B = ryb2rgb_smooth(fract(offset + increment), 1.0, 1.0);
    const float3 C = ryb2rgb_smooth(fract(offset + 2.0 * increment), 1.0, 1.0);
    const float3 D = ryb2rgb_smooth(fract(offset + 3.0 * increment), 1.0, 1.0);
    const float3 E = ryb2rgb_smooth(fract(offset + 4.0 * increment), 1.0, 1.0);
    return linear(mx, A, B, C, D, E);
}

float3 blendRYB6LinearIncrement(float x, float offset, float increment)
{
    const float mx = 1.0 - pow(abs(2.0 * fract(x) - 1.0), 1.0);
    const float3 A = ryb2rgb_smooth(fract(offset), 1.0, 1.0);
    const float3 B = ryb2rgb_smooth(fract(offset + increment), 1.0, 1.0);
    const float3 C = ryb2rgb_smooth(fract(offset + 2.0 * increment), 1.0, 1.0);
    const float3 D = ryb2rgb_smooth(fract(offset + 3.0 * increment), 1.0, 1.0);
    const float3 E = ryb2rgb_smooth(fract(offset + 4.0 * increment), 1.0, 1.0);
    const float3 F = ryb2rgb_smooth(fract(offset + 5.0 * increment), 1.0, 1.0);
    return linear(mx, A, B, C, D, E, F);
}

float3 blendRYB3LinearTriad(float x, float offset)
{
    const float intervals = 1.0 / 3.0;
    const float mx = 1.0 - pow(abs(2.0 * fract(x) - 1.0), 1.0);
    const float3 c0 = ryb2rgb_smooth(fract(offset - intervals), 1.0, 1.0);
    const float3 c1 = ryb2rgb_smooth(fract(offset), 1.0, 1.0);
    const float3 c2 = ryb2rgb_smooth(fract(offset + intervals), 1.0, 1.0);
    return linear(mx, c0, c1, c2);
}

float3 blendRYB3LinearIso(float x, float offset, float interval)
{
    const float intervals = interval / 3.0;
    const float mx = 1.0 - pow(abs(2.0 * fract(x) - 1.0), 1.0);
    const float3 c0 = ryb2rgb_smooth(fract(offset - intervals), 1.0, 1.0);
    const float3 c1 = ryb2rgb_smooth(fract(offset + intervals), 1.0, 1.0);
    const float3 c2 = ryb2rgb_smooth(fract(offset + 0.5), 1.0, 1.0);
    return linear(mx, c0, c1, c2);
}

float3 blendRYB3BezierIso(float x, float offset, float interval)
{
    const float intervals = interval / 3.0;
    const float mx = cubicSmooth(1.0 - pow(abs(2.0 * fract(x) - 1.0), 1.0));
    const float3 c0 = ryb2rgb_smooth(fract(offset - intervals), 1.0, 1.0);
    const float3 c1 = ryb2rgb_smooth(fract(offset + intervals), 1.0, 1.0);
    const float3 c2 = ryb2rgb_smooth(fract(offset + 0.5), 1.0, 1.0);
    return bezier(mx, c0, c1, c2);
}

float3 blendRYB4LinearQuad(float x, float offset)
{
    const float mx = 1.0 - pow(abs(2.0 * x - 1.0), 1.0);
    const float3 c0 = ryb2rgb_smooth(fract(offset), 1.0, 1.0);
    const float3 c1 = ryb2rgb_smooth(fract(offset + 0.25), 1.0, 1.0);
    const float3 c2 = ryb2rgb_smooth(fract(offset + 0.5), 1.0, 1.0);
    const float3 c3 = ryb2rgb_smooth(fract(offset + 0.75), 1.0, 1.0);
    return linear(mx, c0, c1, c2, c3);
}
