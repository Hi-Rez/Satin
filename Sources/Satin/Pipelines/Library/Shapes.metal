
#define HEXANGLE tan(3.1415926536 / 3.0) / 2.0
// 2D SHAPES
float Line(float2 pos, float2 a, float2 b)
{
    float2 pa = pos - a;
    float2 ba = b - a;
    float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    float2 pt = a + t * ba;
    return length(pt - pos);
}

float Line(float3 pos, float3 a, float3 b)
{
    float3 pa = pos - a;
    float3 ba = b - a;
    float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    float3 pt = a + t * ba;
    return length(pt - pos);
}

float Circle(float2 pos, float radius) { return length(pos) - radius; }

float Rect(float2 pos, float2 size)
{
    float2 v = abs(pos) - size;
    return max(v.x, v.y);
}

float RoundedRect(float2 pos, float2 size, float radius)
{
    float2 v = max(abs(pos) - size, 0.0);
    return length(v) - radius;
}

float Plane(float3 pos, float3 normal, float offset) { return dot(pos, normal) + offset; }

float Cone(float3 pos, float radius, float height)
{
    float z = (height * 0.5) - pos.z;
    float c = Circle(pos.xy, radius * z / height);
    float h = abs(z) - height;
    return max(c, h);
}

float Pyramid(float3 pos, float3 size)
{
    float y = (size.y * 0.5) - pos.y;
    float c = Rect(pos.xz, size.xz * (y / size.y));
    float h = abs(y) - size.y;
    return max(c, h);
}

float Sphere(float3 pos, float radius) { return length(pos) - radius; }

float Box(float3 pos, float3 size)
{
    float3 result = abs(pos) - size;
    return min(max(result.x, max(result.y, result.z)), 0.0) + length(max(result, 0.0));
}

float Box(float3 pos, float size) { return Box(pos, float3(size)); }

float Box(float3 pos, float3 size, float radius)
{
    float3 result = abs(pos) - size;
    return length(max(result, 0.0)) - radius;
}

float Box(float3 pos, float size, float radius) { return Box(pos, float3(size), radius); }

float Cylinder(float3 pos, float radius, float height)
{
    float c = Circle(pos.xy, radius);
    float h = abs(pos.z) - height;
    return max(c, h);
}

float Capsule(float3 pos, float3 a, float3 b, float r) { return Line(pos, a, b) - r; }

float Torus(float3 pos, float2 size)
{
    float2 c2 = float2(length(pos.xy) - size.x, pos.z);
    return length(c2) - size.y;
}

float Octahedron(float3 pos, float size)
{
    float s = size * 0.5;
    float3 r = abs(pos) - float3(s);
    return r.x + r.y + r.z;
}

float Tetrahedron(float3 pos, float size)
{
    float hs = size;
    float result = Box(pos, size);
    result = max(result, -Plane(pos, float3(1, 1, 1), hs));
    result = max(result, -Plane(pos, float3(1, -1, -1), hs));
    result = max(result, -Plane(pos, float3(-1, 1, -1), hs));
    result = max(result, -Plane(pos, float3(-1, -1, 1), hs));
    return result;
}

float Hexagon(float3 pos, float2 size)
{
    float3 apos = abs(pos);
    float z = apos.z - size.y;
    float xy = max(apos.x * HEXANGLE + apos.y * 0.5, apos.y) - size.x;
    return max(xy, z);
}

float Hexagon(float2 pos, float2 size)
{
    float3 apos = abs(float3(pos, 0.0));
    float z = apos.z - size.y;
    float xy = max(apos.x * HEXANGLE + apos.y * 0.5, apos.y) - size.x;
    return max(xy, z);
}

#define sabs(p) sqrt((p) * (p) + 2e-3)
#define smin(a, b) (a + b - sabs(a - b)) * .5
#define smax(a, b) (a + b + sabs(a - b)) * .5

float Dodecahedron(float3 pos, float r)
{
    const float G = sqrt(5.) * .5 + .5;
    const float3 n = normalize(float3(G, 1, 0));
    float d = 0.0;
    pos = sabs(pos);
    d = smax(d, dot(pos, n));
    d = smax(d, dot(pos, n.yzx));
    d = smax(d, dot(pos, n.zxy));
    return d - r;
}

float Icosahedron(float3 pos, float r)
{
    const float G = sqrt(5.) * .5 + .5;
    const float3 n = normalize(float3(G, 1. / G, 0));
    float d = 0.;
    pos = sabs(pos);
    d = smax(d, dot(pos, n));
    d = smax(d, dot(pos, n.yzx));
    d = smax(d, dot(pos, n.zxy));
    d = smax(d, dot(pos, normalize(float3(1.0))));
    return d - r;
}
