/* SolisLite - gbuffers_entities.fsh */
#version 120
/* DRAWBUFFERS:02 */ // 0=colortex0 (Bildschirm), 2=colortex2 (Kopie fuer Wasser-Refraktion)
#include "lib/common.glsl"
#include "lib/lighting.glsl"

uniform sampler2D texture;
uniform sampler2D shadowtex0;

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

    float ndotlRaw = wrapDiffuse(vViewNormal, sunDirView, false);
    vec3 shadowScreenPos = computeShadowScreenPos(vViewPos);
    float shadow = mix(0.35, 1.0, sampleShadow(shadowtex0, shadowScreenPos, ndotlRaw));

    vec3 directLight = getDirectLight(vViewNormal, sunDirView, false, shadow);
    vec3 handLight = getDynamicHandLight(vViewPos, heldBlockLightValue, heldBlockLightValue2, vec3(1.0, 0.72, 0.45));

    vec3 finalColor = tex.rgb * vColor.rgb * (lightmapLight + directLight + handLight);
    vec4 outColor0 = vec4(finalColor, tex.a * vColor.a);
    gl_FragData[0] = outColor0;
    gl_FragData[1] = outColor0;
}
