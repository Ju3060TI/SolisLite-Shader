/* SolisLite - gbuffers_hand.fsh */
#version 120
#include "lib/common.glsl"
#include "lib/lighting.glsl"

uniform sampler2D texture;

varying vec2 vTexCoord;
varying vec2 vLmCoord;
varying vec4 vColor;
varying vec3 vViewNormal;
varying vec3 vViewPos;

void main() {
    vec4 tex = texture2D(texture, vTexCoord);
    if (tex.a < 0.1) discard;

    vec3 sunDirView = normalize(shadowLightPosition);
    float skyBrightness = getSkyBrightness();

    vec3 lightmapLight = getLightmapLighting(vLmCoord, skyBrightness);
    // Kein Schatten-Sampling noetig (das gehaltene Item ist immer nah an
    // der Kamera) - Schattenfaktor daher fest auf 1.0 (voll beleuchtet).
    vec3 directLight = getDirectLight(vViewNormal, sunDirView, false, 1.0);

    // Das gehaltene Item beleuchtet sich immer selbst voll, unabhaengig
    // von der ungefaehren Positionsannahme in getDynamicHandLight.
    float lightValue = max(float(heldBlockLightValue), float(heldBlockLightValue2));
    vec3 selfGlow = vec3(1.0, 0.72, 0.45) * (lightValue / 15.0) * DYNAMIC_LIGHT_STRENGTH;

    vec3 finalColor = tex.rgb * vColor.rgb * (lightmapLight + directLight + selfGlow);
    gl_FragColor = vec4(finalColor, tex.a * vColor.a);
}
