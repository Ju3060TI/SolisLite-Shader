#ifndef SOLISLITE_CLOUDS_GLSL
#define SOLISLITE_CLOUDS_GLSL
#include "common.glsl"
vec4 shadeClouds(vec4 baseCloud, vec3 worldPos, vec3 viewDir, vec3 sunDir, float rain) {
    vec4 r = baseCloud;
    r.a *= 0.04;
    return r;
}
#endif
