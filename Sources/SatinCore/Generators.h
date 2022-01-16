//
//  Generators.h
//  Satin
//
//  Created by Reza Ali on 6/5/20.
//

#ifndef Generators_h
#define Generators_h

#include <stdio.h>
#include "Types.h"

GeometryData generateCapsuleGeometryData(float radius, float height, int angularResolution, int radialResolution, int verticalResolution, int axis); 

GeometryData generateConeGeometryData(float radius, float height, int angularResolution,
                                          int radialResolution, int verticalResolution);

GeometryData generateCylinderGeometryData(float radius, float height, int angularResolution,
                                          int radialResolution, int verticalResolution);

GeometryData generatePlaneGeometryData(float width, float height, int widthResolution,
                                       int heightResolution, int plane, bool centered);

GeometryData generateArcGeometryData(float innerRadius, float outerRadius, float startAngle,
                                     float endAngle, int angularResolution, int radialResolution);

GeometryData generateTorusGeometryData(float minorRadius, float majorRadius, int minorResolution,
                                       int majorResolution);

GeometryData generateSkyboxGeometryData(float size);

GeometryData generateCircleGeometryData(float radius, int angularResolution, int radialResolution);

GeometryData generateTriangleGeometryData(float size);

GeometryData generateQuadGeometryData(float size);

GeometryData generateSphereGeometryData(float radius, int angularResolution,
                                        int verticalResolution);

GeometryData generateIcoSphereGeometryData(float radius, int res);

GeometryData generateSquircleGeometryData(float size, float p, int angularResolution,
                                          int radialResolution);

GeometryData generateRoundedRectGeometryData(float width, float height, float radius,
                                             int angularResolution, int edgeXResolution,
                                             int edgeYResolution, int radialResolution);

GeometryData generateExtrudedRoundedRectGeometryData(float width, float height, float depth,
                                                     float radius, int angularResolution,
                                                     int edgeXResolution, int edgeYResolution,
                                                     int edgeZResolution, int radialResolution);

#endif /* Generators_h */
