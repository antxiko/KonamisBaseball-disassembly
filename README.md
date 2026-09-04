# Konami's Baseball — a commented disassembly

A complete, commented disassembly of **Konami's Baseball** (Konami, 1984), the
16 KB **RC-724** cartridge for the MSX1.

📖 **[Read the site](https://antxiko.github.io/KonamisBaseball-disassembly/)** ·
🇪🇸 [En castellano](README.es.md)

```
100.00 %  of the binary explained          0  bytes unidentified
   9,618  bytes of traced code           629  named routines
   6,766  bytes of declared data       44.5 %  of the listing commented
```

Reassembling the listing gives back the ROM **byte for byte**:
`06504efb72d1cd3351dae8eb1f7b073f69d599fa7018663937f85535658ad3e7`.

## The ROM is not here

This repository does not distribute the cartridge image. Put your own copy in
the root as `baseball.rom` and check it with:

```sh
shasum -a 256 baseball.rom
```

## Build it

```sh
make            # listing + verify + sanity + tests
make verify     # reassemble and compare against the ROM, byte for byte
make sanity     # the four checks reassembling does not cover
make densidad   # how much of the listing is commented
make web        # the bilingual site in docs/
```

## What turned up

- **The script's address is written behind the CALL itself.** 0x4582 does
  `ex (sp),hl`, reads the two bytes that follow the call, and pushes the return
  past them. Nine places do this — and a disassembler that does not know takes
  eighteen bytes of data for instructions while still reassembling perfectly.
- **The Japanese league's twelve teams, in twelve letters.** The selection grid
  shows only initials: `C D G S T W` for the Central and `B Bu F H L O` for the
  Pacific — the twelve NPB teams of 1984. Tile 0xE8 is a **"Bu" in a single
  character**, made so the Buffaloes are not mistaken for the Braves.
- **The computer plays by writing into the joystick slot.** There is no separate
  path for the opponent: it leaves its moves in 0xE011, the very byte where the
  second player's freshly pressed bits live. Same trick for the menu demo — and
  since the sound engine refuses to play while the demo is on, the automatic
  game is silent.
- **The screen's three thirds, painted with one loop that reads its own
  output**: 4,095 bytes copied from VRAM 0x0000 to 0x0800, overlapping on
  purpose. It falls one byte short of the third third, and always has.
- **The byte that ends a script is the next sprite's first byte.** In 21 of the
  22 player poses the offset pointer lands on the script's own 0x00 terminator.
- **A script nobody draws**: 99 valid bytes at 0x4AF0 loading eight sprite
  patterns, with four separate checks all coming back negative on who reads it.
- **It carries Konami's hidden mark** (found by
  [Manuel Pazos](https://twitter.com/ManuelPazosMSX)): `RC-724` and `YA KI U` —
  野球, *yakyū*, baseball.

Full detail on the site, under
[Findings](https://antxiko.github.io/KonamisBaseball-disassembly/FINDINGS.html).

## Every picture is drawn from the ROM

Not one emulator capture. `tools/pantallas.py` runs the cartridge's own script
interpreter over a 16 KB VRAM image in Python, then reveals it as SCREEN 2 —
the title screen, the league and team grids, the stadium, and all 22 player
poses with their three colour layers.

## Layout

```
src/baseball.notes     what has been understood: names, comments, data blocks
src/baseball.entries   entry points static tracing cannot deduce
src/baseball.nocode    regions the tracer must not read as code
src/baseball.asm       GENERATED — never edited by hand
tools/                 tracer, listing builder, checks, renderers, openMSX scripts
docs/                  the bilingual site
```

## Licence

The analysis, the comments and the tools are under the [MIT licence](LICENSE).
The game itself is not covered: see the [legal notice](LEGAL-NOTICE.md).
