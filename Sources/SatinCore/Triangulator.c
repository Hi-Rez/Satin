

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
#include <simd/simd.h>
#include <simd/quaternion.h>

#include "Triangulator.h"
#include "Geometry.h"

//#define DEBUGDIAGONAL
//#define DEBUGTRIANGULATION
//#define DEBUGCOMBINEPATHS
//#define DEBUGINITALIZEEARS
#define ALLOWFAILEDTRIAGULATIONS

/* Types */

typedef struct tVertexStructure tsVertex;
struct tVertexStructure {
    int index;
    simd_float2 v;
    bool ear;
    bool virtual;
    tsVertex *next;
    tsVertex *prev;
};

typedef struct tPathStructure tsPath;
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
        if ((c != a) && (c1 != a) && (c != b) && (c1 != b)) {
            if (isBetween(a->v, b->v, c->v) && isBetween(a->v, b->v, c1->v)) { return false; }
            if (intersectsProper(a->v, b->v, c->v, c1->v)) { return false; }
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
        return isLeftOn(a->v, b->v, a0->v) && isLeftOn(b->v, a->v, a1->v);
    }
    return !(isLeftOn(a->v, b->v, a1->v) && isLeftOn(b->v, a->v, a0->v));
}

bool _isDiagonal(tsVertex *vertices, tsVertex *a, tsVertex *b) {
    const bool i0 = _inCone(a, b);
    const bool i1 = _inCone(b, a);
    const bool i2 = _isDiagonalie(vertices, a, b);
#ifdef DEBUGDIAGONAL
    printf("inCone: \t\t%d\ninCone: \t\t%d\nisDiagonalie: \t%d\n", i0, i1, i2);
#endif
    return i0 && i1 && i2;
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

tsVertex *createVertexStructureFromPath(simd_float2 *path, int length, int indexOffset,
                                        int localOffset, GeometryData *data) {

    const float lengthMinusOne = length - 1.0;
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
        const int next = (i + 1) % length;
        const int prev = (i - 1) < 0 ? (length - 1) : (i - 1);

        vertices[i] = (tsVertex) {
            .index = (i + indexOffset),
            .v = path[i],
            .ear = false,
            .next = &vertices[next],
            .prev = &vertices[prev],
        };

        //        printf("(%f, %f)\n", path[i].x, path[i].y);
        data->vertexData[localOffset + i] =
            (Vertex) { .position = simd_make_float4(path[i].x, path[i].y, 0.0, 1.0),
                       .normal = simd_make_float3(0.0, 0.0, 1.0),
                       .uv = simd_make_float2((float)i / lengthMinusOne, 0.0) };
    }
    //    printf("\n");

    return vertices;
}

