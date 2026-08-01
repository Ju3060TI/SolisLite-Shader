/* SolisLite - gbuffers_clouds.fsh */
#version 120
/* DRAWBUFFERS:02 */ // 0=colortex0 (Bildschirm), 2=colortex2 (Kopie fuer Wasser-Refraktion)

#include "lib/common.glsl"
#include "lib/clouds.glsl"

varying vec4 vColor;
varying vec3 vWorldPos;

void main() {
    // shadowLightPosition liegt im View-Space vor - fuer den Himmel-
    // Farbverlauf (getSkyGradient, ueber shadeClouds) in Weltraum zurueckdrehen.
    vec3 sunDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    vec3 viewDir = normalize(vWorldPos - cameraPosition);
    vec4 shaded = shadeClouds(vColor, vWorldPos, viewDir, sunDir, rainStrength);
    if (shaded.a < 0.02) discard;
    vec4 outColor0 = shaded;
    gl_FragData[0] = outColor0;
    gl_FragData[1] = outColor0;
}
