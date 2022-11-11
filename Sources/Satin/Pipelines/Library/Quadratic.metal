float3 quadratic(float a, float b, float c)
{
    float3 solution = float3(0.0, 0.0, -1.0); // x1, x2, solved
    if (b == 0) {
        // Handle special case where the the two vector ray.dir and V are perpendicular
        // with V = ray.orig - sphere.centre
        if (a == 0) return solution;
        solution.x = 0.0;
        solution.y = sqrt(-c / a);
        solution.z = 1.0;
        return solution;
    }

    float discr = b * b - 4.0 * a * c;
    if (discr < 0) return solution;

    float q = (b < 0.0) ? -0.5 * (b - sqrt(discr)) : -0.5 * (b + sqrt(discr));
    solution.x = q / a;
    solution.y = c / q;
    solution.z = 1.0;
    return solution;
}
