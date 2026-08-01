/* SolisLite - gbuffers_skybasic.vsh
 * Untexturierte Himmelsgeometrie: Himmelskuppel/-ebene, Horizontring,
 * Void-Ebene UND Sterne laufen alle durch dieses Programm. Da die
 * Geometrie um den Ursprung (die Kamera) herum aufgebaut ist, liefert
 * die normalisierte Vertexposition direkt die Blickrichtung. */
#version 120

#include "lib/common.glsl"

varying vec4 vColor;
varying vec3 vViewDir;

void main() {
    gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;
    vColor = gl_Color;
    vViewDir = normalize(gl_Vertex.xyz);
}
