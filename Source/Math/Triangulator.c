

//
//  Triangulator.c
//  Satin
//
//  Created by Reza Ali on 7/5/20.
//

#include <float.h>
#include <string.h>
#include <math.h>
#include <malloc/_malloc.h>

#include "Triangulator.h"
#include "Geometry.h"

/* Types */

typedef struct tVertexStructure tsVertex;
typedef tsVertex *tVertex;
struct tVertexStructure {
    int index;
    simd_float2 v;
    bool ear;
    tsVertex *next;
    tsVertex *prev;
};

typedef struct tPathStructure tsPath;
typedef tsPath *tPath;
struct tPathStructure {
    int index;
    int length;
    int added;
    simd_float2 *points;
    bool clockwise;
    tsPath *parent;
    tsPath *next;
    tsPath *prev;
    tsVertex *v;
};

typedef struct {
    int indexCount;
    TriangleIndices *indexData;
} TriangulationData;

/* Helper Functions */

bool _isDiagonalie(tsVertex *vertices, tsVertex *a, tsVertex *b) {
    tsVertex *c, *c1;
    c = vertices;
    do {
        c1 = c->next;
        if ((c != a) && (c1 != a) && (c != b) && (c1 != b) &&
            intersectsProper(a->v, b->v, c->v, c1->v)) {
            //            printf("_isDiagonalie failed at: %d, %d, %d, %d\n", a->index, b->index,
            //            c->index,
            //                   c1->index);
            return false;
        }
        c = c->next;
    } while (c != vertices);
    return true;
}

bool _inCone(tsVertex *a, tsVertex *b) {
    tsVertex *a0, *a1;
    a1 = a->next;
    a0 = a->prev;
    if (isLeftOn(a->v, a1->v, a0->v)) {
        return isLeft(a->v, b->v, a0->v) && isLeft(b->v, a->v, a1->v);
    }
    return !(isLeftOn(a->v, b->v, a1->v) && isLeftOn(b->v, a->v, a0->v));
}

bool _isDiagonal(tsVertex *vertices, tsVertex *a, tsVertex *b) {
    //    bool i0 = _inCone(a, b);
    //    bool i1 = _inCone(b, a);
    //    bool i2 = _isDiagonalie(vertices, a, b);
    //    printf("inCone: \t\t%d\ninCone: \t\t%d\nisDiagonalie: \t%d\n", i0, i1, i2);
    return _inCone(a, b) && _inCone(b, a) && _isDiagonalie(vertices, a, b);
}

bool insidePath2(tsPath *path, tsVertex *vertex) {
    bool inside = false;
    tsVertex *vertices = path->v;
    tsVertex *curr = vertices;
    simd_float2 pt = vertex->v;
    do {
        simd_float2 v0 = curr->v;
        simd_float2 v1 = curr->next->v;
        if (((v0.y > pt.y) != (v1.y > pt.y)) &&
            (pt.x < ((v1.x - v0.x) * (pt.y - v0.y) / (v1.y - v0.y) + v0.x))) {
            inside = !inside;
        }
        curr = curr->next;
    } while (curr != vertices);
//    printf("In polygon: %d, %d\n", path->index, inside);
    return inside;
}

/* Creator Functions */

tsVertex *createVertexStructure(simd_float2 *path, int length, int indexOffset, int localOffset,
                                GeometryData *data) {

    tsVertex *vertices = (tsVertex *)malloc(sizeof(tsVertex) * length);

    if (data->vertexCount == 0) {
        data->vertexData = (Vertex *)malloc(sizeof(Vertex) * length);
        data->vertexCount = length;
    } else {
        int totalCount = length + data->vertexCount;
        data->vertexData = (Vertex *)realloc(data->vertexData, sizeof(Vertex) * totalCount);
        data->vertexCount = totalCount;
    }

//    printf("indexOffset: %d, localOffset: %d\n", indexOffset, localOffset);
    for (int i = 0; i < length; i++) {
        int next = (i + 1) % length;
        int prev = (i - 1) < 0 ? (length - 1) : (i - 1);

        vertices[i] = (tsVertex){
            .index = (i + indexOffset),
            .v = path[i],
            .ear = false,
            .next = &vertices[next],
            .prev = &vertices[prev],
        };

//        printf("(%f, %f)\n", path[i].x, path[i].y);
        data->vertexData[localOffset + i] =
            (Vertex){.position = simd_make_float4(path[i].x, path[i].y, 0.0, 1.0),
                     .normal = simd_make_float3(0.0, 0.0, 1.0),
                     .uv = simd_make_float2(0.0, 0.0) };
    }
//    printf("\n");

    return vertices;
}

