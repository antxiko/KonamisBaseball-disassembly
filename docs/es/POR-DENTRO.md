# Por dentro

## Empezar

Este repositorio contiene el desensamblado comentado de **Konami's Baseball**
(Konami, 1984), el cartucho **RC-724** de 16 KB para MSX1.

La ROM **no se distribuye aquí**. Hace falta ponerla en la raíz del repositorio
con el nombre `baseball.rom`. Para comprobar que es la misma:

```
shasum -a 256 baseball.rom
06504efb72d1cd3351dae8eb1f7b073f69d599fa7018663937f85535658ad3e7
```

### Lo que hace `make`

```
make listado    genera src/baseball.asm desde el trazado y las notas
make verify     reensambla el listado y compara con la ROM, byte a byte
make sanity     las cuatro comprobaciones que el reensamblado NO cubre
make densidad   cuenta cuánto del listado está comentado
make imagenes   dibuja los bloques gráficos declarados, para mirarlos
make web        genera la web bilingüe de docs/
```

`make` a secas hace `listado`, `verify`, `sanity` y `test`.

### Por qué `verify` es la prueba que importa

Un desensamblado se puede escribir de muchas maneras, y casi todas están mal de
alguna forma que no se nota. La única prueba que no admite discusión es
reensamblar el listado y comprobar que sale **exactamente la misma ROM**: los
16.384 bytes, en el mismo orden, con el mismo sha256.

Eso es lo que hace `make verify`, y se ha ejecutado después de cada tanda de
trabajo. Si alguna vez falla, el listado está mal, por bonito que se lea.

### Lo que NO cubre el reensamblado

Que los bytes salgan iguales no dice nada sobre si los hemos **entendido**. Un
bloque de datos leído como si fuera código produce el mismo binario y una
mentira en el listado. Este cartucho tiene un ejemplo perfecto: las direcciones
que van escritas **detrás** de cada `call 0x4582`. El desensamblador las tomaba
por instrucciones, el binario salía idéntico, y el listado mentía en nueve
sitios.

Por eso `make sanity` corre cuatro comprobaciones aparte:

- **`check_trace.py`**: ninguna zona declarada como datos en el `.nocode` puede
  haber salido trazada como código.
- **`check_datos_como_codigo.py`**: ningún bloque de datos del `.notes` puede
  solaparse con código trazado.
- **`check_entradas.py`**: ningún punto de entrada declarado a mano puede caer
  dentro de una zona de datos, y **cada uno tiene que llevar su razón escrita
  al lado**.
- **`presupuesto.py`**: los 16.384 bytes tienen que estar asignados. Ahora
  mismo: 9.618 de código, 6.766 de datos, **cero sin explicar**.

### Y los tests

`make test` corre doce comprobaciones más sobre el propio listado: que no
desaparezcan comentarios, que ninguna rutina baje del 10 % de densidad, que las
cifras publicadas en esta web sean las del árbol y no las que había cuando se
escribió el texto, y que no se cuele el nombre de otro juego de la serie -que
ya ha pasado, con cinco ficheros LICENSE y con el pie de catorce páginas.

### Los ficheros

```
baseball.rom          la ROM (NO está aquí)
src/baseball.entries  los puntos de entrada, cada uno con su justificación
src/baseball.notes    TODO lo entendido: nombres, comentarios, bloques de datos
src/baseball.nocode   zonas declaradas como datos antes de trazar (vacío aquí)
src/baseball.asm      el listado, GENERADO; no se edita a mano
tools/                el desensamblador, los comprobadores y la web
```

El fichero que importa es **`src/baseball.notes`**. El `.asm` se regenera
entero cada vez; lo que se escribe a mano son las notas, y están ancladas a
direcciones, de modo que sobreviven a un retrazado.

## El cartucho

16.384 bytes en la página 1, de 0x4000 a 0x7FFF. Todos asignados:

```
código trazado      9.618 bytes    58,70 %
datos declarados    6.766 bytes    41,30 %
sin explicar                0 bytes     0,00 %
```

### La cabecera

Los diez primeros bytes son `41 42 61 40 00 00 00 00 00 00`: la marca **AB** y
la dirección de **INIT**, 0x4061. STATEMENT, DEVICE y TEXT a cero, y seis bytes
de relleno hasta el manejador de interrupción de 0x4010.

### El arranque

INIT no usa la BIOS para enganchar la interrupción: pone un `0xC3` -un `jp`- en
**H.KEYI** (0xFD9A) y la dirección 0x4010 detrás, borra 0xE000-0xE7FE con un
`ldir` y deja la pila ahí. **Todo el juego corre dentro de la interrupción.**

Es el mismo patrón que King's Valley, y no es la única coincidencia.

### El mismo armazón que King's Valley

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

### La geometría de la VRAM

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

### El interprete de guiones

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

### Los bloques de datos

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

### La marca oculta

En 0x7FF6, cerrando el cartucho: **RC-724** y el título en katakana, **YA KI
U**, que es 野球 (*yakyū*), béisbol. Konami escondía esto al final de muchos de
sus cartuchos; lo descubrió **Manuel Pazos**
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)).

## El código

629 rutinas con nombre, 5.301 instrucciones, 2.357 comentarios de línea:
**44,5 % del listado comentado**, y **ninguna rutina por debajo del 10 %**.

### Por dónde empieza todo

```
0x4061  INIT           engancha la interrupción y borra la RAM
0x4010  interrupción   TODO el juego corre aquí dentro
0x411e  bucle_principal  el logotipo de Konami subiendo por la pantalla
```

La interrupción se protege con dos candados, lleva el contador de fotogramas de
0xE000, y al final vuelve a leer el estado del VDP: si hay otra interrupción
pendiente, **se re-ejecuta a sí misma** en vez de volver.