tsPath *createPathStructureFromPaths(simd_float2 **paths, int *lengths, int count, int indexOffset,
                                     GeometryData *data) {
    tsPath *result = (tsPath *)malloc(sizeof(tsPath) * count);
    int localOffset = 0;
    for (int i = 0; i < count; i++) {
        simd_float2 *path = paths[i];
        const int length = lengths[i];
        const int next = (i + 1) % count;
        const int prev = (i - 1) < 0 ? (count - 1) : (i - 1);
        result[i] = (tsPath) { .index = i,
                               .length = length,
                               .added = 0,
                               .points = path,
                               .clockwise = isClockwise(path, length),
                               .parent = NULL,
                               .next = &result[next],
                               .prev = &result[prev],
                               .v = createVertexStructureFromPath(path, length, indexOffset,
                                                                  localOffset, data) };
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
#ifdef DEBUGINITALIZEEARS
        printf("\n\nEar Test: %d, %d, %d\n", v0->index, v1->index, v2->index);
        printf("Ear Index: %d\n", v1->index);
        printf("is Ear: %d\n\n\n", v1->ear);
#endif
        v1 = v1->next;
    } while (v1 != vertices);
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

    tsVertex *rightOuter = NULL;
    tsVertex *rightOuterNext = NULL;
    tsVertex *outer = oData;
#ifdef DEBUGCOMBINEPATHS
    printf("Right Inner Index: %d\n", rightInner->index);
#endif

    float intersectionDistance = FLT_MAX;
    simd_float2 rightInnerPosExt = rightInner->v + simd_make_float2(FLT_MAX - rightInner->v.x, 0.0);
    int intersectionCount = 0;
    do {
        if (!isColinear2(rightInner->v, outer->v, outer->next->v) &&
            intersects(rightInner->v, rightInnerPosExt, outer->v, outer->next->v)) {
            intersectionCount++;

            if (isColinear2(rightInner->v, rightInnerPosExt, outer->v)) {
                if (rightOuter != NULL && rightOuterNext->index == outer->index) {
#ifdef DEBUGCOMBINEPATHS
                    printf("we have overlapping intersections at: %d\n", outer->index);
#endif
                    intersectionCount++;
                } else if (!isColinear2(rightInner->v, outer->v, outer->next->v)) {
#ifdef DEBUGCOMBINEPATHS
                    printf("intersection is colinear at outer: %d\n", outer->index);
#endif
                    intersectionCount++;
                }
            }

            float dist = pointLineDistance2(outer->v, outer->next->v, rightInner->v);
#ifdef DEBUGCOMBINEPATHS
            printf("intersection index: %d, next: %d time: %f\n", outer->index, outer->next->index,
                   dist);
#endif
            if (dist <= intersectionDistance) {
#ifdef DEBUGCOMBINEPATHS
                printf("setting right outer: %d & right outer next: %d\n", outer->index,
                       outer->next->index);
#endif
                intersectionDistance = dist;
                rightOuter = outer;
                rightOuterNext = outer->next;
            }
        }
        outer = outer->next;
    } while (outer != oData);
#ifdef DEBUGCOMBINEPATHS
    printf("\nIntersections: %d at: %d\n\n", intersectionCount,
           rightOuter == NULL ? -1 : rightOuter->index);
#endif
    if (intersectionCount % 2 == 0) { rightOuter = NULL; }
#ifdef DEBUGCOMBINEPATHS
    printf("Right most inner index: %d %f %f\n", rightInner->index, rightInner->v.x,
           rightInner->v.y);
#endif

    // connect paths if valid
    if (rightOuter != NULL) {
#ifdef DEBUGCOMBINEPATHS
        printf("\nCombining paths at outer: %d, inner: %d\n", rightOuter->index, rightInner->index);
#endif
        // add new vertices to pool
        int pl = *poolLength;
        pool = (tsVertex *)realloc(pool, sizeof(tsVertex) * (pl + 2));

        tsVertex *rightOuterNew = (pool + pl);
        rightOuterNew->index = rightOuter->index;
        rightOuterNew->v = rightOuter->v;
        rightOuterNew->ear = rightOuter->ear;
        rightOuterNew->virtual = true;

        tsVertex *rightInnerNew = (pool + pl + 1);
        rightInnerNew->index = rightInner->index;
        rightInnerNew->v = rightInner->v;
        rightInnerNew->ear = rightInner->ear;
        rightInnerNew->virtual = true;

        *poolLength = pl + 2;

        //        // Relink path with new virtual vertices rO, rI
        //
        //        tsVertex *rightOuterNext = rightOuter->next;
        //        tsVertex *rightInnerPrev = rightInner->prev;
        //
        //        rightInnerPrev->next = rightInnerNew;
        //        rightOuterNext->prev = rightOuterNew;
        //
        //        rightOuterNew->prev = rightInnerNew;
        //        rightOuterNew->next = rightOuterNext;
        //
        //        rightInnerNew->prev = rightInnerPrev;
        //        rightInnerNew->next = rightOuterNew;
        //
        //
        //        rightOuter->next = rightInner;
        //        rightInner->prev = rightOuter;

        //         Relink path with new virtual vertices rO, rI (interlink virtual vertices)

        tsVertex *rightOuterNext = rightOuter->next;
        tsVertex *rightInnerNext = rightInner->next;

        // 0
        rightOuter->next = rightInnerNew;
        rightInnerNew->prev = rightOuter;

        // 1
        rightInnerNew->next = rightInnerNext;
        rightInnerNext->prev = rightInnerNew;

        // 2
        rightInner->next = rightOuterNew;
        rightOuterNew->prev = rightInner;

        // 3
        rightOuterNew->next = rightOuterNext;
        rightOuterNext->prev = rightOuterNew;

        // Set path length (+2 because of virtual vertices add)
        outerPath->length += innerPath->length;
        outerPath->added += 2;

        innerPath->parent = outerPath;
        return true;
    }

    return false;
}