tsPath *createPathStructure(simd_float2 **paths, int *lengths, int count, int indexOffset,
                            GeometryData *data) {
//    for (int i = 0; i < count; i++) {
//        int length = lengths[i];
//        simd_float2 *path = paths[i];
//        printf("createPathStructure Path Index: %d, Length: %d\n", i, length);
//        for (int j = 0; j < length; j++) {
//            printf("(%f, %f)\n", path[j].x, path[j].y);
//        }
//        printf("\n");
//    }
    tsPath *result = (tsPath *)malloc(sizeof(tsPath) * count);
    int localOffset = 0;
    for (int i = 0; i < count; i++) {
        simd_float2 *path = paths[i];
        //        printf("createPathStructure index: %d, first point: %f, %f\n", i, path[0].x,
        //        path[0].y);
        int length = lengths[i];
        int next = (i + 1) % count;
        int prev = (i - 1) < 0 ? (count - 1) : (i - 1);
        result[i] =
            (tsPath){.index = i,
                     .length = length,
                     .added = 0,
                     .points = path,
                     .clockwise = isClockwise(path, length),
                     .parent = NULL,
                     .next = &result[next],
                     .prev = &result[prev],
                     .v = createVertexStructure(path, length, indexOffset, localOffset, data) };
        indexOffset += length;
        localOffset += length;
    }
    return result;
}

/* Memory Deallocations Functions */

void freeTriangulationData(TriangulationData data) {
    if (data.indexCount > 0 && data.indexData == NULL) { return; }
    free(data.indexData);
}

void freePathVertexStructure(tsPath *paths, int count) {
    tsPath *path = paths;
    for (int i = 0; i < count; i++) {
        if (path->v != NULL) {
            //            printf("freeing path index: %d, length: %d\n", path->index, path->length);
            free(path->v);
            path->v = NULL;
        }
        path++;
    }
}

/* Memory Appending Functions */

void appendVertexData(GeometryData *gDataDest, GeometryData *gDataSrc) {
    if (gDataSrc->vertexCount > 0) {
        if (gDataDest->vertexCount > 0) {
            int totalCount = gDataSrc->vertexCount + gDataDest->vertexCount;
            gDataDest->vertexData = realloc(gDataDest->vertexData, totalCount * sizeof(Vertex));
            memcpy(gDataDest->vertexData + gDataDest->vertexCount, gDataSrc->vertexData,
                   gDataSrc->vertexCount * sizeof(Vertex));
            gDataDest->vertexCount += gDataSrc->vertexCount;
        } else {
            gDataDest->vertexData = (Vertex *)malloc(gDataSrc->vertexCount * sizeof(Vertex));
            memcpy(gDataDest->vertexData, gDataSrc->vertexData,
                   gDataSrc->vertexCount * sizeof(Vertex));
            gDataDest->vertexCount = gDataSrc->vertexCount;
        }
    }
}

void appendIndexData(GeometryData *gDataDest, GeometryData *gDataSrc) {
    if (gDataSrc->indexCount > 0) {
        if (gDataDest->indexCount > 0) {
            int totalCount = gDataSrc->indexCount + gDataDest->indexCount;
            gDataDest->indexData =
                realloc(gDataDest->indexData, totalCount * sizeof(TriangleIndices));
            memcpy(gDataDest->indexData + gDataDest->indexCount, gDataSrc->indexData,
                   gDataSrc->indexCount * sizeof(TriangleIndices));
            gDataDest->indexCount += gDataSrc->indexCount;
        } else {
            gDataDest->indexData =
                (TriangleIndices *)malloc(sizeof(TriangleIndices) * gDataSrc->indexCount);
            memcpy(gDataDest->indexData, gDataSrc->indexData,
                   sizeof(TriangleIndices) * gDataSrc->indexCount);
            gDataDest->indexCount = gDataSrc->indexCount;
        }
    }
}

