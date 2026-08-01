/* SolisLite - gbuffers_clouds.vsh
 * Nimmt die vorhandene, flache (also bereits "2D") Vanilla-Wolkenebene
 * und bereitet Weltposition + Normale fuer eine hochwertigere
 * Einfaerbung im Fragment-Shader vor. */
#version 120

#include "lib/common.glsl"

varying vec4 vColor;
varying vec3 vWorldPos;

void main() {
    gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;
    vColor = gl_Color;

    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    vec4 playerSpacePos = gbufferModelViewInverse * viewPos;
    vWorldPos = playerSpacePos.xyz + cameraPosition;
}
