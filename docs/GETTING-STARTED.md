# Getting started

This repository holds a commented disassembly of **Konami's Baseball** (Konami,
1984), the 16 KB **RC-724** cartridge for the MSX1.

The ROM is **not distributed here**. You need to put it in the root of the
repository under the name `baseball.rom`. To check it is the same one:

```
shasum -a 256 baseball.rom
06504efb72d1cd3351dae8eb1f7b073f69d599fa7018663937f85535658ad3e7
```

## What `make` does

```
make listado    builds src/baseball.asm from the trace and the notes
make verify     reassembles the listing and compares it with the ROM, byte by byte
make sanity     the four checks reassembling does NOT cover
make densidad   counts how much of the listing is commented
make imagenes   draws the declared graphic blocks, so you can look at them
make web        builds the bilingual site under docs/
```

Plain `make` runs `listado`, `verify`, `sanity` and `test`.

## Why `verify` is the test that matters

A disassembly can be written many ways, and nearly all of them are wrong in
some way you will not notice. The one test that admits no argument is to
reassemble the listing and check that it produces **exactly the same ROM**: all
16,384 bytes, in the same order, with the same sha256.

That is what `make verify` does, and it has been run after every working round.
If it ever fails, the listing is wrong, however nicely it reads.

## What reassembling does NOT cover

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

## And the tests

`make test` runs twelve more checks on the listing itself: that comments do not
disappear, that no routine drops below 10 % density, that the numbers published
on this site are the ones in the tree and not the ones that were true when the
text was written, and that no other game from the series sneaks into a page -
which has happened before, with five LICENSE files and with the footer of
fourteen pages.

## The files

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
