//
//  Generators.c
//  Satin
//
//  Created by Reza Ali on 6/5/20.
//

#include <malloc/_malloc.h>
#include <simd/simd.h>

#include "Generators.h"
#include "Geometry.h"
#include "Helpers.h"

GeometryData generateBoxGeometryData(float width, float height, float depth,
                                     float centerX, float centerY, float centerZ,
                                     int widthResolution, int heightResolution, int depthResolution)
{
    const int resWidth = widthResolution > 0 ? widthResolution : 1;
    const int resHeight = heightResolution > 0 ? heightResolution : 1;
    const int resDepth = depthResolution > 0 ? depthResolution : 1;

    const float resWidthf = (float)resWidth;
    const float resHeightf = (float)resHeight;
    const float resDepthf = (float)resDepth;

    const float halfWidth = width * 0.5;
    const float halfHeight = height * 0.5;
    const float halfDepth = depth * 0.5;

    const float widthInc = width / resWidthf;
    const float heightInc = height / resHeightf;
    const float depthInc = depth / resDepthf;

    const int perRowWidth = resWidth + 1;
    const int perRowHeight = resHeight + 1;
    const int perRowDepth = resDepth + 1;
    
    const int perWidthHeightFace = perRowWidth * perRowHeight;
    const int verticesPerFaceWidthHeight = perWidthHeightFace;
    const int trianglesPerFaceWidthHeight = resWidth * resHeight * 2;
    
    const int perWidthDepthFace = perRowWidth * perRowDepth;
    const int verticesPerFaceWidthDepth = perWidthDepthFace;
    const int trianglesPerFaceWidthDepth = resWidth * resDepth * 2;
    
    const int perDepthHeightFace = perRowDepth * perRowHeight;
    const int verticesPerFaceDepthHeight = perDepthHeightFace;
    const int trianglesPerFaceDepthHeight = resDepth * resHeight * 2;
    
    const int vertices = (verticesPerFaceWidthHeight + verticesPerFaceWidthDepth + verticesPerFaceDepthHeight) * 2;
    const int triangles = (trianglesPerFaceWidthHeight + trianglesPerFaceWidthDepth + trianglesPerFaceDepthHeight) * 2;

    Vertex *vtx = (Vertex *)malloc(vertices * sizeof(Vertex));
    TriangleIndices *ind = (TriangleIndices *)malloc(triangles * sizeof(TriangleIndices));
    
    int vertexIndex = 0;
    int triangleIndex = 0;
    int vertexOffset = vertexIndex;
    
    // Front (XYZ+) & Rear (XYZ-) Faces
    simd_float3 normal0 = simd_make_float3(0.0, 0.0, 1.0);
    simd_float3 normal1 = -normal0;
    simd_float2 uv;
    for(int y = 0; y <= resHeight; y++) {
        const float fy = (float)y;
        const float yPos = -halfHeight + fy * heightInc;
        uv.y = fy / resHeightf;

        for(int x = 0; x <= resWidth; x++) {
            const float fx = (float)x;
            const float xPos = fx * widthInc;
            uv.x = fx / resWidthf;

            vtx[vertexIndex++] = (Vertex) {
                .position = simd_make_float4(-halfWidth + xPos + centerX, yPos + centerY, halfDepth + centerZ, 1.0),
                .normal = normal0,
                .uv = uv
            };

            vtx[vertexIndex++] = (Vertex) {
                .position = simd_make_float4(halfWidth - xPos + centerX, yPos + centerY, -halfDepth + centerZ, 1.0),
                .normal = normal1,
                .uv = uv
            };

            if(x != resWidth && y != resHeight) {
                const uint32_t findex = vertexOffset + x * 2 + y * perRowWidth * 2;

                const uint32_t fbl = findex;
                const uint32_t fbr = fbl + 2;
                const uint32_t ftl = fbl + perRowWidth * 2;
                const uint32_t ftr = ftl + 2;

                ind[triangleIndex++] = (TriangleIndices) { .i0 = fbl, .i1 = fbr, .i2 = ftr };
                ind[triangleIndex++] = (TriangleIndices) { .i0 = fbl, .i1 = ftr, .i2 = ftl };

                const uint32_t rbl = findex + 1;
                const uint32_t rbr = rbl + 2;
                const uint32_t rtl = rbl + perRowWidth * 2;
                const uint32_t rtr = rtl + 2;

                ind[triangleIndex++] = (TriangleIndices) { .i0 = rbl, .i1 = rbr, .i2 = rtr };
                ind[triangleIndex++] = (TriangleIndices) { .i0 = rbl, .i1 = rtr, .i2 = rtl };
            }
        }
    }
    
    vertexOffset = vertexIndex;
    
    // Top (XY+Z) & Bottom (XY+Z) Faces
    normal0 = simd_make_float3(0.0, 1.0, 0.0);
    normal1 = -normal0;
    for(int z = 0; z <= resDepth; z++) {
        const float fz = (float)z;
        const float zPos = fz * depthInc;
        uv.y = fz / resDepthf;

        for(int x = 0; x <= resWidth; x++) {
            const float fx = (float)x;
            const float xPos = -halfWidth + fx * widthInc;
            uv.x = fx / resWidthf;

            vtx[vertexIndex++] = (Vertex) {
                .position = simd_make_float4(xPos + centerX, halfHeight + centerY, halfDepth - zPos + centerZ, 1.0),
                .normal = normal0,
                .uv = uv
            };

            vtx[vertexIndex++] = (Vertex) {
                .position = simd_make_float4(xPos + centerX, -halfHeight + centerY, -halfDepth + zPos + centerZ, 1.0),
                .normal = normal1,
                .uv = uv
            };

            if(x != resWidth && z != resDepth) {
                const uint32_t findex = vertexOffset + x * 2 + z * perRowWidth * 2;

                const uint32_t fbl = findex;
                const uint32_t fbr = fbl + 2;
                const uint32_t ftl = fbl + perRowWidth * 2;
                const uint32_t ftr = ftl + 2;

                ind[triangleIndex++] = (TriangleIndices) { .i0 = fbl, .i1 = fbr, .i2 = ftr };
                ind[triangleIndex++] = (TriangleIndices) { .i0 = fbl, .i1 = ftr, .i2 = ftl };

                const uint32_t rbl = findex + 1;
                const uint32_t rbr = rbl + 2;
                const uint32_t rtl = rbl + perRowWidth * 2;
                const uint32_t rtr = rtl + 2;

                ind[triangleIndex++] = (TriangleIndices) { .i0 = rbl, .i1 = rbr, .i2 = rtr };
                ind[triangleIndex++] = (TriangleIndices) { .i0 = rbl, .i1 = rtr, .i2 = rtl };
            }
        }
    }
    
    vertexOffset = vertexIndex;
    
    // Right (X+YZ) & Left (X-YZ) Faces
    normal0 = simd_make_float3(1.0, 0.0, 0.0);
    normal1 = -normal0;
    for(int y = 0; y <= resHeight; y++) {
        const float fy = (float)y;
        const float yPos = -halfHeight + fy * heightInc;
        uv.y = fy / resHeightf;
        
        for(int z = 0; z <= resDepth; z++) {
            const float fz = (float)z;
            const float zPos = fz * depthInc;
            uv.x = fz / resDepthf;
            
            vtx[vertexIndex++] = (Vertex) {
                .position = simd_make_float4(halfWidth + centerX, yPos + centerY, halfDepth - zPos + centerZ, 1.0),
                .normal = normal0,
                .uv = uv
            };
            
            vtx[vertexIndex++] = (Vertex) {
                .position = simd_make_float4(-halfWidth + centerX, yPos + centerY, -halfDepth + zPos + centerZ, 1.0),
                .normal = normal1,
                .uv = uv
            };
            
            if(y != resHeight && z != resDepth) {
                const uint32_t findex = vertexOffset + z * 2 + y * perRowDepth * 2;
                                
                const uint32_t fbl = findex;
                const uint32_t fbr = fbl + 2;
                const uint32_t ftl = fbl + perRowDepth * 2;
                const uint32_t ftr = ftl + 2;
                
                ind[triangleIndex++] = (TriangleIndices) { .i0 = fbl, .i1 = fbr, .i2 = ftr };
                ind[triangleIndex++] = (TriangleIndices) { .i0 = fbl, .i1 = ftr, .i2 = ftl };
                                                
                const uint32_t rbl = findex + 1;
                const uint32_t rbr = rbl + 2;
                const uint32_t rtl = rbl + perRowDepth * 2;
                const uint32_t rtr = rtl + 2;

                ind[triangleIndex++] = (TriangleIndices) { .i0 = rbl, .i1 = rbr, .i2 = rtr };
                ind[triangleIndex++] = (TriangleIndices) { .i0 = rbl, .i1 = rtr, .i2 = rtl };
            }
        }
    }
    
    return (GeometryData) {
        .vertexCount = vertices, .vertexData = vtx, .indexCount = triangles, .indexData = ind
    };
}

