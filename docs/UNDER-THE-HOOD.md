# Under the hood

## Getting started

This repository holds a commented disassembly of **Konami's Baseball** (Konami,
1984), the 16 KB **RC-724** cartridge for the MSX1.

The ROM is **not distributed here**. You need to put it in the root of the
repository under the name `baseball.rom`. To check it is the same one:

```
shasum -a 256 baseball.rom
06504efb72d1cd3351dae8eb1f7b073f69d599fa7018663937f85535658ad3e7
```

### What `make` does

```
make listado    builds src/baseball.asm from the trace and the notes
make verify     reassembles the listing and compares it with the ROM, byte by byte
make sanity     the four checks reassembling does NOT cover
make densidad   counts how much of the listing is commented
make imagenes   draws the declared graphic blocks, so you can look at them
make web        builds the bilingual site under docs/
```

Plain `make` runs `listado`, `verify`, `sanity` and `test`.

### Why `verify` is the test that matters

A disassembly can be written many ways, and nearly all of them are wrong in
some way you will not notice. The one test that admits no argument is to
reassemble the listing and check that it produces **exactly the same ROM**: all
16,384 bytes, in the same order, with the same sha256.

That is what `make verify` does, and it has been run after every working round.
If it ever fails, the listing is wrong, however nicely it reads.

### What reassembling does NOT cover

The bytes coming out identical says nothing about whether we have **understood**
them. A data block read as if it were code produces the same binary and a lie in
the listing. This cartridge has a perfect example: the addresses written
**behind** each `call 0x4582`. The disassembler took them for instructions, the
binary came out identical, and the listing lied in nine places.

That is why `make sanity` runs four separate checks:

- **`check_trace.py`**: nothing declared as data in the `.nocode` may have been
  traced as code.
- **`check_datos_como_codigo.py`**: no data block from the `.notes` may overlap
  traced code.
- **`check_entradas.py`**: no hand-declared entry point may land inside a data
  block, and **every one of them must carry its reason alongside**.
- **`presupuesto.py`**: all 16,384 bytes must be accounted for. Right now:
  9,618 of code, 6,766 of data, **zero unexplained**.

### And the tests

`make test` runs twelve more checks on the listing itself: that comments do not
disappear, that no routine drops below 10 % density, that the numbers published
on this site are the ones in the tree and not the ones that were true when the
text was written, and that no other game from the series sneaks into a page -
which has happened before, with five LICENSE files and with the footer of
fourteen pages.

### The files

```
baseball.rom          the ROM (NOT here)
src/baseball.entries  the entry points, each with its justification
src/baseball.notes    EVERYTHING understood: names, comments, data blocks
src/baseball.nocode   ranges declared as data before tracing (empty here)
src/baseball.asm      the listing, GENERATED; never edited by hand
tools/                the disassembler, the checkers and the site
```

The file that matters is **`src/baseball.notes`**. The `.asm` is regenerated
whole every time; what is written by hand are the notes, and they are anchored
to addresses, so they survive a re-trace.

## The cartridge

16,384 bytes in page 1, from 0x4000 to 0x7FFF. All of them accounted for:

```
traced code         9,618 bytes    58.70 %
declared data       6,766 bytes    41.30 %
unexplained             0 bytes     0.00 %
```

### The header

The first ten bytes are `41 42 61 40 00 00 00 00 00 00`: the **AB** mark and the
address of **INIT**, 0x4061. STATEMENT, DEVICE and TEXT all zero, and six bytes
of padding up to the interrupt handler at 0x4010.

### The start-up

INIT does not use the BIOS to hook the interrupt: it puts a `0xC3` - a `jp` -
into **H.KEYI** (0xFD9A) with the address 0x4010 behind it, clears
0xE000-0xE7FE with an `ldir` and leaves the stack there. **The whole game runs
inside the interrupt.**

That is King's Valley's pattern, and it is not the only thing they share.

### The same frame as King's Valley

This cartridge is from 1984 and King's Valley from 1985, and they share things
that are not coincidence:

**The VDP register table is identical but for one byte:**

```
Baseball        02 E2 0E 7F 07 76 03 E1   (0x46cc)
King's Valley   02 E2 0E 7F 07 76 03 E4   (0x45c0)
```

Only R7 changes, the border colour. That is, the **same VRAM geometry**,
including the oddity explained on the findings page: colours at 0x0000 and
patterns at 0x2000, the reverse of the usual layout.

**The same script language**, with two real differences:

- Baseball has **one command more**, `0x01`: the low nibble of the next byte
  says how many bytes a run takes and the high one how many times it repeats.
  King's Valley does not have it.
