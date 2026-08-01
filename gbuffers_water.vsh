/* SolisLite - gbuffers_basic.vsh
 * Fuer einfache Debug-/Auswahl-Geometrie (z.B. Selection Box). Reine
 * Passthrough-Transformation ohne Beleuchtung noetig. */
#version 120

varying vec4 vColor;

void main() {
    gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;
    vColor = gl_Color;
}
