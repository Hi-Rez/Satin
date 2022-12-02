//
//  Rectangle.c
//  Satin
//
//  Created by Reza Ali on 12/2/22.
//

#include <stdio.h>
#include <simd/simd.h>

#include "Rectangle.h"
#include "Bounds.h"

Rectangle createRectangle(void) {
    return (Rectangle) { .min = { INFINITY, INFINITY }, .max = { -INFINITY, -INFINITY } };
}

Rectangle expandRectangle(Rectangle rect, simd_float2 pt) {
    return (Rectangle) { .min = simd_min(rect.min, pt), .max = simd_max(rect.max, pt) };
}

Rectangle mergeRectangle(Rectangle a, Rectangle b) {
    simd_float2 min = a.min, max = a.max;
    for (int i = 0; i < 3; i++) {
        if (b.min[i] != INFINITY) { min[i] = simd_min(a.min[i], b.min[i]); }
        if (b.max[i] != -INFINITY) { max[i] = simd_max(a.max[i], b.max[i]); }
    }
    return (Rectangle) { .min = min, .max = max };
}

void mergeRectangleInPlace(Rectangle *a, const Rectangle *b) {
    for (int i = 0; i < 2; i++) {
        if (b->min[i] != INFINITY) { a->min[i] = simd_min(a->min[i], b->min[i]); }
        if (b->max[i] != -INFINITY) { a->max[i] = simd_max(a->max[i], b->max[i]); }
    }
}

void expandRectangleInPlace(Rectangle *rect, const simd_float2 *pt) {
    rect->min = simd_min(rect->min, *pt);
    rect->max = simd_max(rect->max, *pt);
}

bool rectangleContainsPoint(Rectangle rect, simd_float2 pt) {
    return (pt.x <= rect.max.x) && (pt.y <= rect.max.y) && (pt.x >= rect.min.x) &&
           (pt.y >= rect.min.y);
}

bool rectangleContainsRectangle(Rectangle a, Rectangle b) {
    for (int i = 0; i < 4; i++) {
        if (!rectangleContainsPoint(a, rectangleCorner(&b, i))) { return false; }
    }
    return true;
}

bool rectangleIntersectsRectangle(Rectangle a, Rectangle b) {
    for (int i = 0; i < 4; i++) {
        if (rectangleContainsPoint(a, rectangleCorner(&b, i)) ||
            rectangleContainsPoint(b, rectangleCorner(&a, i))) {
            return true;
        }
    }
    return false;
}

Rectangle projectBoundsToRectangle(Bounds a, simd_float4x4 transform) {
    Rectangle result = createRectangle();
    simd_float4 pt;
    simd_float2 pt2;
    for (int i = 0; i < 8; i++) {
        pt = simd_mul(transform, boundsCorner(a, i));
        pt /= pt.w;
        pt2 = pt.xy;
        expandRectangleInPlace(&result, &pt2);
    }
    return result;
}
