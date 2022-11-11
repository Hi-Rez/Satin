#include "Quadratic.metal"

float3 raySphereIntersect(float3 orig, float3 dir, float radius)
{
    float3 solution = float3(0.0, 0.0, -1.0);
    // They ray dir is normalized so A = 1
    float A = dir.x * dir.x + dir.y * dir.y + dir.z * dir.z;
    float B = 2.0 * (dir.x * orig.x + dir.y * orig.y + dir.z * orig.z);
    float C = orig.x * orig.x + orig.y * orig.y + orig.z * orig.z - radius * radius;
    float3 quadraticSolve = quadratic(A, B, C);
    if (quadraticSolve.z < 0) { return solution; }

    solution.x = min(quadraticSolve.x, quadraticSolve.y);
    solution.y = max(quadraticSolve.x, quadraticSolve.y);
    solution.z = 1.0;
    return solution;
}
