/*
 * SolisLite - lib/colorgrade.glsl
 * Finale Farbkorrektur: Belichtung, Kontrast, Saettigung sowie ein
 * guenstiges, filmisches Tonemapping (Reinhard-Variante) fuer ein
 * natuerliches Gesamtbild ohne ausgefressene Lichter.
 */
#ifndef SOLISLITE_COLORGRADE_GLSL
#define SOLISLITE_COLORGRADE_GLSL
#include "common.glsl"

vec3 applyExposure(vec3 color, float exposure) {
    return color * exposure;
}

vec3 applyContrast(vec3 color, float contrast) {
    return (color - 0.5) * contrast + 0.5;
}

vec3 applySaturation(vec3 color, float saturation) {
    float g = luma(color);
    return mix(vec3(g), color, saturation);
}

// Guenstiges Tonemapping - vermeidet harte Clips in hellen Bereichen
// (z.B. direkte Sonne, Glowstone-Nahaufnahmen) ohne teure ACES-Fits.
vec3 tonemapReinhardExt(vec3 color) {
    float whitePoint = 2.2;
    vec3 mapped = color * (1.0 + color / (whitePoint * whitePoint)) / (1.0 + color);
    return mapped;
}

vec3 gradeFinalColor(vec3 color) {
    color = applyExposure(color, EXPOSURE);
    color = tonemapReinhardExt(color);
    color = applyContrast(color, CONTRAST);
    color = applySaturation(color, SATURATION);
    return clamp(color, 0.0, 1.0);
}

#endif
