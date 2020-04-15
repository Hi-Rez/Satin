float3x3 rotateAxisAngle(float3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    return float3x3(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s,
                    oc * axis.z * axis.x + axis.y * s,
                    oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c,
                    oc * axis.y * axis.z - axis.x * s,
                    oc * axis.z * axis.x - axis.y * s,
                    oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c);
}
