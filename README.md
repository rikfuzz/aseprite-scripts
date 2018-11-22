# aseprite-scripts
Scritpts for Aseprite

Currently requires Aseprite v1.2.10-beta2

<h1>Antialias.lua</h1>
Antialiases inside the foreground colour anywhere it touches the background colour (automatically picks a colour inbetween the two).
(Swap fg/bg colours before running to antialias outside instead)
This is a pixel-art style antialias, only adding 1 new colour with a max length of 2 on the antialis pixels each side.
(affecting a selection is currently broken)

<h1>Outline</h1>
Outlines the current image with the foreground colour. 
(undo doesn't totally work here, will move the image down-right 1px)