GeometryData generateCylinderWallGeometryData(float radius, float height, int angularResolution,
                                              int verticalResolution) {
    const int vertical = verticalResolution > 0 ? verticalResolution : 1;
    const int angular = angularResolution > 2 ? angularResolution : 3;

    const float verticalf = (float)vertical;
    const float angularf = (float)angular;

    const float angularInc = (2.0 * M_PI) / angularf;
    const float verticalInc = height / verticalf;

    const float yOffset = -0.5 * height;
    const int perLoop = angular + 1;

    const int vertices = perLoop * (vertical + 1);
    const int triangles = angular * 2 * vertical;

    Vertex *vtx = (Vertex *)malloc(vertices * sizeof(Vertex));
    TriangleIndices *ind = (TriangleIndices *)malloc(triangles * sizeof(TriangleIndices));

    int vertexIndex = 0;
    int triangleIndex = 0;

    for (int v = 0; v <= vertical; v++) {
        const float vf = (float)v;
        const float y = yOffset + vf * verticalInc;

        for (int a = 0; a <= angular; a++) {
            const float af = (float)a;
            const float angle = af * angularInc;
            const float x = cos(angle);
            const float z = sin(angle);

            vtx[vertexIndex++] =
                (Vertex) { .position = simd_make_float4(radius * x, y, radius * z, 1.0),
                           .normal = simd_make_float3(x, 0.0, z),
                           .uv = simd_make_float2(af / angularf, vf / verticalf) };

            if (v != vertical && a != angular) {
                const uint32_t index = a + v * perLoop;

                const uint32_t tl = index;
                const uint32_t tr = tl + 1;
                const uint32_t bl = index + perLoop;
                const uint32_t br = bl + 1;

                ind[triangleIndex++] = (TriangleIndices) { .i0 = tl, .i1 = bl, .i2 = tr };
                ind[triangleIndex++] = (TriangleIndices) { .i0 = tr, .i1 = bl, .i2 = br };
            }
        }
    }

    return (GeometryData) {
        .vertexCount = vertices, .vertexData = vtx, .indexCount = triangles, .indexData = ind
    };
}

GeometryData generateCapsuleGeometryData(float radius, float height, int angularResolution, int radialResolution, int verticalResolution, int axis) {
    const int phi = angularResolution > 2 ? angularResolution : 3;
    const int theta = radialResolution > 0 ? radialResolution : 1;
    const int slices = verticalResolution > 0 ? verticalResolution : 1;
    
    const float phif = (float)phi;
    const float thetaf = (float)theta;
    const float slicesf = (float)slices;
    
    const float phiMax = M_PI * 2.0;
    const float thetaMax = M_PI * 0.5;
    
    const float phiInc = phiMax / phif;
    const float thetaInc = thetaMax / thetaf;
    const float heightInc = height / slicesf;
    
    const float halfHeight = height * 0.5;
    const float totalHeight = height + 2.0 * radius;
    const float vPerCap = radius / totalHeight;
    const float vPerCyl = height / totalHeight;
    
    const int perLoop = phi + 1;
    
    const int verticesPerCap = perLoop * (theta + 1);
    const int trianglesPerCap = phi * 2 * theta;
    
    const int verticesPerSide = perLoop * (slices + 1);
    const int trianglesPerSide = phi * 2 * slices;
    
    const int vertices = verticesPerCap * 2 + verticesPerSide;
    const int triangles = trianglesPerCap * 2 + trianglesPerSide;

    Vertex *vtx = (Vertex *)malloc(vertices * sizeof(Vertex));
    TriangleIndices *ind = (TriangleIndices *)malloc(triangles * sizeof(TriangleIndices));

    int vertexIndex = 0;
    int triangleIndex = 0;

    for(int t = 0; t <= theta; t++) {
        const float tf = (float)t;
        const float thetaAngle = tf * thetaInc;
        const float cosTheta = cos(thetaAngle);
        const float sinTheta = sin(thetaAngle);
        
        for(int p = 0; p <= phi; p++) {
            const float pf = (float)p;
            const float phiAngle = pf * phiInc;
            const float cosPhi = cos(phiAngle);
            const float sinPhi = sin(phiAngle);
            
            const float x = cosPhi * sinTheta;
            const float z = sinPhi * sinTheta;
            const float y = cosTheta;
            
            simd_float4 position = simd_make_float4(radius * y + halfHeight, radius * z, radius * x, 1.0);
            simd_float3 normal = simd_make_float3(y, z, x);
            switch(axis) {
                case 1:
                    position = simd_make_float4(radius * x, radius * y + halfHeight, radius * z, 1.0);
                    normal = simd_make_float3(x, y, z);
                    break;
                case 2:
                    position = simd_make_float4(radius * z, radius * x, radius * y + halfHeight, 1.0);
                    normal = simd_make_float3(z, x, y);
                    break;
                default:
                    break;
            }
            
            vtx[vertexIndex++] = (Vertex)
            {
                .position = position,
                .normal = normal,
                .uv = simd_make_float2(pf / phif, map(y, 0.0, radius, vPerCap + vPerCyl, 1.0))
            };
                        
            if(p != phi && t != theta) {
                
                const int index = p + t * perLoop;
                
                const uint32_t tl = index;
                const uint32_t tr = tl + 1;
                const uint32_t bl = index + perLoop;
                const uint32_t br = bl + 1;
                
                ind[triangleIndex++] = (TriangleIndices) { .i0 = tl, .i1 = tr, .i2 = br };
                ind[triangleIndex++] = (TriangleIndices) { .i0 = tl, .i1 = br, .i2 = bl };
            }
        }
    }
    
    for(int t = 0; t <= theta; t++) {
        const float tf = (float)t;
        const float thetaAngle = tf * thetaInc;
        const float cosTheta = cos(thetaAngle);
        const float sinTheta = sin(thetaAngle);
        
        for(int p = 0; p <= phi; p++) {
            const float pf = (float)p;
            const float phiAngle = pf * phiInc;
            const float cosPhi = cos(phiAngle);
            const float sinPhi = sin(phiAngle);
            
            const float x = cosPhi * sinTheta;
            const float z = sinPhi * sinTheta;
            const float y = -cosTheta;
            
            simd_float4 position = simd_make_float4(radius * y - halfHeight, radius * z, radius * x, 1.0);
            simd_float3 normal = simd_make_float3(y, z, x);
            switch(axis) {
                case 1:
                    position = simd_make_float4(radius * x, radius * y - halfHeight, radius * z, 1.0);
                    normal = simd_make_float3(x, y, z);
                    break;
                case 2:
                    position = simd_make_float4(radius * z, radius * x, radius * y - halfHeight, 1.0);
                    normal = simd_make_float3(z, x, y);
                    break;
                default:
                    break;
            }
            
            vtx[vertexIndex++] = (Vertex)
            {
                .position = position,
                .normal = normal,
                .uv = simd_make_float2(pf / phif, map(y, -radius, 0, 0.0, vPerCap))
            };
                        
            if(p != phi && t != theta) {
                const int index = verticesPerCap + p + t * perLoop;
                
                const uint32_t tl = index;
                const uint32_t tr = tl + 1;
                const uint32_t bl = index + perLoop;
                const uint32_t br = bl + 1;
                
                ind[triangleIndex++] = (TriangleIndices) { .i0 = tl, .i1 = bl, .i2 = tr };
                ind[triangleIndex++] = (TriangleIndices) { .i0 = tr, .i1 = bl, .i2 = br };
            }
        }
    }
    
    for(int s = 0; s <= slices; s++) {
        const float sf = (float)s;
        const float y = sf * heightInc;
        for(int p = 0; p <= phi; p++) {
            
            const float pf = (float)p;
            const float phiAngle = pf * phiInc;
            const float cosPhi = cos(phiAngle);
            const float sinPhi = sin(phiAngle);

            const float x = cosPhi;
            const float z = sinPhi;

            simd_float4 position = simd_make_float4(y - halfHeight, radius * z, radius * x, 1.0);
            simd_float3 normal = simd_make_float3(0, z, x);
            switch(axis) {
                case 1:
                    position = simd_make_float4(radius * x, y - halfHeight, radius * z, 1.0);
                    normal = simd_make_float3(x, 0, z);
                    break;
                case 2:
                    position = simd_make_float4(radius * z, radius * x, y - halfHeight, 1.0);
                    normal = simd_make_float3(z, x, 0);
                    break;
                default:
                    break;
            }
            
            vtx[vertexIndex++] = (Vertex) {
                .position = position,
                .normal = normal,
                .uv = simd_make_float2(pf / phif, map(sf, 0.0, slicesf, vPerCap, vPerCap + vPerCyl))
            };
            

            if(s != slices && p != phi) {
                const uint32_t index = verticesPerCap * 2 + p + s * perLoop;

                const uint32_t tl = index;
                const uint32_t tr = tl + 1;
                const uint32_t bl = index + perLoop;
                const uint32_t br = bl + 1;

                ind[triangleIndex++] = (TriangleIndices) { .i0 = tl, .i1 = bl, .i2 = tr };
                ind[triangleIndex++] = (TriangleIndices) { .i0 = tr, .i1 = bl, .i2 = br };
            }
        }
    }
    
    
    return (GeometryData) {
        .vertexCount = vertices, .vertexData = vtx, .indexCount = triangles, .indexData = ind
    };
}

