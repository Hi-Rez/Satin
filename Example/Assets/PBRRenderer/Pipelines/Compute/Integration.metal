// From the filament docs. Geometric Shadowing function
// https://google.github.io/filament/Filament.html#toc4.4.2
float D_Smith(float NoV, float NoL, float roughness)
{
    float k = (roughness * roughness) / 2.0;
    float GGXL = NoL / (NoL * (1.0 - k) + k);
    float GGXV = NoV / (NoV * (1.0 - k) + k);
    return GGXL * GGXV;
}

// From the filament docs. Geometric Shadowing function
// https://google.github.io/filament/Filament.html#toc4.4.2
float V_SmithGGXCorrelated(float NoV, float NoL, float roughness) {
    float a2 = pow(roughness, 4.0);
    float GGXV = NoL * sqrt(NoV * NoV * (1.0 - a2) + a2);
    float GGXL = NoV * sqrt(NoL * NoL * (1.0 - a2) + a2);
    return 0.5 / (GGXV + GGXL);
}

// Based on Karis 2014
float3 importanceSampleGGX(float2 Xi, float roughness, float3 N)
{
    float a = roughness * roughness;
    // Sample in spherical coordinates
    float Phi = 2.0 * PI * Xi.x;
    float CosTheta = sqrt((1.0 - Xi.y) / (1.0 + (a*a - 1.0) * Xi.y));
    float SinTheta = sqrt(1.0 - CosTheta * CosTheta);
    // Construct tangent space vector
    float3 H;
    H.x = SinTheta * cos(Phi);
    H.y = SinTheta * sin(Phi);
    H.z = CosTheta;
    
    // Tangent to world space
    float3 UpVector = abs(N.z) < 0.999 ? float3(0.0,0.0,1.0) : float3(1.0,0.0,0.0);
    float3 TangentX = normalize(cross(UpVector, N));
    float3 TangentY = cross(N, TangentX);
    return TangentX * H.x + TangentY * H.y + N * H.z;
}

// Karis 2014
float2 integrate(float NoV, float roughness)
{
    float3 V;
    V.x = sqrt(1.0 - NoV * NoV); // sin
    V.y = 0.0;
    V.z = NoV; // cos
    
    // N points straight upwards for this integration
    const float3 N = float3(0.0, 0.0, 1.0);
    
    float A = 0.0;
    float B = 0.0;
    
    
    for (uint i = 0u; i < SAMPLE_COUNT; i++) {
        float2 Xi = hammersley(i, SAMPLE_COUNT);
        
        // Sample microfacet direction
        float3 H = importanceSampleGGX(Xi, roughness, N);
        
        // Get the light direction
        float3 L = 2.0 * dot(V, H) * H - V;
        
        float NoL = saturate(dot(N, L));
        float NoH = saturate(dot(N, H));
        float VoH = saturate(dot(V, H));
        
        if(NoL > 0.0) {
            float V_pdf = V_SmithGGXCorrelated(NoV, NoL, roughness) * VoH * NoL / NoH;
            float Fc = pow(1.0 - VoH, 5.0);
            A += (1.0 - Fc) * V_pdf;
            B += Fc * V_pdf;
        }
    }

    return 4.0 * float2(A, B) / float(SAMPLE_COUNT);
}

kernel void integrationCompute(uint2 gid [[thread_position_in_grid]],
                               texture2d<float, access::write> tex [[texture( 0 )]])
{
    if(gid.x >= tex.get_width() || gid.y >= tex.get_height()) { return; }
    const float2 size = float2( tex.get_width(), tex.get_height() );
    const float2 uv = float2( gid + 1 ) / size;
    tex.write( float4( integrate( uv.x, uv.y ), 0.0, 1.0 ), gid );
}
