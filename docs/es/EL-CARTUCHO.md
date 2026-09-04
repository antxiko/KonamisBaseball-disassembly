# El cartucho

16.384 bytes en la página 1, de 0x4000 a 0x7FFF. Todos asignados:

```
código trazado      9.618 bytes    58,70 %
datos declarados    6.766 bytes    41,30 %
sin explicar                0 bytes     0,00 %
```

## La cabecera

Los diez primeros bytes son `41 42 61 40 00 00 00 00 00 00`: la marca **AB** y
la dirección de **INIT**, 0x4061. STATEMENT, DEVICE y TEXT a cero, y seis bytes
de relleno hasta el manejador de interrupción de 0x4010.

## El arranque

INIT no usa la BIOS para enganchar la interrupción: pone un `0xC3` -un `jp`- en
**H.KEYI** (0xFD9A) y la dirección 0x4010 detrás, borra 0xE000-0xE7FE con un
`ldir` y deja la pila ahí. **Todo el juego corre dentro de la interrupción.**

Es el mismo patrón que King's Valley, y no es la única coincidencia.

## El mismo armazón que King's Valley

Este cartucho es de 1984 y King's Valley de 1985, y comparten cosas que no son
casualidad:

**La tabla de registros del VDP es idéntica salvo un byte:**

```
Baseball        02 E2 0E 7F 07 76 03 E1   (0x46cc)
King's Valley   02 E2 0E 7F 07 76 03 E4   (0x45c0)
```

Sólo cambia R7, el color de borde. O sea, la **misma geometría de VRAM**,
incluida la rareza que se explica en la página de hallazgos: colores en 0x0000
y patrones en 0x2000, al revés de lo habitual.

**El mismo lenguaje de guiones**, con dos diferencias reales:

- Baseball tiene un comando **de más**, el `0x01`: el nibble bajo del byte
  siguiente dice cuántos bytes ocupa un tramo y el alto cuántas veces se
  repite. King's Valley no lo tiene.
- Al encadenar (`0x80`), Baseball lee la dirección con el byte **alto primero**
  (`ld d,(hl)` antes que `ld e,(hl)`, en 0x4589); King's Valley con el bajo
  primero. Leer uno con el orden del otro da ruido.

Que el cartucho **viejo** tenga el comando de más y el nuevo no, encaja con que
King's Valley sea una simplificación, no al revés. **SUPOSICIÓN**: no se ha
comprobado con más cartuchos de la familia.

**Diferencia propia de Baseball**: la interrupción lleva **dos candados**
(0xE01E y 0xE01F), y `arma_escritura_vram` (0x4689) **repite la operación
entera** si la interrupción se cuela entre medias -mira 0xE01D-. King's Valley
no necesita eso. Es el mecanismo que le deja escribir VRAM con la interrupción
suelta.

## La geometría de la VRAM

```
COLOR     0x0000    (R3 = 0x7F)
PATRÓN    0x2000    (R4 = 0x07)
NOMBRE    0x3800    (R2 = 0x0E)
SPRITES   0x1800    (R6 = 0x03), atributos en 0x3B00 (R5 = 0x76)
```

En SCREEN 2 el TMS9918 no lee R3 y R4 como una dirección, sino como un bit de
base y una máscara. Leerlo del otro modo tiene un síntoma que engaña: las
formas se siguen reconociendo -los dos bloques son simétricos- pero los colores
salen a franjas.

## El interprete de guiones

Todo lo que el cartucho dibuja está guardado como **guiones**: tiras de órdenes
que 0x458d va ejecutando contra el puerto de datos del VDP.

```
0x01 nb       n = nibble alto, b = nibble bajo. Copia n veces el mismo tramo
              de b bytes, sin gastarlo, y al final salta esos b bytes
0x00          fin del guion
0x80          encadena: los dos bytes siguientes son una dirección de VRAM
              nueva, BYTE ALTO PRIMERO
n (bit 7 a 0) relleno: el byte siguiente, repetido n veces
n (bit 7 a 1) copia cruda de (n and 0x7F) bytes
```

`tools/guiones.py` reproduce este intérprete en Python, y es de donde salen
todas las imágenes de esta web.

## Los bloques de datos

Están todos separados por uso, cada uno con su nombre y su anchura declarada.
Los grandes:

| Dónde | Qué |
|---|---|
| 0x46d4-0x4765 | los guiones de la pantalla de título y de la elección |
| 0x4765-0x477f | las tablas del cursor del menú |
| 0x477f-0x47c9 | los tres guiones del marcador |
| 0x47cf-0x4af0 | el guion largo del arranque y sus reentradas |
| 0x4af0-0x4b53 | **un guion que no dibuja nadie** |
| 0x5048-0x5a32 | las posturas de los jugadores, tres capas cada una |
| 0x5bd9-0x5c03 | los dos registros de arranque, 21 bytes cada uno |
| 0x5c03-0x5d3b | las quince fichas de los jugadores de campo |
| 0x65ad-0x6c0e | los guiones del estadio |
| 0x6e84-0x7080 | las notas, los punteros de sonido y sus guiones |
| 0x7c20-0x7c7a | los siete carteles y sus textos |
| 0x7ff6-0x8000 | la marca oculta de Konami |

## La marca oculta

En 0x7FF6, cerrando el cartucho: **RC-724** y el título en katakana, **YA KI
U**, que es 野球 (*yakyū*), béisbol. Konami escondía esto al final de muchos de
sus cartuchos; lo descubrió **Manuel Pazos**
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)).
