# The cartridge

16,384 bytes in page 1, from 0x4000 to 0x7FFF. All of them accounted for:

```
traced code         9,618 bytes    58.70 %
declared data       6,766 bytes    41.30 %
unexplained             0 bytes     0.00 %
```

## The header

The first ten bytes are `41 42 61 40 00 00 00 00 00 00`: the **AB** mark and the
address of **INIT**, 0x4061. STATEMENT, DEVICE and TEXT all zero, and six bytes
of padding up to the interrupt handler at 0x4010.

## The start-up

INIT does not use the BIOS to hook the interrupt: it puts a `0xC3` - a `jp` -
into **H.KEYI** (0xFD9A) with the address 0x4010 behind it, clears
0xE000-0xE7FE with an `ldir` and leaves the stack there. **The whole game runs
inside the interrupt.**

That is King's Valley's pattern, and it is not the only thing they share.

## The same frame as King's Valley

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

## The VRAM geometry

```
COLOUR    0x0000    (R3 = 0x7F)
PATTERN   0x2000    (R4 = 0x07)
NAME      0x3800    (R2 = 0x0E)
SPRITES   0x1800    (R6 = 0x03), attributes at 0x3B00 (R5 = 0x76)
```

In SCREEN 2 the TMS9918 does not read R3 and R4 as an address, but as a base bit
and a mask. Reading it the other way has a deceptive symptom: the shapes still
read - the two blocks are symmetric - but the colours come out in bands.

## The script interpreter

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

## The data blocks

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

## The hidden mark

At 0x7FF6, closing out the cartridge: **RC-724** and the katakana title, **YA KI
U**, which is 野球 (*yakyū*), baseball. Konami hid this at the end of many of its
cartridges; **Manuel Pazos**
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)) found it.