void appendTriangulationData(GeometryData *gDataDest, TriangulationData *tDataSrc) {
    if (tDataSrc->indexCount > 0) {
        if (gDataDest->indexCount > 0) {
            int totalCount = tDataSrc->indexCount + gDataDest->indexCount;
            gDataDest->indexData =
                realloc(gDataDest->indexData, totalCount * sizeof(TriangleIndices));
            memcpy(gDataDest->indexData + gDataDest->indexCount, tDataSrc->indexData,
                   tDataSrc->indexCount * sizeof(TriangleIndices));
            gDataDest->indexCount += tDataSrc->indexCount;
        } else {
            gDataDest->indexData =
                (TriangleIndices *)malloc(sizeof(TriangleIndices) * tDataSrc->indexCount);
            memcpy(gDataDest->indexData, tDataSrc->indexData,
                   sizeof(TriangleIndices) * tDataSrc->indexCount);
            gDataDest->indexCount = tDataSrc->indexCount;
        }
    }
}

void appendGeometryData(GeometryData *gDataDest, GeometryData *gDataSrc) {
    appendVertexData(gDataDest, gDataSrc);
    appendIndexData(gDataDest, gDataSrc);
}

/* Initializer Functions */

int initalizeEars(tsVertex *vertices) {
    tsVertex *v0, *v1, *v2;
    v1 = vertices;
    int ears = 0;
    do {
        v0 = v1->prev;
        v2 = v1->next;
        v1->ear = _isDiagonal(vertices, v0, v2);
        ears += (v1->ear == true) ? 1 : 0;
//        printf("\n\nEar Test: %d, %d, %d\n", v0->index, v1->index, v2->index);
//        printf("Ear Index: %d\n", v1->index);
//        printf("is Ear: %d\n\n\n", v1->ear);
        v1 = v1->next;
    } while (v1 != vertices);
    //    printf("# of ears: %d\n", ears);
    return ears;
}

/* Triangulation Functions */

void reversePath(tsPath *path) {
    tsVertex *head = path->v;
    tsVertex *curr = head;

    do {
        tsVertex *prev = curr->prev;
        tsVertex *next = curr->next;
        curr->next = prev;
        curr->prev = next;
        curr = curr->next;
    } while (curr != head);

    path->clockwise = !path->clockwise;
}

bool combineOuterAndInnerPaths(tsPath *outerPath, tsPath *innerPath, tsVertex *pool,
                               int *poolLength) {
    tsVertex *oData = outerPath->v;
    tsVertex *iData = innerPath->v;

    // find the right most inner vertex (if tie take lowest the vertex in the y direction)
    tsVertex *rightInner = iData;
    tsVertex *inner = iData;
    do {
        if (inner->v.x > rightInner->v.x) {
            rightInner = inner;
        } else if (isEqual(rightInner->v.x, inner->v.x) && inner->v.y < rightInner->v.y) {
            rightInner = inner;
        }
        inner = inner->next;
    } while (inner != iData);

    //    // this is checked before so the outer path will always contain the inner path and both
    //    paths
    //    // will be oriented properly
    //    if (!insidePath2(outerPath, rightInner)) {
    //        printf("returning since inner path %d isn't contained in outer path %d\n",
    //        innerPath->index,
    //               outerPath->index);
    //        return false;
    //    }

    tsVertex *rightOuter = NULL;    
    tsVertex *outer = oData;

    float intersectionDistance = FLT_MAX;
    simd_float2 rightInnerPosExt = rightInner->v + simd_make_float2(FLT_MAX - rightInner->v.x, 0.0);
    int intersectionCount = 0;
    do {
        if (!isColinear2(rightInner->v, outer->v, outer->next->v) && intersects(rightInner->v, rightInnerPosExt, outer->v, outer->next->v)) {
            
            intersectionCount++;
            if(rightOuter != NULL && isColinear2(rightInner->v, rightOuter->next->v, outer->v)) {
                intersectionCount--;
            }
            
            float dist = pointLineDistance2(outer->v, outer->next->v, rightInner->v);
//            printf("intersection %d, %d time: %f\n", outer->index, outer->next->index, dist);
            if (dist <= intersectionDistance) {
                intersectionDistance = dist;
                // in case the intersection happens right on the vertex
                rightOuter = outer;
            }
//            printf("found an intersection: %d, %d, %f\n", outer->index, outer->next->index, dist);
        }
        outer = outer->next;
    } while (outer != oData);

//    printf("\nIntersections: %d at: %d\n\n", intersectionCount, rightOuter == NULL ? -1 : rightOuter->index);

    if (intersectionCount %2 == 0) {
        rightOuter = NULL;
    }

//    printf("right most inner index: %d %f %f\n", rightInner->index, rightInner->v.x, rightInner->v.y);

    // connect paths if valid
    if (rightOuter != NULL) {
//        printf("\nCombining paths at outer: %d, inner: %d\n", rightOuter->index, rightInner->index);
        
        // add new vertices to pool
        int pl = *poolLength;
        pool = (tsVertex *)realloc(pool, sizeof(tsVertex) * (pl + 2));

        tsVertex *rO = (pool + pl);
        tsVertex *rI = (pool + pl + 1);

        *poolLength = pl + 2;

        // new right outer vertex to inner right vertex
        //        tsVertex *rO = (tsVertex *)malloc(sizeof(tsVertex));
        rO->index = rightOuter->index;
        rO->v = rightOuter->v;
        rO->ear = rightOuter->ear;
        rO->prev = rightOuter->prev;
        rO->next = rightInner;

        // new inner vertex to outer right vertex
        //        tsVertex *rI = (tsVertex *)malloc(sizeof(tsVertex));
        rI->index = rightInner->index;
        rI->v = rightInner->v;
        rI->ear = rightInner->ear;
        rI->prev = rightInner->prev;
        rI->next = rightOuter;

        // fix outer points
        rightOuter->prev->next = rO;
        rightOuter->prev = rI;

        // fix inner points
        rightInner->prev->next = rI;
        rightInner->prev = rO;

        // set path length (+2 because of virtual vertices add)
        outerPath->length += innerPath->length;
        outerPath->added += 2;

        innerPath->parent = outerPath;
        return true;
    }

    return false;
}

