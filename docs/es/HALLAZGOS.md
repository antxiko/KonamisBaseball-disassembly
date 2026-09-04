# Hallazgos

Lo que apareció al desmontarlo. Todo está medido sobre el binario; cuando algo
es una suposición, se dice.

## 1. La dirección del guion va escrita detrás del propio CALL

0x4582 no recibe nada en registros. Hace `ex (sp),hl` para pillar la dirección
de retorno, lee de ahí una palabra, adelanta el retorno **dos bytes** para que
no se ejecuten, y cae dentro del intérprete de guiones.

```
        call 0x4582
        defw 0x65AD      <- esto NO es código, es el argumento
        ld de,...
```

Hay **nueve** sitios que llaman así. Sin saberlo, un desensamblador toma esos
dieciocho bytes por instrucciones; el binario vuelve a salir idéntico -son los
mismos bytes- pero el listado miente, y **no hay manera de que el reensamblado
lo cace**.

Aquí están declarados con la directiva `!skip 0x4582 2` del fichero de
entradas, y los nueve argumentos caen dentro de bloques de guiones ya
conocidos, que es lo que confirma la lectura.

## 2. Los tres tercios de la pantalla, con un solo bucle

SCREEN 2 son tres tercios independientes de 2 KB, y para que los tres tengan lo
mismo hay que escribirlo tres veces. 0x4485 copia de VRAM a VRAM byte a byte, y
le mandan **4.095** bytes de 0x0000 a 0x0800.

Como el destino va 0x800 por delante, pasado el primer bloque está leyendo lo
que él mismo acaba de escribir. **Un bucle, tres tercios iguales, 4 KB
ahorrados.** Se hace dos veces: colores y patrones.

Y se queda **un byte corto**: 4.095 y no 4.096, así que el último byte del
tercer tercio no se llega a escribir nunca.

## 3. Los doce equipos de la liga japonesa, en doce letras

La parrilla de elección no enseña nombres: enseña iniciales. Los doce bytes de
0x4649 son números de tile, y dibujando la fuente desde la ROM se leen:

```
Central   C D G S T W    Carp, Dragons, Giants, Swallows, Tigers, Whales
Pacific   B Bu F H L O   Braves, Buffaloes, Fighters, Hawks, Lions, Orions
```

Los doce equipos de la **Nippon Professional Baseball de 1984**, en orden
alfabético dentro de cada liga. Y hay un tile hecho a propósito para esto: el
**0xE8 es una "Bu" en un solo carácter**, que existe sólo para que los
Buffaloes no se confundan con los Braves.

## 4. La máquina juega escribiendo en el hueco del mando

No hay una vía aparte para el rival. 0x7d04 calcula qué haría un jugador y lo
deja escrito en **0xE011**, que es el mismo byte donde 0x43e2 pone los bits
recién pulsados del segundo jugador. La demostración del menú hace lo mismo con
**0xE00E**, el del primero.

Por eso el resto del cartucho -el bateo, la carrera, el lanzamiento- no sabe ni
le importa si le está jugando una persona o el propio cartucho.

Y hay un efecto secundario bonito: como 0x6c0e se niega a hacer sonar nada
mientras 0xE002 esté puesto, **la partida automática del menú es muda**.

## 5. La fuente no es ASCII: es el orden en que hicieron falta las letras

```
0xD0 B   0xD1 D   0xD2 J   0xD3 O   0xD4 T   0xD5 I   0xD6 C   0xD7 K
0xD8 P   0xD9 L   0xDA A   0xDB Y   0xDC E   0xDD R   0xDE S   0xDF G
0xE0 H   0xE1 M   0xE2 V   0xE3 W   0xE4 F   0xE5 U   0xE6 N   0xE7 X
0xE8 Bu  0xE9 ,   0xEA (c)
0xF0 a 0xF9: las cifras del 0 al 9
```

No hay ningún orden: hay **las 24 letras que el cartucho llega a escribir**,
puestas según fueron haciendo falta. Y en medio, un regalo: los tiles **0xD8 a
0xDE son P L A Y E R S seguidos**, que es lo que permite escribir "1 PLAYER" y
"2 PLAYERS" sin tabla ninguna.