GeometryData generateConeGeometryData(float radius, float height, int angularResolution, int radialResolution, int verticalResolution)
{
    const int vertical = verticalResolution > 0 ? verticalResolution : 1;
    const int angular = angularResolution > 2 ? angularResolution : 3;
    const int radial = radialResolution > 0 ? radialResolution : 1;

    const float verticalf = (float)vertical;
    const float angularf = (float)angular;
    const float radialf = (float)radial;

    const float angularInc = (2.0 * M_PI) / angularf;
    const float verticalInc = height / verticalf;
    const float radialInc = radius / radialf;
    const float radiusInc = radius / verticalf;

    const float yOffset = -0.5 * height;
    const int perLoop = angular + 1;

    const int verticesPerWall = perLoop * (vertical + 1);
    const int trianglesPerWall = angular * 2 * vertical;
    
    const int verticesPerCircle = perLoop * (radial + 1);
    const int trianglesPerCircle = angular * 2 * radial;
    
    const int vertices = verticesPerWall + verticesPerCircle;
    const int triangles = trianglesPerWall + trianglesPerCircle;
    
    Vertex *vtx = (Vertex *)malloc(vertices * sizeof(Vertex));
    TriangleIndices *ind = (TriangleIndices *)malloc(triangles * sizeof(TriangleIndices));
    
    int vertexIndex = 0;
    int triangleIndex = 0;

    const float slopeInv = -radius / height;
    const float theta = atan(slopeInv);
    const simd_quatf quatTilt = simd_quaternion(theta, simd_make_float3(0.0, 0.0, 1.0));
    
    const simd_float3 xDir = simd_make_float3(1.0, 0.0, 0.0);
    const simd_float3 yDir = simd_make_float3(0.0, 1.0, 0.0);
    
    for (int v = 0; v <= vertical; v++) {
        const float vf = (float)v;
        const float y = yOffset + vf * verticalInc;
        const float rad = radius - v * radiusInc;

        for (int a = 0; a <= angular; a++) {
            const float af = (float)a;
            const float angle = af * angularInc;
            
            const float cosAngle = cos(angle);
            const float sinAngle = sin(angle);
            
            const float x = rad * cosAngle;
            const float z = rad * sinAngle;

            simd_float3 normal = xDir;
            const simd_quatf quatRot = simd_quaternion(-angle, yDir);
            
            normal = simd_act(quatTilt, normal);
            normal = simd_act(quatRot, normal);
            
            vtx[vertexIndex++] =
                (Vertex) { .position = simd_make_float4(x, y, z, 1.0),
                           .normal = simd_normalize(normal),
                           .uv = simd_make_float2(af / angularf, 1.0 - vf / verticalf) };

            if (v != vertical && a != angular) {
                const uint32_t index = a + v * perLoop;

                const uint32_t tl = index;
                const uint32_t tr = tl + 1;
                const uint32_t bl = index + perLoop;
                const uint32_t br = bl + 1;

                ind[triangleIndex++] = (TriangleIndices) { .i0 = tl, .i1 = bl, .i2 = tr };
                ind[triangleIndex++] = (TriangleIndices) { .i0 = tr, .i1 = bl, .i2 = br };
            }
        }
    }

    for (int r = 0; r <= radial; r++) {
        const float rf = (float)r;
        const float rad = rf * radialInc;
        for (int a = 0; a <= angular; a++) {
            const float af = (float)a;
            const float angle = af * angularInc;
            const float x = rad * cos(angle);
            const float y = rad * sin(angle);

            vtx[vertexIndex++] =
                (Vertex) {
                    .position = simd_make_float4(x, -height * 0.5, y, 1.0),
                    .normal = simd_make_float3(0.0, -1.0, 0.0),
                    .uv = simd_make_float2(af / angularf, rf / radialf)
                };

            if (r != radial && a != angular) {
                const uint32_t index = verticesPerWall + a + r * perLoop;

                const uint32_t tl = index;
                const uint32_t tr = tl + 1;
                const uint32_t bl = index + perLoop;
                const uint32_t br = bl + 1;

                ind[triangleIndex++] = (TriangleIndices) { .i0 = tl, .i1 = bl, .i2 = tr };
                ind[triangleIndex++] = (TriangleIndices) { .i0 = tr, .i1 = bl, .i2 = br };
            }
        }
    }

    return (GeometryData) {
        .vertexCount = vertices, .vertexData = vtx, .indexCount = triangles, .indexData = ind
    };
}

GeometryData generateCylinderGeometryData(float radius, float height, int angularResolution,
                                          int radialResolution, int verticalResolution) {

    const int radial = radialResolution > 0 ? radialResolution : 1;
    const int angular = angularResolution > 2 ? angularResolution : 3;

    const float radialf = (float)radial;
    const float angularf = (float)angular;

    const float radialInc = radius / radialf;
    const float angularInc = (2.0 * M_PI) / angularf;

    const int perLoop = angular + 1;

    GeometryData geometry =
        generateCylinderWallGeometryData(radius, height, angularResolution, verticalResolution);

    const int verticesPerCircle = perLoop * (radial + 1);
    const int trianglesPerCircle = angular * 2 * radial;
    const int vertices = 2 * verticesPerCircle + geometry.vertexCount;
    const int triangles = 2 * trianglesPerCircle + geometry.indexCount;

    Vertex *vtx = (Vertex *)realloc(geometry.vertexData, vertices * sizeof(Vertex));
    TriangleIndices *ind =
        (TriangleIndices *)realloc(geometry.indexData, triangles * sizeof(TriangleIndices));

    int vertexOffset = geometry.vertexCount;
    int vertexIndex = geometry.vertexCount;
    int triangleIndex = geometry.indexCount;

    bool flip = true;
    float direction = 1.0;
    for (int i = 0; i < 2; i++) {

        for (int r = 0; r <= radial; r++) {
            const float rf = (float)r;
            const float rad = rf * radialInc;
            for (int a = 0; a <= angular; a++) {
                const float af = (float)a;
                const float angle = af * angularInc;
                const float x = rad * cos(angle);
                const float y = rad * sin(angle);

                vtx[vertexIndex++] =
                    (Vertex) { .position = simd_make_float4(x, direction * height * 0.5, y, 1.0),
                               .normal = simd_make_float3(0.0, direction, 0.0),
                               .uv = flip ? simd_make_float2(af / angularf, rf / radialf)
                                          : simd_make_float2(af / angularf, 1.0 - rf / radialf) };

                if (r != radial && a != angular) {
                    const uint32_t index = vertexOffset + a + r * perLoop;

                    const uint32_t tl = index;
                    const uint32_t tr = tl + 1;
                    const uint32_t bl = index + perLoop;
                    const uint32_t br = bl + 1;

                    if (flip) {
                        ind[triangleIndex++] = (TriangleIndices) { .i0 = tl, .i1 = tr, .i2 = bl };
                        ind[triangleIndex++] = (TriangleIndices) { .i0 = tr, .i1 = br, .i2 = bl };
                    } else {
                        ind[triangleIndex++] = (TriangleIndices) { .i0 = tl, .i1 = bl, .i2 = tr };
                        ind[triangleIndex++] = (TriangleIndices) { .i0 = tr, .i1 = bl, .i2 = br };
                    }
                }
            }
        }
        vertexOffset += verticesPerCircle;
        direction *= -1.0;
        flip = !flip;
    }

    geometry.vertexData = vtx;
    geometry.indexData = ind;
    geometry.vertexCount = vertices;
    geometry.indexCount = triangles;

    return geometry;
}

enum PlaneOrientation {
    xy = 0, // points in +z direction
    yx = 1, // points in -z direction
    xz = 2, // points in -y direction
    zx = 3, // points in +y direction
    yz = 4, // points in +x direction
    zy = 5  // points in -x direction
};

GeometryData generatePlaneGeometryData(float width, float height, int widthResolution,
                                       int heightResolution, int plane, bool centered) {
    const int resWidth = widthResolution > 0 ? widthResolution : 1;
    const int resHeight = heightResolution > 0 ? heightResolution : 1;

    const float resWidthf = (float)resWidth;
    const float resHeightf = (float)resHeight;

    const float halfWidth = width * 0.5;
    const float halfHeight = height * 0.5;

    const float widthInc = width / resWidthf;
    const float heightInc = height / resHeightf;

    const float centerXOffset = centered ? -halfWidth : 0.0;
    const float centerYOffset = centered ? -halfHeight : 0.0;

    const int perRow = resWidth + 1;
    const int vertices = (resHeight + 1) * perRow;
    const int triangles = resWidth * 2 * resHeight;

    Vertex *vtx = (Vertex *)malloc(vertices * sizeof(Vertex));
    TriangleIndices *ind = (TriangleIndices *)malloc(triangles * sizeof(TriangleIndices));

    int vertexIndex = 0;
    int triangleIndex = 0;

    for (int y = 0; y <= resHeight; y++) {
        const float yf = (float)y;
        const float yuv = yf / resHeightf;

        for (int x = 0; x <= resWidth; x++) {
            const float xf = (float)x;
            const float xuv = xf / resWidthf;

            const float xP = centerXOffset + xf * widthInc;
            const float yP = centerYOffset + yf * heightInc;

            simd_float4 position = simd_make_float4(xP, yP, 0.0, 1.0);
            simd_float3 normal = simd_make_float3(0.0, 0.0, 1.0);
            simd_float2 uv = simd_make_float2(xuv, yuv);

            bool flip = false;
            switch (plane) {
                case yx: // points in -z direction
                    normal = simd_make_float3(0.0, 0.0, -1.0);
                    uv.x = 1.0 - uv.x;
                    flip = true;
                    break;
                case xz: // points in -y direction
                    position = simd_make_float4(xP, 0.0, yP, 1.0);
                    normal = simd_make_float3(0.0, -1.0, 0.0);
                    break;
                case zx: // points in +y direction
                    position = simd_make_float4(xP, 0.0, yP, 1.0);
                    normal = simd_make_float3(0.0, 1.0, 0.0);
                    uv.y = 1.0 - uv.y;
                    flip = true;
                    break;
                case yz: // points in +x direction
                    position = simd_make_float4(0.0, xP, yP, 1.0);
                    normal = simd_make_float3(1.0, 0.0, 0.0);
                    uv.x = 1.0 - yuv;
                    uv.y = xuv;
                    break;
                case zy: // points in -x direction
                    position = simd_make_float4(0.0, xP, yP, 1.0);
                    normal = simd_make_float3(-1.0, 0.0, 0.0);
                    uv.x = yuv;
                    uv.y = xuv;
                    flip = true;
                    break;
                default: break;
            }

            vtx[vertexIndex++] = (Vertex) { .position = position, .normal = normal, .uv = uv };

            if (x != resWidth && y != resHeight) {
                const uint32_t index = x + y * perRow;
                const uint32_t bl = index;
                const uint32_t br = bl + 1;
                const uint32_t tl = index + perRow;
                const uint32_t tr = tl + 1;

                if (flip) {
                    ind[triangleIndex++] = (TriangleIndices) { .i0 = bl, .i1 = tl, .i2 = br };
                    ind[triangleIndex++] = (TriangleIndices) { .i0 = br, .i1 = tl, .i2 = tr };
                } else {
                    ind[triangleIndex++] = (TriangleIndices) { .i0 = bl, .i1 = br, .i2 = tl };
                    ind[triangleIndex++] = (TriangleIndices) { .i0 = br, .i1 = tr, .i2 = tl };
                }
            }
        }
    }

    return (GeometryData) {
        .vertexCount = vertices, .vertexData = vtx, .indexCount = triangles, .indexData = ind
    };
}

