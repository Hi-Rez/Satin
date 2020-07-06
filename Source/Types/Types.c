//
//  Types.c
//  Satin
//
//  Created by Reza Ali on 7/5/20.
//

#include "Types.h"

void freeGeometryData(GeometryData geometry) {
    if (geometry.vertexCount > 0 && geometry.vertexData == NULL) { return; }
    free(geometry.vertexData);

    if (geometry.indexCount > 0 && geometry.indexData == NULL) { return; }
    free(geometry.indexData);
}
