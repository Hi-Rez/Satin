//
//  Bezier.h
//  Satin
//
//  Created by Reza Ali on 6/28/20.
//

#ifndef Bezier_h
#define Bezier_h

#include "Types.h"

void freePolyline2D(Polyline2D *line);

void addPointToPolyline2D(simd_float2 p, Polyline2D *line);
void removeFirstPointInPolyline2D(Polyline2D *line);
void removeLastPointInPolyline2D(Polyline2D *line);
void appendPolyline2D(Polyline2D *dst, Polyline2D *src);

Polyline2D getAdaptiveLinearPath2(simd_float2 a, simd_float2 b, float distanceLimit);

simd_float2 quadraticBezier2(simd_float2 a, simd_float2 b, simd_float2 c, float t);
simd_float2 quadraticBezierVelocity2(simd_float2 a, simd_float2 b, simd_float2 c, float t);
simd_float2 quadraticBezierAcceleration2(simd_float2 a, simd_float2 b, simd_float2 c, float t);
float quadraticBezierCurvature2(simd_float2 a, simd_float2 b, simd_float2 c, float t);

Polyline2D getQuadraticBezierPath2(simd_float2 a, simd_float2 b, simd_float2 c, int res);
Polyline2D getAdaptiveQuadraticBezierPath2(simd_float2 a, simd_float2 b, simd_float2 c,
                                           float angleLimit);

float cubicBezier1(float a, float b, float c, float d, float t);
simd_float2 cubicBezier2(simd_float2 a, simd_float2 b, simd_float2 c, simd_float2 d, float t);
simd_float2 cubicBezierVelocity2(simd_float2 a, simd_float2 b, simd_float2 c, simd_float2 d,
                                 float t);
simd_float2 cubicBezierAcceleration2(simd_float2 a, simd_float2 b, simd_float2 c, simd_float2 d,
                                     float t);
float cubicBezierCurvature2(simd_float2 a, simd_float2 b, simd_float2 c, simd_float2 d, float t);

Polyline2D getCubicBezierPath2(simd_float2 a, simd_float2 b, simd_float2 c, simd_float2 d, int res);
Polyline2D getAdaptiveCubicBezierPath2(simd_float2 a, simd_float2 b, simd_float2 c, simd_float2 d,
                                       float angleLimit);

simd_float3 quadraticBezier3(simd_float3 a, simd_float3 b, simd_float3 c, float t);
simd_float3 cubicBezier3(simd_float3 a, simd_float3 b, simd_float3 c, simd_float3 d, float t);

void freePolyline3D(Polyline3D *line);
Polyline3D convertPolyline2DToPolyline3D(Polyline2D *line);

#endif /* Bezier_h */
