
//
//  Geometry.c
//  Satin
//
//  Created by Reza Ali on 6/28/20.
//

#include <float.h>
#include "Geometry.h"

float map(float input, float inMin, float inMax, float outMin, float outMax) {
    return ((input - inMin) / (inMax - inMin) * (outMax - outMin)) + outMin;
}

bool greaterThanZero(float a) { return a > FLT_EPSILON; }

bool isZero(float a) { return a == 0 || fabsf(a) < FLT_EPSILON; }

float area2(simd_float2 a, simd_float2 b, simd_float2 c) {
    return (b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y);
}

float cross2(simd_float2 a, simd_float2 b) { return a.x * b.y - b.x * a.y; }

bool isLeft(simd_float2 a, simd_float2 b, simd_float2 c) { return greaterThanZero(area2(a, b, c)); }

bool isLeftOn(simd_float2 a, simd_float2 b, simd_float2 c) {
    float res = area2(a, b, c);
    return greaterThanZero(res) || isZero(res);
}

bool inCone(simd_float2 a0, simd_float2 a, simd_float2 a1, simd_float2 b) {
    if (isLeftOn(a, a1, a0)) { return isLeft(a, b, a0) && isLeft(b, a, a1); }
    return !(isLeftOn(a, b, a1) && isLeftOn(b, a, a0));
}

bool isEqual(float a, float b) { return (a == b || isZero(a - b)); }

bool isEqual2(simd_float2 a, simd_float2 b) { return isEqual(a.x, b.x) && isEqual(a.y, b.y); }

bool isColinear2(simd_float2 a, simd_float2 b, simd_float2 c) { return isZero(area2(a, b, c)); }

bool isColinear3(simd_float3 a, simd_float3 b, simd_float3 c) {
    float cax = c[0] - a[0];
    float cay = c[1] - a[1];
    float caz = c[2] - a[2];
    float bax = b[0] - a[0];
    float bay = b[1] - a[1];
    float baz = b[2] - a[2];
    return isZero((caz * bay) - (baz * cay)) && isZero((baz * cax) - (bax * caz)) &&
           isZero((bax * cay) - (bay * cax));
}

bool isBetween(simd_float2 a, simd_float2 b, simd_float2 c) {
    if (!isColinear2(a, b, c)) { return false; }
    if (a[0] != b[0]) {
        return ((a[0] <= c[0]) && (c[0] <= b[0])) || ((a[0] >= c[0]) && (c[0] >= b[0]));
    } else {
        return ((a[1] <= c[1]) && (c[1] <= b[1])) || ((a[1] >= c[1]) && (c[1] >= b[1]));
    }
}

bool intersectsProper(simd_float2 a, simd_float2 b, simd_float2 c, simd_float2 d) {
    if (isColinear2(a, b, c) || isColinear2(a, b, d) || isColinear2(c, d, a) ||
        isColinear2(c, d, b)) {
        return false;
    }
    return (isLeft(a, b, c) ^ isLeft(a, b, d)) && (isLeft(c, d, a) ^ isLeft(c, d, b));
}

bool intersects(simd_float2 a, simd_float2 b, simd_float2 c, simd_float2 d) {
    if (intersectsProper(a, b, c, d)) {
        return true;
    } else if (isBetween(a, b, c) || isBetween(a, b, d) || isBetween(c, d, a) ||
               isBetween(c, d, b)) {
        return true;
    } else {
        return false;
    }
}

bool isDiagonalie(simd_float2 a, simd_float2 b, simd_float2 *polygon, int count) {

    for (int i = 0; i < count; i++) {
        simd_float2 c = polygon[i];
        simd_float2 c1 = polygon[(i + 1) % count];
        if (!isEqual2(c, a) && !isEqual2(c1, a) && !isEqual2(c, b) && !isEqual2(c1, b) &&
            intersects(a, b, c, c1)) {
            return false;
        }
    }
    return true;
}

bool isDiagonal(int i, int j, simd_float2 *polygon, int count) {
    int i0 = (i - 1 < 0) ? count - 1 : i - 1;
    int i1 = (i + 1) % count;

    simd_float2 a0 = polygon[i0];
    simd_float2 a = polygon[i];
    simd_float2 a1 = polygon[i1];

    int j0 = (j - 1 < 0) ? count - 1 : j - 1;
    int j1 = (j + 1) % count;

    simd_float2 b0 = polygon[j0];
    simd_float2 b = polygon[j];
    simd_float2 b1 = polygon[j1];

    return inCone(a0, a, a1, b) && inCone(b0, b, b1, a) && isDiagonalie(a, b, polygon, count);
}

bool isClockwise(simd_float2 *polygon, int length) {
    float area = 0;
    for (int i = 0; i < length; i++) {
        int i0 = i;
        int i1 = (i + 1) % length;
        simd_float2 a = polygon[i0];
        simd_float2 b = polygon[i1];
        area += (b.x - a.x) * (b.y + a.y);
    }
    return !signbit(area);
}

bool rayPlaneIntersection( simd_float3 origin, simd_float3 direction, simd_float3 planeNormal, simd_float3 planeOrigin, simd_float3 *intersection)
{
    simd_float3 o = planeOrigin - origin;
    const float oProj = simd_dot(o, planeNormal);
    const float dProj = simd_dot(direction, planeNormal);
    const float t = oProj / dProj;
    *intersection = origin + direction * t;
    return (dProj < 0);
}

simd_float3 projectPointOnPlane( simd_float3 origin, simd_float3 normal, simd_float3 point )
{
    simd_float3 v = point - origin;
    float pn = simd_dot(v, normal);
    return point - pn * normal;
}

float pointLineDistance2(simd_float2 start, simd_float2 end, simd_float2 point) {
    simd_float2 ab = simd_normalize(end - start);
    simd_float2 ac = point - start;
    float acLength = simd_length(ac);
    ac /= acLength;
    float angle = acos(simd_dot(ab, ac));
    return acLength * sin(angle);
}

float pointLineDistance3(simd_float3 start, simd_float3 end, simd_float3 point) {
    simd_float3 ab = simd_normalize(end - start);
    simd_float3 ac = point - start;
    float acLength = simd_length(ac);
    ac /= acLength;
    float angle = acos(simd_dot(ab, ac));
    return acLength * sin(angle);
}


float angle2(simd_float2 a)
{
    float theta = atan2f(a.y, a.x);
    if(theta < 0) {
        theta += M_PI * 2.0;
    }
    return theta;
}
