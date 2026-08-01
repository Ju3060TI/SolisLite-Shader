/*
 * SolisLite - lib/lighting.glsl
 * ----------------------------------------------------------------------
 * Eigene Beleuchtungs-Engine.
 *
 * Baut auf drei Saeulen auf:
 *   1) Lightmap-basierte Block-/Himmelshelligkeit (weiche, eigene Kurve
 *      statt der harten Vanilla-Kurve -> beleuchtet Innenraeume und
 *      Hoehlen glaubwuerdig, ohne zusaetzliche Texturzugriffe).
 *   2) Gerichtetes Sonnen-/Mondlicht mit Shadow-Map (weiche PCF-Schatten,
 *      Distanz-Distortion fuer mehr Aufloesung nahe dem Spieler).
 *   3) Dynamisches Handlicht (heldBlockLightValue) fuer JEDE leuchtende
 *      Ressource, die der Spieler haelt (Fackel, Laterne, Soul-Variante,
 *      Glowstone, Sea Lantern, Redstone-Lampe, ...) - die Iris-Engine
 *      liefert den Lichtwert automatisch, dadurch muss keine Item-Liste
 *      von Hand gepflegt werden.
 * ----------------------------------------------------------------------
 */

#ifndef SOLISLITE_LIGHTING_GLSL
#define SOLISLITE_LIGHTING_GLSL

#include "common.glsl"

// ------------------------------------------------------------------
// Lightmap-Kurve
// ------------------------------------------------------------------
// Vanilla liefert lmcoord.x = Blocklicht, lmcoord.y = Himmelslicht (0-1).
// Wir formen daraus eine weichere, waermere Kurve statt eines linearen
// Verlaufs - das laesst Fackeln/Lava warm gluehen und Hoehlen wirklich
// dunkel werden, statt "grau" zu bleiben.
vec3 getLightmapLighting(vec2 lmcoord, float skyBrightness) {
    // Blocklicht: sanfte Kubik-Kurve fuer angenehmeren Falloff nahe Lichtquellen
    float blockLight = clamp(lmcoord.x, 0.0, 1.0);
    blockLight = blockLight * blockLight * (3.0 - 2.0 * blockLight);
    blockLight = pow(blockLight, 1.4);

    // Himmelslicht: an aktuelle Tageshelligkeit gekoppelt, damit Hoehlen
    // bei Nacht wirklich dunkel abgeriegelt werden ("Hoehlen korrekt abdunkeln")
    float skyLight = clamp(lmcoord.y, 0.0, 1.0);
    skyLight = skyLight * skyLight;
    skyLight *= skyBrightness;

    vec3 warmBlockColor = vec3(1.0, 0.75, 0.48);
    vec3 skyLightColor  = vec3(0.70, 0.80, 1.0);

    vec3 result = warmBlockColor * blockLight * 1.45 + skyLightColor * skyLight;

    // Minimale Ambient-Untergrenze - verhindert komplett schwarze Flaechen
    // (z.B. Laubunterseiten ohne direkten Skylight-Beitrag).
    result += vec3(0.028, 0.030, 0.036);
    return result;
}

// ------------------------------------------------------------------
// Sonnen-/Mond-Richtungslicht mit weichem Wrap-Diffuse
// ------------------------------------------------------------------
// Normale Lambert-Beleuchtung erzeugt bei duennem Blattwerk und Gras
// (einzelne, beidseitig sichtbare Polygone) leicht schwarze Flecken,
// da die Rueckseite kein Licht empfaengt. "Wrap lighting" haengt daher
// dem NdotL etwas Offset an, isFoliage schaltet einen staerkeren Wrap
// zu - so bleiben Pflanzen IMMER sichtbar eingefaerbt.
float wrapDiffuse(vec3 normal, vec3 lightDir, bool isFoliage) {
    float wrap = isFoliage ? 0.55 : 0.15;
    float ndotl = dot(normalize(normal), lightDir);
    return clamp((ndotl + wrap) / (1.0 + wrap), 0.0, 1.0);
}