GeometryData generateArcGeometryData(float innerRadius, float outerRadius, float startAngle,
                                     float endAngle, int angularResolution, int radialResolution) {
    const int radial = radialResolution > 0 ? radialResolution : 1;
    const int angular = angularResolution > 2 ? angularResolution : 3;

    const float radialf = (float)radial;
    const float angularf = (float)angular;

    const float radialInc = (outerRadius - innerRadius) / radialf;
    const float angularInc = (endAngle - startAngle) / angularf;

    const int perArc = angular + 1;
    const int vertices = (radial + 1) * perArc;
    const int triangles = angular * 2 * radial;

    Vertex *vtx = (Vertex *)malloc(vertices * sizeof(Vertex));
    TriangleIndices *ind = (TriangleIndices *)malloc(triangles * sizeof(TriangleIndices));

    int vertexIndex = 0;
    int triangleIndex = 0;

    for (int r = 0; r <= radial; r++) {
        const float rf = (float)r;
        const float rad = innerRadius + rf * radialInc;

        for (int a = 0; a <= angular; a++) {
            const float af = (float)a;
            const float angle = startAngle + af * angularInc;
            const float x = rad * cos(angle);
            const float y = rad * sin(angle);

            vtx[vertexIndex++] = (Vertex) { .position = simd_make_float4(x, y, 0.0, 1.0),
                                            .normal = simd_make_float3(0.0, 0.0, 1.0),
                                            .uv = simd_make_float2(rf / radialf, af / angularf) };

            if (r != radial && a != angular) {
                const uint32_t index = a + r * perArc;

                const uint32_t br = index;
                const uint32_t bl = br + 1;
                const uint32_t tr = br + perArc;
                const uint32_t tl = bl + perArc;

                ind[triangleIndex++] = (TriangleIndices) { .i0 = bl, .i1 = br, .i2 = tr };
                ind[triangleIndex++] = (TriangleIndices) { .i0 = bl, .i1 = tr, .i2 = tl };
            }
        }
    }

    return (GeometryData) {
        .vertexCount = vertices, .vertexData = vtx, .indexCount = triangles, .indexData = ind
    };
}

GeometryData generateTorusGeometryData(float minorRadius, float majorRadius, int minorResolution,
                                       int majorResolution) {
    const int slices = minorResolution > 2 ? minorResolution : 3;
    const int angular = majorResolution > 2 ? majorResolution : 3;

    const float slicesf = (float)slices;
    const float angularf = (float)angular;

    const float limit = M_PI * 2.0;
    const float sliceInc = limit / slicesf;
    const float angularInc = limit / angularf;

    const int perLoop = angular + 1;
    const int vertices = (slices + 1) * perLoop;
    const int triangles = angular * 2 * slices;

    Vertex *vtx = (Vertex *)malloc(vertices * sizeof(Vertex));
    TriangleIndices *ind = (TriangleIndices *)malloc(triangles * sizeof(TriangleIndices));

    int vertexIndex = 0;
    int triangleIndex = 0;

    for (int s = 0; s <= slices; s++) {
        const float sf = (float)s;
        const float slice = sf * sliceInc;

        const float cosSlice = cos(slice);
        const float sinSlice = sin(slice);

        for (int a = 0; a <= angular; a++) {
            const float af = (float)a;
            const float angle = af * angularInc;

            const float cosAngle = cos(angle);
            const float sinAngle = sin(angle);

            const float x = cosSlice * (majorRadius + cosAngle * minorRadius);
            const float y = sinSlice * (majorRadius + cosAngle * minorRadius);
            const float z = sinAngle * minorRadius;

            const simd_float3 tangent = simd_make_float3(-sinSlice, cosSlice, 0.0);
            const simd_float3 stangent =
                simd_make_float3(cosSlice * (-sinAngle), sinSlice * (-sinAngle), cosAngle);

            vtx[vertexIndex++] = (Vertex) { .position = simd_make_float4(x, z, y, 1.0),
                                            .normal = simd_normalize(simd_cross(tangent, stangent)),
                                            .uv = simd_make_float2(af / angularf, sf / slicesf) };

            if (s != slices && a != angular) {
                const uint32_t index = a + s * perLoop;

                const uint32_t tl = index;
                const uint32_t tr = tl + 1;
                const uint32_t bl = index + perLoop;
                const uint32_t br = bl + 1;

                ind[triangleIndex++] = (TriangleIndices) { .i0 = tl, .i1 = tr, .i2 = bl };
                ind[triangleIndex++] = (TriangleIndices) { .i0 = tr, .i1 = br, .i2 = bl };
            }
        }
    }

    return (GeometryData) {
        .vertexCount = vertices, .vertexData = vtx, .indexCount = triangles, .indexData = ind
    };
}

