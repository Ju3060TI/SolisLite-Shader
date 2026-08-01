# =====================================================================
# SolisLite - block.properties
# Weist Bloecken eigene, im Shader abfragbare IDs (mc_Entity.x) zu.
# Wird fuer folgende Zwecke genutzt:
#   1700   = Wasser (Unterscheidung von anderen "translucent"-Bloecken -
#            Glas, Eis, Honig, Slime, Nether-Portal usw. laufen in
#            Iris/OptiFine durch DASSELBE gbuffers_water-Programm wie
#            Wasser! Ohne diese explizite Markierung wuerde der Shader
#            faelschlich Wellen/Refraktion auf Glasscheiben anwenden.)
#   1801.* = bewegliche, niedrige Pflanzen (Windanimation)
#   1802.* = Laub (Windanimation, staerkeres Wrap-Licht gegen schwarzes Laub)
#   1803.* = Ranken-artige haengende Vegetation
#   1900   = Glas/Glasscheiben (fuer nahtlose "Connected Glass"-Ueberblendung)
# =====================================================================

block.1700=minecraft:water minecraft:bubble_column

block.1801=minecraft:short_grass minecraft:tall_grass minecraft:fern minecraft:large_fern \
    minecraft:dandelion minecraft:poppy minecraft:blue_orchid minecraft:allium \
    minecraft:azure_bluet minecraft:red_tulip minecraft:orange_tulip minecraft:white_tulip \
    minecraft:pink_tulip minecraft:oxeye_daisy minecraft:cornflower minecraft:lily_of_the_valley \
    minecraft:wither_rose minecraft:sunflower minecraft:lilac minecraft:rose_bush minecraft:peony \
    minecraft:sapling minecraft:oak_sapling minecraft:spruce_sapling minecraft:birch_sapling \
    minecraft:jungle_sapling minecraft:acacia_sapling minecraft:dark_oak_sapling minecraft:mangrove_propagule \
    minecraft:wheat minecraft:carrots minecraft:potatoes minecraft:beetroots minecraft:sweet_berry_bush \
    minecraft:seagrass minecraft:tall_seagrass

block.1802=minecraft:oak_leaves minecraft:spruce_leaves minecraft:birch_leaves minecraft:jungle_leaves \
    minecraft:acacia_leaves minecraft:dark_oak_leaves minecraft:mangrove_leaves minecraft:azalea_leaves \
    minecraft:flowering_azalea_leaves minecraft:cherry_leaves

block.1803=minecraft:vine minecraft:weeping_vines minecraft:weeping_vines_plant \
    minecraft:twisting_vines minecraft:twisting_vines_plant minecraft:cave_vines \
    minecraft:cave_vines_plant minecraft:hanging_roots minecraft:glow_lichen

block.1900=minecraft:glass minecraft:white_stained_glass minecraft:orange_stained_glass \
    minecraft:magenta_stained_glass minecraft:light_blue_stained_glass minecraft:yellow_stained_glass \
    minecraft:lime_stained_glass minecraft:pink_stained_glass minecraft:gray_stained_glass \
    minecraft:light_gray_stained_glass minecraft:cyan_stained_glass minecraft:purple_stained_glass \
    minecraft:blue_stained_glass minecraft:brown_stained_glass minecraft:green_stained_glass \
    minecraft:red_stained_glass minecraft:black_stained_glass minecraft:tinted_glass \
    minecraft:glass_pane minecraft:white_stained_glass_pane minecraft:orange_stained_glass_pane \
    minecraft:magenta_stained_glass_pane minecraft:light_blue_stained_glass_pane minecraft:yellow_stained_glass_pane \
    minecraft:lime_stained_glass_pane minecraft:pink_stained_glass_pane minecraft:gray_stained_glass_pane \
    minecraft:light_gray_stained_glass_pane minecraft:cyan_stained_glass_pane minecraft:purple_stained_glass_pane \
    minecraft:blue_stained_glass_pane minecraft:brown_stained_glass_pane minecraft:green_stained_glass_pane \
    minecraft:red_stained_glass_pane minecraft:black_stained_glass_pane
