# El código

629 rutinas con nombre, 5.301 instrucciones, 2.357 comentarios de línea:
**44,5 % del listado comentado**, y **ninguna rutina por debajo del 10 %**.

## Por dónde empieza todo

```
0x4061  INIT           engancha la interrupción y borra la RAM
0x4010  interrupción   TODO el juego corre aquí dentro
0x411e  bucle_principal  el logotipo de Konami subiendo por la pantalla
```

La interrupción se protege con dos candados, lleva el contador de fotogramas de
0xE000, y al final vuelve a leer el estado del VDP: si hay otra interrupción
pendiente, **se re-ejecuta a sí misma** en vez de volver.

## El reparto del cuadro

0x7bb0 parte el trabajo en dos mitades que se turnan cuadro a cuadro, mirando
el bit 0 del contador de fotogramas:

| Cuadros pares | Cuadros impares |
|---|---|
| la pelota bateada (0x620a) | la defensa (0x7373) |
| el lanzamiento (0x4ccc) | el bateador (0x7080) |
| los corredores (0x5e80) | la recogida (0x7692) |
| | la máquina (0x7d04) |

## Las fichas

Casi todo lo que se mueve se describe con una **ficha** a la que se apunta con
IX. Los huecos que usa el motor de movimiento de 0x4b53:

```
+0x00  banderas: bit 0 en marcha, bit 6 "se ha movido este cuadro"
+0x01  acumulador de subpíxel, 16 bits
+0x03  el paso que se le suma cada cuadro, 16 bits
+0x07  X en píxeles          +0x08  Y en píxeles
+0x0c  X mínima  +0x0d  X máxima  +0x0e  Y mínima  +0x0f  Y máxima
+0x10  banderas de dirección: bit 7 el eje que manda, bits 6 y 5 los signos
+0x11  lo que le queda por recorrer en X
+0x12  lo que le queda por recorrer en Y
```

El truco del subpíxel es el mismo de King's Valley: la posición fina va en 16
bits, cada cuadro se le suma el paso, y el **byte alto** del acumulador es
cuántos píxeles enteros toca mover; se gasta y se pone a cero, y el resto se
queda para el cuadro siguiente.

## Dónde vive el estado

| Dirección | Qué |
|---|---|
| 0xE000 | el contador de fotogramas, que sube la interrupción |
| 0xE001 | el contador lento, que baja cada 32 cuadros |
| 0xE002 | manda el piloto automático de la demostración |
| 0xE00C..0xE011 | los dos mandos: lectura, lectura anterior y flancos |
| 0xE100 | el estado del lanzador |
| 0xE140 | el del bateador |
| 0xE180..0xE1FF | las cuatro bases, 32 bytes cada una |
| 0xE220..0xE33F | los nueve jugadores de campo |
| 0xE340 | la pelota lanzada entre bases |
| 0xE360..0xE36E | el medidor del lanzamiento y su barra |
| 0xE380 | la palabra de la carrera |
| 0xE388 | la palabra de la defensa |
| 0xE400 | el estado de la jugada |
| 0xE408..0xE40E | strikes, bolas, eliminados, entrada, carreras |
| 0xE440..0xE446 | liga, equipos y las dos semillas de azar |
| 0xE660..0xE686 | el motor de sonido, tres canales de once bytes |

## La calculadora

Todo el vuelo de la pelota bateada se calcula en cuatro bytes de RAM, de 0xE060
a 0xE063, con dos rutinas que son una multiplicación y una división hechas a
mano:

- **0x6539**, multiplicar: dieciséis vueltas de desplazar 24 bits y sumar.
- **0x6519**, dividir: ocho vueltas de desplazar y restar.

Y aparte hay otra división más pequeña, la de 0x4cb0, que trabaja sobre 0xE700
y sirve para calcular la pendiente de una trayectoria: se llama **dos veces**
seguidas (0x4ca1) para sacar dos decimales.

## Cómo se dibuja un jugador

Un jugador son **tres sprites de 16x16 superpuestos**, uno por color, y el
cartucho **no guarda todas las posturas en VRAM**: cada vez que la postura
cambia sube los tres patrones enteros -32 bytes cada uno- desde la ROM,
descomprimiéndolos con el mismo intérprete que dibuja las pantallas.

