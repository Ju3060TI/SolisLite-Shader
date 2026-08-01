/* SolisLite - gbuffers_textured_lit.fsh */
#version 120
/* DRAWBUFFERS:02 */ // 0=colortex0 (Bildschirm), 2=colortex2 (Kopie fuer Wasser-Refraktion)
#include "lib/common.glsl"
#include "lib/lighting.glsl"

uniform sampler2D texture;

varying vec2 vTexCoord;
varying vec2 vLmCoord;
varying vec4 vColor;

void main() {
    vec4 tex = texture2D(texture, vTexCoord);
    if (tex.a < 0.05) discard;

    float skyBrightness = getSkyBrightness();
    vec3 light = getLightmapLighting(vLmCoord, skyBrightness);

    vec4 outColor0 = vec4(tex.rgb * vColor.rgb * light, tex.a * vColor.a);
    gl_FragData[0] = outColor0;
    gl_FragData[1] = outColor0;
}
