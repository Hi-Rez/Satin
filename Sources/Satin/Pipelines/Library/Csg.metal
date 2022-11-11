float shell(float a, float d)
{
    float d2 = d * 0.5;
    return max(a - d2, -d2 - a);
}

float morph(float a, float b, float d) { return d * a + (1.0 - d) * b; }

float blend(float a, float b, float r) { return min(min(a, b), sqrt(a) + sqrt(b) - r); }

float unionHard(float a, float b) { return min(a, b); }

float unionStep(float a, float b, float r)
{
    float am = a - r;
    float bm = b - r;
    float m = max(am, bm);
    return min(min(b, a), m);
}

float unionRound(float a, float b, float r)
{
    float2 u = max(float2(r - a, r - b), float2(0.0));
    return max(r, min(a, b)) - length(u);
}

float unionSoft(float a, float b, float r)
{
    float u = max(r - abs(a - b), 0.0);
    return min(a, b) - u * u * 0.25 / r;
}

float intersection(float a, float b) { return max(a, b); }

float difference(float a, float b) { return max(a, -b); }