void combinePaths(tsPath *pData, int count, tsVertex *pool, int *poolLength) {
    for (int i = 0; i < count; i++) {
        tsPath *a = pData + i;
        for (int j = i + 1; j < count; j++) {
            tsPath *b = pData + j;
#ifdef DEBUGTRIANGULATION
            printf("Count: %d, i: %d, j: %d\n", count, i, j);
            printf("A: %d, B: %d\n", a->index, b->index);
#endif
            if (b->parent == NULL && insidePath2(a, b->v)) {
#ifdef DEBUGTRIANGULATION
                printf("B %d is inside of A: %d\n", b->index, a->index);
#endif
                if (a->clockwise) {
                    reversePath(a);
#ifdef DEBUGTRIANGULATION
                    printf("Reversed a: %d clockwise: %d\n", a->index, a->clockwise);
#endif
                }

                if (!b->clockwise) {
                    reversePath(b);
#ifdef DEBUGTRIANGULATION
                    printf("Reversed b: %d clockwise: %d\n", b->index, b->clockwise);
#endif
                }

                if (combineOuterAndInnerPaths(a, b, pool, poolLength)) {
#ifdef DEBUGTRIANGULATION
                    printf("\nCombined Paths: %d, %d\n\n", a->index, b->index);
#endif
                }
            } else if (a->parent == NULL && insidePath2(b, a->v)) {
#ifdef DEBUGTRIANGULATION
                printf("A %d is inside of B: %d\n", a->index, b->index);
#endif
                if (!a->clockwise) {
                    reversePath(a);
#ifdef DEBUGTRIANGULATION
                    printf("Reversed a: %d clockwise: %d\n", a->index, a->clockwise);
#endif
                }

                if (b->clockwise) {
                    reversePath(b);
#ifdef DEBUGTRIANGULATION
                    printf("Reversed b: %d clockwise: %d\n", b->index, b->clockwise);
#endif
                }

                if (combineOuterAndInnerPaths(b, a, pool, poolLength)) {
#ifdef DEBUGTRIANGULATION
                    printf("\nCombined Paths: %d, %d\n\n", b->index, a->index);
#endif
                }
            }
        }
    }
}

