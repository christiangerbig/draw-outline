# draw-outline

This is a very fast outline drawing routine for filled vectors on the Commodore Amiga.

It considers only interleaved bitplanes. More information about the [interleaved bitplane format](https://megaburken.net/~patrik/ScrollingTricks/ScrollingTricks/Docs/interleaved-uk.html).

Advantages:

- No octants table is needed
- No XOR blit for the edges, they are blunt
