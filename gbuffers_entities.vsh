/* SolisLite - shadow.vsh
 * Rendert die Szene aus Sicht der Sonne/des Mondes in die Shadow-Map.
 *
 * WICHTIG: Die Verzerrung (shadowDistortionFactor) MUSS hier exakt so
 * angewendet werden wie beim spaeteren Sampling in
 * lib/lighting.glsl::computeShadowScreenPos() - sonst landet die
 * Shadow-Map an anderer Stelle, als spaeter abgefragt wird, was zu
 * flimmernden/rauschenden Schatten fuehrt (siehe common.glsl-Kommentar
 * bei shadowDistortionFactor fuer Details).
 *
 * Technik: xy der Clip-Space-Position VOR der Perspektiventeilung durch
 * den Verzerrungsfaktor teilen (w bleibt unveraendert) - die Hardware
 * fuehrt die Teilung durch w danach automatisch aus und erzeugt so
 * exakt die gewuenschte verzerrte NDC-Position.
 */
#version 120
#include "lib/common.glsl"
#include "lib/lighting.glsl"

varying vec2 vTexCoord;
varying vec4 vColor;

void main() {
    // Waehrend des Shadow-Passes setzt Iris gl_ModelViewMatrix/
    // gl_ProjectionMatrix automatisch auf shadowModelView/shadowProjection.
    vec4 clip = gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;

    vec2 ndcApprox = clip.xy / max(clip.w, EPSILON);
    float distortFactor = shadowDistortionFactor(ndcApprox);
    clip.xy /= distortFactor;

    gl_Position = clip;

    vTexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vColor = gl_Color;
}
