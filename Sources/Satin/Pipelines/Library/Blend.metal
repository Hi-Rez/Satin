/*
Blending Equations adapted from https://github.com/jamieowen/glsl-blend (MIT License)
*/

float blendAdd(float base, float blend) { return min(base + blend, 1.0); }

float3 blendAdd(float3 base, float3 blend) { return min(base + blend, float3(1.0)); }

float3 blendAdd(float3 base, float3 blend, float opacity)
{
    return (blendAdd(base, blend) * opacity + base * (1.0 - opacity));
}

float3 blendAverage(float3 base, float3 blend) { return min((base + blend) / 2.0, float3(1.0)); }

float3 blendAverage(float3 base, float3 blend, float opacity)
{
    return (blendAverage(base, blend) * opacity + base * (1.0 - opacity));
}

float blendColorBurn(float base, float blend)
{
    return (blend == 0.0) ? blend : max((1.0 - ((1.0 - base) / blend)), 0.0);
}

float3 blendColorBurn(float3 base, float3 blend)
{
    return float3(blendColorBurn(base.r, blend.r), blendColorBurn(base.g, blend.g), blendColorBurn(base.b, blend.b));
}

float3 blendColorBurn(float3 base, float3 blend, float opacity)
{
    return (blendColorBurn(base, blend) * opacity + base * (1.0 - opacity));
}

float blendColorDodge(float base, float blend)
{
    return (blend == 1.0) ? blend : min(base / (1.0 - blend), 1.0);
}

float3 blendColorDodge(float3 base, float3 blend)
{
    return float3(blendColorDodge(base.r, blend.r), blendColorDodge(base.g, blend.g), blendColorDodge(base.b, blend.b));
}

float3 blendColorDodge(float3 base, float3 blend, float opacity)
{
    return (blendColorDodge(base, blend) * opacity + base * (1.0 - opacity));
}

float blendDarken(float base, float blend) { return min(blend, base); }

float3 blendDarken(float3 base, float3 blend)
{
    return float3(blendDarken(base.r, blend.r), blendDarken(base.g, blend.g), blendDarken(base.b, blend.b));
}

float3 blendDarken(float3 base, float3 blend, float opacity)
{
    return (blendDarken(base, blend) * opacity + base * (1.0 - opacity));
}

float3 blendDifference(float3 base, float3 blend) { return abs(base - blend); }

float3 blendDifference(float3 base, float3 blend, float opacity)
{
    return (blendDifference(base, blend) * opacity + base * (1.0 - opacity));
}

float3 blendExclusion(float3 base, float3 blend) { return base + blend - 2.0 * base * blend; }

float3 blendExclusion(float3 base, float3 blend, float opacity)
{
    return (blendExclusion(base, blend) * opacity + base * (1.0 - opacity));
}

float blendReflect(float base, float blend)
{
    return (blend == 1.0) ? blend : min(base * base / (1.0 - blend), 1.0);
}

float3 blendReflect(float3 base, float3 blend)
{
    return float3(blendReflect(base.r, blend.r), blendReflect(base.g, blend.g), blendReflect(base.b, blend.b));
}

float3 blendReflect(float3 base, float3 blend, float opacity)
{
    return (blendReflect(base, blend) * opacity + base * (1.0 - opacity));
}

float3 blendGlow(float3 base, float3 blend) { return blendReflect(blend, base); }

float3 blendGlow(float3 base, float3 blend, float opacity)
{
    return (blendGlow(base, blend) * opacity + base * (1.0 - opacity));
}

float blendOverlay(float base, float blend)
{
    return base < 0.5 ? (2.0 * base * blend) : (1.0 - 2.0 * (1.0 - base) * (1.0 - blend));
}

float3 blendOverlay(float3 base, float3 blend)
{
    return float3(blendOverlay(base.r, blend.r), blendOverlay(base.g, blend.g), blendOverlay(base.b, blend.b));
}

float3 blendOverlay(float3 base, float3 blend, float opacity)
{
    return (blendOverlay(base, blend) * opacity + base * (1.0 - opacity));
}

float3 blendHardLight(float3 base, float3 blend) { return blendOverlay(blend, base); }

float3 blendHardLight(float3 base, float3 blend, float opacity)
{
    return (blendHardLight(base, blend) * opacity + base * (1.0 - opacity));
}

float blendVividLight(float base, float blend)
{
    return (blend < 0.5) ? blendColorBurn(base, (2.0 * blend))
                         : blendColorDodge(base, (2.0 * (blend - 0.5)));
}

float3 blendVividLight(float3 base, float3 blend)
{
    return float3(blendVividLight(base.r, blend.r), blendVividLight(base.g, blend.g), blendVividLight(base.b, blend.b));
}

float3 blendVividLight(float3 base, float3 blend, float opacity)
{
    return (blendVividLight(base, blend) * opacity + base * (1.0 - opacity));
}

float blendHardMix(float base, float blend)
{
    return (blendVividLight(base, blend) < 0.5) ? 0.0 : 1.0;
}

float3 blendHardMix(float3 base, float3 blend)
{
    return float3(blendHardMix(base.r, blend.r), blendHardMix(base.g, blend.g), blendHardMix(base.b, blend.b));
}