// added represents the number of addition verticies added to connect an outer path to an inner path
int _triangulate(tsVertex *vertices, int count, int added, TriangulationData *data) {
//    printf("\n\n\n");
    int ears = initalizeEars(vertices);
    if (ears == 0) {
//        printf("invalid polygon\n");
        return 1;
    }
//    printf("\n\n\n");

    int triangleIndex = 0;
    data->indexCount = count + added - 2;
    data->indexData = (TriangleIndices *)malloc(sizeof(TriangleIndices) * data->indexCount);

    tsVertex *v0, *v1, *v2 = vertices, *v3, *v4;
    int n = count + added;

    int indexCache = 0;
    int nCache = 0;
    int lastN = -1;
    int lastIndex = -1;

    while (n > 3) {
        v2 = vertices;

        // these can be removed when the triangulator is rock solid, otherwise if triangulation fails, your program will crash completely
        if (n != lastN) {
            lastN = n;
            nCache = 0;
        } else {
            nCache++;
        }

        if (v2->index != lastIndex) {
            lastIndex = v2->index;
            indexCache = 0;
        } else {
            indexCache++;
        }

        if (nCache > 1 && indexCache > 1) {
//            printf("\n\n\nbreaking at n: %d index: %d\n\n\n", n, v2->index);
            return 1;
        }

//        printf("\nIndex: %d, %d\n", v2->index, n);
        do {
            if (v2->ear) {
                v3 = v2->next;
                v4 = v3->next;
                v1 = v2->prev;
                v0 = v1->prev;

//                printf("Ear @ Index: %d\n", triangleIndex);
//                printf("\nAdding Triangle: %d, %d, %d\n", v1->index, v2->index, v3->index);

                // add triangle
                data->indexData[triangleIndex] = (TriangleIndices){.i0 = v1->index, .i1 = v2->index, .i2 = v3->index };
                triangleIndex++;

                v1->ear = _isDiagonal(vertices, v0, v3);
                v3->ear = _isDiagonal(vertices, v1, v4);

                v1->next = v3;
                v3->prev = v1;

                vertices = v3;
                n--;
                break;
            }
            v2 = v2->next;
        } while (v2 != vertices);
    }

    v2 = v2->next;
    v3 = v2->next;
    v1 = v2->prev;
//    printf("\nAdding Triangle: %d, %d, %d\n", v1->index, v2->index, v3->index);
    data->indexData[triangleIndex] =
        (TriangleIndices){.i0 = v1->index, .i1 = v2->index, .i2 = v3->index };
    triangleIndex++;

    return 0;
}

