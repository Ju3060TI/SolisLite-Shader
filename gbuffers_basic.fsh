/* SolisLite - gbuffers_terrain.fsh
 * Fragment-Shader fuer Terrain: kombiniert Lightmap-Beleuchtung,
 * gerichtetes Sonnen-/Mondlicht mit weichem, PRO FRAGMENT berechnetem
 * Schatten (kein Vertex-Interpolations-Rauschen mehr) und dynamisches
 * Handlicht. Schreibt zusaetzlich eine Glas-Materialmaske in colortex1
 * fuer die spaetere "Connected Glass"-Glaettung in composite.fsh.
 */
#version 120
/* DRAWBUFFERS:012 */

#include "lib/common.glsl"
#include "lib/lighting.glsl"
#include "lib/wind.glsl"

uniform sampler2D texture;
uniform sampler2D shadowtex0;

varying vec2  vTexCoord;
varying vec2  vLmCoord;
varying vec4  vColor;
varying vec3  vViewNormal;
varying vec3  vViewPos;
varying float vBlockId;

void main() {
    vec4 tex = texture2D(texture, vTexCoord);
    if (tex.a < 0.1) discard;

    vec3 albedo = tex.rgb * vColor.rgb;

    bool isFoliage = (vBlockId == ID_TALL_PLANT || vBlockId == ID_LEAVES || vBlockId == ID_VINE);

    // ---- Lightmap (Block-/Himmelslicht) ----
    vec3 sunDirView = normalize(shadowLightPosition); // zeigt zur aktiven Lichtquelle, View-Space
    float skyBrightness = getSkyBrightness(); // rein sonnenbasiert - Mondhoehe faelscht die Nacht nicht mehr
    vec3 lightmapLight = getLightmapLighting(vLmCoord, skyBrightness);

    // ---- Schatten: vollstaendig pro Fragment berechnet (kein Acne) ----
    float ndotlRaw = wrapDiffuse(vViewNormal, sunDirView, isFoliage);
    vec3 shadowScreenPos = computeShadowScreenPos(vViewPos);
    float shadow = sampleShadow(shadowtex0, shadowScreenPos, ndotlRaw);
    // Schatten duerfen die Lightmap-Grundhelligkeit nie komplett aufheben
    // (verhindert unnatuerlich harte, komplett schwarze Kanten).
    shadow = mix(0.35, 1.0, shadow);

    // ---- Direktes Sonnen-/Mondlicht ----
    vec3 directLight = getDirectLight(vViewNormal, sunDirView, isFoliage, shadow);

    // ---- Dynamisches Handlicht ----
    vec3 handLight = getDynamicHandLight(vViewPos, heldBlockLightValue, heldBlockLightValue2, vec3(1.0, 0.72, 0.45));

    vec3 totalLight = lightmapLight + directLight + handLight;
    vec3 finalColor = albedo * totalLight;

    vec4 outColor = vec4(finalColor, tex.a * vColor.a);
    gl_FragData[0] = outColor;

    // colortex1 dient der Glas-Materialmaske fuer "Connected Glass".
    // Echtes Glas ist in Minecraft "translucent" und laeuft daher ueber
    // gbuffers_water.fsh (siehe dort) - hier (opakes Terrain) kann kein
    // Glas ankommen, die Maske bleibt also stets 0. Sie wird dennoch
    // explizit geschrieben, weil colortex1 als MRT-Ziel deklariert ist
    // und sonst unbestimmten Inhalt aus vorherigen Frames haben koennte.
    gl_FragData[1] = vec4(0.0, 0.0, 0.0, 1.0);

    // colortex2: unveraenderte Kopie der opaken Farbe - einzige sichere
    // Quelle fuer die Wasser-Refraktion (siehe shaders.properties-Kommentar).
    // WICHTIG: aus einer lokalen Variable schreiben, NICHT aus gl_FragData
    // zuruecklesen - gl_FragData ist ein schreibender Ausgabe-Port, ein
    // Rueckgriff darauf ist undefiniertes Verhalten und war die Ursache
    // der "Fragmente der Szene im Wasser"-Glitches.
    gl_FragData[2] = outColor;
}