// Added represents the number of addition verticies added to connect an outer path to an inner path
int _triangulate(tsVertex *vertices, int count, int added, TriangulationData *data) {
    if (initalizeEars(vertices) == 0) {
        printf("Invalid Polygon: Doesn't have any ears.\n");
        return 1;
    }

#ifdef DEBUGTRIANGULATION
    printf("\n");
    tsVertex *head = vertices;
    do {
        printf("%d ", head->index);
        head = head->next;
    } while (head != vertices);
    printf("\n");
#endif

    int triangleIndex = 0;
    data->indexCount = count + added - 2;
    data->indexData = (TriangleIndices *)malloc(sizeof(TriangleIndices) * data->indexCount);

    tsVertex *v0, *v1, *v2 = vertices, *v3, *v4;
    int n = count + added;
//    int n = count;
#ifdef ALLOWFAILEDTRIAGULATIONS
    int indexCache = 0;
    int nCache = 0;
    int lastN = -1;
    int lastIndex = -1;
#endif

    while (n > 3) {
        v2 = vertices;
#ifdef ALLOWFAILEDTRIAGULATIONS
        // these can be removed when the triangulator is rock solid, otherwise if triangulation
        // fails, your program will crash completely
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
#ifdef DEBUGTRIANGULATION
            printf("\n\nBreaking at n: %d index: %d\n\n", n, v2->index);
            tsVertex *head = v2;
            do {
                printf("%d ", head->index);
                head = head->next;
            } while (head != vertices);
            printf("\n");
#endif
            return 2;
        }
#endif

        do {
            if (v2->ear) {
                v3 = v2->next;
                v4 = v3->next;
                v1 = v2->prev;
                v0 = v1->prev;
#ifdef DEBUGTRIANGULATION
                printf("\nLeft: %d\n", n - 1);
                printf("v0: %d, v1: %d, v2: %d, v3: %d, v4: %d\n", v0->index, v1->index, v2->index,
                       v3->index, v4->index);
                printf("Ear @ Index: %d\n", triangleIndex);
                printf("Adding Triangle: %d, %d, %d\n", v1->index, v2->index, v3->index);

#endif
                // add triangle
                data->indexData[triangleIndex] =
                    (TriangleIndices) { .i0 = v1->index, .i1 = v2->index, .i2 = v3->index };
                triangleIndex++;

                v1->next = v3;
                v3->prev = v1;

                vertices = v3;

                v1->ear = _isDiagonal(vertices, v1->prev, v1->next);
                v3->ear = _isDiagonal(vertices, v3->prev, v3->next);

#ifdef DEBUGTRIANGULATION
                printf("v0: %d, v1: %d, v2: %d, v3: %d, v4: %d\n", v0->index, v1->index, v2->index,
                       v3->index, v4->index);
                printf("v1->prev: %d, v1: %d, v1->next: %d, ear: %d\n", v1->prev->index, v1->index,
                       v1->next->index, v1->ear);
                printf("v3->prev: %d, v3: %d, v3->next: %d, ear: %d\n", v3->prev->index, v3->index,
                       v3->next->index, v3->ear);
                printf("\n");

                tsVertex *start = v1;
                tsVertex *head = v1;
                do {
                    printf("%d ", head->index);
                    head = head->next;
                } while (head != start);
                printf("\n");

#endif
                n--;
                break;
            }

            v2 = v2->next;
        } while (v2 != vertices);
    }

    v2 = v2->next;
    v3 = v2->next;
    v1 = v2->prev;
#ifdef DEBUGTRIANGULATION
    printf("Adding last triangle: %d, %d, %d\n", v1->index, v2->index, v3->index);
#endif
    data->indexData[triangleIndex] =
        (TriangleIndices) { .i0 = v1->index, .i1 = v2->index, .i2 = v3->index };
    return 0;
}

bool isVertexStructureClockwise(tsVertex *vertices, int length) {
    float area = 0;
    for (int i = 0; i < length; i++) {
        int i0 = i;
        int i1 = (i + 1) % length;
        simd_float2 a = vertices[i0].v;
        simd_float2 b = vertices[i1].v;
        area += (b.x - a.x) * (b.y + a.y);
    }
    return !signbit(area);
}

void reverseStructure(tsVertex *structure) {
    tsVertex *head = structure;
    tsVertex *curr = structure;

    do {
        tsVertex *prev = curr->prev;
        tsVertex *next = curr->next;
        curr->next = prev;
        curr->prev = next;
        curr = next;
    } while (curr != head);
}

