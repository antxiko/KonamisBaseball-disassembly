# Konami's Baseball — desensamblado comentado

Desensamblado completo y comentado de **Konami's Baseball** (Konami, 1984), el
cartucho **RC-724** de 16 KB para MSX1.

📖 **[Leer la web](https://antxiko.github.io/KonamisBaseball-disassembly/es/)** ·
🇬🇧 [In English](README.md)

```
100,00 %  del binario explicado            0  bytes sin identificar
   9.618  bytes de código trazado        629  rutinas con nombre
   6.766  bytes de datos declarados    44,5 %  del listado comentado
```

Reensamblar el listado devuelve la ROM **byte a byte**:
`06504efb72d1cd3351dae8eb1f7b073f69d599fa7018663937f85535658ad3e7`.

## La ROM no está aquí

Este repositorio no distribuye la imagen del cartucho. Pon la tuya en la raíz
con el nombre `baseball.rom` y compruébala con:

```sh
shasum -a 256 baseball.rom
```

## Compilarlo

```sh
make            # listado + verify + sanity + tests
make verify     # reensambla y compara con la ROM, byte a byte
make sanity     # las cuatro comprobaciones que el reensamblado no cubre
make densidad   # cuánto del listado está comentado
make web        # la web bilingüe de docs/
```

## Lo que apareció

- **La dirección del guion va escrita detrás del propio CALL.** 0x4582 hace
  `ex (sp),hl`, lee los dos bytes que siguen al call, y adelanta el retorno para
  que no se ejecuten. Hay nueve sitios que llaman así — y un desensamblador que
  no lo sepa toma dieciocho bytes de datos por instrucciones y aun así
  reensambla perfecto.
- **Los doce equipos de la liga japonesa, en doce letras.** La parrilla sólo
  enseña iniciales: `C D G S T W` para la Central y `B Bu F H L O` para la
  Pacific — los doce equipos de la NPB de 1984. El tile 0xE8 es una **"Bu" en un
  solo carácter**, hecha para que los Buffaloes no se confundan con los Braves.
- **La máquina juega escribiendo en el hueco del mando.** No hay una vía aparte
  para el rival: deja sus órdenes en 0xE011, que es el mismo byte donde viven
  los bits recién pulsados del segundo jugador. Lo mismo con la demostración del
  menú — y como el motor de sonido se niega a sonar mientras la demostración
  está en marcha, la partida automática es muda.
- **Los tres tercios de la pantalla, pintados con un bucle que se lee a sí
  mismo**: 4.095 bytes copiados de la VRAM 0x0000 a 0x0800, solapándose a
  propósito. Se queda un byte corto del tercer tercio, y siempre lo estuvo.
- **El byte que cierra un guion es el primer byte del sprite siguiente.** En 21
  de las 22 posturas, el puntero a los desplazamientos cae sobre el propio 0x00
  que cierra el guion.
- **Un guion que no dibuja nadie**: 99 bytes válidos en 0x4AF0 que cargan ocho
  patrones de sprite, con cuatro comprobaciones distintas dando negativo sobre
  quién lo lee.
- **Lleva la marca oculta de Konami** (descubierta por
  [Manuel Pazos](https://twitter.com/ManuelPazosMSX)): `RC-724` y `YA KI U` —
  野球, *yakyū*, béisbol.

Todo el detalle en la web, en
[Hallazgos](https://antxiko.github.io/KonamisBaseball-disassembly/es/HALLAZGOS.html).

## Todas las imágenes están dibujadas desde la ROM

Ni una captura de emulador. `tools/pantallas.py` ejecuta en Python el propio
intérprete de guiones del cartucho sobre una VRAM de 16 KB y luego la revela
como SCREEN 2 — la pantalla de título, las parrillas de liga y de equipos, el
estadio, y las 22 posturas de los jugadores con sus tres capas de color.

## Los ficheros

```
src/baseball.notes     lo entendido: nombres, comentarios, bloques de datos
src/baseball.entries   los puntos de entrada que el trazado no puede deducir
src/baseball.nocode    zonas que el trazador no debe leer como código
src/baseball.asm       GENERADO — nunca se edita a mano
tools/                 trazador, listado, comprobaciones, dibujos, openMSX
docs/                  la web bilingüe
```

## Licencia

El análisis, los comentarios y las herramientas están bajo [licencia
MIT](LICENSE). El juego no: ver el [aviso legal](AVISO-LEGAL.md).