GeometryData generateSkyboxGeometryData(float size) {
    const float halfSize = size * 0.5;

    const int vertices = 24;
    const int triangles = 12;

    Vertex *vtx = (Vertex *)malloc(vertices * sizeof(Vertex));
    TriangleIndices *ind = (TriangleIndices *)malloc(triangles * sizeof(TriangleIndices));

    // +Y
    vtx[0] = (Vertex) { .position = simd_make_float4(-halfSize, halfSize, halfSize, 1.0),
                        .normal = simd_make_float3(0.0, -1.0, 0.0),
                        .uv = simd_make_float2(1.0, 1.0) };
    vtx[1] = (Vertex) { .position = simd_make_float4(halfSize, halfSize, halfSize, 1.0),
                        .normal = simd_make_float3(0.0, -1.0, 0.0),
                        .uv = simd_make_float2(0.0, 1.0) };
    vtx[2] = (Vertex) { .position = simd_make_float4(halfSize, halfSize, -halfSize, 1.0),
                        .normal = simd_make_float3(0.0, -1.0, 0.0),
                        .uv = simd_make_float2(0.0, 0.0) };
    vtx[3] = (Vertex) { .position = simd_make_float4(-halfSize, halfSize, -halfSize, 1.0),
                        .normal = simd_make_float3(0.0, -1.0, 0.0),
                        .uv = simd_make_float2(1.0, 0.0) };
    // -Y
    vtx[4] = (Vertex) { .position = simd_make_float4(halfSize, -halfSize, halfSize, 1.0),
                        .normal = simd_make_float3(0.0, 1.0, 0.0),
                        .uv = simd_make_float2(1.0, 1.0) };
    vtx[5] = (Vertex) { .position = simd_make_float4(-halfSize, -halfSize, halfSize, 1.0),
                        .normal = simd_make_float3(0.0, 1.0, 0.0),
                        .uv = simd_make_float2(0.0, 1.0) };
    vtx[6] = (Vertex) { .position = simd_make_float4(-halfSize, -halfSize, -halfSize, 1.0),
                        .normal = simd_make_float3(0.0, 1.0, 0.0),
                        .uv = simd_make_float2(0.0, 0.0) };
    vtx[7] = (Vertex) { .position = simd_make_float4(halfSize, -halfSize, -halfSize, 1.0),
                        .normal = simd_make_float3(0.0, 1.0, 0.0),
                        .uv = simd_make_float2(1.0, 0.0) };
    // +Z
    vtx[8] = (Vertex) { .position = simd_make_float4(-halfSize, -halfSize, halfSize, 1.0),
                        .normal = simd_make_float3(0.0, 0.0, -1.0),
                        .uv = simd_make_float2(1.0, 1.0) };
    vtx[9] = (Vertex) { .position = simd_make_float4(halfSize, -halfSize, halfSize, 1.0),
                        .normal = simd_make_float3(0.0, 0.0, -1.0),
                        .uv = simd_make_float2(0.0, 1.0) };
    vtx[10] = (Vertex) { .position = simd_make_float4(halfSize, halfSize, halfSize, 1.0),
                         .normal = simd_make_float3(0.0, 0.0, -1.0),
                         .uv = simd_make_float2(0.0, 0.0) };
    vtx[11] = (Vertex) { .position = simd_make_float4(-halfSize, halfSize, halfSize, 1.0),
                         .normal = simd_make_float3(0.0, 0.0, -1.0),
                         .uv = simd_make_float2(1.0, 0.0) };
    // -Z
    vtx[12] = (Vertex) { .position = simd_make_float4(halfSize, -halfSize, -halfSize, 1.0),
                         .normal = simd_make_float3(0.0, 0.0, 1.0),
                         .uv = simd_make_float2(1.0, 1.0) };
    vtx[13] = (Vertex) { .position = simd_make_float4(-halfSize, -halfSize, -halfSize, 1.0),
                         .normal = simd_make_float3(0.0, 0.0, 1.0),
                         .uv = simd_make_float2(0.0, 1.0) };
    vtx[14] = (Vertex) { .position = simd_make_float4(-halfSize, halfSize, -halfSize, 1.0),
                         .normal = simd_make_float3(0.0, 0.0, 1.0),
                         .uv = simd_make_float2(0.0, 0.0) };
    vtx[15] = (Vertex) { .position = simd_make_float4(halfSize, halfSize, -halfSize, 1.0),
                         .normal = simd_make_float3(0.0, 0.0, 1.0),
                         .uv = simd_make_float2(1.0, 0.0) };
    // -X
    vtx[16] = (Vertex) { .position = simd_make_float4(-halfSize, -halfSize, -halfSize, 1.0),
                         .normal = simd_make_float3(1.0, 0.0, 0.0),
                         .uv = simd_make_float2(1.0, 1.0) };
    vtx[17] = (Vertex) { .position = simd_make_float4(-halfSize, -halfSize, halfSize, 1.0),
                         .normal = simd_make_float3(1.0, 0.0, 0.0),
                         .uv = simd_make_float2(0.0, 1.0) };
    vtx[18] = (Vertex) { .position = simd_make_float4(-halfSize, halfSize, halfSize, 1.0),
                         .normal = simd_make_float3(1.0, 0.0, 0.0),
                         .uv = simd_make_float2(0.0, 0.0) };
    vtx[19] = (Vertex) { .position = simd_make_float4(-halfSize, halfSize, -halfSize, 1.0),
                         .normal = simd_make_float3(1.0, 0.0, 0.0),
                         .uv = simd_make_float2(1.0, 0.0) };
    // +X
    vtx[20] = (Vertex) { .position = simd_make_float4(halfSize, -halfSize, halfSize, 1.0),
                         .normal = simd_make_float3(-1.0, 0.0, 0.0),
                         .uv = simd_make_float2(1.0, 1.0) };
    vtx[21] = (Vertex) { .position = simd_make_float4(halfSize, -halfSize, -halfSize, 1.0),
                         .normal = simd_make_float3(-1.0, 0.0, 0.0),
                         .uv = simd_make_float2(0.0, 1.0) };
    vtx[22] = (Vertex) { .position = simd_make_float4(halfSize, halfSize, -halfSize, 1.0),
                         .normal = simd_make_float3(-1.0, 0.0, 0.0),
                         .uv = simd_make_float2(0.0, 0.0) };
    vtx[23] = (Vertex) { .position = simd_make_float4(halfSize, halfSize, halfSize, 1.0),
                         .normal = simd_make_float3(-1.0, 0.0, 0.0),
                         .uv = simd_make_float2(1.0, 0.0) };

    ind[0] = (TriangleIndices) { .i0 = 0, .i1 = 3, .i2 = 2 };
    ind[1] = (TriangleIndices) { .i0 = 2, .i1 = 1, .i2 = 0 };
    ind[2] = (TriangleIndices) { .i0 = 5, .i1 = 7, .i2 = 6 };
    ind[3] = (TriangleIndices) { .i0 = 5, .i1 = 4, .i2 = 7 };
    ind[4] = (TriangleIndices) { .i0 = 8, .i1 = 11, .i2 = 10 };
    ind[5] = (TriangleIndices) { .i0 = 10, .i1 = 9, .i2 = 8 };
    ind[6] = (TriangleIndices) { .i0 = 12, .i1 = 15, .i2 = 14 };
    ind[7] = (TriangleIndices) { .i0 = 14, .i1 = 13, .i2 = 12 };
    ind[8] = (TriangleIndices) { .i0 = 16, .i1 = 19, .i2 = 18 };
    ind[9] = (TriangleIndices) { .i0 = 18, .i1 = 17, .i2 = 16 };
    ind[10] = (TriangleIndices) { .i0 = 20, .i1 = 23, .i2 = 22 };
    ind[11] = (TriangleIndices) { .i0 = 22, .i1 = 21, .i2 = 20 };

    return (GeometryData) {
        .vertexCount = vertices, .vertexData = vtx, .indexCount = triangles, .indexData = ind
    };
}

GeometryData generateCircleGeometryData(float radius, int angularResolution, int radialResolution) {
    const int radial = radialResolution > 0 ? radialResolution : 1;
    const int angular = angularResolution > 2 ? angularResolution : 3;

    const float radialf = (float)radial;
    const float angularf = (float)angular;

    const float radialInc = radius / radialf;
    const float angularInc = (2.0 * M_PI) / angularf;

    const int perLoop = angular + 1;

    const int vertices = perLoop * (radial + 1);
    const int triangles = angular * 2 * radial;

    Vertex *vtx = (Vertex *)malloc(vertices * sizeof(Vertex));
    TriangleIndices *ind = (TriangleIndices *)malloc(triangles * sizeof(TriangleIndices));

    int vertexIndex = 0;
    int triangleIndex = 0;

    for (int r = 0; r <= radial; r++) {
        const float rf = (float)r;
        const float rad = rf * radialInc;
        for (int a = 0; a <= angular; a++) {
            const float af = (float)a;
            const float angle = af * angularInc;
            const float x = rad * cos(angle);
            const float y = rad * sin(angle);

            vtx[vertexIndex++] = (Vertex) { .position = simd_make_float4(x, y, 0.0, 1.0),
                                            .normal = simd_make_float3(0.0, 0.0, 1.0),
                                            .uv = simd_make_float2(rf / radialf, af / angularf) };

            if (r != radial && a != angular) {
                const uint32_t index = a + r * perLoop;

                const uint32_t tl = index;
                const uint32_t tr = tl + 1;
                const uint32_t bl = index + perLoop;
                const uint32_t br = bl + 1;

                ind[triangleIndex++] = (TriangleIndices) { .i0 = tl, .i1 = bl, .i2 = tr };
                ind[triangleIndex++] = (TriangleIndices) { .i0 = tr, .i1 = bl, .i2 = br };
            }
        }
    }

    return (GeometryData) {
        .vertexCount = vertices, .vertexData = vtx, .indexCount = triangles, .indexData = ind
    };
}

GeometryData generateTriangleGeometryData(float size) {
    const int vertices = 3;
    const int triangles = 1;

    Vertex *vtx = (Vertex *)malloc(vertices * sizeof(Vertex));
    TriangleIndices *ind = (TriangleIndices *)malloc(triangles * sizeof(TriangleIndices));

    const float twoPi = M_PI * 2.0;
    float angle = 0.0;
    vtx[0] =
        (Vertex) { .position = simd_make_float4(size * sin(angle), size * cos(angle), 0.0, 1.0),
                   .normal = simd_make_float3(0.0, 0.0, 1.0),
                   .uv = simd_make_float2(0, 0) };

    angle = twoPi / 3.0;
    vtx[1] =
        (Vertex) { .position = simd_make_float4(size * sin(angle), size * cos(angle), 0.0, 1.0),
                   .normal = simd_make_float3(0.0, 0.0, 1.0),
                   .uv = simd_make_float2(0, 1) };

    angle = 2.0 * twoPi / 3.0;
    vtx[2] =
        (Vertex) { .position = simd_make_float4(size * sin(angle), size * cos(angle), 0.0, 1.0),
                   .normal = simd_make_float3(0.0, 0.0, 1.0),
                   .uv = simd_make_float2(1, 0) };

    ind[0] = (TriangleIndices) { .i0 = 0, .i1 = 2, .i2 = 1 };

    return (GeometryData) {
        .vertexCount = vertices, .vertexData = vtx, .indexCount = triangles, .indexData = ind
    };
}

