/* SolisLite - gbuffers_terrain.vsh
 * Hauptprogramm fuer Terrain-Geometrie (Bloecke). Zustaendig fuer:
 *  - Wind-Animation von Gras/Laub/Ranken
 *  - Weiterreichen der View-Space-Normalen/Position fuer die Beleuchtung
 *  - Markieren von Glas-Vertices fuer die "Connected Glass"-Nachbearbeitung
 *
 * Die Shadow-Map-Projektion wird bewusst NICHT mehr hier (pro Vertex)
 * berechnet, sondern im Fragment-Shader - siehe lib/lighting.glsl::
 * computeShadowScreenPos() fuer die Begruendung (Shadow-Acne-Fix).
 */
#version 120

#include "lib/common.glsl"
#include "lib/lighting.glsl"
#include "lib/wind.glsl"

attribute vec4 mc_Entity;
attribute vec2 mc_midTexCoord;

varying vec2  vTexCoord;
varying vec2  vLmCoord;
varying vec4  vColor;
varying vec3  vViewNormal;
varying vec3  vViewPos;
varying float vBlockId;

void main() {
    vBlockId = mc_Entity.x;

    vec4 pos = gl_Vertex;

    // ---- Wind-Animation ----
    // Obere Modell-Vertices (kleinerer V-Texturkoordinate) schwingen,
    // untere bleiben am Boden verankert - Standardtechnik fuer
    // kreuzfoermige Pflanzengeometrie.
    float heightInBlock = (gl_MultiTexCoord0.t < mc_midTexCoord.t) ? 1.0 : 0.0;
    if (mc_Entity.x == ID_LEAVES) heightInBlock = 1.0; // starre Wuerfelgeometrie: gesamter Block schwingt gleichmaessig

    vec3 worldPosApprox = pos.xyz + cameraPosition;
    vec3 windOffset = getWindOffset(mc_Entity.x, worldPosApprox, heightInBlock, frameTimeCounter);
    pos.xyz += windOffset;

    vec4 viewPos = gl_ModelViewMatrix * pos;
    gl_Position = gl_ProjectionMatrix * viewPos;

    vViewPos = viewPos.xyz;
    vViewNormal = normalize(gl_NormalMatrix * gl_Normal);

    vTexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vLmCoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vColor = gl_Color;
}
