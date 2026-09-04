# El juego

**Konami's Baseball** es un partido de béisbol para uno o dos jugadores. Sale
en 1984, es el **RC-724** del catálogo de Konami, y ocupa 16 KB.

Todo lo que hay en esta página está leído del binario. Cuando algo no se ha
podido comprobar, se dice.

## Cómo se elige la partida

La pantalla de título ofrece **1 PLAYER** y **2 PLAYERS**. Con uno, la máquina
juega el otro lado; con dos, el segundo jugador usa el segundo mando o su
mitad del teclado.

Debajo aparece la elección de liga: **CENTRAL** y **PACIFIC**. Y con la liga
elegida, la parrilla de los seis equipos, cada uno con su inicial:

| Central | | Pacific | |
|---|---|---|---|
| **C** | Carp | **B** | Braves |
| **D** | Dragons | **Bu** | Buffaloes |
| **G** | Giants | **F** | Fighters |
| **S** | Swallows | **H** | Hawks |
| **T** | Tigers | **L** | Lions |
| **W** | Whales | **O** | Orions |

Son los doce equipos de la **Nippon Professional Baseball de 1984**, en orden
alfabético dentro de cada liga. El cartucho no escribe los nombres en ningún
sitio: sólo las iniciales, en los doce bytes de 0x4649. La **Bu** de los
Buffaloes es un tile hecho a propósito, el 0xE8, para que no se confunda con la
B de los Braves.

Lo único que distingue a un equipo de otro son **dos bytes**, los que 0x5b5a
saca de las tablas de 0x5b9c y 0x5ba8 y mete en los huecos 0x0c y 0x10 de las
fichas del lanzador y del bateador. No hay plantillas ni estadísticas: dos
números por equipo.

## Los mandos

El primer jugador puede usar el joystick del primer puerto o **las cuatro
flechas del teclado más la barra espaciadora** (0x436e). El segundo, el segundo
puerto o **W arriba, Z abajo, A izquierda, D derecha y SHIFT** (0x432a).

Las dos lecturas de teclado se recolocan al orden en que las quiere el resto
del cartucho, que es el del joystick: bit 0 arriba, 1 abajo, 2 izquierda, 3
derecha, 4 y 5 los botones. La de las flechas se traduce de golpe con la tabla
de dieciséis entradas de 0x4396, en la que las seis combinaciones imposibles
-arriba y abajo a la vez, izquierda y derecha a la vez- valen 0x0F.

## Lanzar

Antes de lanzar hay un **medidor** que se llena y se vacía solo, abajo a la
izquierda: quince casillas y un contador BCD que sube hasta 60 y luego baja
(0x4fc3). El nibble alto de 0xE364 y los dos pares de bits del bajo son la
velocidad y el efecto del lanzamiento.

Con el lanzamiento armado, el brazo pasa por **seis posturas**, una cada cinco
cuadros (0x4d74). En la sexta suelta la pelota, y a partir de ahí manda 0x4dac:
la pelota avanza sumando el paso de 0xE125 a un acumulador de 16 bits, y el
byte entero que sale de ahí es lo que se mueve. Cada tres vueltas del contador
de 0xE127 se le busca un paso nuevo en la tabla de 0x4f97: eso es la **curva**.

## Batear

El bate tiene **cinco posturas** por tipo de golpe (tabla de 0x4faf), y avanza
mientras se siga pulsando. Hay golpe si la pelota entra en la caja de contacto
-que es una de las tres de 0x730a, dos límites por eje- y el bate está en la
postura 2, 3 o 4.

De **dónde** entra la pelota en el bate sale el ángulo con el que sale
despedida: la tabla de 0x728a tiene quince ángulos por lado del bateador -tres
posturas por cinco columnas-, y van de 0x3c a 0x04 y vuelven a 0x3c, o sea del
extremo de un lado al del otro. Al ángulo se le suman **dos bits del registro
R** del Z80 (0x714b), así que no hay dos golpes exactamente iguales.

## Correr

Las cuatro bases son cuatro fichas de 32 bytes en 0xE180. El corredor sale
cuando se pulsa la dirección de esa base con el botón, y hay una comprobación
bonita en 0x44ed: si con el paso se cae encima del equipo que ya tiene el otro
jugador, da otro paso más en el mismo sentido.

Con un jugador, la máquina decide sola qué corredor manda: recorre las cuatro
bases, se queda con el que va más adelantado por cada sentido, y **escribe la
orden en 0xE011**, que es el mismo byte donde se guardan los bits recién
pulsados del segundo jugador.

## Contar

Los contadores están todos juntos a partir de 0xE408: strikes, bolas,
eliminados, la entrada, y las carreras de cada equipo. Tres strikes son un
eliminado, tres eliminados cambian la entrada, y **cuatro bolas** son base por
bolas -y sale el cartel de "4 BALL", que se escribe con el tile 0xF4 del cuatro
delante de la palabra.

Los carteles son siete, en la tabla de 0x7c20, cada uno con su sonido:
**STRIKE**, **BALL**, **OUT**, **SAFE**, **CHANGE**, **FOUL** y ese **4 BALL**.
Y aparte, **HOME RUN**, que parpadea con el marco vacío cada 32 cuadros.

## Cuántas entradas

Nueve. 0x7b36 sube el contador de 0xE40B cada vez que acaba el turno del
segundo equipo, y al llegar a **nueve** pone 0xE402 a 0x80, que es lo que el
bucle de fuera mira para dar el partido por acabado.

Hay una excepción: en la **octava**, si los dos marcadores están empatados,
0x7b7b escribe un 0xE7 en la casilla y el partido sigue. O sea que hay algo
parecido a una prórroga por empate. **SUPOSICIÓN**: no se ha llegado a jugar un
partido entero para verlo.