### El reparto del cuadro

0x7bb0 parte el trabajo en dos mitades que se turnan cuadro a cuadro, mirando
el bit 0 del contador de fotogramas:

| Cuadros pares | Cuadros impares |
|---|---|
| la pelota bateada (0x620a) | la defensa (0x7373) |
| el lanzamiento (0x4ccc) | el bateador (0x7080) |
| los corredores (0x5e80) | la recogida (0x7692) |
| | la máquina (0x7d04) |

### Las fichas

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

### Dónde vive el estado

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

### La calculadora

Todo el vuelo de la pelota bateada se calcula en cuatro bytes de RAM, de 0xE060
a 0xE063, con dos rutinas que son una multiplicación y una división hechas a
mano:

- **0x6539**, multiplicar: dieciséis vueltas de desplazar 24 bits y sumar.
- **0x6519**, dividir: ocho vueltas de desplazar y restar.

Y aparte hay otra división más pequeña, la de 0x4cb0, que trabaja sobre 0xE700
y sirve para calcular la pendiente de una trayectoria: se llama **dos veces**
seguidas (0x4ca1) para sacar dos decimales.

### Cómo se dibuja un jugador

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

### El motor de sonido

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

### Las herramientas

```
tools/z80trace.py    el trazado de flujo, con la directiva !skip
tools/mkasm.py       el listado, desde el trazado y las notas
tools/guiones.py     el intérprete de guiones, rehecho en Python
tools/pantallas.py   las pantallas y las posturas, dibujadas desde la ROM
tools/densidad.py    cuánto del listado está comentado, rutina a rutina
tools/presupuesto.py que no quede un byte sin asignar
```

## En el emulador

### Qué se ha comprobado y qué no

Hay que decirlo claro antes de nada: **las imágenes de esta web no se han
comparado byte a byte contra la VRAM de openMSX**. Se han mirado, y lo que se
ve encaja con lo que dice el código -el estadio con su marcador, el rótulo, las
dos ligas, las veintidós posturas-, pero eso no es lo mismo que una comparación.

Lo que sí está comprobado es que **el listado reproduce la ROM byte a byte**
(`make verify`) y que **no queda un byte del cartucho sin asignar** (`make
sanity`). Esas dos cosas se han corrido después de cada tanda de trabajo.

### Cómo se dibujan las imágenes

No hay ninguna captura. `tools/pantallas.py` ejecuta en Python el mismo
intérprete de guiones que corre el Z80, sobre una VRAM de 16 KB en memoria, y
luego la revela como SCREEN 2:

```
python3 tools/pantallas.py baseball.rom 0x4000 docs/imagenes
```

Cada escena reproduce la secuencia del cartucho, en el mismo orden:

```
LA PORTADA, como la monta 0x40cc:
    0x40d1  guion 0x47cf ......... patrones y colores
    0x40e2  guion 0x4a96
    0x40d6  guion 0x4a27 en VRAM 0x6680
    0x40e7  guion 0x49d4 en VRAM 0x6780
    0x40f9  réplica de VRAM 0x0000 -> 0x0800 (4095 bytes) ..... colores
    0x4102  réplica de VRAM 0x2000 -> 0x2800 (4095 bytes) .... patrones

EL CAMPO, como lo monta 0x4219:
    0x421e  borrado de la tabla de nombres
    0x4226  guion 0x65ad ............ patrones y colores del estadio
    0x4231  réplica de VRAM 0x0000 -> 0x0800
    0x423a  réplica de VRAM 0x2000 -> 0x2800
    0x4243  guion 0x6a1c .................... la tabla de nombres
```

Si el dibujo sale bien es porque el intérprete es correcto, no porque se haya
mirado una foto. Y cuando el intérprete estaba mal, se notó: las primeras
pasadas de las posturas de los jugadores salían **ruido**, y ahí fue donde se
descubrió que lo que se estaba leyendo como filas de tiles eran en realidad
**patrones de sprite**.

### Dos comentarios que mentían, cazados al dibujar

Dibujar las cosas destapa errores que leer el código no caza. En este cartucho
salieron dos:

- 0x44b7 estaba comentado como "las dos filas de casillas numeradas del
  marcador". No lo es: es **el rótulo del juego**, 46 tiles correlativos del
  0x40 al 0x6D en dos filas de 23. Se vio en cuanto se dibujó la pantalla del
  menú y apareció "Konami's Baseball".
- La segunda pantalla estaba comentada como "la pantalla de equipos". No lo es:
  es la de **ligas**, CENTRAL y PACIFIC, y la de equipos viene después.

### Poner el cartucho a correr

```
openmsx -machine Philips_NMS_8250 -carta baseball.rom
```

Para volcar la VRAM y comparar de verdad hace falta un guion de emulador, y
**este repositorio no lo trae**. La comparación queda **pendiente**, y está
anotada como tal en la página de preguntas abiertas; los sitios buenos donde
parar son los de aquí abajo.

### Lo que hay que saber antes de medir

- **La interrupción lo es todo.** Si se para el emulador dentro del manejador
  de 0x4010, la mitad del estado está a medio escribir. Los sitios buenos para
  parar son los bucles de espera: 0x4260, 0x4266, 0x42ec.
- **Los buffers se reutilizan varias veces por cuadro.** 0xE700 es un hueco de
  trabajo que usan al menos cuatro rutinas distintas; leerlo fuera del instante
  justo no dice nada.
- **El azar es el registro R.** El cartucho lo usa de dado en cinco sitios
  (0x4219, 0x4d69, 0x714b, 0x7196, 0x7d66), así que dos partidas idénticas no
  existen ni parando el emulador en el mismo sitio.

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
