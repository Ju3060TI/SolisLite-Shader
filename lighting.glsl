/*
 * SolisLite - lib/common.glsl
 * ----------------------------------------------------------------------
 * Zentrale Konstanten, Uniform-Deklarationen und mathematische
 * Hilfsfunktionen, die von praktisch jedem Shader-Stage benoetigt werden.
 * Diese Datei wird per #include in jedes .vsh/.fsh eingebunden, damit
 * Werte (z.B. shadowMapResolution) im gesamten Pack konsistent sind.
 * ----------------------------------------------------------------------
 */

#ifndef SOLISLITE_COMMON_GLSL
#define SOLISLITE_COMMON_GLSL

// ------------------------------------------------------------------
// Qualitaets-/Performance-Optionen (erscheinen im Iris-Optionsmenue)
// ------------------------------------------------------------------

#define SHADOW_QUALITY 1 // [0 1 2] Schattenqualitaet. 0 = aus, 1 = weich (iGPU-Standard), 2 = hoch
#define SHADOW_DISTANCE_BLOCKS 96.0 // [48.0 64.0 96.0 128.0] Reichweite der Schattenberechnung in Bloecken
#define DYNAMIC_LIGHT_STRENGTH 1.0 // [0.0 0.5 1.0 1.5 2.0] Staerke des Hand-/Traglichts
#define WATER_QUALITY 2 // [1 2 3] Wasserqualitaet. 1 = einfach, 2 = Standard, 3 = hoch
#define CLOUD_OPACITY 0.65 // [0.0 0.25 0.5 0.65 0.8 1.0] Deckkraft der 2D-Wolkenebene
#define WIND_STRENGTH 1.0 // [0.0 0.5 1.0 1.5 2.0] Staerke der Wind-Animation von Pflanzen
#define FOG_STRENGTH 0.85 // [0.0 0.5 1.0 1.5 2.0] Staerke des atmosphaerischen Nebels
#define SATURATION 1.06 // [0.85 0.9 0.95 1.0 1.06 1.1 1.15 1.2] Saettigung der Farbkorrektur
#define CONTRAST 1.05 // [0.9 0.95 1.0 1.05 1.1 1.15] Kontrast der Farbkorrektur
#define EXPOSURE 1.0 // [0.8 0.9 1.0 1.1 1.2] Belichtung / Helligkeit

// Diese "const"-Deklarationen werden von Iris/OptiFine gezielt nach
// bestimmten Namen durchsucht und steuern Engine-Verhalten -
// sie muessen als echte GLSL-"const" vorliegen (keine #define).
const int   shadowMapResolution = 1536;   // moderat: gute Qualitaet, iGPU-tauglich
const float shadowDistance      = SHADOW_DISTANCE_BLOCKS;
const float shadowIntervalSize  = 4.0;    // Schatten-Update-Intervall (Performance)
// false, da die Shadow-Map manuell per texture2D() + eigenem PCF-Kernel
// ausgewertet wird (siehe lib/lighting.glsl::sampleShadow) und NICHT ueber
// die Hardware-Vergleichsfunktion (shadow2D/sampler2DShadow).
const bool  shadowHardwareFiltering = false;
const bool  generateShadowMipmap = false; // Mipmaps kosten Speicherbandbreite - fuer iGPU aus

// ------------------------------------------------------------------
// Mathematische Konstanten
// ------------------------------------------------------------------
const float PI      = 3.14159265359;
const float TAU      = 6.28318530718;
const float HALF_PI  = 1.57079632679;
const float EPSILON  = 1e-5;

// ------------------------------------------------------------------
// Allgemeine Uniforms, die praktisch jeder Stage benoetigt
// ------------------------------------------------------------------
uniform float frameTimeCounter; // Sekunden seit Weltstart (fuer Animation)
uniform int   worldTime;        // 0-24000 Minecraft-Ticks
uniform int   worldDay;
uniform float rainStrength;
uniform float wetness;
uniform vec3  cameraPosition;
uniform vec3  sunPosition;
uniform vec3  moonPosition;
uniform vec3  shadowLightPosition; // zeigt immer zur aktuell aktiven Lichtquelle (Sonne/Mond)
uniform vec3  upPosition;
uniform float near;
uniform float far;
uniform vec3  fogColor;
uniform vec3  skyColor;
uniform int   isEyeInWater;
uniform float viewWidth;
uniform float viewHeight;

// Matrizen fuer Welt-/Schatten-Transformationen (in mehreren Stages benoetigt)
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;

// Lichtwert des in der Haupt-/Nebenhand gehaltenen Items, falls dieses
// als platzierter Block Licht ausstrahlen wuerde (0-15). Wird von Iris
// automatisch befuellt - deckt somit jede leuchtende Ressource ab.
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

// ------------------------------------------------------------------
// Kleine, guenstige Hilfsfunktionen
// ------------------------------------------------------------------

// Normale in zwei 8-Bit-Kanaele packen (spart Bandbreite ggue. vec3-Puffer)
vec2 encodeNormal(vec3 n) {
    return n.xy / (abs(n.x) + abs(n.y) + abs(n.z) + EPSILON) * 0.5 + 0.5;
}

vec3 decodeNormal(vec2 enc) {
    vec2 f = enc * 2.0 - 1.0;
    vec3 n = vec3(f.x, f.y, 1.0 - abs(f.x) - abs(f.y));
    float t = clamp(-n.z, 0.0, 1.0);
    n.x += n.x >= 0.0 ? -t : t;
    n.y += n.y >= 0.0 ? -t : t;
    return normalize(n);
}

// Billiges Pseudo-Zufallsrauschen (keine Textur-Lookups noetig)
float hash12(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// Wertrauschen mit bilinearer Interpolation - Basis fuer Wolken/Sterne/Wellen
float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash12(i);
    float b = hash12(i + vec2(1.0, 0.0));
    float c = hash12(i + vec2(0.0, 1.0));
    float d = hash12(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// Fraktale Brownsche Bewegung mit wenigen Oktaven (guenstig gehalten)
float fbm2(vec2 p) {
    float sum = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 4; i++) {
        sum += valueNoise(p) * amp;
        p *= 2.02;
        amp *= 0.5;
    }
    return sum;
}

// Reine Rec.709-Luminanz - fuer Saettigungs-/Tonemap-Berechnungen
float luma(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

// Begrenzt absolute Weltkoordinaten auf einen kleinen, periodischen Bereich,
// BEVOR sie in sin()/cos() einfliessen. Ohne dies verlieren trigonometrische
// Funktionen bei grossen Koordinaten (mehrere tausend Bloecke vom Ursprung
// entfernt, z.B. durch weite Sicht mit Bobby o.ae.) massiv an Praezision und
// erzeugen sichtbares, chaotisches Rauschen statt sanfter Wellen. 4096
// Bloecke Periodenlaenge sind praktisch nie als Wiederholung wahrnehmbar,
// beheben das Problem aber vollstaendig.
vec2 wrapForTrig(vec2 worldXZ) {
    return mod(worldXZ, 4096.0);
}

// Glatte, guenstige Rueckprojektion von Bildschirmraum in Sichtraum
vec3 screenToView(vec2 texcoord, float depth, mat4 projInverse) {
    vec4 clip = vec4(texcoord * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 view = projInverse * clip;
    return view.xyz / view.w;
}

#endif // SOLISLITE_COMMON_GLSL