float3 blendHardMix(float3 base, float3 blend, float opacity)
{
    return (blendHardMix(base, blend) * opacity + base * (1.0 - opacity));
}

float blendLighten(float base, float blend) { return max(blend, base); }

float3 blendLighten(float3 base, float3 blend)
{
    return float3(blendLighten(base.r, blend.r), blendLighten(base.g, blend.g), blendLighten(base.b, blend.b));
}

float3 blendLighten(float3 base, float3 blend, float opacity)
{
    return (blendLighten(base, blend) * opacity + base * (1.0 - opacity));
}

float blendLinearBurn(float base, float blend)
{
    // Note : Same implementation as BlendSubtractf
    return max(base + blend - 1.0, 0.0);
}

float3 blendLinearBurn(float3 base, float3 blend)
{
    // Note : Same implementation as BlendSubtract
    return max(base + blend - float3(1.0), float3(0.0));
}

float3 blendLinearBurn(float3 base, float3 blend, float opacity)
{
    return (blendLinearBurn(base, blend) * opacity + base * (1.0 - opacity));
}

float blendLinearDodge(float base, float blend)
{
    // Note : Same implementation as BlendAddf
    return min(base + blend, 1.0);
}

float3 blendLinearDodge(float3 base, float3 blend)
{
    // Note : Same implementation as BlendAdd
    return min(base + blend, float3(1.0));
}

float3 blendLinearDodge(float3 base, float3 blend, float opacity)
{
    return (blendLinearDodge(base, blend) * opacity + base * (1.0 - opacity));
}

float blendLinearLight(float base, float blend)
{
    return blend < 0.5 ? blendLinearBurn(base, (2.0 * blend))
                       : blendLinearDodge(base, (2.0 * (blend - 0.5)));
}

float3 blendLinearLight(float3 base, float3 blend)
{
    return float3(blendLinearLight(base.r, blend.r), blendLinearLight(base.g, blend.g), blendLinearLight(base.b, blend.b));
}

float3 blendLinearLight(float3 base, float3 blend, float opacity)
{
    return (blendLinearLight(base, blend) * opacity + base * (1.0 - opacity));
}

float3 blendMultiply(float3 base, float3 blend) { return base * blend; }

float3 blendMultiply(float3 base, float3 blend, float opacity)
{
    return (blendMultiply(base, blend) * opacity + base * (1.0 - opacity));
}

float3 blendNegation(float3 base, float3 blend)
{
    return float3(1.0) - abs(float3(1.0) - base - blend);
}

float3 blendNegation(float3 base, float3 blend, float opacity)
{
    return (blendNegation(base, blend) * opacity + base * (1.0 - opacity));
}

float3 blendNormal(float3 base, float3 blend) { return blend; }

float3 blendNormal(float3 base, float3 blend, float opacity)
{
    return (blendNormal(base, blend) * opacity + base * (1.0 - opacity));
}

float3 blendPhoenix(float3 base, float3 blend)
{
    return min(base, blend) - max(base, blend) + float3(1.0);
}

float3 blendPhoenix(float3 base, float3 blend, float opacity)
{
    return (blendPhoenix(base, blend) * opacity + base * (1.0 - opacity));
}

float blendPinLight(float base, float blend)
{
    return (blend < 0.5) ? blendDarken(base, (2.0 * blend))
                         : blendLighten(base, (2.0 * (blend - 0.5)));
}

float3 blendPinLight(float3 base, float3 blend)
{
    return float3(blendPinLight(base.r, blend.r), blendPinLight(base.g, blend.g), blendPinLight(base.b, blend.b));
}

float3 blendPinLight(float3 base, float3 blend, float opacity)
{
    return (blendPinLight(base, blend) * opacity + base * (1.0 - opacity));
}

float blendScreen(float base, float blend) { return 1.0 - ((1.0 - base) * (1.0 - blend)); }

float3 blendScreen(float3 base, float3 blend)
{
    return float3(blendScreen(base.r, blend.r), blendScreen(base.g, blend.g), blendScreen(base.b, blend.b));
}

float3 blendScreen(float3 base, float3 blend, float opacity)
{
    return (blendScreen(base, blend) * opacity + base * (1.0 - opacity));
}

float blendSoftLight(float base, float blend)
{
    return (blend < 0.5) ? (2.0 * base * blend + base * base * (1.0 - 2.0 * blend))
                         : (sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base * (1.0 - blend));
}

float3 blendSoftLight(float3 base, float3 blend)
{
    return float3(blendSoftLight(base.r, blend.r), blendSoftLight(base.g, blend.g), blendSoftLight(base.b, blend.b));
}

float3 blendSoftLight(float3 base, float3 blend, float opacity)
{
    return (blendSoftLight(base, blend) * opacity + base * (1.0 - opacity));
}

float blendSubtract(float base, float blend) { return max(base + blend - 1.0, 0.0); }

float3 blendSubtract(float3 base, float3 blend)
{
    return max(base + blend - float3(1.0), float3(0.0));
}

float3 blendSubtract(float3 base, float3 blend, float opacity)
{
    return (blendSubtract(base, blend) * opacity + base * (1.0 - opacity));
}