GeometryData generateQuadGeometryData(float size) {
    const float halfSize = size * 0.5;

    const int vertices = 4;
    const int triangles = 2;

    Vertex *vtx = (Vertex *)malloc(vertices * sizeof(Vertex));
    TriangleIndices *ind = (TriangleIndices *)malloc(triangles * sizeof(TriangleIndices));

    vtx[0] = (Vertex) { .position = simd_make_float4(-halfSize, -halfSize, 0.0, 1.0),
                        .normal = simd_make_float3(0.0, 0.0, 1.0),
                        .uv = simd_make_float2(0.0, 1.0) };

    vtx[1] = (Vertex) { .position = simd_make_float4(halfSize, -halfSize, 0.0, 1.0),
                        .normal = simd_make_float3(0.0, 0.0, 1.0),
                        .uv = simd_make_float2(1.0, 1.0) };

    vtx[2] = (Vertex) { .position = simd_make_float4(halfSize, halfSize, 0.0, 1.0),
                        .normal = simd_make_float3(0.0, 0.0, 1.0),
                        .uv = simd_make_float2(1.0, 0.0) };

    vtx[3] = (Vertex) { .position = simd_make_float4(-halfSize, halfSize, 0.0, 1.0),
                        .normal = simd_make_float3(0.0, 0.0, 1.0),
                        .uv = simd_make_float2(0.0, 0.0) };

    ind[0] = (TriangleIndices) { .i0 = 0, .i1 = 1, .i2 = 2 };
    ind[1] = (TriangleIndices) { .i0 = 0, .i1 = 2, .i2 = 3 };

    return (GeometryData) {
        .vertexCount = vertices, .vertexData = vtx, .indexCount = triangles, .indexData = ind
    };
}

GeometryData generateSphereGeometryData(float radius, int angularResolution,
                                        int verticalResolution) {
    const int phi = angularResolution > 2 ? angularResolution : 3;
    const int layers = verticalResolution > 2 ? verticalResolution : 3;

    const float phif = (float)phi;
    const float layersf = (float)layers;

    const float phiMax = M_PI * 2.0;
    const float thetaMax = M_PI;

    const float phiInc = phiMax / phif;
    const float layerInc = thetaMax / layersf;

    int perLoop = phi + 1;

    const int vertices = (layers + 1) * perLoop;
    const int triangles = layers * phi * 2;

    Vertex *vtx = (Vertex *)malloc(vertices * sizeof(Vertex));
    TriangleIndices *ind = (TriangleIndices *)malloc(triangles * sizeof(TriangleIndices));

    int vertexIndex = 0;
    int triangleIndex = 0;
    for (int layer = 0; layer <= layers; layer++) {
        const float layerf = (float)layer;
        const float thetaAngle = layerf * layerInc;
        const float cosTheta = cos(thetaAngle);
        const float sinTheta = sin(thetaAngle);
        const float radiusTimesCosTheta = radius * cosTheta;
        const float radiusTimesSinTheta = radius * sinTheta;

        for (int p = 0; p <= phi; p++) {
            const float pf = (float)p;
            const float phiAngle = pf * phiInc;
            const float cosPhi = cos(phiAngle);
            const float sinPhi = sin(phiAngle);

            const float x = radiusTimesSinTheta * cosPhi;
            const float y = radiusTimesCosTheta;
            const float z = radiusTimesSinTheta * sinPhi;

            vtx[vertexIndex++] =
                (Vertex) { .position = simd_make_float4(x, y, z, 1.0),
                           .normal = simd_normalize(simd_make_float3(x, y, z)),
                           .uv = simd_make_float2(pf / phif, 1.0 - (layerf / layersf)) };

            if (p != phi && layer != layers) {
                const uint32_t index = p + layer * perLoop;

                const uint32_t tl = index;
                const uint32_t tr = tl + 1;
                const uint32_t bl = index + perLoop;
                const uint32_t br = bl + 1;

                ind[triangleIndex++] = (TriangleIndices) { .i0 = tl, .i1 = tr, .i2 = bl };
                ind[triangleIndex++] = (TriangleIndices) { .i0 = tr, .i1 = br, .i2 = bl };
            }
        }
    }

    return (GeometryData) {
        .vertexCount = vertices, .vertexData = vtx, .indexCount = triangles, .indexData = ind
    };
}

GeometryData generateIcoSphereGeometryData(float radius, int res) {
    const float phi = (1.0 + sqrt(5)) * 0.5;
    const float r2 = radius * radius;
    const float den = (1.0 + (1.0 / pow(phi, 2.0)));
    const float h = sqrt(r2 / (den));
    const float w = h / phi;

    int vertices = 12;
    int triangles = 20;

    Vertex *vtx = (Vertex *)malloc(vertices * sizeof(Vertex));
    TriangleIndices *ind = (TriangleIndices *)malloc(triangles * sizeof(TriangleIndices));

    vtx[0].position = simd_make_float4(0.0, h, w, 1.0);
    vtx[1].position = simd_make_float4(0.0, h, -w, 1.0);
    vtx[2].position = simd_make_float4(0.0, -h, w, 1.0);
    vtx[3].position = simd_make_float4(0.0, -h, -w, 1.0);

    vtx[4].position = simd_make_float4(h, -w, 0.0, 1.0);
    vtx[5].position = simd_make_float4(h, w, 0.0, 1.0);
    vtx[6].position = simd_make_float4(-h, -w, 0.0, 1.0);
    vtx[7].position = simd_make_float4(-h, w, 0.0, 1.0);

    vtx[8].position = simd_make_float4(-w, 0.0, -h, 1.0);
    vtx[9].position = simd_make_float4(w, 0.0, -h, 1.0);
    vtx[10].position = simd_make_float4(-w, 0.0, h, 1.0);
    vtx[11].position = simd_make_float4(w, 0.0, h, 1.0);

    ind[0] = (TriangleIndices) { 0, 11, 5 };
    ind[1] = (TriangleIndices) { 0, 5, 1 };
    ind[2] = (TriangleIndices) { 0, 1, 7 };
    ind[3] = (TriangleIndices) { 0, 7, 10 };
    ind[4] = (TriangleIndices) { 0, 10, 11 };

    ind[5] = (TriangleIndices) { 1, 5, 9 };
    ind[6] = (TriangleIndices) { 5, 11, 4 };
    ind[7] = (TriangleIndices) { 11, 10, 2 };
    ind[8] = (TriangleIndices) { 10, 7, 6 };
    ind[9] = (TriangleIndices) { 7, 1, 8 };

    ind[10] = (TriangleIndices) { 3, 9, 4 };
    ind[11] = (TriangleIndices) { 3, 4, 2 };
    ind[12] = (TriangleIndices) { 3, 2, 6 };
    ind[13] = (TriangleIndices) { 3, 6, 8 };
    ind[14] = (TriangleIndices) { 3, 8, 9 };

    ind[15] = (TriangleIndices) { 4, 9, 5 };
    ind[16] = (TriangleIndices) { 2, 4, 11 };
    ind[17] = (TriangleIndices) { 6, 2, 10 };
    ind[18] = (TriangleIndices) { 8, 6, 7 };
    ind[19] = (TriangleIndices) { 9, 8, 1 };

    for (int r = 0; r < res; r++) {
        int newTriangles = triangles * 4;
        int newVertices = vertices + triangles * 3;
        vtx = (Vertex *)realloc(vtx, newVertices * sizeof(Vertex));
        TriangleIndices *newInd = (TriangleIndices *)malloc(newTriangles * sizeof(TriangleIndices));

        int j = vertices;
        int k = 0;
        simd_float3 pos;
        for (int i = 0; i < triangles; i++) {
            TriangleIndices t = ind[i];
            const int i0 = t.i0;
            const int i1 = t.i1;
            const int i2 = t.i2;

            const Vertex v0 = vtx[i0];
            const Vertex v1 = vtx[i1];
            const Vertex v2 = vtx[i2];

            // a
            pos = simd_make_float3(v0.position + v1.position) * 0.5;
            pos = simd_normalize(pos) * radius;
            vtx[j].position = simd_make_float4(pos, 1.0);
            uint32_t a = (uint32_t)j;
            j++;

            // b
            pos = simd_make_float3(v1.position + v2.position) * 0.5;
            pos = simd_normalize(pos) * radius;
            vtx[j].position = simd_make_float4(pos, 1.0);
            uint32_t b = (uint32_t)j;
            j++;
            // c
            pos = simd_make_float3(v2.position + v0.position) * 0.5;
            pos = simd_normalize(pos) * radius;
            vtx[j].position = simd_make_float4(pos, 1.0);
            uint32_t c = (uint32_t)j;
            j++;

            newInd[k] = (TriangleIndices) { i0, a, c };
            k++;
            newInd[k] = (TriangleIndices) { a, i1, b };
            k++;
            newInd[k] = (TriangleIndices) { a, b, c };
            k++;
            newInd[k] = (TriangleIndices) { c, b, i2 };
            k++;
        }

        free(ind);
        ind = newInd;
        triangles = newTriangles;
        vertices = newVertices;
    }

    for (int i = 0; i < vertices; i++) {
        const simd_float4 p = vtx[i].position;
        const simd_float3 n = simd_normalize(simd_make_float3(p.x, p.y, p.z));
        vtx[i].normal = n;
        vtx[i].uv = simd_make_float2((atan2(n.x, n.z) + M_PI) / (2.0 * M_PI), acos(n.y) / M_PI);
    }

    return (GeometryData) {
        .vertexCount = vertices, .vertexData = vtx, .indexCount = triangles, .indexData = ind
    };
}

// Referenced from: https://prideout.net/blog/octasphere/

