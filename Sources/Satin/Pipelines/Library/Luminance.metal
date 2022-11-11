float luminance(float3 color) { return 0.299 * color.r + 0.587 * color.g + 0.114 * color.b; }

float luminance2(float3 color) { return 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b; }

float luminance3(float3 color)
{
    return sqrt(0.299 * pow(color.r, 2.0) + 0.587 * pow(color.g, 2.0) + 0.114 * pow(color.b, 2.0));
}
