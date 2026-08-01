/* SolisLite - composite.vsh
 * Composite laeuft als Fullscreen-Pass. Reine Passthrough-Weitergabe
 * der Bildschirm-UV, keine weitere Transformation noetig. */
#version 120

varying vec2 vTexCoord;

void main() {
    gl_Position = ftransform();
    vTexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