tsVertex *createVertexStructure(Vertex *vertices, const uint32_t *face, int length) {
    //    printf("face length: %d\n", length);
    //    printf("CREATING VERTEX STRUCTURE!\n\n");
    //
    //    printf("face indicies: ");
    //    for (int i = 0; i < length; i++) {
    //        printf("%d ", face[i]);
    //    }
    //    printf("\n");

    // Calculate normal
    simd_float3 n = simd_make_float3(0.0, 0.0, 0.0);

    for (int i = 0; i < length; i++) {
        int i0 = i;
        int i1 = (i + 1) % length;
        int i2 = (i + 2) % length;

        uint32_t index0 = face[i0];
        uint32_t index1 = face[i1];
        uint32_t index2 = face[i2];

        Vertex *v0 = &vertices[index0];
        Vertex *v1 = &vertices[index1];
        Vertex *v2 = &vertices[index2];

        simd_float3 p0 = simd_make_float3(v0->position);
        simd_float3 p1 = simd_make_float3(v1->position);
        simd_float3 p2 = simd_make_float3(v2->position);

        if (isColinear3(p0, p1, p2)) {
            //            printf("colinear, trying another set of verts\n");
            continue;
        } else {
            simd_float3 a = p2 - p1;
            simd_float3 b = p0 - p1;
            n = simd_normalize(simd_cross(a, b));
            break;
        }
    }

    //    printf("faces: %d, %d, %d\n\n", i0, i1, i2);
    //    printf("normal: %f, %f, %f\n", n.x, n.y, n.z);
    const simd_quatf q = simd_quaternion(n, simd_make_float3(0.0, 0.0, 1.0));

    tsVertex *structure = (tsVertex *)malloc(length * sizeof(tsVertex));
    for (int i = 0; i < length; i++) {
        uint32_t index = face[i];
        simd_float3 p = simd_act(q, simd_make_float3(vertices[index].position));
        //        printf("pos: %f, %f, %f\n", p.x, p.y, p.z);

        int next = (i + 1) % length;
        int prev = (i - 1) < 0 ? (length - 1) : (i - 1);

        structure[i] = (tsVertex) { .index = index,
                                    .v = simd_make_float2(p),
                                    .ear = false,
                                    .virtual = false,
                                    .next = &structure[next],
                                    .prev = &structure[prev] };
    }

    return structure;
}

tsPath *createPathStructure(Vertex *vertices, const uint32_t *face, int length) {
    tsPath *result = (tsPath *)malloc(sizeof(tsPath));
    result->index = 0;
    result->length = length;
    result->added = 0;
    result->points = NULL;
    result->clockwise = false;
    result->parent = NULL;
    result->next = NULL;
    result->prev = NULL;
    result->v = createVertexStructure(vertices, face, length);
    result->clockwise = isVertexStructureClockwise(result->v, length);
    if (result->clockwise) { reverseStructure(result->v); }
    return result;
}

