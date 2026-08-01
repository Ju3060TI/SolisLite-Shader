/*
 * SolisLite - lib/wind.glsl
 * Wind-/Vegetationsanimation. Verwendet mc_Entity.x (per block.properties
 * zugewiesene IDs) um zu erkennen, ob ein Vertex zu einer beweglichen
 * Pflanze gehoert, und at_midBlock, um den unteren (fixierten) vom
 * oberen (beweglichen) Rand eines Blocks zu unterscheiden.
 */
#ifndef SOLISLITE_WIND_GLSL
#define SOLISLITE_WIND_GLSL
#include "common.glsl"

// Block-ID-Bereiche, siehe block.properties
const float ID_TALL_PLANT = 1801.0; // Gras, Bluemchen, Sapling, Farn
const float ID_LEAVES     = 1802.0; // Laub
const float ID_VINE       = 1803.0; // Ranken / Weinreben-artiges Zeug

// Liefert einen Verschiebungsvektor (World-Space) fuer den uebergebenen
// Vertex. worldPos = Vertexposition + cameraPosition (absolute Weltkoordinate).
// vertexHeightInBlock: 0 = unterer Blockrand (fix), 1 = oberer Rand (voll beweglich)
vec3 getWindOffset(float blockId, vec3 worldPos, float vertexHeightInBlock, float time) {
    if (WIND_STRENGTH <= 0.0) return vec3(0.0);

    float sway = 0.0;
    float freq = 1.0;
    float amp  = 0.0;

    if (blockId == ID_TALL_PLANT) {
        amp = 0.09;
        freq = 1.6;
    } else if (blockId == ID_LEAVES) {
        amp = 0.045;
        freq = 1.1;
    } else if (blockId == ID_VINE) {
        amp = 0.07;
        freq = 0.8;
    } else {
        return vec3(0.0);
    }

    // Mehrere ueberlagerte Sinuswellen mit leicht unterschiedlicher
    // Frequenz/Phase je nach Weltposition -> wirkt organisch, bleibt
    // aber guenstig (nur 2 sin()-Aufrufe statt echter Noise-Textur).
    // wrapForTrig() verhindert Praezisions-Rauschen weit vom Ursprung
    // entfernt (z.B. bei sehr grosser Sichtweite).
    vec2 wrapped = wrapForTrig(worldPos.xz);
    float phase = wrapped.x * 0.35 + wrapped.y * 0.35;
    float t = time * freq;
    sway = sin(t + phase) * 0.7 + sin(t * 1.8 + phase * 2.1) * 0.3;

    // Wind wird bei Regen etwas staerker (boeiger)
    float gust = 1.0 + rainStrength * 0.6;

    vec3 offset = vec3(sway, 0.0, sway * 0.6) * amp * WIND_STRENGTH * gust;
    offset *= vertexHeightInBlock; // unterer Rand bleibt fest verankert
    return offset;
}

#endif
