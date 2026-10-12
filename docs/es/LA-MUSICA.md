# La música

Todo lo que suena aquí sale de ejecutar el motor de sonido del cartucho (`mueve_el_sonido`, 0x6CAE, y `pide_un_sonido`, 0x6C0E, que le reparte los canales; lo llama la interrupción) en un Z80 emulado, cuadro a cuadro y a 60 por segundo, igual que lo llama el juego. Lo que el motor escribe en el PSG pasa a sonido con un AY-3-8910 (`tools/musica.py`). Cada MP3 es la pieza entera hasta donde vuelve a empezar, más 8 segundos de la vuelta apagándose; las que no se repiten acaban donde acaba el motor.

## Cotejado con openMSX

Las escrituras al PSG se han comparado cuadro a cuadro con las de openMSX (C-BIOS MSX1 japonés). En todos los cuadros el PSG queda igual:

- la melodía de entrada (0x95) entera, 368 cuadros;
- el aviso de la entrada (0x8E) entero, 578 cuadros.

El timbre no está cotejado: es el de un AY-3-8910 de manual, no una grabación del emulador. Las sondas están en `tools/omsx_psg.tcl` y `tools/coteja_psg.py`.

## Cómo se pide una pieza

`pide_un_sonido` recibe el número en A y no suena con el piloto automático puesto (0xE002). Los números bajos son efectos y del 0x86 en adelante hay música. Cada ficha ocupa once bytes desde 0xE661 y 0xE660 guarda la copia del mezclador del PSG, que el arranque deja en 0xB8. Las pistas «de la tabla» están en la tabla de pistas pero ninguna rutina las pide con un `ld a`.

## Las músicas

**La melodía de entrada** (0x95)

Lo pide la rutina de 0x4254, al presentar el partido; dura 6,1 s.

<audio controls preload="none" src="../audio/musica_95.mp3?v=a4d5bb8c"></audio>

**El final del partido** (0x93)

Lo pide la rutina de 0x429E; dura 5,0 s.

<audio controls preload="none" src="../audio/musica_93.mp3?v=b765405d"></audio>

**El aviso de la entrada** (0x8E)

Lo pide `acaba_la_entrada`; dura 9,6 s y vuelve a empezar en el segundo 0,0.

<audio controls preload="none" src="../audio/musica_8E.mp3?v=86d20ef3"></audio>

**Una pista de la tabla** (0x8D)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 4,8 s y vuelve a empezar en el segundo 0,0.

<audio controls preload="none" src="../audio/musica_8D.mp3?v=2e3b6e49"></audio>

**Otra pista de la tabla** (0x8C)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 3,4 s.

<audio controls preload="none" src="../audio/musica_8C.mp3?v=1d95cb2f"></audio>

**Una tercera pista de la tabla** (0x8F)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,3 s y vuelve a empezar en el segundo 1,5.

<audio controls preload="none" src="../audio/musica_8F.mp3?v=d3bb305d"></audio>

**Una cuarta pista de la tabla** (0x90)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 1,5 s.

<audio controls preload="none" src="../audio/musica_90.mp3?v=96171765"></audio>

**Una quinta pista de la tabla** (0x91)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 1,5 s.

<audio controls preload="none" src="../audio/musica_91.mp3?v=a9b5da67"></audio>

**Una sexta pista de la tabla** (0x92)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,0 s.

<audio controls preload="none" src="../audio/musica_92.mp3?v=d79610cd"></audio>

**Una séptima pista de la tabla** (0x94)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,1 s.

<audio controls preload="none" src="../audio/musica_94.mp3?v=fd9abadc"></audio>

**Una octava pista de la tabla** (0x96)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,1 s.

<audio controls preload="none" src="../audio/musica_96.mp3?v=ea367cff"></audio>
