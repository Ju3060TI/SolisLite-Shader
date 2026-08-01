/*
 * SolisLite - lib/water.glsl
 * Stabiles Wasser OHNE colortex2 (kein SSR, keine Refraction).
 */
#ifndef SOLISLITE_WATER_GLSL
#define SOLISLITE_WATER_GLSL
#include "common.glsl"

float waterHeightLarge(vec2 wxz, float t) {
    float h = 0.0;
    h += sin(wxz.x * 0.32 + t * 0.70) * 0.055;
    h += sin(wxz.y * 0.27 - t * 0.52 + wxz.x * 0.14) * 0.045;
    h += sin((wxz.x + wxz.y) * 0.19 + t * 0.38) * 0.028;
    return h;
}

float waterHeightDetail(vec2 wxz, float t) {
    float h = 0.0;
#if WATER_QUALITY >= 2
    h += sin(wxz.x * 1.20 + wxz.y * 0.70 + t * 1.60) * 0.014;
    h += sin(wxz.x * 0.85 - wxz.y * 1.10 + t * 1.25) * 0.010;
#endif
#if WATER_QUALITY >= 3
    h += sin(wxz.x * 2.5  - wxz.y * 1.8  + t * 2.2)  * 0.007;
    h += sin(wxz.x * 4.0  + wxz.y * 3.0  - t * 2.9)  * 0.004;
#endif
    return h;
}

float waterWaveHeight(vec2 worldXZ, float t) {
    vec2 wxz = wrapForTrig(worldXZ);
    return waterHeightLarge(wxz, t) + waterHeightDetail(wxz, t);
}

vec3 waterNormal(vec2 worldXZ, float t) {
#if WATER_QUALITY >= 3
    float eps = 0.09;
#else
    float eps = 0.14;
#endif
    float hL = waterWaveHeight(worldXZ - vec2(eps, 0.0), t);
    float hR = waterWaveHeight(worldXZ + vec2(eps, 0.0), t);
    float hD = waterWaveHeight(worldXZ - vec2(0.0, eps), t);
    float hU = waterWaveHeight(worldXZ + vec2(0.0, eps), t);
    return normalize(vec3((hL - hR) / (2.0 * eps), 1.0, (hD - hU) / (2.0 * eps)));
}

float fresnelSchlick(float cosTheta, float f0) {
    return f0 + (1.0 - f0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

const vec3 WATER_EXTINCTION = vec3(0.42, 0.10, 0.055);
const vec3 WATER_DEEP_COLOR = vec3(0.02, 0.12, 0.22);
const vec3 WATER_SHALLOW_TINT = vec3(0.08, 0.30, 0.42);

vec3 applyWaterDepthColor(vec3 baseColor, float waterDepth) {
    float d = max(waterDepth, 0.0);
    vec3 transmittance = exp(-WATER_EXTINCTION * d);
    return baseColor * transmittance + WATER_DEEP_COLOR * (1.0 - transmittance);
}

vec3 analyticWaterColor(float waterDepth, float fresnel, vec3 skyReflect, float skyBrightness) {
    float d = max(waterDepth, 0.0);
    float shallow = exp(-d * 0.20);
    vec3 body = mix(WATER_DEEP_COLOR, WATER_SHALLOW_TINT, shallow);
    body *= mix(0.60, 1.05, skyBrightness);
    // Fresnel mischt Koerper mit Himmel (kein Scene-Sample)
    return mix(body, skyReflect, fresnel * 0.85);
}

#endif
