/*
 * SolisLite - lib/sky.glsl
 * Softes Hoehen-Scattering, VoS-Sonne, planare 2D-Wolken, 5 Stimmungen.
 */
#ifndef SOLISLITE_SKY_GLSL
#define SOLISLITE_SKY_GLSL
#include "common.glsl"

float thunderAmount() {
    return clamp(wetness * 1.15 - rainStrength * 0.25, 0.0, 1.0);
}

vec3 skyPaletteZenith(float sunH, float rain, float thun) {
    vec3 day   = vec3(0.22, 0.48, 0.92);
    vec3 dusk  = vec3(0.25, 0.20, 0.42);
    vec3 night = vec3(0.015, 0.020, 0.050);
    vec3 col = mix(night, dusk, smoothstep(-0.20, 0.05, sunH));
    col = mix(col, day, smoothstep(0.05, 0.32, sunH));
    col = mix(col, vec3(0.26, 0.30, 0.36), rain * 0.85);
    col = mix(col, vec3(0.09, 0.10, 0.13), thun * 0.90);
    return col;
}

vec3 skyPaletteHorizon(float sunH, float rain, float thun) {
    vec3 day   = vec3(0.65, 0.78, 0.95);
    vec3 dusk  = vec3(0.98, 0.50, 0.28);
    vec3 night = vec3(0.06, 0.07, 0.11);
    vec3 col = mix(night, dusk, smoothstep(-0.12, 0.08, sunH));
    col = mix(col, day, smoothstep(0.05, 0.38, sunH));
    col = mix(col, vec3(0.40, 0.42, 0.46), rain * 0.85);
    col = mix(col, vec3(0.15, 0.16, 0.19), thun * 0.90);
    return col;
}

float planarCloudNoise(vec2 p) {
    float n = valueNoise(p);
    n += valueNoise(p * 2.05 + 7.3) * 0.50;
    n += valueNoise(p * 4.10 + 19.1) * 0.25;
    return n * 0.57;
}

float planarCloudMask(vec3 worldDir, float time) {
    float up = worldDir.y;
    if (up < 0.015) return 0.0;

    vec2 plane = worldDir.xz / max(up, 0.08);
    plane *= 0.50;
    plane += vec2(time * 0.004, time * 0.0022);
    plane.x += sin(plane.y * 1.4 + time * 0.05) * 0.10;
    plane.y += cos(plane.x * 1.1 + time * 0.04) * 0.10;

    float n = planarCloudNoise(plane);
    n = n * 0.6 + planarCloudNoise(plane * 1.35 + 5.0) * 0.4;

    // Etwas mehr Wolken als zuvor (niedrigerer Schwellwert)
    float c = smoothstep(0.42, 0.62, n);
    c = clamp(c * (1.0 + rainStrength * 0.55 + thunderAmount() * 0.45), 0.0, 1.0);

    float fade = smoothstep(0.015, 0.10, up) * (1.0 - smoothstep(0.50, 0.95, up) * 0.35);
    return c * fade;
}

vec3 planarCloudColor(float sunH, float VoS, float rain, float thun) {
    vec3 dayC   = vec3(0.96, 0.97, 1.00);
    vec3 duskC  = vec3(1.00, 0.72, 0.55);
    vec3 nightC = vec3(0.24, 0.27, 0.36);
    vec3 rainC  = vec3(0.50, 0.52, 0.56);
    vec3 thunC  = vec3(0.22, 0.23, 0.26);

    vec3 col = mix(nightC, duskC, smoothstep(-0.12, 0.08, sunH));
    col = mix(col, dayC, smoothstep(0.05, 0.30, sunH));
    col = mix(col, rainC, rain * 0.9);
    col = mix(col, thunC, thun * 0.95);
    float lit = mix(0.68, 1.12, pow(max(VoS, 0.0), 1.2) * 0.5 + 0.5);
    return col * lit;
}

vec3 getSkyGradient(vec3 worldDir, vec3 sunDir) {
    float sunH = clamp(sunDir.y, -1.0, 1.0);
    float VoS  = max(dot(worldDir, sunDir), 0.0);
    float rain = clamp(rainStrength, 0.0, 1.0);
    float thun = thunderAmount();
    float day  = smoothstep(-0.06, 0.12, sunH);

    vec3 zenith  = skyPaletteZenith(sunH, rain, thun);
    vec3 horizon = skyPaletteHorizon(sunH, rain, thun);

    // Soft height scattering
    float elev = clamp(worldDir.y, -1.0, 1.0);
    float hf = pow(clamp(1.0 - elev, 0.0, 1.0), 2.2 - VoS * 0.7);
    hf *= sqrt(clamp(1.0 + elev, 0.0, 1.0) + 0.05);
    vec3 sky = mix(zenith, horizon, clamp(hf, 0.0, 1.0));
    float below = smoothstep(0.0, -0.35, elev);
    sky = mix(sky, horizon * 0.55, below * 0.65);

    // Daemmerung
    float dusk = (1.0 - smoothstep(0.0, 0.28, abs(sunH))) * (1.0 - rain * 0.6);
    sky += vec3(0.98, 0.50, 0.28) * pow(VoS, 4.0) * dusk * 0.50;

    // ---- Sonne (hohe pow wie bei guten Packs, rein analytisch) ----
    float sunVis = day * (1.0 - rain * 0.5) * (1.0 - thun * 0.75);
    vec3 sunCol = mix(vec3(1.0, 0.62, 0.35), vec3(1.05, 0.98, 0.92), smoothstep(0.0, 0.25, sunH));
    // Glare
    float glare = pow(VoS, 32.0) * 0.35 * sunVis;
    sky += sunCol * glare;
    // Scheibe: pow^64 aehnlich, dann Schwellwert
    float sunCore = max(pow(VoS, 64.0) - 0.35, 0.0) * 12.0 * sunVis;
    sky += sunCol * sunCore;
    // Extra enger Kern
    sky += sunCol * pow(VoS, 256.0) * 2.5 * sunVis;

    // ---- Planare Wolken ----
    float cloud = planarCloudMask(worldDir, frameTimeCounter);
    if (cloud > 0.01) {
        vec3 ccol = planarCloudColor(sunH, VoS, rain, thun);
        float dens = cloud * mix(0.55, 0.95, CLOUD_OPACITY);
        dens = clamp(dens * (1.0 + rain * 0.3 + thun * 0.25), 0.0, 1.0);
        sky = mix(sky, ccol, dens);
    }

    return sky;
}

vec3 applyHorizonHaze(vec3 skyColor, vec3 worldDir, vec3 sunDir) {
    float y = worldDir.y;
    float haze = exp(-pow(y * 2.6, 2.0)) * 0.30;
    haze += pow(1.0 - clamp(abs(y), 0.0, 1.0), 1.5) * 0.12;
    haze = clamp(haze * (1.0 + rainStrength * 0.35), 0.0, 0.55);
    float sunH = clamp(sunDir.y, -1.0, 1.0);
    vec3 hz = skyPaletteHorizon(sunH, rainStrength, thunderAmount());
    return mix(skyColor, hz, haze);
}

vec3 tintCelestialBody(vec3 texColor, bool isSun, float sunHeight) {
    if (isSun) return mix(vec3(1.0, 0.6, 0.3), vec3(1.1, 1.0, 0.95), smoothstep(-0.05, 0.3, sunHeight));
    return texColor * vec3(0.85, 0.88, 0.98);
}

#endif
