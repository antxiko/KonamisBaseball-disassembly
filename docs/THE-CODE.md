# The code

629 named routines, 5,301 instructions, 2,357 line comments: **44.5 % of the
listing commented**, and **no routine below 10 %**.

## Where everything starts

```
0x4061  INIT             hooks the interrupt and clears the RAM
0x4010  interrupt        ALL the game runs in here
0x411e  bucle_principal  the Konami logo rising up the screen
```

The interrupt guards itself with two locks, keeps the frame counter at 0xE000,
and at the end reads the VDP status again: if another interrupt is pending it
**re-executes itself** instead of returning.

## How a frame is split

0x7bb0 splits the work into two halves that alternate frame by frame, on bit 0
of the frame counter:

| Even frames | Odd frames |
|---|---|
| the batted ball (0x620a) | the fielding (0x7373) |
| the pitch (0x4ccc) | the batter (0x7080) |
| the runners (0x5e80) | the pick-up (0x7692) |
| | the machine (0x7d04) |

## The records

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

## Where the state lives

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

## The calculator

The whole flight of a batted ball is worked out in four bytes of RAM, 0xE060 to
0xE063, with two routines that are a multiply and a divide done by hand:

- **0x6539**, multiply: sixteen rounds of shifting 24 bits and adding.
- **0x6519**, divide: eight rounds of shifting and subtracting.

And there is a smaller divide besides, the one at 0x4cb0, which works on 0xE700
and computes the slope of a trajectory: it is called **twice** in a row (0x4ca1)
to get two decimals.

## How a player is drawn

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

## The sound engine

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

## The tools

```
tools/z80trace.py    the flow trace, with the !skip directive
tools/mkasm.py       the listing, from the trace and the notes
tools/guiones.py     the script interpreter, redone in Python
tools/pantallas.py   the screens and the poses, drawn from the ROM
tools/densidad.py    how much of the listing is commented, routine by routine
tools/presupuesto.py that not one byte is left unassigned
```