int triangulate(simd_float2 **paths, int *lengths, int count, GeometryData *gData) {
//    printf("number of paths:%d\n", count);
    int success = 0;
    GeometryData geometryData =
        (GeometryData){.vertexCount = 0, .vertexData = NULL, .indexCount = 0, .indexData = NULL };

    //    for (int i = 0; i < count; i++) {
    //        int length = lengths[i];
    //        simd_float2 *path = paths[i];
    //        printf("Path Index: %d, Length: %d\n", i, length);
    //        for (int j = 0; j < length; j++) {
    //            printf("(%f, %f)\n", path[j].x, path[j].y);
    //        }
    //        printf("\n");
    //    }

    tsPath *pData = createPathStructure(paths, lengths, count, gData->vertexCount, &geometryData);
//    printf("Created Path Structure\n");

    tsVertex *pool = NULL;
    int poolLength = 0;
//    printf("Set Up Memory Pool\n");
    
    //this makes sure that if paths are within other paths, they are oriented properly, optimized so look out for j = i + 1 when modifying
    for (int i = 0; i < count; i++) {
        tsPath *a = pData + i;
        for (int j = i + 1; j < count; j++) {
            tsPath *b = pData + j;
//            printf("A: %d, B: %d\n", a->index, b->index);
            if (insidePath2(a, b->v)) {
//                printf("B %d is inside of A: %d\n", b->index, a->index);
                if (a->clockwise) { reversePath(a); }
                if (!b->clockwise) { reversePath(b); }
            }
            if (insidePath2(b, a->v)) {
//                printf("A %d is inside of B: %d\n", a->index, b->index);
                if (b->clockwise) { reversePath(b); }
                if (!a->clockwise) { reversePath(a); }
            }
        }
    }

    if (pData->clockwise && count == 1) { reversePath(pData); }

    tsPath *head = pData;
    // pick a head that isn't an inner loop
    do {
        if (!head->clockwise) { break; }
        head = head->next;
    } while (head != pData);

    // combine paths that are inside outer paths
    tsPath *curr = head;
    tsPath *next = curr->next;
    tsPath *last = curr;
    do {
//        printf("\nouter loop start curr: %d, next: %d last:%d\n", curr->index, next->index, last->index);
        do {
//            printf("curr: %d, next: %d\n", curr->index, next->index);
//            printf("pre path index: %d, length: %d, clockwise: %d\n", curr->index, curr->length, curr->clockwise);
//            printf("pre next path index: %d, length: %d, clockwise: %d\n", next->index, next->length, next->clockwise);
            if (curr != next && (curr->clockwise ^ next->clockwise)) {
//                printf("checking if paths can be combined: %d, %d\n", curr->index, next->index);
                if (combineOuterAndInnerPaths(curr, next, pool, &poolLength)) {
//                    printf("\ncombined paths: %d, %d\n\n", curr->index, next->index);
                    tsPath *nextPrev = next->prev;
                    tsPath *nextNext = next->next;
                    nextPrev->next = nextNext;
                    nextNext->prev = nextPrev;
                    head = curr;
                }
            }
//            printf("post path index: %d, length: %d, clockwise: %d\n", curr->index, curr->length, curr->clockwise);
            next = next->next;
        } while (next != curr);

        curr = curr->next;
        last = curr;
        next = curr->next;
//        printf("outer loop end curr: %d, next: %d last:%d\n\n", curr->index, next->index, last->index);
    } while (curr != head);

    for (int i = 0; i < count; i++) {
        tsPath *path = pData + i;
        bool triangulate = false;
        if (!path->clockwise) {
            triangulate = true;
        }
        // this condition means that the direction was reversed and this path didn't contain any
        // other paths so it wasn't flipped
        else if (path->parent == NULL) {
            reversePath(path);
            triangulate = true;
        }

        if (triangulate) {
//            printf("Triangulating path: %d, clockwise: %d\n", path->index, path->clockwise);
            TriangulationData triData = (TriangulationData) { .indexCount = 0, .indexData = NULL };
            success += _triangulate(path->v, path->length, path->added, &triData);
            appendTriangulationData(&geometryData, &triData);
            freeTriangulationData(triData);
        }
    }

    appendGeometryData(gData, &geometryData);
    freeGeometryData(&geometryData);
    if (pData != NULL) {
        freePathVertexStructure(pData, count);
        free(pData);
    }
    if (poolLength > 0) { free(pool); }
    
    return success;
}