// ------------------------------------------------------------------
// Schatten: Distortion fuer bessere Aufloesungsverteilung
// ------------------------------------------------------------------
// Klassische, guenstige Verzerrungsfunktion: staucht weit entfernte
// Shadow-Map-Texel zusammen, damit die begrenzte Aufloesung vor allem
// dort verwendet wird, wo der Spieler tatsaechlich hinschaut.
//
// WICHTIG: Diese Funktion wird an ZWEI Stellen verwendet - beim
// Rendern der Shadow-Map selbst (shadow.vsh) UND beim spaeteren
// Sampling (hier). Beide MUESSEN exakt denselben Faktor verwenden,
// sonst zeigt das Sampling auf eine andere Stelle, als tatsaechlich
// gerendert wurde -> Schatten wirken kamera-abhaengig/zufaellig
// ("Shadow Acne", sichtbar als flaechiges Rauschen).
float shadowDistortionFactor(vec2 ndcXY) {
    return (length(ndcXY) * 0.9 + 0.1);
}

// Berechnet die verzerrte Shadow-Map-Bildschirmkoordinate (0-1) samt
// Vergleichstiefe VOLLSTAENDIG PRO FRAGMENT statt im Vertex-Shader.
// Grund: shadowDistortionFactor() ist nichtlinear - wuerde man sie nur
// pro Vertex auswerten und ueber ein grosses Dreieck (z.B. eine
// Wasserflaeche oder ein Sodium-Terrain-Quad) linear interpolieren,
// weicht das Ergebnis in der Flaechenmitte spuerbar vom korrekten
// Wert ab. Das war die Ursache des flaechigen Rauschens auf Eis/
// Wasser/Himmel in den Bug-Screenshots.
vec3 computeShadowScreenPos(vec3 viewPos) {
    vec4 playerPos     = gbufferModelViewInverse * vec4(viewPos, 1.0);
    vec4 shadowViewPos = shadowModelView * playerPos;
    vec4 shadowClipPos = shadowProjection * shadowViewPos;

    // Verzerrung VOR der Perspektiventeilung anwenden (Standardtrick):
    // nur xy durch den Faktor teilen, w unveraendert lassen. Nach der
    // Teilung durch w (naechste Zeile) ergibt sich exakt die gewuenschte
    // verzerrte NDC-Position, ohne die Tiefe zu verfaelschen.
    vec2 ndcApprox = shadowClipPos.xy / max(shadowClipPos.w, EPSILON);
    float distortFactor = shadowDistortionFactor(ndcApprox);
    shadowClipPos.xy /= distortFactor;

    vec3 shadowNDC = shadowClipPos.xyz / max(shadowClipPos.w, EPSILON);
    return shadowNDC * 0.5 + 0.5;
}

// PCF-Sampling der Shadow-Map - bewusst mit wenigen Taps fuer iGPUs.
// bias ist "slope-scaled": bei flachem Lichteinfall (kleines ndotl)
// groesser, bei steilem Einfall kleiner - reduziert Shadow-Acne, ohne
// bei steilen Winkeln unnoetig "Peter Panning" (abgeloeste Schatten)
// zu erzeugen.
float sampleShadow(sampler2D shadowMap, vec3 shadowScreenPos, float ndotl) {
#if SHADOW_QUALITY == 0
    return 1.0;
#else
    // Ausserhalb der Shadow-Map (jenseits von shadowDistance): kein
    // Schatten anwenden, statt an den Texturraendern zu clampen (das
    // wuerde am Sichtweiten-Rand sichtbare falsche Schattenkanten
    // erzeugen).
    if (shadowScreenPos.x < 0.002 || shadowScreenPos.x > 0.998 ||
        shadowScreenPos.y < 0.002 || shadowScreenPos.y > 0.998 ||
        shadowScreenPos.z > 1.0) {
        return 1.0;
    }

    #if SHADOW_QUALITY >= 2
        const int taps = 2; // 5x5 Kernel
    #else
        const int taps = 1; // 3x3 Kernel - Standard fuer iGPU
    #endif

    float bias = mix(0.0032, 0.0007, clamp(ndotl, 0.0, 1.0));

    float texel = 1.0 / float(shadowMapResolution);
    float sum = 0.0;
    float count = 0.0;
    for (int x = -taps; x <= taps; x++) {
        for (int y = -taps; y <= taps; y++) {
            vec2 offset = vec2(float(x), float(y)) * texel;
            float depthSample = texture2D(shadowMap, shadowScreenPos.xy + offset).r;
            sum += step(shadowScreenPos.z - bias, depthSample);
            count += 1.0;
        }
    }
    return sum / count;
#endif
}

