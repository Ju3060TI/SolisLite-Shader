/*
 * SolisLite - lib/fog.glsl
 * Verbesserter Distanz- und Hoehennebel. Weich, tageszeitabhaengig
 * eingefaerbt, ohne harte Kante.
 */
#ifndef SOLISLITE_FOG_GLSL
#define SOLISLITE_FOG_GLSL
#include "common.glsl"

float distanceFogFactor(float viewDistance, float fogStart, float fogEnd) {
    float f = clamp((viewDistance - fogStart) / max(fogEnd - fogStart, 0.001), 0.0, 1.0);
    return f * f * (3.0 - 2.0 * f); // smoothstep-Kurve statt linear -> wirkt weicher
}

// Zusaetzlicher, guenstiger Hoehennebel (dichter nahe der "Bodenschicht")
float heightFogFactor(float worldY, float groundLevel) {
    float h = clamp((worldY - groundLevel) / 40.0, 0.0, 1.0);
    return 1.0 - h * h;
}

vec3 fogTintForTime(vec3 sunDir, vec3 baseFogColor) {
    float sunHeight = clamp(sunDir.y, -1.0, 1.0);
    vec3 duskTint = vec3(0.85, 0.55, 0.42);
    float duskAmount = 1.0 - smoothstep(0.0, 0.3, abs(sunHeight));
    return mix(baseFogColor, baseFogColor * duskTint * 1.15, duskAmount * 0.5);
}

vec3 applyFog(vec3 color, vec3 fogCol, float distFactor, float heightFactor, float rain) {
    float density = clamp(distFactor * mix(1.0, 0.55, 1.0 - heightFactor), 0.0, 1.0);
    // Klar: max ~70% Mix, Regen etwas dichter
    density = clamp(density * FOG_STRENGTH * mix(0.95, 1.4, rain), 0.0, 0.90);
    return mix(color, fogCol, density);
}

#endif
