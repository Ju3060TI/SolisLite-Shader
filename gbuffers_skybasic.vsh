/* SolisLite - composite.fsh
 * Connected Glass, Nebel, Unterwasser (Tiefenfarbe + guenstige God-Rays), Regen.
 */
#version 120

#include "lib/common.glsl"
#include "lib/sky.glsl"
#include "lib/fog.glsl"
#include "lib/water.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex1;

varying vec2 vTexCoord;

vec3 reconstructViewPos(vec2 uv, float depth) {
    return screenToView(uv, depth, gbufferProjectionInverse);
}

vec3 smoothConnectedGlass(vec2 uv, vec3 centerColor, float centerDepth, float centerMask) {
    if (centerMask < 0.5) return centerColor;

    vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
    vec3 sum = centerColor;
    float weight = 1.0;

    const vec2 offsets[8] = vec2[8](
        vec2(-1.0, 0.0), vec2(1.0, 0.0), vec2(0.0, -1.0), vec2(0.0, 1.0),
        vec2(-1.0, -1.0), vec2(1.0, -1.0), vec2(-1.0, 1.0), vec2(1.0, 1.0)
    );

    for (int i = 0; i < 8; i++) {
        vec2 sampleUV = uv + offsets[i] * texel * 1.5;
        float mask = texture2D(colortex1, sampleUV).r;
        float d = texture2D(depthtex1, sampleUV).r;
        float depthSimilarity = 1.0 - clamp(abs(d - centerDepth) * 400.0, 0.0, 1.0);
        float w = mask * depthSimilarity;
        sum += texture2D(colortex0, sampleUV).rgb * w;
        weight += w;
    }
    return sum / weight;
}

// Guenstige God-Rays: radialer Sample-Pfad Richtung Sonne (nur Unterwasser)
vec3 applyGodRays(vec3 color, vec2 uv, float depth) {
    // Sonne in Bildschirmkoordinaten
    vec4 sunClip = gbufferProjection * vec4(sunPosition, 1.0);
    if (sunClip.w < 0.05) return color; // Sonne hinter Kamera
    vec2 sunUV = sunClip.xy / sunClip.w * 0.5 + 0.5;
    if (sunUV.x < -0.2 || sunUV.x > 1.2 || sunUV.y < -0.2 || sunUV.y > 1.2)
        return color;

    vec2 delta = (sunUV - uv) / 12.0;
    float illumination = 0.0;
    vec2 sampleUV = uv;

    for (int i = 0; i < 12; i++) {
        sampleUV += delta;
        if (sampleUV.x < 0.0 || sampleUV.x > 1.0 || sampleUV.y < 0.0 || sampleUV.y > 1.0)
            break;
        float d = texture2D(depthtex1, sampleUV).r;
        // Himmel / weit weg = Licht kommt durch
        illumination += (d > 0.998) ? 1.0 : 0.15;
    }
    illumination /= 12.0;

    // Staerker in der Naehe der Sonne, weich auslaufend
    float distToSun = length(uv - sunUV);
    float falloff = exp(-distToSun * 2.2) * 0.55 + exp(-distToSun * 0.6) * 0.25;
    float shafts = illumination * falloff;

    vec3 rayColor = vec3(0.35, 0.75, 0.95) * shafts * 0.9;
    return color + rayColor;
}

void main() {
    vec3 color = texture2D(colortex0, vTexCoord).rgb;
    float depth = texture2D(depthtex1, vTexCoord).r;
    float glassMask = texture2D(colortex1, vTexCoord).r;

    color = smoothConnectedGlass(vTexCoord, color, depth, glassMask);

    vec3 sunDirWorld = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

    if (depth < 1.0) {
        vec3 viewPos = reconstructViewPos(vTexCoord, depth);
        float viewDistance = length(viewPos);

        vec4 playerPos = gbufferModelViewInverse * vec4(viewPos, 1.0);
        float worldY = playerPos.y + cameraPosition.y;

        // Mittel: sichtbar, aber nicht milchig
        float fogStart = mix(40.0, 18.0, rainStrength);
        float fogEnd   = mix(150.0, 80.0, rainStrength);
        float distFactor = distanceFogFactor(viewDistance, fogStart, fogEnd);
        float heightFactor = heightFogFactor(worldY, cameraPosition.y - 8.0);
        // Hoehennebel nur leicht
        heightFactor = mix(1.0, heightFactor, 0.35);

        vec3 viewDirWorld = normalize(mat3(gbufferModelViewInverse) * viewPos);
        vec3 fogBaseColor = getSkyGradient(viewDirWorld, sunDirWorld);
        fogBaseColor = fogTintForTime(sunDirWorld, fogBaseColor);
        // Fog-Farbe etwas entsaettigt, damit Terrain nicht blau-grau wird
        float fl = dot(fogBaseColor, vec3(0.3, 0.5, 0.2));
        fogBaseColor = mix(fogBaseColor, vec3(fl), 0.25);

        color = applyFog(color, fogBaseColor, distFactor, heightFactor, rainStrength);
    }

    // ---- Unterwasser ----
    if (isEyeInWater == 1) {
        float uwDist = (depth < 1.0) ? length(reconstructViewPos(vTexCoord, depth)) : far;
        // Staerkere Tuerkis-/Blau-Absorption
        color = applyWaterDepthColor(color, uwDist * 1.35);
        // Zusaetzlicher Unterwasser-Ton
        color = mix(color, color * vec3(0.55, 0.85, 1.0), 0.35);
        // God-Rays Richtung Sonne
        color = applyGodRays(color, vTexCoord, depth);
        // Leichter Kontrastverlust (Wasser streut)
        float g = luma(color);
        color = mix(vec3(g), color, 0.85);
    }

    if (rainStrength > 0.0) {
        float g = luma(color);
        color = mix(color, vec3(g) * 0.92, rainStrength * 0.35);
    }

    gl_FragColor = vec4(color, 1.0);
}