La tabla de 0x5048 lleva un puntero por postura, y cada uno apunta a un
registro de **cuatro palabras**: los tres guiones -una capa cada uno- y un
puntero a seis bytes de desplazamiento, una pareja (fila, columna) con signo
por capa.

Los jugadores de campo son más baratos: **una sola capa** y un sprite, y ahí la
tabla de 0x5048 se usa de otra manera -lo que devuelve es el guion
directamente, no un registro de cuatro palabras.

## El motor de sonido

Tres canales, once bytes de estado cada uno, empezando en 0xE661. La entrada es
0x6c0e, que recibe el número de sonido en A y **se niega a sonar** si 0xE002
dice que manda la demostración.

El reparto de 0x6c20 decide en cuántos canales cabe el sonido y se lo queda
sólo si su número es **mayor** que el que ya estaba sonando: los seis bits bajos
del número hacen de prioridad.

El guion de un sonido, tal como lo lee 0x6ced:

```
0xFF  fin: el canal se calla
0xFE  vuelta al principio, contando las que lleva
0x2n  cambia la duración de las notas a n
0x1n  ruido: n va al registro 6 del PSG
resto una nota, con su duración en el nibble alto
```

Y hay un segundo camino, el del bit 7 del modo, con hasta tres prefijos delante
de la nota: `0xDn` la unidad de duración, `0xFn` la caída del volumen y `0xEn`
la octava, que se consigue **doblando** la frecuencia tantas veces como diga.

## Las herramientas

```
tools/z80trace.py    el trazado de flujo, con la directiva !skip
tools/mkasm.py       el listado, desde el trazado y las notas
tools/guiones.py     el intérprete de guiones, rehecho en Python
tools/pantallas.py   las pantallas y las posturas, dibujadas desde la ROM
tools/densidad.py    cuánto del listado está comentado, rutina a rutina
tools/presupuesto.py que no quede un byte sin asignar
```

## Código compartido con otros cartuchos de Konami

Este desensamblado se ha comparado, instrucción por instrucción, con
todos los demás de Konami de la serie. Cuenta un bloque cuando las
mismas instrucciones, al menos seis desde una etiqueta hasta su `ret`
o su salto sin condición, están en los dos cartuchos; las direcciones
no se miran, porque cambian de un cartucho a otro. De los otros 57,
**31** tienen al menos un bloque en común con este; estos son los
que más comparten:

| Cartucho | Bloques | Instrucciones | Por ejemplo (aquí = allí) |
|---|---:|---:|---|
| [Konami's Golf](https://antxiko.github.io/KonamisGolf-disassembly/es/) | 34 | 552 | `lee_una_nota_larga` (0x6D9F) = `corre_el_canal_nota_larga` |
| [Konami's Tennis](https://antxiko.github.io/KonamisTennis-disassembly/es/) | 32 | 518 | `lee_una_nota_larga` (0x6D9F) = `manda_de_la_melodia` |
| [Hyper Olympic 1](https://antxiko.github.io/HyperOlympic1-disassembly/es/) | 19 | 218 | `replica_el_tercio_en_los_otros_dos` (0x4485) = `COPIA_VRAM_A_VRAM` |
| [Hyper Olympic 2](https://antxiko.github.io/HyperOlympic2-disassembly/es/) | 18 | 209 | `replica_el_tercio_en_los_otros_dos` (0x4485) = `COPIA_VRAM_A_VRAM` |
| [Hyper Sports 1](https://antxiko.github.io/HyperSports1-disassembly/es/) | 5 | 58 | `cierra_el_bucle_del_guion` (0x6C6D) = `SUMA_BONUS_7BFC` |
| [Magical Tree](https://antxiko.github.io/MagicalTree-disassembly/es/) | 5 | 65 | `toca_una_nota` (0x6D3F) = `lee_la_nota_de_la_partitura` |
| [Konami's Ping Pong](https://antxiko.github.io/KonamisPingPong-disassembly/es/) | 5 | 49 | `abre_o_cierra_el_canal` (0x6C88) = `pon_el_mezclador` |

La matriz entera, los 58 cartuchos entre sí, está en
[Las rutinas](https://antxiko.github.io/MSX-disassembly-database/es/LAS-RUTINAS.html) de la base de datos de la
serie, con el método y el programa que la mide.
