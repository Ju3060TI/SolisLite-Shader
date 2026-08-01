/* SolisLite - shadow.fsh
 * Nur ein Alpha-Test fuer Cutout-Geometrie (Gras, Laub, Ranken) wird
 * benoetigt, damit diese Blaetter/Halme im Schatten korrekt "durchsichtige"
 * Bereiche freigeben, statt als massiver Block zu schatten. Es wird keine
 * Farbe geschrieben - nur die Tiefe wird von der Fixed-Function-Pipeline
 * automatisch in shadowtex0 abgelegt.
 */
#version 120

uniform sampler2D texture;

varying vec2 vTexCoord;
varying vec4 vColor;

void main() {
    vec4 tex = texture2D(texture, vTexCoord);
    if (tex.a * vColor.a < 0.5) discard;
    gl_FragColor = vec4(1.0);
}
