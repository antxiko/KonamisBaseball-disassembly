# In the emulator

## What has been checked and what has not

Let us be clear before anything else: **the pictures on this site have not been
compared byte by byte against openMSX's VRAM**. They have been looked at, and
what is on them matches what the code says - the stadium with its scoreboard,
the title, the two leagues, the twenty-two poses - but that is not the same as a
comparison.

What *is* checked is that **the listing reproduces the ROM byte by byte** (`make
verify`) and that **not one byte of the cartridge is left unassigned** (`make
sanity`). Both have been run after every working round.

## How the pictures are drawn

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

## Two comments that lied, caught by drawing

Drawing things uncovers errors that reading the code does not catch. Two turned
up in this cartridge:

- 0x44b7 was commented as "the two rows of numbered scoreboard cells". It is
  not: it is **the game's title**, 46 consecutive tiles from 0x40 to 0x6D in two
  rows of 23. It showed the moment the menu screen was drawn and "Konami's
  Baseball" appeared.
- The second screen was commented as "the team screen". It is not: it is the
  **league** screen, CENTRAL and PACIFIC, and the team one comes after it.

## Running the cartridge

```
openmsx -machine Philips_NMS_8250 -carta baseball.rom
```

To dump VRAM and compare for real, `tools/omsx_vram.tcl` has the breakpoints
ready. That comparison is **still pending**, and it is written down as such on
the open questions page.

## What to know before measuring

- **The interrupt is everything.** Stop the emulator inside the handler at
  0x4010 and half the state is half-written. The good places to stop are the
  wait loops: 0x4260, 0x4266, 0x42ec.
- **Buffers are reused several times per frame.** 0xE700 is a scratch slot used
  by at least four different routines; reading it outside the exact instant
  tells you nothing.
- **The randomness is the R register.** The cartridge uses it as a die in five
  places (0x4219, 0x4d69, 0x714b, 0x7196, 0x7d66), so two identical games do not
  exist even stopping the emulator at the same spot.