GeometryData generateOctaSphereGeometryData(float radius, int res)
{
    const int n = (1 << res) + 1;
    const float nf = (float)n;
    
    const int verticesPerPatch = n * (n + 1) / 2;
    const int trianglesPerPatch = (n - 2) * (n - 1) + n - 1;
    const int patches = 1;
    
    const int vertices = verticesPerPatch * patches;
    const int triangles = trianglesPerPatch * patches;

    Vertex *vtx = (Vertex *)malloc(vertices * sizeof(Vertex));
    TriangleIndices *ind = (TriangleIndices *)malloc(triangles * sizeof(TriangleIndices));

    const int nMinusOne = n - 1;
    const float nMinusOnef = nf - 1.0;
    
    const simd_float2 uv = simd_make_float2(0.0, 0.0);
    const simd_float3 normal = simd_make_float3(0.0, 0.0, 0.0);
    
    int vertexIndex = 0;
    for (int v = 0; v < n; v++) {
        const float vf = (float)v;
        const float theta = M_PI_2 * vf / nMinusOnef;
        
        const float cosTheta = cos(theta);
        const float sinTheta = sin(theta);
        
        const simd_float3 a = simd_make_float3(0.0, sinTheta, cosTheta);
        const simd_float3 b = simd_make_float3(cosTheta, sinTheta, 0.0);
        
        const int segments = n - 1 - v;
        
        vtx[vertexIndex++] = (Vertex) {
            .position = simd_make_float4(radius * a, 1.0),
            .normal = normal,
            .uv = uv
        };
        
        if(segments > 0) {
            const float angle = acos(simd_dot(a, b));
            const float angleInc = angle / (float)segments;
            const simd_float3 axis = simd_normalize(simd_cross(a, b));
            
            for(int s = 1; s < segments; s++) {
                const float sf = (float)s;
                const simd_quatf quat = simd_quaternion(sf * angleInc, axis);
                const simd_float3 p = simd_act(quat, a);
                vtx[vertexIndex++] = (Vertex) {
                    .position = simd_make_float4(radius * p, 1.0),
                    .normal = normal,
                    .uv = uv
                };
            }
        
            vtx[vertexIndex++] = (Vertex) {
                .position = simd_make_float4(radius * b, 1.0),
                .normal = normal,
                .uv = uv
            };
        }
    }
    
    int j0 = 0;
    int triangleIndex = 0;
    for (int col_index = 0; col_index < nMinusOne; col_index++) {
        const int col_height = n - 1 - col_index;
        const int j1 = j0 + 1;
        const int j2 = j0 + col_height + 1;
        const int j3 = j0 + col_height + 2;
        for (int row = 0; row < col_height - 1; row++) {
            ind[triangleIndex++] = (TriangleIndices) { .i0 = j0 + row, .i1 = j1 + row, .i2 = j2 + row };
            ind[triangleIndex++] = (TriangleIndices) { .i0 = j2 + row, .i1 = j1 + row, .i2 = j3 + row };
        }
        const int row = col_height - 1;
        ind[triangleIndex++] = (TriangleIndices) { .i0 = j0 + row, .i1 = j1 + row, .i2 = j2 + row };
        j0 = j2;
    }
    
    GeometryData geoData = (GeometryData) {
        .vertexCount = vertices, .vertexData = vtx, .indexCount = triangles, .indexData = ind
    };
    
    {
        GeometryData copied;
        copyGeometryData(&copied, &geoData);
        transformGeometryData(&copied, simd_matrix4x4(simd_quaternion(M_PI_2, simd_make_float3(0.0, 1.0, 0.0))));
        combineGeometryData(&geoData, &copied);
        freeGeometryData(&copied);
    }
    
    {
        GeometryData copied;
        copyGeometryData(&copied, &geoData);
        transformGeometryData(&copied, simd_matrix4x4(simd_quaternion(M_PI, simd_make_float3(0.0, 1.0, 0.0))));
        combineGeometryData(&geoData, &copied);
        freeGeometryData(&copied);
    }
    
    {
        GeometryData copied;
        copyGeometryData(&copied, &geoData);
        transformGeometryData(&copied, simd_matrix4x4(simd_quaternion(M_PI, simd_make_float3(1.0, 0.0, 0.0))));
        combineGeometryData(&geoData, &copied);
        freeGeometryData(&copied);
    }
    
    for (int i = 0; i < geoData.vertexCount; i++) {
        const simd_float4 p = geoData.vertexData[i].position;
        const simd_float3 n = simd_normalize(simd_make_float3(p.x, p.y, p.z));
        geoData.vertexData[i].normal = n;
        geoData.vertexData[i].uv = simd_make_float2((atan2(n.x, n.z) + M_PI) / (2.0 * M_PI), acos(n.y) / M_PI);
    }
    
    return geoData;
}

GeometryData generateSquircleGeometryData(float size, float p, int angularResolution,
                                          int radialResolution) {
    const float rad = size * 0.5;
    const int angular = angularResolution > 2 ? angularResolution : 3;
    const int radial = radialResolution > 1 ? radialResolution : 1;

    const int perLoop = angular + 1;
    const int vertices = perLoop * (radial + 1);
    const int triangles = angular * 2 * radial;

    Vertex *vtx = (Vertex *)malloc(vertices * sizeof(Vertex));
    TriangleIndices *ind = (TriangleIndices *)malloc(triangles * sizeof(TriangleIndices));

    int vertexIndex = 0;
    int triangleIndex = 0;

    for (int r = 0; r <= radial; r++) {
        const float k = r / (float)radial;
        const float radius = map(r, 0.0, radial, 0.0, rad);

        for (int a = 0; a <= angular; a++) {
            const float t = a / (float)angular;
            const float theta = 2.0 * M_PI * t;

            const float cost = cos(theta);
            const float sint = sin(theta);

            const float den = pow(fabs(cost), p) + pow(fabs(sint), p);
            const float phi = 1.0 / pow(den, 1.0 / p);

            const float x = radius * phi * cost;
            const float y = radius * phi * sint;

            vtx[vertexIndex++] = (Vertex) { .position = simd_make_float4(x, y, 0.0, 1.0),
                                            .normal = simd_make_float3(0.0, 0.0, 1.0),
                                            .uv = simd_make_float2(t, k) };

            if (r != radial && a != angular) {
                const uint32_t index = a + r * perLoop;

                const uint32_t tl = index;
                const uint32_t tr = tl + 1;
                const uint32_t bl = index + perLoop;
                const uint32_t br = bl + 1;

                ind[triangleIndex++] = (TriangleIndices) { .i0 = tl, .i1 = bl, .i2 = tr };
                ind[triangleIndex++] = (TriangleIndices) { .i0 = tr, .i1 = bl, .i2 = br };
            }
        }
    }

    return (GeometryData) {
        .vertexCount = vertices, .vertexData = vtx, .indexCount = triangles, .indexData = ind
    };
}

