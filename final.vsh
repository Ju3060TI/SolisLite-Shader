/* SolisLite - gbuffers_water.fsh
 * Stabiles Wasser OHNE colortex2.
 * Wellen + Fresnel-Himmelsreflexion + Tiefenfarbe + Specular.
 */
#version 120
/* DRAWBUFFERS:01 */

#include "lib/common.glsl"
#include "lib/lighting.glsl"
#include "lib/water.glsl"
#include "lib/sky.glsl"

uniform sampler2D texture;
uniform sampler2D depthtex1;
uniform sampler2D shadowtex0;

varying vec2  vTexCoord;
varying vec2  vLmCoord;
varying vec4  vColor;
varying vec3  vViewNormal;
varying vec3  vViewPos;
varying vec3  vWorldPos;
varying float vBlockId;

const float ID_WATER = 1700.0;
const float ID_GLASS = 1900.0;

vec3 shadeSimpleTranslucent(vec3 albedo, float skyBrightness, vec3 sunDirView, float shadow) {
    vec3 lightmapLight = getLightmapLighting(vLmCoord, skyBrightness);
    vec3 directLight   = getDirectLight(vViewNormal, sunDirView, false, shadow);
    vec3 handLight     = getDynamicHandLight(vViewPos, heldBlockLightValue, heldBlockLightValue2, vec3(1.0, 0.72, 0.45));
    vec3 viewDirView = normalize(-vViewPos);
    float fresnel = fresnelSchlick(clamp(dot(viewDirView, normalize(vViewNormal)), 0.0, 1.0), 0.03);
    return albedo * (lightmapLight + directLight + handLight)
         + vec3(0.9, 0.95, 1.0) * fresnel * 0.12;
}

void main() {
    vec4 baseTex = texture2D(texture, vTexCoord);
    if (baseTex.a < 0.02) discard;

    vec3 sunDirView     = normalize(shadowLightPosition);
    float skyBrightness = getSkyBrightness();

    float ndotlRaw = wrapDiffuse(vViewNormal, sunDirView, false);
    vec3 shadowScreenPos = computeShadowScreenPos(vViewPos);
    float shadow = mix(0.35, 1.0, sampleShadow(shadowtex0, shadowScreenPos, ndotlRaw));

    float bid = floor(vBlockId + 0.5);
    bool isWater = (bid == 1700.0);
    bool isGlass = (bid == 1900.0);
    if (!isWater && !isGlass && bid < 1.0) {
        if (vViewNormal.y > 0.7 && baseTex.a < 0.95) isWater = true;
    }

    vec3 finalColor;
    float alpha;

    if (isWater) {
        vec3 waveN = waterNormal(vWorldPos.xz, frameTimeCounter);
        mat3 viewRot = mat3(gbufferModelView);
        vec3 normal = (vViewNormal.y > 0.5)
            ? normalize(viewRot * waveN)
            : normalize(vViewNormal);

        vec3 viewDirView = normalize(-vViewPos);
        float cosTheta   = clamp(dot(viewDirView, normal), 0.0, 1.0);
        float fresnel    = fresnelSchlick(cosTheta, 0.02);

        // Tiefe nur fuer Farbe/Alpha (kein colortex-Sample)
        vec2 screenUV = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
        float opaqueDepth = texture2D(depthtex1, screenUV).r;
        vec3 opaqueViewPos = screenToView(screenUV, opaqueDepth, gbufferProjectionInverse);
        float waterColumnDepth = max(length(opaqueViewPos) - length(vViewPos), 0.0);
        if (opaqueDepth > 0.999) waterColumnDepth = 10.0;

        // Himmelsreflexion
        vec3 viewDirWorld = normalize((gbufferModelViewInverse * vec4(viewDirView, 0.0)).xyz);
        vec3 normalWorld  = normalize((gbufferModelViewInverse * vec4(normal, 0.0)).xyz);
        vec3 sunDirWorld  = normalize((gbufferModelViewInverse * vec4(sunDirView, 0.0)).xyz);
        vec3 skyReflect   = getSkyGradient(reflect(-viewDirWorld, normalWorld), sunDirWorld);

        vec3 waterColor = analyticWaterColor(waterColumnDepth, fresnel, skyReflect, skyBrightness);

        vec3 lm = getLightmapLighting(vLmCoord, skyBrightness);
        waterColor *= mix(vec3(1.0), lm * 1.1, 0.22);

        // Specular
        vec3 halfDir = normalize(sunDirView + viewDirView);
        float spec = pow(clamp(dot(normal, halfDir), 0.0, 1.0), 120.0);
        waterColor += vec3(1.0, 0.98, 0.94) * spec * shadow * skyBrightness * 0.65;

        finalColor = waterColor;
        float depthAlpha = mix(0.78, 0.93, smoothstep(0.0, 5.0, waterColumnDepth));
        alpha = mix(depthAlpha, 0.97, fresnel);
    } else {
        vec3 albedo = baseTex.rgb * vColor.rgb;
        finalColor  = shadeSimpleTranslucent(albedo, skyBrightness, sunDirView, shadow);
        alpha       = baseTex.a * vColor.a;
    }

    gl_FragData[0] = vec4(finalColor, alpha);
    gl_FragData[1] = vec4(isGlass ? 1.0 : 0.0, 0.0, 0.0, 1.0);
}
