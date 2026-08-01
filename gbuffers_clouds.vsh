/* SolisLite - gbuffers_weather.fsh */
#version 120

#include "lib/common.glsl"
#include "lib/lighting.glsl"

uniform sampler2D texture;

varying vec4 vColor;
varying vec2 vTexCoord;
varying vec2 vLightmap;

void main() {
    vec4 texColor = texture2D(texture, vTexCoord);
    if (texColor.a < 0.02) discard;

    float skyBrightness = getSkyBrightness();
    vec3 light = getLightmapLighting(vLightmap, skyBrightness);
    // Regen/Schnee leicht abgedunkelt und etwas kuehler eingefaerbt,
    // damit es sich harmonisch in truebe Wetterstimmung einfuegt.
    vec3 weatherTint = vec3(0.85, 0.90, 1.0);

    gl_FragColor = vec4(texColor.rgb * vColor.rgb * light * weatherTint, texColor.a * vColor.a * 0.9);
}
