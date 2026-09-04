# Open questions

What is left to close. It is written down here so it stays visible, not so it
gets forgotten.

## The pictures have not been compared against the emulator's VRAM

They have been **looked at**, and they match what the code says, but looking is
not comparing. The real check is to dump openMSX's VRAM at the exact instant and
compare it byte by byte with what `tools/pantallas.py` produces. It is pending.

## Nobody has played a whole match

The listing is understood top to bottom and the numbers are measured, but **a
complete nine-inning match has never been played through**. There are two things
that can only be closed that way:

- The **extra innings on a tie**. 0x7b7b, in the eighth inning, checks whether
  the two scores are level and writes an 0xE7 into the cell; the match carries
  on. That this is extra innings is what the code says, but it has not been
  seen.
- The **"4 BALL" card**. It is in the table, it reads correctly with the
  cartridge's font, and 0x7afd brings it out on the fourth ball. It has not been
  seen on screen.

## The script at 0x4AF0 still has no reader

99 bytes that form a valid script and that load eight sprite patterns and five
attributes. Four checks were made - the previous script does not chain, there is
no 16-bit immediate pointing there, the two pointer tables point inside their
own blocks, and the nine embedded arguments are not this one - and all four come
back negative.

A negative is not a proof. If anybody finds who draws it, this gets corrected.

## The three bytes of the fifteenth record

Fifteen records of 21 bytes is 315 and the table holds 312: the three missing
ones are the first three of the routine that follows. Whether that is
**deliberate saving** or an **oversight nobody notices** because those slots go
unused cannot be decided from the binary. It would take watching whether those
three slots are ever read in a real game.

## What 0xE032, 0xE057 and 0xE650 really are

They show up in the batted ball's flight and in the sound engine, and we know
**when** they change and **who** reads them, but no name could be put on them
that says what they mean. In the listing they are commented by what they do, not
by what they are.

## The shadow chain at 0xE245

0x5d62 rotates five bytes 0x20 apart inside the 0xE200 block. That this is the
trail left by whatever is moving is what the chained rotation suggests, but it
**has not been measured**.

## The 0x01 command - do more cartridges in the family have it?

Baseball (1984) has a script command King's Valley (1985) does not, and it
chains addresses the other way round. The easy reading is that King's Valley
simplified the interpreter. To know for sure you would have to look at the other
cartridges in the same family: **Athletic Land**, **Cabbage Patch Kids**, **Hyper
Olympic**, **Hyper Sports**, **Hyper Rally**, **Konami's Tennis**, **Konami's
Golf** and **Sky Jaguar**, all of which are disassembled in this same series.

It is material for the series' global database, and it is not done.

## The sound channels, unlistened to

The engine is understood - three channels, priority by the low six bits, scripts
with prefixes for duration, octave and decay - but **it has not been listened to
channel by channel** in the emulator to confirm that the `0x1n` command really is
noise and not something else.
