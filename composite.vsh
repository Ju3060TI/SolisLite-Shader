/* SolisLite - final.fsh
 * Finale Farbkorrektur (Belichtung, Tonemapping, Kontrast, Saettigung)
 * und Ausgabe an den Bildschirm. */
#version 120

#include "lib/common.glsl"
#include "lib/colorgrade.glsl"

uniform sampler2D colortex0;

varying vec2 vTexCoord;

void main() {
    vec3 color = texture2D(colortex0, vTexCoord).rgb;
    color = gradeFinalColor(color);
    gl_FragColor = vec4(color, 1.0);
}
