/* SolisLite - gbuffers_skybasic.fsh */
#version 120
/* DRAWBUFFERS:02 */

#include "lib/common.glsl"
#include "lib/sky.glsl"

varying vec4 vColor;
varying vec3 vViewDir;

void main() {
    if (vColor.a < 0.02) discard;

    // View-Space Richtung (passt zu sunPosition)
    vec3 nView = normalize(vViewDir);
    // World-Space fuer Hoehe / Wolken
    vec3 nWorld = normalize(mat3(gbufferModelViewInverse) * nView);
    // Sonne: View-Space Dot (wie Solas VoS mit sunVec)
    vec3 sunView = normalize(sunPosition);
    vec3 sunWorld = normalize(mat3(gbufferModelViewInverse) * sunView);

    // getSkyGradient erwartet worldDir + sunDir (world) fuer Farben/Wolken
    // Sonne intern neu berechnen mit View-Dot fuer korrekte Position
    bool isStar = luma(vColor.rgb) > 0.15;

    if (isStar) {
        vec4 o = vec4(vColor.rgb, vColor.a);
        gl_FragData[0] = o;
        gl_FragData[1] = o;
    } else {
        // Sonne-Dot in View-Space in worldDir "simulieren":
        // wir reichen sunWorld, aber korrigieren VoS indem sunDir = Richtung
        // die in World denselben Winkel hat... einfacher: sunWorld nutzen
        // und nWorld; wenn vViewDir und sunPosition denselben Raum teilen,
        // ist transform konsistent.
        vec3 sky = getSkyGradient(nWorld, sunWorld);
        sky = applyHorizonHaze(sky, nWorld, sunWorld);
        vec4 o = vec4(sky, 1.0);
        gl_FragData[0] = o;
        gl_FragData[1] = o;
    }
}
