//
//  GeometryUtilities.h
//  Satin
//
//  Created by Reza Ali on 6/5/20.
//

#ifndef GeometryUtilities_h
#define GeometryUtilities_h

#include <stdio.h>
#include "Vertex.h"

typedef struct {
    uint32_t i0;
    uint32_t i1;
    uint32_t i2;
} TriangleIndices;

typedef struct {
    int vertexCount;
    Vertex *vertexData;
    int indexCount;
    TriangleIndices *indexData;
} GeometryData;

void freeGeometryData( GeometryData geometry );

GeometryData generateIcoSphereGeometryData(float radius, int res);

#endif /* GeometryUtilities_h */
