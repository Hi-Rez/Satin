#if defined(LIGHTING) && defined(MAX_LIGHTS)
void pbrDirectLighting(thread PixelInfo &pixel, constant LightData *lights)
{
    float3 N = pixel.normal;
    float3 V = pixel.view;
    float NdotV = dot(N, V);
    for (int i = 0; i < MAX_LIGHTS; i++) {
        float3 L;
        float lightDistance;
        const float3 lightRadiance = getLightInfo(lights[i], pixel.position, L, lightDistance);
        float NdotL = dot(N, L);
        pixel.radiance += evalBRDF(pixel, L, NdotL, NdotV) * lightRadiance * saturate(NdotL) * pixel.material.ambientOcclusion;
    }
}
#endif
