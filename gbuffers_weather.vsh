/* SolisLite - gbuffers_water.vsh */
#version 120
#include "lib/common.glsl"
#include "lib/water.glsl"

attribute vec4 mc_Entity;

varying vec2  vTexCoord;
varying vec2  vLmCoord;
varying vec4  vColor;
varying vec3  vViewNormal;
varying vec3  vViewPos;
varying vec3  vWorldPos;
varying float vBlockId;

void main() {
    vBlockId = mc_Entity.x;
    float bid = floor(mc_Entity.x + 0.5);
    bool isWater = (bid == 1700.0);

    vec4 pos = gl_Vertex;
    vec3 worldPos = pos.xyz + cameraPosition;

    if (isWater && gl_Normal.y > 0.9) {
        float wave = waterWaveHeight(worldPos.xz, frameTimeCounter);
        pos.y += wave;
        worldPos.y += wave;
    }

    vec4 viewPos = gl_ModelViewMatrix * pos;
    gl_Position = gl_ProjectionMatrix * viewPos;

    vViewPos     = viewPos.xyz;
    vWorldPos    = worldPos;
    vViewNormal  = normalize(gl_NormalMatrix * gl_Normal);
    vTexCoord    = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vLmCoord     = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vColor       = gl_Color;
}
