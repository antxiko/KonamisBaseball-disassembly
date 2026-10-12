# The music

Everything you hear here comes from running the cartridge's own sound engine (`mueve_el_sonido`, 0x6CAE, and `pide_un_sonido`, 0x6C0E, which hands it the channels; the interrupt calls it) on an emulated Z80, frame by frame at 60 per second, just as the game calls it. What the engine writes to the PSG is turned into sound with an AY-3-8910 (`tools/musica.py`). Each MP3 is the whole piece up to where it starts again, plus 8 seconds of the repeat fading out; those that do not repeat end where the engine ends.

## Checked against openMSX

The PSG writes have been compared frame by frame with those of openMSX (C-BIOS MSX1 japonés). In every frame the PSG ends up the same:

- the entrance melody (0x95), whole, 368 frames;
- the entrance warning (0x8E), whole, 578 frames.

The timbre is not checked: it is a textbook AY-3-8910, not a recording of the emulator. The probes are `tools/omsx_psg.tcl` and `tools/coteja_psg.py`.

## How a piece is asked for

`pide_un_sonido` takes the number in A and makes no sound with the autopilot on (0xE002). Low numbers are effects and from 0x86 up there is music. Each record takes eleven bytes from 0xE661 and 0xE660 holds the copy of the PSG mixer, which start-up leaves at 0xB8. The tracks marked «in the table» are in the track table but no routine asks for them with an `ld a`.

## The tunes

**The entrance melody** (0x95)

Asked for by la rutina de 0x4254, al presentar el partido; lasts 6.1 s.

<audio controls preload="none" src="audio/musica_95.mp3?v=a4d5bb8c"></audio>

**The end of the match** (0x93)

Asked for by la rutina de 0x429E; lasts 5.0 s.

<audio controls preload="none" src="audio/musica_93.mp3?v=b765405d"></audio>

**The entrance warning** (0x8E)

Asked for by `acaba_la_entrada`; lasts 9.6 s and starts again at second 0.0.

<audio controls preload="none" src="audio/musica_8E.mp3?v=86d20ef3"></audio>

**A track in the table** (0x8D)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 4.8 s and starts again at second 0.0.

<audio controls preload="none" src="audio/musica_8D.mp3?v=2e3b6e49"></audio>

**Another track in the table** (0x8C)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 3.4 s.

<audio controls preload="none" src="audio/musica_8C.mp3?v=1d95cb2f"></audio>

**A third track in the table** (0x8F)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.3 s and starts again at second 1.5.

<audio controls preload="none" src="audio/musica_8F.mp3?v=d3bb305d"></audio>

**A fourth track in the table** (0x90)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 1.5 s.

<audio controls preload="none" src="audio/musica_90.mp3?v=96171765"></audio>

**A fifth track in the table** (0x91)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 1.5 s.

<audio controls preload="none" src="audio/musica_91.mp3?v=a9b5da67"></audio>

**A sixth track in the table** (0x92)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.0 s.

<audio controls preload="none" src="audio/musica_92.mp3?v=d79610cd"></audio>

**A seventh track in the table** (0x94)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.1 s.

<audio controls preload="none" src="audio/musica_94.mp3?v=fd9abadc"></audio>

**An eighth track in the table** (0x96)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.1 s.

<audio controls preload="none" src="audio/musica_96.mp3?v=ea367cff"></audio>