int extrudePaths(simd_float2 **paths, int *lengths, int count, GeometryData *gData) {
    int success = 0;
    GeometryData geometryData =
        (GeometryData) { .vertexCount = 0, .vertexData = NULL, .indexCount = 0, .indexData = NULL };
    tsPath *pData =
        createPathStructureFromPaths(paths, lengths, count, gData->vertexCount, &geometryData);
    freeGeometryData(&geometryData);

    if (count == 1) {
        if (pData->clockwise) { reversePath(pData); }
    } else {
        for (int i = 0; i < count; i++) {
            tsPath *a = pData + i;
            for (int j = i + 1; j < count; j++) {
                tsPath *b = pData + j;
                if (insidePath2(a, b->v)) {
                    // B is inside of A
                    // if B is already inside of another path, then its enclosed in a bigger path,
                    // so unlink the path from the parent
                    if (b->parent != NULL) {
                        b->parent = NULL;
                    } else {
                        b->parent = a;
                    }
                } else if (insidePath2(b, a->v)) {
                    // A is inside of B
                    // if A is already inside of another path, then its enclosed in a bigger path,
                    // so unlink the path from the parent
                    if (a->parent != NULL) {
                        a->parent = NULL;
                    } else {
                        a->parent = b;
                    }
                }
            }
        }
    }

    for (int i = 0; i < count; i++) {
        tsPath *path = pData + i;
        if (path->parent == NULL) {
            if (path->clockwise) { reversePath(path); }
        } else {
            if (!path->clockwise) { reversePath(path); }
        }

        int length = path->length;
        int vertexCount = length * 2;
        int indexCount = length * 2;
        GeometryData extrudeData =
            (GeometryData) { .vertexCount = vertexCount,
                             .vertexData = malloc(vertexCount * sizeof(Vertex)),
                             .indexCount = indexCount,
                             .indexData =
                                 (TriangleIndices *)malloc(indexCount * sizeof(TriangleIndices)) };

        float lengthMinusOne = (float)(length - 1);
        tsVertex *curr = path->v;
        for (int j = 0; j < length; j++) {
            const simd_float2 pt = curr->v;
            const float uv = (float)j / lengthMinusOne;
            // front vertex
            extrudeData.vertexData[j] =
                (Vertex) { .position = simd_make_float4(pt.x, pt.y, 1.0, 1.0),
                           .normal = simd_make_float3(0.0, 0.0, 0.0),
                           .uv = simd_make_float2(uv, 0.0) };

            // rear vertex
            extrudeData.vertexData[j + length] =
                (Vertex) { .position = simd_make_float4(pt.x, pt.y, -1.0, 1.0),
                           .normal = simd_make_float3(0.0, 0.0, 0.0),
                           .uv = simd_make_float2(uv, 1.0) };

            const uint32_t i0 = j;
            const uint32_t i1 = i0 + length;
            const uint32_t i3 = (i0 + 1) % length;
            const uint32_t i2 = i3 + length;

            const int j0 = j * 2;
            const int j1 = j0 + 1;

            extrudeData.indexData[j0] = (TriangleIndices) { .i0 = i0, .i1 = i1, .i2 = i2 };
            extrudeData.indexData[j1] = (TriangleIndices) { .i0 = i0, .i1 = i2, .i2 = i3 };

            curr = curr->next;
        }

        combineGeometryData(gData, &extrudeData);
        freeGeometryData(&extrudeData);
    }

    if (pData != NULL) {
        freePathVertexStructure(pData, count);
        free(pData);
    }

    return success;
}

