/* SolisLite - gbuffers_textured_lit.vsh
 * Fuer beleuchtete texturierte Geometrie (die meisten Partikel: Rauch,
 * Flammen, Bloecke-brechen-Partikel usw.). Traegt die Lightmap-Koordinate
 * fuer unsere eigene Beleuchtungskurve mit. */
#version 120

varying vec2 vTexCoord;
varying vec2 vLmCoord;
varying vec4 vColor;

void main() {
    gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;
    vTexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vLmCoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vColor = gl_Color;
}