// ------------------------------------------------------------------
// Dynamisches Handlicht
// ------------------------------------------------------------------
// heldBlockLightValue (0-15) wird von Iris automatisch fuer JEDES
// Item geliefert, das als Block Licht ausstrahlen wuerde - deckt somit
// Fackel, Laterne, Soul Torch, Soul Lantern, Glowstone, Sea Lantern,
// Redstone-Lampe und jeden weiteren leuchtenden Block/Item ab, ohne
// dass Item-IDs einzeln hart codiert werden muessen.
//
// Die Lichtquelle wird nahe der Kamera angenommen (typische Distanz
// eines in der Hand gehaltenen Items) und faellt quadratisch mit der
// Entfernung zum beleuchteten Fragment ab - guenstig zu berechnen und
// bewegt sich automatisch mit dem Spieler mit.
vec3 getDynamicHandLight(vec3 viewSpacePos, int heldLight, int heldLight2, vec3 baseTint) {
    float lightValue = max(float(heldLight), float(heldLight2));
    if (lightValue <= 0.0) return vec3(0.0);

    // Ungefaehre Position des gehaltenen Items im Sichtraum (leicht vor
    // und unterhalb der Kamera, wie ein in der Hand gehaltenes Objekt).
    vec3 handPos = vec3(0.28, -0.35, -0.45);

    float dist = length(viewSpacePos - handPos);
    float radius = (lightValue / 15.0) * 11.0 + 2.0;
    float atten = 1.0 - clamp(dist / radius, 0.0, 1.0);
    atten = atten * atten; // quadratischer Falloff, aber ohne 1/d^2-Singularitaet

    float intensity = (lightValue / 15.0) * atten * DYNAMIC_LIGHT_STRENGTH;
    return baseTint * intensity;
}

// ------------------------------------------------------------------
// Tag/Nacht-Modell
// ------------------------------------------------------------------
// Fruehere Version hat die Taghelligkeit aus shadowLightPosition
// abgeleitet - diese zeigt nachts aber zur MONDPOSITION, wodurch ein
// hoch stehender Mond faelschlich "Taghelligkeit" erzeugte (Nacht zu
// hell) und ein tiefer Mond die Nacht zu dunkel werden liess. Jetzt
// getrennt: sunFactor haengt AUSSCHLIESSLICH von der Sonne ab,
// moonFactor ist bei Nacht immer gleich schwach gedeckelt - dadurch
// bleibt die Nachthelligkeit konstant und die Sonnenauf-/untergaenge
// gehen weich ineinander ueber (beide Faktoren ueberlappen glatt am
// Horizont, kein Sprung beim Sonne/Mond-Wechsel).
float getSunFactor() {
    float sunDot = dot(normalize(sunPosition), normalize(upPosition));
    return smoothstep(-0.06, 0.20, sunDot);
}

float getMoonFactor() {
    float sunDot = dot(normalize(sunPosition), normalize(upPosition));
    return smoothstep(-0.06, 0.20, -sunDot) * 0.16;
}

// Fuer Lightmap-/Ambient-Helligkeit: Tag ~1.0, Nacht konstant gedaempft.
float getSkyBrightness() {
    return clamp(getSunFactor() + getMoonFactor(), 0.0, 1.0);
}

const vec3 SUN_COLOR  = vec3(1.15, 1.05, 0.92);
const vec3 MOON_COLOR = vec3(0.45, 0.55, 0.80);

// Kombiniertes gerichtetes Sonnen-/Mondlicht (Farbe * Intensitaet),
// bereits mit Wrap-Diffuse und Schatten multipliziert. lightDirView
// ist shadowLightPosition (zeigt zur jeweils aktiven Lichtquelle).
vec3 getDirectLight(vec3 normal, vec3 lightDirView, bool isFoliage, float shadow) {
    float ndotl = wrapDiffuse(normal, lightDirView, isFoliage);
    float sunF = getSunFactor();
    float moonF = getMoonFactor();
    return (SUN_COLOR * sunF + MOON_COLOR * moonF) * ndotl * shadow;
}

#endif // SOLISLITE_LIGHTING_GLSL
