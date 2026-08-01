# =====================================================================
# SolisLite - shaders.properties
# Optionsmenue-Konfiguration und Qualitaets-Profile fuer Iris.
# Alle eigentlichen Zahlenwerte stecken als #define in lib/common.glsl -
# hier wird nur gesteuert, WIE sie im Iris-Optionsbildschirm dargestellt
# und gruppiert werden.
# =====================================================================

# ---- Reihenfolge/Sichtbarkeit der Regler im Optionsmenue ----
sliders=SHADOW_QUALITY SHADOW_DISTANCE_BLOCKS DYNAMIC_LIGHT_STRENGTH WATER_QUALITY CLOUD_OPACITY WIND_STRENGTH FOG_STRENGTH EXPOSURE CONTRAST SATURATION

screen=<empty> LIGHTING WORLD COLOR
screen.LIGHTING=SHADOW_QUALITY SHADOW_DISTANCE_BLOCKS DYNAMIC_LIGHT_STRENGTH
screen.WORLD=WATER_QUALITY CLOUD_OPACITY WIND_STRENGTH FOG_STRENGTH
screen.COLOR=EXPOSURE CONTRAST SATURATION
screen.columns=1

# ---- Vordefinierte Qualitaetsprofile (per Klick waehlbar) ----
profile.POTATO.SHADOW_QUALITY=0
profile.POTATO.SHADOW_DISTANCE_BLOCKS=48.0
profile.POTATO.WATER_QUALITY=1
profile.POTATO.CLOUD_OPACITY=0.5

profile.LOW.SHADOW_QUALITY=1
profile.LOW.SHADOW_DISTANCE_BLOCKS=64.0
profile.LOW.WATER_QUALITY=1
profile.LOW.CLOUD_OPACITY=0.6

profile.BALANCED.SHADOW_QUALITY=1
profile.BALANCED.SHADOW_DISTANCE_BLOCKS=96.0
profile.BALANCED.WATER_QUALITY=2
profile.BALANCED.CLOUD_OPACITY=0.65

profile.HIGH.SHADOW_QUALITY=2
profile.HIGH.SHADOW_DISTANCE_BLOCKS=128.0
profile.HIGH.WATER_QUALITY=3
profile.HIGH.CLOUD_OPACITY=0.8

# ---- Standard-Fensterprofil beim ersten Start ----
profile.default=BALANCED

# ---- Zusaetzliche Render-Ziele (Farb-Buffer) ----
# colortex0 = Hauptfarbpuffer
# colortex1 = Glas-Materialmaske (Connected Glass)
# colortex2 = von opaken Passes beschrieben (fuer Wasser-Refraction + SSR)
texture.colortex1.format=R8
texture.colortex1.clear=true
texture.colortex2.format=RGBA8
texture.colortex2.clear=true

# Klassische OptiFine/Iris-Schreibweise (Kompatibilitaet)
colortex1Format=R8
colortex2Format=RGBA8

# Composite 1:1
resolution.composite=1.0
