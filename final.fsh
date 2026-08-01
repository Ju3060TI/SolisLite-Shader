/* SolisLite - gbuffers_textured.vsh
 * Fuer unbeleuchtete texturierte Geometrie (Partikel ohne Licht, GUI-nahe
 * Elemente in der Welt). */
#version 120

varying vec2 vTexCoord;
varying vec4 vColor;

void main() {
    gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;
    vTexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vColor = gl_Color;
}
