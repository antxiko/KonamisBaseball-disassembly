# Empezar

Este repositorio contiene el desensamblado comentado de **Konami's Baseball**
(Konami, 1984), el cartucho **RC-724** de 16 KB para MSX1.

La ROM **no se distribuye aquí**. Hace falta ponerla en la raíz del repositorio
con el nombre `baseball.rom`. Para comprobar que es la misma:

```
shasum -a 256 baseball.rom
06504efb72d1cd3351dae8eb1f7b073f69d599fa7018663937f85535658ad3e7
```

## Lo que hace `make`

```
make listado    genera src/baseball.asm desde el trazado y las notas
make verify     reensambla el listado y compara con la ROM, byte a byte
make sanity     las cuatro comprobaciones que el reensamblado NO cubre
make densidad   cuenta cuánto del listado está comentado
make imagenes   dibuja los bloques gráficos declarados, para mirarlos
make web        genera la web bilingüe de docs/
```

`make` a secas hace `listado`, `verify`, `sanity` y `test`.

## Por qué `verify` es la prueba que importa

Un desensamblado se puede escribir de muchas maneras, y casi todas están mal de
alguna forma que no se nota. La única prueba que no admite discusión es
reensamblar el listado y comprobar que sale **exactamente la misma ROM**: los
16.384 bytes, en el mismo orden, con el mismo sha256.

Eso es lo que hace `make verify`, y se ha ejecutado después de cada tanda de
trabajo. Si alguna vez falla, el listado está mal, por bonito que se lea.

## Lo que NO cubre el reensamblado

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

## Y los tests

`make test` corre doce comprobaciones más sobre el propio listado: que no
desaparezcan comentarios, que ninguna rutina baje del 10 % de densidad, que las
cifras publicadas en esta web sean las del árbol y no las que había cuando se
escribió el texto, y que no se cuele el nombre de otro juego de la serie -que
ya ha pasado, con cinco ficheros LICENSE y con el pie de catorce páginas.

## Los ficheros

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
