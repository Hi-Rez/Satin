float2x2 rotate2D(float theta)
{
    float ct = cos(theta);
    float st = sin(theta);
    return float2x2(ct, st, -st, ct);
}
