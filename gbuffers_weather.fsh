/* SolisLite - final.vsh
 * Letzter Fullscreen-Pass vor der Bildschirmausgabe. */
#version 120

varying vec2 vTexCoord;

void main() {
    gl_Position = ftransform();
    vTexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