GeometryData generateRoundedRectGeometryData(float width, float height, float radius,
                                             int angularResolution, int edgeXResolution,
                                             int edgeYResolution, int radialResolution) {
    const float twoPi = M_PI * 2.0;
    const float halfPi = M_PI * 0.5;

    const int angular = angularResolution > 2 ? angularResolution : 3;
    const int angularMinusOne = angular - 1;
    const float angularMinusOnef = (float)angularMinusOne;
    
    const int radial = radialResolution > 1 ? radialResolution : 2;
    const float radialf = (float)radial;
    const float radialMinusOnef = radialf - 1.0;
        
    int edgeX = edgeXResolution > 1 ? edgeXResolution : 2;
//    edgeX += edgeX % 2 == 0 ? 1 : 0;
    
    const int edgeXMinusOne = edgeX - 1;
    const float edgeXMinusOnef = (float)edgeXMinusOne;
    
    int edgeY = edgeYResolution > 1 ? edgeYResolution : 2;
//    edgeY += edgeY % 2 == 0 ? 1 : 0;
    
    const int edgeYMinusOne = edgeY - 1;
    const float edgeYMinusOnef = (float)edgeYMinusOne;

    const int perLoop = (angular - 2) * 4 + edgeX * 2 + edgeY * 2;
    const int vertices = perLoop * radial;
    const int triangles = perLoop * 2 * (radial - 1);

    Vertex *vtx = (Vertex *)malloc(vertices * sizeof(Vertex));
    TriangleIndices *ind = (TriangleIndices *)malloc(triangles * sizeof(TriangleIndices));

    const float widthHalf = width * 0.5;
    const float heightHalf = height * 0.5;

    const float minDim = (widthHalf < heightHalf ? widthHalf : heightHalf);
    radius = radius > minDim ? minDim : radius;
    
    int vertexIndex = 0;
    int triangleIndex = 0;
    
    const simd_float3 normal = simd_make_float3(0.0, 0.0, 1.0);
    
    for (int j = 0; j < radial; j++) {
        const float n = (float)j / radialMinusOnef;

        // +X, -Y -> +Y
        simd_float2 start = simd_make_float2(widthHalf, -heightHalf + radius);
        simd_float2 end = simd_make_float2(widthHalf, heightHalf - radius);
        for (int i = 0; i < edgeY; i++) {
            const float t = (float)i / edgeYMinusOnef;
            const simd_float2 pos = simd_mix(start, end, t);
            
            vtx[vertexIndex].position = simd_make_float4(n * pos, 0.0, 1.0);
            vtx[vertexIndex].normal = normal;
            
            const float angle = angle2(pos);
            const float uvx = angle / twoPi;
            const float uvy = n;
            
            vtx[vertexIndex].uv = simd_make_float2(uvx, uvy);
            vertexIndex++;
        }

        // corner 0
        for (int i = 1; i < angularMinusOne; i++) {
            const float t = (float)i / angularMinusOnef;
            const float theta = t * halfPi;
            const float x = radius * cos(theta);
            const float y = radius * sin(theta);
            const simd_float2 pos = simd_make_float2(widthHalf - radius + x, heightHalf - radius + y);
            
            vtx[vertexIndex].position = simd_make_float4(n * pos, 0.0, 1.0);
            vtx[vertexIndex].normal = normal;
            
            const float angle = angle2(pos);
            const float uvx = angle / twoPi;
            const float uvy = n;
            
            vtx[vertexIndex].uv = simd_make_float2(uvx, uvy);
            vertexIndex++;
        }

        // +Y, +X -> -X
        start = simd_make_float2(widthHalf - radius, heightHalf);
        end = simd_make_float2(-widthHalf + radius, heightHalf);
        for (int i = 0; i < edgeX; i++) {
            const float t = (float)i / edgeXMinusOnef;
            const simd_float2 pos = simd_mix(start, end, t);
            
            vtx[vertexIndex].position = simd_make_float4(n * pos, 0.0, 1.0);
            vtx[vertexIndex].normal = normal;
            
            const float angle = angle2(pos);
            const float uvx = angle / twoPi;
            const float uvy = n;
            
            vtx[vertexIndex].uv = simd_make_float2(uvx, uvy);
            vertexIndex++;
        }

        // corner 1
        for (int i = 1; i < angularMinusOne; i++) {
            const float t = (float)i / angularMinusOnef;
            const float theta = t * halfPi + halfPi;
            const float x = radius * cos(theta);
            const float y = radius * sin(theta);
            const simd_float2 pos = simd_make_float2(-widthHalf + radius + x, heightHalf - radius + y);
            
            vtx[vertexIndex].position = simd_make_float4(n * pos, 0.0, 1.0);
            vtx[vertexIndex].normal = normal;
            
            const float angle = angle2(pos);
            const float uvx = angle / twoPi;
            const float uvy = n;
            
            vtx[vertexIndex].uv = simd_make_float2(uvx, uvy);
            vertexIndex++;
        }

        // -X, +Y -> -Y
        start = simd_make_float2(-widthHalf, heightHalf - radius);
        end = simd_make_float2(-widthHalf, -heightHalf + radius);
        for (int i = 0; i < edgeY; i++) {
            const float t = (float)i / edgeYMinusOnef;
            const simd_float2 pos = simd_mix(start, end, t);

            vtx[vertexIndex].position = simd_make_float4(n * pos, 0.0, 1.0);
            vtx[vertexIndex].normal = normal;

            const float angle = angle2(pos);
            const float uvx = angle / twoPi;
            const float uvy = n;
            
            vtx[vertexIndex].uv = simd_make_float2(uvx, uvy);
            vertexIndex++;
        }

        // corner 2
        for (int i = 1; i < angularMinusOne; i++) {
            const float t = (float)i / angularMinusOnef;
            const float theta = t * halfPi + M_PI;
            const float x = radius * cos(theta);
            const float y = radius * sin(theta);
            const simd_float2 pos = simd_make_float2(-widthHalf + radius + x, -heightHalf + radius + y);
            
            vtx[vertexIndex].position = simd_make_float4(n * pos, 0.0, 1.0);
            vtx[vertexIndex].normal = normal;
            
            const float angle = angle2(pos);
            const float uvx = angle / twoPi;
            const float uvy = n;
            
            vtx[vertexIndex].uv = simd_make_float2(uvx, uvy);
            vertexIndex++;
        }
        
        // -Y, -X -> +X
        start = simd_make_float2(-widthHalf + radius, -heightHalf);
        end = simd_make_float2(widthHalf - radius, -heightHalf);
        for (int i = 0; i < edgeX; i++) {
            const float t = (float)i / edgeXMinusOnef;
            const simd_float2 pos = simd_mix(start, end, t);

            vtx[vertexIndex].position = simd_make_float4(n * pos, 0.0, 1.0);
            vtx[vertexIndex].normal = normal;

            const float angle = angle2(pos);
            const float uvx = angle / twoPi;
            const float uvy = n;
            
            vtx[vertexIndex].uv = simd_make_float2(uvx, uvy);
            vertexIndex++;
        }

        // corner 3
        for (int i = 1; i < angularMinusOne; i++) {
            const float t = (float)i / angularMinusOnef;
            const float theta = t * halfPi + 1.5 * M_PI;
            const float x = radius * cos(theta);
            const float y = radius * sin(theta);
            const simd_float2 pos = simd_make_float2(widthHalf - radius + x, -heightHalf + radius + y);
            
            vtx[vertexIndex].position = simd_make_float4(n * pos, 0.0, 1.0);
            vtx[vertexIndex].normal = normal;
            
            float angle = angle2(pos);
            angle = isZero(angle) ? twoPi : angle;
            
            const float uvx = angle / twoPi;
            const float uvy = n;

            vtx[vertexIndex].uv = simd_make_float2(uvx, uvy);
            vertexIndex++;
        }
        
        for (int i = 0; i < perLoop; i++) {
            if ((j + 1) != radial) {
                const uint32_t currLoop = j * perLoop;
                const uint32_t nextLoop = (j + 1) * perLoop;
                const uint32_t next = (i + 1) % perLoop;

                const uint32_t i0 = currLoop + i;
                const uint32_t i1 = currLoop + next;
                const uint32_t i2 = nextLoop + i;
                const uint32_t i3 = nextLoop + next;

                ind[triangleIndex++] = (TriangleIndices) { .i0 = i0, .i1 = i2, .i2 = i3 };
                ind[triangleIndex++] = (TriangleIndices) { .i0 = i0, .i1 = i3, .i2 = i1 };
            }
        }
    }

    return (GeometryData) {
        .vertexCount = vertices, .vertexData = vtx, .indexCount = triangles, .indexData = ind
    };
}

GeometryData generateExtrudedRoundedRectGeometryData(float width, float height, float depth,
                                                     float radius, int angularResolution,
                                                     int edgeXResolution, int edgeYResolution,
                                                     int edgeZResolution, int radialResolution) {
    GeometryData faceData =
        generateRoundedRectGeometryData(width, height, radius, angularResolution, edgeXResolution,
                                        edgeYResolution, radialResolution);

    GeometryData result = {
        .vertexCount = 0, .vertexData = NULL, .indexCount = 0, .indexData = NULL
    };

    float depthHalf = depth * 0.5;
    combineAndOffsetGeometryData(&result, &faceData, simd_make_float3(0.0, 0.0, depthHalf));

    // Calculations from RoundedRectGeometry
    int angular = angularResolution > 2 ? angularResolution : 3;
    int radial = radialResolution > 1 ? radialResolution : 2;
    int edgeX = edgeXResolution > 1 ? edgeXResolution : 2;
    int edgeY = edgeYResolution > 1 ? edgeYResolution : 2;
    int edgeZ = edgeZResolution > 0 ? edgeZResolution : 1;

    int perLoop = (angular - 2) * 4 + edgeX * 2 + edgeY * 2;
    int vertices = perLoop * radial;

    GeometryData edgeData = {
        .vertexCount = 0, .vertexData = NULL, .indexCount = 0, .indexData = NULL
    };

    copyGeometryVertexData(&edgeData, &result, vertices - perLoop, perLoop);

    int extrudeTriangles = perLoop * 2 * edgeZ;
    TriangleIndices *ind = (TriangleIndices *)malloc(extrudeTriangles * sizeof(TriangleIndices));

    GeometryData extrudeData = {
        .vertexCount = 0, .vertexData = NULL, .indexCount = extrudeTriangles, .indexData = ind
    };

    int triIndex = 0;
    float zInc = depth / edgeZ;
    for (int j = 0; j <= edgeZ; j++) {
        float z = j * zInc;
        float uvx = (float)j / (float)edgeZ;
        int currLoop = j * perLoop;
        int nextLoop = (j + 1) * perLoop;
        for (int i = 0; i < perLoop; i++) {
            float uvy = (float)i / (float)perLoop;
            edgeData.vertexData[i].uv = simd_make_float2(uvx, uvy);
            edgeData.vertexData[i].position.z -= z;

            int prev = i - 1;
            prev = prev < 0 ? (perLoop - 1) : prev;
            int curr = i;
            int next = (i + 1) % perLoop;

            simd_float4 prevPos = edgeData.vertexData[prev].position;
            simd_float4 currPos = edgeData.vertexData[curr].position;
            simd_float4 nextPos = edgeData.vertexData[next].position;

            simd_float4 d0 = prevPos - currPos;
            simd_float4 d1 = currPos - nextPos;

            d0 += d1;
            edgeData.vertexData[i].normal = simd_normalize(simd_make_float3(-d0.y, d0.x, 0.0));

            if (j != edgeZ) {
                int i0 = currLoop + curr;
                int i1 = currLoop + next;

                int i2 = nextLoop + curr;
                int i3 = nextLoop + next;

                ind[triIndex] = (TriangleIndices) { i0, i2, i3 };
                triIndex++;
                ind[triIndex] = (TriangleIndices) { i0, i3, i1 };
                triIndex++;
            }
        }
        combineGeometryData(&extrudeData, &edgeData);
    }

    combineGeometryData(&result, &extrudeData);
    reverseFacesOfGeometryData(&faceData);
    combineAndOffsetGeometryData(&result, &faceData, simd_make_float3(0.0, 0.0, -depthHalf));

    freeGeometryData(&edgeData);
    freeGeometryData(&extrudeData);
    freeGeometryData(&faceData);

    return result;
}
