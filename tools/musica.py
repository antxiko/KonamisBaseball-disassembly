#!/usr/bin/env python3
"""La musica del cartucho, ejecutando su motor de sonido (ver motor_musica.py).

Pide el sonido con `pide_un_sonido` (0x6C0E, A = numero; no suena con el piloto
automatico puesto) y corre `mueve_el_sonido` (0x6CAE), que la interrupcion llama
cada cuadro. Tres fichas de 11 bytes desde 0xE661; la copia del registro 7 del
PSG, en 0xE660.
Uso:  musica.py registros 0x95 [cuadros] | mp3 0x95 f.mp3 | todas docs/audio
      musica.py barrido 0x80 0xBF | emu
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402
from motor_musica import P  # noqa: E402

TABLA = "ninguna llamada directa: está en la tabla de pistas"

PIEZAS = [
    P(0x95, "La melodía de entrada", "The entrance melody",
      "la rutina de 0x4254, al presentar el partido"),
    P(0x93, "El final del partido", "The end of the match",
      "la rutina de 0x429E"),
    P(0x8E, "El aviso de la entrada", "The entrance warning",
      "`acaba_la_entrada`"),
    P(0x8D, "Una pista de la tabla", "A track in the table", TABLA),
    P(0x8C, "Otra pista de la tabla", "Another track in the table", TABLA),
    P(0x8F, "Una tercera pista de la tabla", "A third track in the table",
      TABLA),
    P(0x90, "Una cuarta pista de la tabla", "A fourth track in the table",
      TABLA),
    P(0x91, "Una quinta pista de la tabla", "A fifth track in the table",
      TABLA),
    P(0x92, "Una sexta pista de la tabla", "A sixth track in the table",
      TABLA),
    P(0x94, "Una séptima pista de la tabla", "A seventh track in the table",
      TABLA),
    P(0x96, "Una octava pista de la tabla", "An eighth track in the table",
      TABLA),
]

PAGINA = motor_musica.pagina_basica(
    "`mueve_el_sonido`, 0x6CAE, y `pide_un_sonido`, 0x6C0E, que le reparte "
    "los canales; lo llama la interrupción",
    "`mueve_el_sonido`, 0x6CAE, and `pide_un_sonido`, 0x6C0E, which hands it "
    "the channels; the interrupt calls it",
    "C-BIOS MSX1 japonés",
    [("la melodía de entrada (0x95) entera, 368 cuadros",
      "the entrance melody (0x95), whole, 368 frames"),
     ("el aviso de la entrada (0x8E) entero, 578 cuadros",
      "the entrance warning (0x8E), whole, 578 frames")],
    [("Cómo se pide una pieza",
      "`pide_un_sonido` recibe el número en A y no suena con el piloto "
      "automático puesto (0xE002). Los números bajos son efectos y del 0x86 "
      "en adelante hay música. Cada ficha ocupa once bytes desde 0xE661 y "
      "0xE660 guarda la copia del mezclador del PSG, que el arranque deja "
      "en 0xB8. Las pistas «de la tabla» están en la tabla de pistas pero "
      "ninguna rutina las pide con un `ld a`.",
      "How a piece is asked for",
      "`pide_un_sonido` takes the number in A and makes no sound with the "
      "autopilot on (0xE002). Low numbers are effects and from 0x86 up there "
      "is music. Each record takes eleven bytes from 0xE661 and 0xE660 holds "
      "the copy of the PSG mixer, which start-up leaves at 0xB8. The tracks "
      "marked «in the table» are in the track table but no routine asks for "
      "them with an `ld a`.")])

CFG = dict(rom="baseball.rom", org=0x4000, frame=0x6CAE, pide=0x6C0E,
           ram=(0xE660, 0xE684), ram0=[(0xE660, 0xB8)],
           excluye=[0xE66A, 0xE675, 0xE680], hz=60, psg0={7: 0xB8},
           piezas=PIEZAS, pagina=PAGINA,
           cotejado=[(0x95, 368, None), (0x8E, 578, 1)])

if __name__ == "__main__":
    sys.exit(motor_musica.main(CFG, sys.argv[1:]))