- When chaining (`0x80`), Baseball reads the address **high byte first** (`ld
  d,(hl)` before `ld e,(hl)`, at 0x4589); King's Valley low byte first. Reading
  one with the other's order gives noise.

That the **older** cartridge has the extra command and the newer one does not
fits with King's Valley being a simplification, not the other way round.
**ASSUMPTION**: not checked against more cartridges in the family.

**Baseball's own difference**: the interrupt carries **two locks** (0xE01E and
0xE01F), and `arma_escritura_vram` (0x4689) **redoes the whole operation** if the
interrupt slips in halfway - it watches 0xE01D. King's Valley does not need
that. It is the mechanism that lets it write VRAM with interrupts enabled.

### The VRAM geometry

```
COLOUR    0x0000    (R3 = 0x7F)
PATTERN   0x2000    (R4 = 0x07)
NAME      0x3800    (R2 = 0x0E)
SPRITES   0x1800    (R6 = 0x03), attributes at 0x3B00 (R5 = 0x76)
```

In SCREEN 2 the TMS9918 does not read R3 and R4 as an address, but as a base bit
and a mask. Reading it the other way has a deceptive symptom: the shapes still
read - the two blocks are symmetric - but the colours come out in bands.

### The script interpreter

Everything the cartridge draws is stored as **scripts**: runs of orders that
0x458d executes against the VDP data port.

```
0x01 nb       n = high nibble, b = low nibble. Copies the same b-byte run n
              times without consuming it, then skips those b bytes
0x00          end of script
0x80          chain: the next two bytes are a new VRAM address, HIGH BYTE FIRST
n (bit 7 = 0) fill: the next byte, repeated n times
n (bit 7 = 1) raw copy of (n and 0x7F) bytes
```

`tools/guiones.py` reproduces this interpreter in Python, and it is where every
picture on this site comes from.

### The data blocks

They are all separated by use, each with its name and its declared width. The
big ones:

| Where | What |
|---|---|
| 0x46d4-0x4765 | the title screen and selection scripts |
| 0x4765-0x477f | the menu cursor tables |
| 0x477f-0x47c9 | the three scoreboard scripts |
| 0x47cf-0x4af0 | the long start-up script and its re-entries |
| 0x4af0-0x4b53 | **a script nobody draws** |
| 0x5048-0x5a32 | the player poses, three layers each |
| 0x5bd9-0x5c03 | the two start-up records, 21 bytes each |
| 0x5c03-0x5d3b | the fifteen fielders' records |
| 0x65ad-0x6c0e | the stadium scripts |
| 0x6e84-0x7080 | the notes, the sound pointers and their scripts |
| 0x7c20-0x7c7a | the seven cards and their texts |
| 0x7ff6-0x8000 | Konami's hidden mark |

### The hidden mark

At 0x7FF6, closing out the cartridge: **RC-724** and the katakana title, **YA KI
U**, which is 野球 (*yakyū*), baseball. Konami hid this at the end of many of its
cartridges; **Manuel Pazos**
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)) found it.

## The code

629 named routines, 5,301 instructions, 2,357 line comments: **44.5 % of the
listing commented**, and **no routine below 10 %**.

### Where everything starts

```
0x4061  INIT             hooks the interrupt and clears the RAM
0x4010  interrupt        ALL the game runs in here
0x411e  bucle_principal  the Konami logo rising up the screen
```

The interrupt guards itself with two locks, keeps the frame counter at 0xE000,
and at the end reads the VDP status again: if another interrupt is pending it
**re-executes itself** instead of returning.

### How a frame is split

0x7bb0 splits the work into two halves that alternate frame by frame, on bit 0
of the frame counter:

| Even frames | Odd frames |
|---|---|
| the batted ball (0x620a) | the fielding (0x7373) |
| the pitch (0x4ccc) | the batter (0x7080) |
| the runners (0x5e80) | the pick-up (0x7692) |
| | the machine (0x7d04) |

### The records

Almost everything that moves is described by a **record** pointed at with IX.
The slots the movement engine at 0x4b53 uses:

```
+0x00  flags: bit 0 running, bit 6 "moved this frame"
+0x01  sub-pixel accumulator, 16 bits
+0x03  the step added every frame, 16 bits
+0x07  X in pixels           +0x08  Y in pixels
+0x0c  min X  +0x0d  max X  +0x0e  min Y  +0x0f  max Y
+0x10  direction flags: bit 7 the dominant axis, bits 6 and 5 the signs
+0x11  how much is left to travel in X
+0x12  how much is left to travel in Y
```