int triangulate(simd_float2 **paths, int *lengths, int count, GeometryData *gData) {
    int success = 0;
    GeometryData geometryData =
        (GeometryData) { .vertexCount = 0, .vertexData = NULL, .indexCount = 0, .indexData = NULL };
    tsPath *pData =
        createPathStructureFromPaths(paths, lengths, count, gData->vertexCount, &geometryData);

    tsVertex *pool = NULL;
    int poolLength = 0;

    if (count == 1) {
        if (pData->clockwise) { reversePath(pData); }
    } else {
        for (int i = 0; i < count; i++) {
            tsPath *a = pData + i;
            for (int j = i + 1; j < count; j++) {
                tsPath *b = pData + j;
                if (insidePath2(a, b->v)) {
                    // B is inside of A
                    // if B is already inside of another path, then its enclosed in a bigger path,
                    // so unlink the path from the parent
                    if (b->parent != NULL) {
                        b->parent = NULL;
                    } else {
                        b->parent = a;
                    }
                } else if (insidePath2(b, a->v)) {
                    // A is inside of B
                    // if A is already inside of another path, then its enclosed in a bigger path,
                    // so unlink the path from the parent
                    if (a->parent != NULL) {
                        a->parent = NULL;
                    } else {
                        a->parent = b;
                    }
                }
            }
        }

        for (int i = 0; i < count; i++) {
            tsPath *inner = pData + i;
            tsPath *parent = inner->parent;
            if (parent != NULL) {
                if (!inner->clockwise) { reversePath(inner); }
                if (parent->clockwise) { reversePath(parent); }
                combineOuterAndInnerPaths(parent, inner, pool, &poolLength);
            }
        }
    }

    for (int i = 0; i < count; i++) {
        tsPath *path = pData + i;
        bool triangulate = false;
        if (path->parent == NULL) {
            if (path->clockwise) { reversePath(path); }
            triangulate = true;
        }

        if (triangulate) {
#ifdef DEBUGTRIANGULATION
            printf("Triangulating path: %d, clockwise: %d\n", path->index, path->clockwise);
#endif
            TriangulationData triData = (TriangulationData) { .indexCount = 0, .indexData = NULL };
            success += _triangulate(path->v, path->length, path->added, &triData);
            appendTriangulationData(&geometryData, &triData);
            freeTriangulationData(triData);
#ifdef DEBUGTRIANGULATION
            printf("Triangulated path: %d, clockwise: %d\n", path->index, path->clockwise);
            printf("Result: %d\n", success);
#endif
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
int triangulateMesh(Vertex *vertices, int vertexCount, const uint32_t **faces, int *faceLengths,
                    int faceCount, GeometryData *gData, TriangleFaceMap *triangleFaceMap) {
    // Copy Vertex Data
    GeometryData rData = (GeometryData) {
        .vertexCount = vertexCount, .vertexData = vertices, .indexCount = 0, .indexData = NULL
    };
    copyGeometryData(gData, &rData);

    // Create Path Structures & Calculate Total Number of Triangles
    tsPath **structures = malloc(faceCount * sizeof(tsPath *));
    int triangleCount = 0;
    for (int i = (faceCount - 1); i >= 0; i--) {
        int len = faceLengths[i];
        triangleCount += len - 2;
        structures[i] = createPathStructure(gData->vertexData, faces[i], len);
    }

    // Set & Allocate Triangle Face Map Data -- this map correlate triangle(s) to the faces they
    // came from
    triangleFaceMap->count = triangleCount;
    triangleFaceMap->data = calloc(triangleCount, sizeof(uint32_t));

    int success = 0;
    int triangles = 0;

    for (int i = 0; i < faceCount; i++) {
        TriangulationData triData = (TriangulationData) { .indexCount = 0, .indexData = NULL };

        int len = faceLengths[i];
        tsPath *structure = structures[i];
        if (len == 3) {
            tsVertex *vertices = structure->v;
            // If three faces only, then add manually
            triData.indexCount = 1;
            triData.indexData = (TriangleIndices *)malloc(sizeof(TriangleIndices));
            triData.indexData[0].i0 = vertices[0].index;
            triData.indexData[0].i1 = vertices[1].index;
            triData.indexData[0].i2 = vertices[2].index;
        } else {
            // Perform Triangulation
            success += _triangulate(structures[i]->v, len, 0, &triData);
        }

        if (structure->clockwise) {
            for (int k = 0; k < triData.indexCount; k++) {
                TriangleIndices tri = triData.indexData[k];
                uint32_t i1 = tri.i1;
                uint32_t i2 = tri.i2;
                triData.indexData[k].i1 = i2;
                triData.indexData[k].i2 = i1;
            }
        }

        // Set Triangle Face Map Data
        int triangleCount = triData.indexCount;
        for (int t = 0; t < triangleCount; t++) {
            triangleFaceMap->data[triangles + t] = i;
        }
        triangles += triangleCount;

        // Append Triangles to Geometry Data
        appendTriangulationData(gData, &triData);
        freeTriangulationData(triData);
    }

    // Free Vertex Structures
    for (int i = 0; i < faceCount; i++) {
        tsPath *structure = structures[i];
        freePathVertexStructure(structure, 1);
        free(structure);
    }
    free(structures);

    // Return if all the triangulations were successful
    return success;
}