Las cifras sí van seguidas, 0xF0 más el dígito, y por eso el marcador y la
cuenta se escriben con un simple `or 0f0h`.

## 6. El byte que cierra un guion es el primer byte del sprite siguiente

Cada postura de jugador son tres guiones -uno por capa de color- y detrás van
seis bytes de desplazamiento. En **21 de las 22 posturas**, el puntero a esos
seis bytes apunta **al 0x00 que cierra el tercer guion**: ese byte hace las dos
cosas a la vez, cerrar el guion y ser el desplazamiento en fila de la primera
capa.

La única que no lo hace es la de 0x50EC, y es porque su primer desplazamiento
vale 1 y no 0. Un byte ahorrado por postura, veintiuna veces.

## 7. La pelota se hace pequeña porque hay cinco pelotas

No hay escalado: hay **cinco dibujos** distintos en 0x6573, de siete filas a
dos. 0x646b elige entre ellos restando la fila de la sombra menos la de la
pelota -que es la altura- y comparando con **0x21, 0x0F y 0x06**, y baja uno más
si la sombra está por encima de la fila 0x40, o sea si la jugada va lejos.

El bote no se calcula: **ocurre** cuando la fila de la pelota alcanza a la de su
sombra.

## 8. El bateador se come tres bytes de la rutina de al lado

Las quince fichas de los jugadores de campo ocupan 21 bytes en la ROM y 32 en
RAM. Quince por 32 llenan exactamente 0xE180..0xE35F, justo hasta donde empieza
el medidor: por arriba cuadra.

Por abajo no: quince por 21 son **315** bytes y de 0x5C03 a 0x5D3B hay **312**.
Los tres que faltan son los tres primeros de la rutina de 0x5D3B -`21 00 E1`, o
sea `ld hl,0e100h`- y acaban en los huecos 28, 29 y 30 de la ficha número
quince.

Que sea a propósito para ahorrar bytes o un descuido que no se nota porque esos
huecos no se usan, **no se puede decidir mirando el binario**.

## 9. Un guion que no dibuja nadie

99 bytes en 0x4AF0 que son un guion perfectamente válido: cargan cuatro
patrones de sprite en la VRAM 0x1800, otros cuatro en 0x1D00 y cinco atributos,
y acaban **exactamente** donde vuelve a haber código.

No los dibuja nadie:

- el arranque dibuja el guion de 0x4A96, que **acaba** en 0x4AF0, y luego pisa
  HL con 0x49D4: no encadena;
- en toda la ROM no hay ni un solo valor inmediato de 16 bits entre 0x4AF0 y
  0x4B53;
- las dos tablas de punteros a guiones -0x5048 y 0x655F- apuntan todas dentro
  de sus propios bloques;
- los nueve `call 0x4582` llevan su argumento escrito al lado, y ninguno es
  éste.

Es un resultado **negativo** -no se ha encontrado el lector, que no es lo mismo
que demostrar que no existe-, pero apunta a bytes que se quedaron dentro.

## 10. El mismo armazón que King's Valley

La tabla de registros del VDP de los dos cartuchos es **idéntica salvo un
byte**, el del color de borde. El lenguaje de guiones es el mismo, con dos
diferencias: Baseball tiene un comando de más -el 0x01- y encadena leyendo la
dirección con el byte alto primero, al revés que King's Valley.

Que el cartucho **viejo** (1984) tenga el comando de más y el nuevo (1985) no,
encaja con que King's Valley sea una simplificación. **SUPOSICIÓN**: no se ha
comprobado con más cartuchos de la familia.

## 11. Todo contador a cero vale 256

El borrado de la pantalla son tres pasadas con B a cero. No son pasadas vacías:
el Z80 decrementa antes de comprobar, así que un `djnz` con B a cero da **256**
vueltas. Tres por 256 son las 768 posiciones de la tabla de nombres, escritas
sin que la cuenta aparezca en ningún sitio.

## 12. Lleva la marca oculta de Konami

En 0x7FF6, cerrando el cartucho: **RC-724** y el título en katakana, **YA KI
U**, que es 野球 (*yakyū*), béisbol.

Konami escondía su número de catálogo y el título al final de muchos de sus
cartuchos; lo descubrió **Manuel Pazos**
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)), y hay que citarlo.
