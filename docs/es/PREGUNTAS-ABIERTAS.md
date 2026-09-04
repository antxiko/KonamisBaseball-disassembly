# Preguntas abiertas

Lo que queda por cerrar. Está aquí escrito para que se vea, no para que se
olvide.

## Las imágenes no se han comparado contra la VRAM del emulador

Se han **mirado**, y encajan con lo que dice el código, pero mirarlas no es
compararlas. La comprobación de verdad es volcar la VRAM de openMSX en el
instante justo y compararla byte a byte con la que produce
`tools/pantallas.py`. Está pendiente.

## Nadie ha jugado un partido entero

El listado está entendido de arriba abajo y las cifras están medidas, pero
**no se ha llegado a jugar un partido completo de nueve entradas**. Hay dos
cosas que sólo se pueden cerrar así:

- Lo de la **prórroga por empate**. 0x7b7b, en la octava entrada, mira si los
  dos marcadores están empatados y escribe un 0xE7 en la casilla; el partido
  sigue. Que eso sea una prórroga es lo que dice el código, pero no se ha visto.
- El **cartel de "4 BALL"**. Está en la tabla, se lee con la fuente del
  cartucho, y 0x7afd lo saca a la cuarta bola. No se ha visto en pantalla.

## El guion de 0x4AF0 sigue sin lector

99 bytes que son un guion válido y que carga ocho patrones de sprite y cinco
atributos. Se han hecho cuatro comprobaciones -el guion anterior no encadena,
no hay ningún inmediato de 16 bits que apunte ahí, las dos tablas de punteros
apuntan a sus propios bloques, y los nueve argumentos incrustados no son éste-
y todas dan negativo.

Un negativo no es una demostración. Si alguien encuentra quién lo dibuja, se
corrige.

## Los tres bytes de la ficha número quince

Quince fichas de 21 bytes son 315 y la tabla tiene 312: los tres que faltan son
los tres primeros de la rutina que viene detrás. Que sea **ahorro a propósito**
o un **descuido que no se nota** porque esos huecos no se usan, no se puede
decidir mirando el binario. Haría falta ver si esos tres huecos se leen alguna
vez en una partida real.

## Qué son de verdad 0xE032, 0xE057 y 0xE650

Aparecen en el vuelo de la pelota bateada y en el motor de sonido, y se sabe
**cuándo** cambian y **quién** los mira, pero no se ha podido poner un nombre
que diga qué significan. En el listado están comentados por lo que hacen, no
por lo que son.

## La cola de sombras de 0xE245

0x5d62 corre en cadena cinco bytes que están a 0x20 de distancia dentro del
bloque de 0xE200. Que sea el rastro de lo que se mueve es lo que sugiere el
corrimiento en cadena, pero **no se ha medido**.

## El comando 0x01, ¿lo tienen más cartuchos de la familia?

Baseball (1984) tiene un comando de guion que King's Valley (1985) no tiene, y
encadena las direcciones al revés. La lectura fácil es que King's Valley
simplificó el intérprete. Para saberlo de verdad habría que mirar los otros
cartuchos de la misma familia: **Athletic Land**, **Cabbage Patch Kids**,
**Hyper Olympic**, **Hyper Sports**, **Hyper Rally**, **Konami's Tennis**,
**Konami's Golf** y **Sky Jaguar**, que están todos desensamblados en esta
misma serie.

Es material para la base de datos global de la serie, y está sin hacer.

## Los canales de sonido, sin escuchar

El motor está entendido -tres canales, prioridad por los seis bits bajos,
guiones con prefijos de duración, octava y caída- pero **no se ha escuchado
canal a canal en el emulador** para confirmar que el comando `0x1n` es de
verdad el ruido y no otra cosa.
