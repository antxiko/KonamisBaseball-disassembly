# Findings

What turned up when we took it apart. All of it is measured on the binary; where
something is an assumption, it says so.

## 1. The script's address is written behind the CALL itself

0x4582 receives nothing in registers. It does `ex (sp),hl` to grab the return
address, reads a word from there, pushes the return **two bytes** past so they
are never executed, and falls into the script interpreter.

```
        call 0x4582
        defw 0x65AD      <- this is NOT code, it is the argument
        ld de,...
```

**Nine** places call it that way. Not knowing this, a disassembler takes those
eighteen bytes for instructions; the binary still comes out identical - they are
the same bytes - but the listing lies, and **no amount of reassembling will
catch it**.

Here they are declared with the `!skip 0x4582 2` directive in the entries file,
and all nine arguments land inside script blocks we already know, which is what
confirms the reading.

## 2. The screen's three thirds, with a single loop

SCREEN 2 is three independent 2 KB thirds, and for all three to hold the same
thing you have to write it three times. 0x4485 copies VRAM to VRAM byte by byte,
and is handed **4,095** bytes from 0x0000 to 0x0800.

Since the destination runs 0x800 ahead, past the first block it is reading what
it has just written. **One loop, three identical thirds, 4 KB saved.** Done
twice: colours and patterns.

And it falls **one byte short**: 4,095 and not 4,096, so the last byte of the
third third is never written at all.

## 3. The Japanese league's twelve teams, in twelve letters

The selection grid shows no names: it shows initials. The twelve bytes at 0x4649
are tile numbers, and drawing the font from the ROM they read:

```
Central   C D G S T W    Carp, Dragons, Giants, Swallows, Tigers, Whales
Pacific   B Bu F H L O   Braves, Buffaloes, Fighters, Hawks, Lions, Orions
```

The twelve teams of **1984 Nippon Professional Baseball**, alphabetical within
each league. And there is a tile made on purpose for it: **0xE8 is a "Bu" in a
single character**, which exists only so the Buffaloes are not mistaken for the
Braves.

## 4. The computer plays by writing into the joystick slot

There is no separate path for the opponent. 0x7d04 works out what a player would
do and leaves it written in **0xE011**, the very byte where 0x43e2 puts the
second player's freshly pressed bits. The menu's demo does the same with
**0xE00E**, the first player's.

So the rest of the cartridge - the batting, the running, the pitching - neither
knows nor cares whether a person or the cartridge itself is playing.

And there is a lovely side effect: since 0x6c0e refuses to play anything while
0xE002 is set, **the menu's automatic game is silent**.

## 5. The font is not ASCII: it is the order the letters were needed in

```
0xD0 B   0xD1 D   0xD2 J   0xD3 O   0xD4 T   0xD5 I   0xD6 C   0xD7 K
0xD8 P   0xD9 L   0xDA A   0xDB Y   0xDC E   0xDD R   0xDE S   0xDF G
0xE0 H   0xE1 M   0xE2 V   0xE3 W   0xE4 F   0xE5 U   0xE6 N   0xE7 X
0xE8 Bu  0xE9 ,   0xEA (c)
0xF0 to 0xF9: the digits 0 to 9
```

There is no order at all: there are **the 24 letters the cartridge ever writes**,
laid down as they were needed. And in the middle, a gift: tiles **0xD8 to 0xDE
are P L A Y E R S in a row**, which is what lets it write "1 PLAYER" and "2
PLAYERS" with no table at all.

The digits do run in order, 0xF0 plus the digit, which is why the scoreboard and
the count are written with a plain `or 0f0h`.

## 6. The byte that ends a script is the next sprite's first byte

Every player pose is three scripts - one per colour layer - followed by six
offset bytes. In **21 of the 22 poses**, the pointer to those six bytes points
**at the 0x00 that ends the third script**: that byte does both jobs at once,
ending the script and being the first layer's row offset.

The only one that does not is 0x50EC, and only because its first offset is 1 and
not 0. One byte saved per pose, twenty-one times over.

## 7. The ball shrinks because there are five balls

There is no scaling: there are **five different drawings** at 0x6573, from seven
rows down to two. 0x646b picks between them by subtracting the ball's row from
its shadow's - which is the height - and comparing against **0x21, 0x0F and
0x06**, and drops one more if the shadow is above row 0x40, that is, if the play
is going far.

The bounce is not computed: it **happens** when the ball's row catches up with
its shadow's.

## 8. The batter eats three bytes of the routine next door

The fifteen fielders' records take 21 bytes in the ROM and 32 in RAM. Fifteen
times 32 fills exactly 0xE180..0xE35F, right up to where the meter starts: the
top end adds up.

The bottom end does not: fifteen times 21 is **315** bytes and from 0x5C03 to
0x5D3B there are **312**. The three missing ones are the first three of the
routine at 0x5D3B - `21 00 E1`, that is `ld hl,0e100h` - and they end up in
slots 28, 29 and 30 of the fifteenth record.

Whether that is deliberate byte-saving or an oversight nobody notices because
those slots go unused **cannot be decided from the binary**.

## 9. A script nobody draws

99 bytes at 0x4AF0 that form a perfectly valid script: they load four sprite
patterns into VRAM 0x1800, four more into 0x1D00 and five attributes, and end
**exactly** where code resumes.

Nobody draws them:

- the start-up draws the script at 0x4A96, which **ends** at 0x4AF0, and then
  overwrites HL with 0x49D4: it does not chain;
- in the whole ROM there is not a single 16-bit immediate between 0x4AF0 and
  0x4B53;
- the two script pointer tables - 0x5048 and 0x655F - all point inside their own
  blocks;
- the nine `call 0x4582` carry their argument alongside, and none of them is
  this one.

It is a **negative** result - the reader was not found, which is not the same as
proving there is none - but it points at bytes that were left inside.

## 10. The same frame as King's Valley

The two cartridges' VDP register tables are **identical but for one byte**, the
border colour. The script language is the same, with two differences: Baseball
has one command more - 0x01 - and chains by reading the address high byte first,
the reverse of King's Valley.

That the **older** cartridge (1984) has the extra command and the newer one
(1985) does not fits with King's Valley being a simplification. **ASSUMPTION**:
not checked against more cartridges in the family.

## 11. Every counter at zero means 256

Clearing the screen is three passes with B at zero. They are not empty passes:
the Z80 decrements before testing, so a `djnz` with B at zero goes round **256**
times. Three times 256 is the name table's 768 cells, written without the count
appearing anywhere.

## 12. It carries Konami's hidden mark

At 0x7FF6, closing out the cartridge: **RC-724** and the katakana title, **YA KI
U**, which is 野球 (*yakyū*), baseball.

Konami hid its catalogue number and title at the end of many of its cartridges;
**Manuel Pazos** ([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)) found
it, and he must be credited.