The sub-pixel trick is King's Valley's: the fine position lives in 16 bits, the
step is added every frame, and the accumulator's **high byte** is how many whole
pixels to move; it is spent and zeroed, and the remainder is kept for the next
frame.

### Where the state lives

| Address | What |
|---|---|
| 0xE000 | the frame counter, raised by the interrupt |
| 0xE001 | the slow counter, lowered every 32 frames |
| 0xE002 | the demo autopilot is in charge |
| 0xE00C..0xE011 | the two pads: read, previous read and edges |
| 0xE100 | the pitcher's state |
| 0xE140 | the batter's |
| 0xE180..0xE1FF | the four bases, 32 bytes each |
| 0xE220..0xE33F | the nine fielders |
| 0xE340 | the ball thrown between bases |
| 0xE360..0xE36E | the pitch meter and its bar |
| 0xE380 | the running word |
| 0xE388 | the fielding word |
| 0xE400 | the state of the play |
| 0xE408..0xE40E | strikes, balls, outs, inning, runs |
| 0xE440..0xE446 | league, teams and the two random seeds |
| 0xE660..0xE686 | the sound engine, three eleven-byte channels |

### The calculator

The whole flight of a batted ball is worked out in four bytes of RAM, 0xE060 to
0xE063, with two routines that are a multiply and a divide done by hand:

- **0x6539**, multiply: sixteen rounds of shifting 24 bits and adding.
- **0x6519**, divide: eight rounds of shifting and subtracting.

And there is a smaller divide besides, the one at 0x4cb0, which works on 0xE700
and computes the slope of a trajectory: it is called **twice** in a row (0x4ca1)
to get two decimals.

### How a player is drawn

A player is **three stacked 16x16 sprites**, one per colour, and the cartridge
**does not keep all the poses in VRAM**: every time the pose changes it uploads
all three patterns - 32 bytes each - from the ROM, decompressing them with the
same interpreter that draws the screens.

The table at 0x5048 holds one pointer per pose, and each points at a
**four-word** record: the three scripts - one layer each - and a pointer to six
offset bytes, one signed (row, column) pair per layer.

Fielders are cheaper: **a single layer** and one sprite, and there the table at
0x5048 is used differently - what it returns is the script directly, not a
four-word record.

### The sound engine

Three channels, eleven bytes of state each, starting at 0xE661. The way in is
0x6c0e, which takes the sound number in A and **refuses to play anything** if
0xE002 says the demo is in charge.

The dispatcher at 0x6c20 decides how many channels a sound fits in and only
takes it if its number is **higher** than the one already playing: the low six
bits of the number act as a priority.

A sound's script, as 0x6ced reads it:

```
0xFF  end: the channel goes quiet
0xFE  back to the start, counting the laps
0x2n  change the note duration to n
0x1n  noise: n goes to PSG register 6
rest  a note, with its duration in the high nibble
```

And there is a second path, behind bit 7 of the mode, with up to three prefixes
in front of the note: `0xDn` the duration unit, `0xFn` the volume decay and
`0xEn` the octave, which is done by **doubling** the frequency that many times.

### The tools

```
tools/z80trace.py    the flow trace, with the !skip directive
tools/mkasm.py       the listing, from the trace and the notes
tools/guiones.py     the script interpreter, redone in Python
tools/pantallas.py   the screens and the poses, drawn from the ROM
tools/densidad.py    how much of the listing is commented, routine by routine
tools/presupuesto.py that not one byte is left unassigned
```

## In the emulator

### What has been checked and what has not

Let us be clear before anything else: **the pictures on this site have not been
compared byte by byte against openMSX's VRAM**. They have been looked at, and
what is on them matches what the code says - the stadium with its scoreboard,
the title, the two leagues, the twenty-two poses - but that is not the same as a
comparison.

What *is* checked is that **the listing reproduces the ROM byte by byte** (`make
verify`) and that **not one byte of the cartridge is left unassigned** (`make
sanity`). Both have been run after every working round.

### How the pictures are drawn

There is not one capture. `tools/pantallas.py` runs in Python the same script
interpreter the Z80 runs, over a 16 KB VRAM in memory, and then develops it as
SCREEN 2:

```
python3 tools/pantallas.py baseball.rom 0x4000 docs/imagenes
```

Each scene reproduces the cartridge's own sequence, in the same order:

