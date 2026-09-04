# En el emulador

## Qué se ha comprobado y qué no

Hay que decirlo claro antes de nada: **las imágenes de esta web no se han
comparado byte a byte contra la VRAM de openMSX**. Se han mirado, y lo que se
ve encaja con lo que dice el código -el estadio con su marcador, el rótulo, las
dos ligas, las veintidós posturas-, pero eso no es lo mismo que una comparación.

Lo que sí está comprobado es que **el listado reproduce la ROM byte a byte**
(`make verify`) y que **no queda un byte del cartucho sin asignar** (`make
sanity`). Esas dos cosas se han corrido después de cada tanda de trabajo.

## Cómo se dibujan las imágenes

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

## Dos comentarios que mentían, cazados al dibujar

Dibujar las cosas destapa errores que leer el código no caza. En este cartucho
salieron dos:

- 0x44b7 estaba comentado como "las dos filas de casillas numeradas del
  marcador". No lo es: es **el rótulo del juego**, 46 tiles correlativos del
  0x40 al 0x6D en dos filas de 23. Se vio en cuanto se dibujó la pantalla del
  menú y apareció "Konami's Baseball".
- La segunda pantalla estaba comentada como "la pantalla de equipos". No lo es:
  es la de **ligas**, CENTRAL y PACIFIC, y la de equipos viene después.

## Poner el cartucho a correr

```
openmsx -machine Philips_NMS_8250 -carta baseball.rom
```

Para volcar la VRAM y comparar de verdad, `tools/omsx_vram.tcl` tiene los
puntos de parada preparados. La comparación queda **pendiente**, y está anotada
como tal en la página de preguntas abiertas.

## Lo que hay que saber antes de medir

- **La interrupción lo es todo.** Si se para el emulador dentro del manejador
  de 0x4010, la mitad del estado está a medio escribir. Los sitios buenos para
  parar son los bucles de espera: 0x4260, 0x4266, 0x42ec.
- **Los buffers se reutilizan varias veces por cuadro.** 0xE700 es un hueco de
  trabajo que usan al menos cuatro rutinas distintas; leerlo fuera del instante
  justo no dice nada.
- **El azar es el registro R.** El cartucho lo usa de dado en cinco sitios
  (0x4219, 0x4d69, 0x714b, 0x7196, 0x7d66), así que dos partidas idénticas no
  existen ni parando el emulador en el mismo sitio.
