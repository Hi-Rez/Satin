static constant int bayer8x8[64] = {
    0, 32, 8, 40, 2, 34, 10, 42, 48, 16, 56, 24, 50, 18, 58, 26, 12, 44, 4, 36, 14, 46,
    6, 38, 60, 28, 52, 20, 62, 30, 54, 22, 3, 35, 11, 43, 1, 33, 9, 41, 51, 19, 59, 27,
    49, 17, 57, 25, 15, 47, 7, 39, 13, 45, 5, 37, 63, 31, 55, 23, 61, 29, 53, 21
};

float dither8x8(float2 pos)
{
    const int2 p = (int2)pos % 8;
    return bayer8x8[p.y * 8 + p.x];
}

float3 dither8x8(float2 pos, float3 color)
{
    return color + (dither8x8(pos) / 32.0 - (1.0 / 128.0)) / 255.0;
}

float4 dither8x8(float2 pos, float4 color)
{
    return color + (dither8x8(pos) / 32.0 - (1.0 / 128.0)) / 255.0;
}

half dither8x8Half(half2 pos)
{
    const int2 p = (int2)pos % 8;
    return bayer8x8[p.y * 8 + p.x];
}

half3 dither8x8Half(half2 pos, half3 color)
{
    return color + (dither8x8Half(pos) / 32.0h - (1.0h / 128.0h)) / 255.0h;
}

half4 dither8x8Half(half2 pos, half4 color)
{
    return color + (dither8x8Half(pos) / 32.0h - (1.0h / 128.0h)) / 255.0h;
}