```
THE TITLE SCREEN, as 0x40cc builds it:
    0x40d1  script 0x47cf ....... patterns and colours
    0x40e2  script 0x4a96
    0x40d6  script 0x4a27 into VRAM 0x6680
    0x40e7  script 0x49d4 into VRAM 0x6780
    0x40f9  replica of VRAM 0x0000 -> 0x0800 (4095 bytes) ..... colours
    0x4102  replica of VRAM 0x2000 -> 0x2800 (4095 bytes) .... patterns

THE FIELD, as 0x4219 builds it:
    0x421e  clearing the name table
    0x4226  script 0x65ad .......... the stadium's patterns and colours
    0x4231  replica of VRAM 0x0000 -> 0x0800
    0x423a  replica of VRAM 0x2000 -> 0x2800
    0x4243  script 0x6a1c ................... the name table
```

If the picture comes out right it is because the interpreter is correct, not
because a photo was looked at. And when the interpreter was wrong, it showed:
the first passes at the player poses came out as **noise**, and that is where it
turned out that what was being read as rows of tiles were in fact **sprite
patterns**.

### Two comments that lied, caught by drawing

Drawing things uncovers errors that reading the code does not catch. Two turned
up in this cartridge:

- 0x44b7 was commented as "the two rows of numbered scoreboard cells". It is
  not: it is **the game's title**, 46 consecutive tiles from 0x40 to 0x6D in two
  rows of 23. It showed the moment the menu screen was drawn and "Konami's
  Baseball" appeared.
- The second screen was commented as "the team screen". It is not: it is the
  **league** screen, CENTRAL and PACIFIC, and the team one comes after it.

### Running the cartridge

```
openmsx -machine Philips_NMS_8250 -carta baseball.rom
```

Dumping VRAM and comparing for real needs an emulator script, and **this
repository does not carry one**. That comparison is **still pending**, and it is
written down as such on the open questions page; the good places to stop are the
ones just below.

### What to know before measuring

- **The interrupt is everything.** Stop the emulator inside the handler at
  0x4010 and half the state is half-written. The good places to stop are the
  wait loops: 0x4260, 0x4266, 0x42ec.
- **Buffers are reused several times per frame.** 0xE700 is a scratch slot used
  by at least four different routines; reading it outside the exact instant
  tells you nothing.
- **The randomness is the R register.** The cartridge uses it as a die in five
  places (0x4219, 0x4d69, 0x714b, 0x7196, 0x7d66), so two identical games do not
  exist even stopping the emulator at the same spot.

## Code shared with other Konami cartridges

This disassembly has been compared, instruction by instruction, with
every other Konami one in the series. A block counts when the same
instructions, at least six of them from a label to its `ret` or its
unconditional jump, are in both cartridges; the addresses are left
aside, because they change from one cartridge to the next. Of the
other 57, **31** have at least one block in common with this one;
these are the ones that share the most:

| Cartridge | Blocks | Instructions | For example (here = there) |
|---|---:|---:|---|
| [Konami's Golf](https://antxiko.github.io/KonamisGolf-disassembly/) | 34 | 552 | `lee_una_nota_larga` (0x6D9F) = `corre_el_canal_nota_larga` |
| [Konami's Tennis](https://antxiko.github.io/KonamisTennis-disassembly/) | 32 | 518 | `lee_una_nota_larga` (0x6D9F) = `manda_de_la_melodia` |
| [Hyper Olympic 1](https://antxiko.github.io/HyperOlympic1-disassembly/) | 19 | 218 | `replica_el_tercio_en_los_otros_dos` (0x4485) = `COPIA_VRAM_A_VRAM` |
| [Hyper Olympic 2](https://antxiko.github.io/HyperOlympic2-disassembly/) | 18 | 209 | `replica_el_tercio_en_los_otros_dos` (0x4485) = `COPIA_VRAM_A_VRAM` |
| [Hyper Sports 1](https://antxiko.github.io/HyperSports1-disassembly/) | 5 | 58 | `cierra_el_bucle_del_guion` (0x6C6D) = `SUMA_BONUS_7BFC` |
| [Magical Tree](https://antxiko.github.io/MagicalTree-disassembly/) | 5 | 65 | `toca_una_nota` (0x6D3F) = `lee_la_nota_de_la_partitura` |
| [Konami's Ping Pong](https://antxiko.github.io/KonamisPingPong-disassembly/) | 5 | 49 | `abre_o_cierra_el_canal` (0x6C88) = `pon_el_mezclador` |

The whole matrix, the 58 cartridges against each other, is on
[The routines](https://antxiko.github.io/MSX-disassembly-database/THE-ROUTINES.html) in the series database, along
with the method and the program that measures it.
