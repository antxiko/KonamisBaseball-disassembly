#!/usr/bin/env python3
"""Genera la portada de la web de Konami's Baseball, en los dos idiomas.

El diseno es el compartido por la serie (tools/estilo_web.py) y la pagina sale
autocontenida, con las imagenes embebidas como data URI.

Las imagenes NO son ilustraciones ni capturas: las dibuja tools/pantallas.py a
partir de los propios bytes de la ROM, ejecutando en Python el mismo interprete
de guiones que corre el Z80. Ninguna se ha retocado.

Uso: make_web.py <docs/imagenes> <salida.html> <idioma>
"""
import base64
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estilo_web import ESTILO                                   # noqa: E402

# Las cifras salen de contar sobre el listado generado, no de escribirlas a ojo:
# 16384 = 9618 + 6766, que es lo que imprime tools/presupuesto.py (make sanity).
# RUTINAS son las etiquetas con nombre propio, las mismas que cuenta densidad.py.
# POSTURAS las cuenta tools/pantallas.py recorriendo la tabla de 0x5048.
CODIGO = 9618
DATOS = 6766
RUTINAS = 629
POSTURAS = 22
DENSIDAD = "44,5"
DENSIDAD_EN = "44.5"


def mil(n, idioma):
    return f"{n:,}".replace(",", "." if idioma == "es" else ",")


TXT = {
    "es": dict(
        titulo="Konami's Baseball - desensamblado comentado",
        aviso="<b>Aqui no hay ninguna captura.</b> Todas las imagenes estan "
              "<b>dibujadas desde los bytes de la ROM</b>, ejecutando en Python "
              "el mismo interprete de guiones que corre el Z80. El listado y "
              "las cifras se reproducen con <code>make</code>.",
        claim="Los tres tercios de la pantalla pintados con un solo bucle que "
              "se lee a si mismo, los doce equipos de la liga japonesa de 1984 "
              "escondidos en doce letras, y una maquina que juega escribiendo "
              "en el hueco del mando.",
        ficha=["Konami - <b>(c) Konami 1984</b>",
               "Cartucho <b>RC-724</b>, 16 KB",
               "MSX1 - <b>pagina 1</b>", "Volcado <b>06504efb...</b>"],
        nav=[("#numbers", "Las cifras"), ("#findings", "Hallazgos"),
             ("#screens", "Lo que dibuja")],
        docnav=[("EMPEZAR.html", "Empezar"), ("EL-JUEGO.html", "El juego"),
                ("EL-CARTUCHO.html", "El cartucho"),
                ("EL-CODIGO.html", "El codigo"),
                ("HALLAZGOS.html", "Hallazgos"),
                ("EN-EL-EMULADOR.html", "En el emulador"),
                ("PREGUNTAS-ABIERTAS.html", "Preguntas abiertas")],
        otro=("../", "In English"),
        h_num="El cartucho en cifras", h_find="Lo que aparecio al desmontarlo",
        h_scr="Lo que el cartucho dibuja",
        cifras=[("100 %", "del binario explicado"),
                (str(RUTINAS), "rutinas con nombre"),
                (DENSIDAD + " %", "del listado comentado"),
                (mil(CODIGO, "es"), "bytes de codigo"),
                (mil(DATOS, "es"), "bytes de datos"),
                ("0", "bytes sin identificar")],
        nota_scr="Debajo de cada imagen esta de donde sale y que se esta "
                 "viendo.",
        pie_leg="Esto es trabajo de documentacion y preservacion: el codigo y "
                "los graficos siguen siendo de sus autores y de Konami, y la "
                "imagen del cartucho no se distribuye.",
    ),
    "en": dict(
        titulo="Konami's Baseball - a commented disassembly",
        aviso="<b>Not one capture here.</b> Every picture is <b>drawn from "
              "the bytes of the ROM</b>, by running in Python the same script "
              "interpreter the Z80 runs. The listing and the numbers are "
              "reproducible with <code>make</code>.",
        claim="The screen's three thirds painted with a single loop that reads "
              "its own output, the twelve teams of the 1984 Japanese league "
              "hidden in twelve letters, and a computer opponent that plays by "
              "writing into the joystick slot.",
        ficha=["Konami - <b>(c) Konami 1984</b>",
               "An <b>RC-724</b> 16 KB cartridge",
               "MSX1 - <b>page 1</b>", "Dump <b>06504efb...</b>"],
        nav=[("#numbers", "The numbers"), ("#findings", "What turned up"),
             ("#screens", "What it draws")],
        docnav=[("GETTING-STARTED.html", "Getting started"),
                ("THE-GAME.html", "The game"),
                ("THE-CARTRIDGE.html", "The cartridge"),
                ("THE-CODE.html", "The code"),
                ("FINDINGS.html", "Findings"),
                ("IN-THE-EMULATOR.html", "In the emulator"),
                ("OPEN-QUESTIONS.html", "Open questions")],
        otro=("es/", "En castellano"),
        h_num="The cartridge in numbers",
        h_find="What turned up when we took it apart",
        h_scr="What the cartridge draws",
        cifras=[("100%", "of the binary explained"),
                (str(RUTINAS), "named routines"),
                (DENSIDAD_EN + "%", "of the listing commented"),
                (mil(CODIGO, "en"), "bytes of code"),
                (mil(DATOS, "en"), "bytes of data"),
                ("0", "bytes unidentified")],
        nota_scr="Under each picture is where it comes from and what is on it.",
        pie_leg="This is documentation and preservation work: the code and "
                "artwork still belong to their authors and to Konami, and the "
                "cartridge image is not distributed.",
    ),
}

HALLAZGOS = {
    "es": [
        ('Los tres tercios de la pantalla, con un solo bucle',
         '<p>SCREEN 2 son tres tercios independientes, y para que los tres '
         'tengan lo mismo hay que escribirlo tres veces. 0x4485 copia de VRAM '
         'a VRAM byte a byte, y le mandan <b>4.095</b> bytes de 0x0000 a '
         '0x0800: como el destino va 0x800 por delante, pasado el primer '
         'bloque esta leyendo lo que el mismo acaba de escribir. Un bucle, '
         'tres tercios iguales, 4 KB ahorrados. Se hace dos veces: colores y '
         'patrones.</p><p>Y se queda <b>un byte corto</b>: 4.095 y no 4.096, '
         'asi que el ultimo byte del tercer tercio no se llega a escribir '
         'nunca.</p>'),
        ('La tabla de colores va debajo de la de patrones',
         '<p>En SCREEN 2 el TMS9918 no lee R3 y R4 como una direccion, sino '
         'como un bit de base y una mascara. Con <code>R4 = 0x07</code> los '
         'patrones quedan en <b>0x2000</b> y con <code>R3 = 0x7F</code> los '
         'colores en <b>0x0000</b>, al reves de lo habitual.</p><p>La tabla de '
         'registros de este cartucho y la de King\'s Valley son <b>identicas '
         'salvo un byte</b>, el del color de borde: <code>02 E2 0E 7F 07 76 03 '
         'E1</code> contra <code>... E4</code>.</p>'),
        ('Los doce equipos de la liga japonesa, en doce letras',
         '<p>La parrilla de eleccion no ensena nombres: ensena iniciales. Los '
         'doce bytes de 0x4649 son tiles, y dibujando la fuente desde la ROM se '
         'leen: <b>C D G S T W</b> para la Central -Carp, Dragons, Giants, '
         'Swallows, Tigers, Whales- y <b>B Bu F H L O</b> para la Pacific '
         '-Braves, Buffaloes, Fighters, Hawks, Lions, Orions-. Los doce equipos '
         'de la <b>Nippon Professional Baseball de 1984</b>, en orden '
         'alfabetico dentro de cada liga.</p><p>Y hay un tile hecho a proposito '
         'para esto: el <b>0xE8 es una "Bu" en un solo caracter</b>, que existe '
         'solo para que los Buffaloes no se confundan con los Braves.</p>'),
        ('La maquina juega escribiendo en el hueco del mando',
         '<p>No hay una via aparte para el rival. 0x7d04 calcula que haria un '
         'jugador y lo deja escrito en <b>0xE011</b>, que es el mismo byte '
         'donde 0x43e2 pone los bits recien pulsados del segundo jugador. La '
         'demostracion del menu hace lo mismo con 0xE00E, el del primero.</p>'
         '<p>Por eso el resto del cartucho -el bateo, la carrera, el '
         'lanzamiento- no sabe ni le importa si le esta jugando una persona o '
         'el propio cartucho. Y por eso, cuando manda la demostracion, '
         '0x6c0e se niega a hacer sonar nada: la partida automatica es '
         '<b>muda</b>.</p>'),
        ('El texto que cierra un guion es el primer byte del sprite siguiente',
         '<p>Cada postura de jugador son tres guiones -uno por capa de color- y '
         'detras van seis bytes de desplazamiento. En <b>21 de las 22 '
         'posturas</b>, el puntero a esos seis bytes apunta AL 0x00 QUE CIERRA '
         'EL TERCER GUION: ese byte hace las dos cosas a la vez, cerrar el '
         'guion y ser el desplazamiento en fila de la primera capa.</p><p>La '
         'unica que no lo hace es la de 0x50EC, y es porque su primer '
         'desplazamiento vale 1 y no 0. Un byte ahorrado por postura, '
         'veintiuna veces.</p>'),
        ('La pelota se hace pequena porque hay cinco pelotas',
         '<p>No hay escalado: hay <b>cinco dibujos</b> distintos en 0x6573, de '
         'siete filas a dos. 0x646b elige entre ellos restando la fila de la '
         'sombra menos la de la pelota -que es la altura- y comparando con '
         '<b>0x21, 0x0F y 0x06</b>, y baja uno mas si la sombra esta por encima '
         'de la fila 0x40, o sea si la jugada va lejos.</p><p>El bote no se '
         'calcula: <b>ocurre</b> cuando la fila de la pelota alcanza a la de su '
         'sombra.</p>'),
        ('La direccion del guion va escrita detras del propio CALL',
         '<p>0x4582 no recibe nada en registros: hace <code>ex (sp),hl</code>, '
         'lee del propio codigo los <b>dos bytes que siguen al call</b>, '
         'adelanta la direccion de retorno para que no se ejecuten, y se pone a '
         'dibujar. Hay <b>nueve</b> sitios que llaman asi.</p><p>Sin saberlo, '
         'un desensamblador toma esos dieciocho bytes por instrucciones. El '
         'binario vuelve a salir identico -son los mismos bytes- pero el '
         'listado miente, y no hay manera de que el reensamblado lo cace.</p>'),
        ('El bateador se pega tres bytes de la rutina de al lado',
         '<p>Las quince fichas de los jugadores de campo ocupan 21 bytes en la '
         'ROM y 32 en RAM. Quince por 32 llenan exactamente 0xE180..0xE35F, '
         'justo hasta donde empieza el medidor: por arriba cuadra.</p><p>Por '
         'abajo no: quince por 21 son <b>315</b> bytes y de 0x5C03 a 0x5D3B hay '
         '<b>312</b>. Los tres que faltan son los tres primeros de la rutina de '
         '0x5D3B -<code>21 00 E1</code>, o sea <code>ld hl,0e100h</code>- y '
         'acaban dentro de la ficha numero quince.</p>'),
        ('Un guion que no dibuja nadie',
         '<p>99 bytes en 0x4AF0 que son un guion perfectamente valido: cargan '
         'cuatro patrones de sprite en la VRAM 0x1800, otros cuatro en 0x1D00 y '
         'cinco atributos, y acaban <b>exactamente</b> donde vuelve a haber '
         'codigo.</p><p>No los dibuja nadie. El guion de antes acaba justo ahi '
         'pero no encadena; en toda la ROM no hay un solo valor inmediato de 16 '
         'bits entre 0x4AF0 y 0x4B53; las dos tablas de punteros a guiones '
         'apuntan dentro de sus propios bloques; y los nueve <code>call '
         '0x4582</code> llevan su argumento escrito al lado y ninguno es este.'
         '</p>'),
        ('Todo contador a cero vale 256',
         '<p>El borrado de la pantalla son tres pasadas con B a cero. No son '
         'pasadas vacias: el Z80 decrementa antes de comprobar, asi que un '
         '<code>djnz</code> con B a cero da <b>256</b> vueltas. Tres por 256 '
         'son las 768 posiciones de la tabla de nombres, escritas sin que la '
         'cuenta aparezca en ningun sitio.</p>'),
        ('La fuente no es ASCII: es el orden en que hicieron falta las letras',
         '<p>La A es 0xDA, la B 0xD0 y la C 0xD6. No hay ningun orden: hay '
         '<b>las 24 letras que el cartucho llega a escribir</b>, puestas segun '
         'fueron haciendo falta. Y en medio, un regalo: los tiles 0xD8 a 0xDE '
         'son <b>P L A Y E R S</b> seguidos, que es lo que permite escribir "1 '
         'PLAYER" y "2 PLAYERS" sin tabla ninguna.</p><p>Las cifras si van '
         'seguidas, 0xF0 mas el digito, y por eso el marcador y la cuenta se '
         'escriben con un simple <code>or 0f0h</code>.</p>'),
        ('Lleva la marca oculta de Konami',
         '<p>Konami escondia su numero de catalogo y el titulo en katakana al '
         'final de muchos cartuchos; lo descubrio <b>Manuel Pazos</b> (<a '
         'href="https://twitter.com/ManuelPazosMSX">@ManuelPazosMSX</a>). Este '
         'la lleva en 0x7FF6: <b>RC-724</b> y <b>YA KI U</b>, que es '
         '<b>&#37326;&#29699;</b> (<i>yakyu</i>), beisbol.</p>'),
    ],
    "en": [
        ("The screen's three thirds, with a single loop",
         '<p>SCREEN 2 is three independent thirds, and for all three to hold '
         'the same thing you have to write it three times. 0x4485 copies VRAM '
         'to VRAM byte by byte, and is given <b>4,095</b> bytes from 0x0000 to '
         '0x0800: since the destination runs 0x800 ahead, past the first block '
         'it is reading what it has just written. One loop, three identical '
         'thirds, 4 KB saved. Done twice: colours and patterns.</p><p>And it '
         'falls <b>one byte short</b>: 4,095 and not 4,096, so the last byte of '
         'the third third is never written.</p>'),
        ('The colour table sits underneath the pattern table',
         '<p>In SCREEN 2 the TMS9918 does not read R3 and R4 as an address, but '
         'as a base bit and a mask. With <code>R4 = 0x07</code> the patterns '
         'land at <b>0x2000</b> and with <code>R3 = 0x7F</code> the colours at '
         '<b>0x0000</b>, the reverse of the usual layout.</p><p>This '
         "cartridge's register table and King's Valley's are <b>identical but "
         'for one byte</b>, the border colour: <code>02 E2 0E 7F 07 76 03 '
         'E1</code> against <code>... E4</code>.</p>'),
        ("The Japanese league's twelve teams, in twelve letters",
         '<p>The selection grid shows no names: it shows initials. The twelve '
         'bytes at 0x4649 are tile numbers, and drawing the font from the ROM '
         'they read: <b>C D G S T W</b> for the Central -Carp, Dragons, Giants, '
         'Swallows, Tigers, Whales- and <b>B Bu F H L O</b> for the Pacific '
         '-Braves, Buffaloes, Fighters, Hawks, Lions, Orions-. The twelve teams '
         'of <b>1984 Nippon Professional Baseball</b>, alphabetical within each '
         'league.</p><p>And there is a tile made on purpose for this: '
         '<b>0xE8 is a "Bu" in a single character</b>, which exists only so the '
         'Buffaloes are not mistaken for the Braves.</p>'),
        ('The computer plays by writing into the joystick slot',
         '<p>There is no separate path for the opponent. 0x7d04 works out what '
         'a player would do and leaves it written in <b>0xE011</b>, the very '
         "byte where 0x43e2 puts the second player's freshly pressed bits. The "
         "menu's demo does the same with 0xE00E, the first player's.</p><p>So "
         'the rest of the cartridge -the batting, the running, the pitching- '
         'neither knows nor cares whether a person or the cartridge itself is '
         'playing. And that is why, while the demo is running, 0x6c0e refuses '
         'to play any sound at all: the automatic game is <b>silent</b>.</p>'),
        ("The byte that ends a script is the next sprite's first byte",
         '<p>Every player pose is three scripts -one per colour layer- followed '
         'by six offset bytes. In <b>21 of the 22 poses</b>, the pointer to '
         'those six bytes points AT THE 0x00 THAT ENDS THE THIRD SCRIPT: that '
         "byte does both jobs, ending the script and being the first layer's "
         'row offset.</p><p>The only one that does not is 0x50EC, and only '
         'because its first offset is 1 and not 0. One byte saved per pose, '
         'twenty-one times over.</p>'),
        ('The ball shrinks because there are five balls',
         '<p>There is no scaling: there are <b>five different drawings</b> at '
         "0x6573, from seven rows down to two. 0x646b picks between them by "
         "subtracting the ball's row from its shadow's -which is the height- "
         'and comparing against <b>0x21, 0x0F and 0x06</b>, and drops one more '
         'if the shadow is above row 0x40, that is, if the play is going '
         'far.</p><p>The bounce is not computed: it <b>happens</b> when the '
         "ball's row catches up with its shadow's.</p>"),
        ("The script's address is written behind the CALL itself",
         '<p>0x4582 receives nothing in registers: it does <code>ex '
         '(sp),hl</code>, reads from the code itself the <b>two bytes that '
         'follow the call</b>, pushes the return address past them so they are '
         'never executed, and starts drawing. <b>Nine</b> places call it that '
         'way.</p><p>Not knowing this, a disassembler takes those eighteen '
         'bytes for instructions. The binary still comes out identical -they '
         'are the same bytes- but the listing lies, and no amount of '
         're-assembling will catch it.</p>'),
        ('The batter eats three bytes of the routine next door',
         "<p>The fifteen fielders' records take 21 bytes in the ROM and 32 in "
         'RAM. Fifteen times 32 fills exactly 0xE180..0xE35F, right up to where '
         'the meter starts: the top end adds up.</p><p>The bottom end does not: '
         'fifteen times 21 is <b>315</b> bytes and from 0x5C03 to 0x5D3B there '
         'are <b>312</b>. The three missing ones are the first three of the '
         'routine at 0x5D3B -<code>21 00 E1</code>, that is <code>ld '
         'hl,0e100h</code>- and they end up inside the fifteenth record.</p>'),
        ('A script nobody draws',
         '<p>99 bytes at 0x4AF0 that form a perfectly valid script: they load '
         'four sprite patterns into VRAM 0x1800, four more into 0x1D00 and five '
         'attributes, and end <b>exactly</b> where code resumes.</p><p>Nobody '
         'draws them. The previous script ends right there but does not chain; '
         'in the whole ROM there is not a single 16-bit immediate between '
         '0x4AF0 and 0x4B53; the two script pointer tables point inside their '
         'own blocks; and the nine <code>call 0x4582</code> carry their '
         'argument alongside and none of them is this one.</p>'),
        ('Every counter at zero means 256',
         '<p>Clearing the screen is three passes with B at zero. They are not '
         'empty passes: the Z80 decrements before testing, so a '
         '<code>djnz</code> with B at zero goes round <b>256</b> times. Three '
         "times 256 is the name table's 768 cells, written without the count "
         'appearing anywhere.</p>'),
        ('The font is not ASCII: it is the order the letters were needed in',
         '<p>A is 0xDA, B is 0xD0 and C is 0xD6. There is no order at all: '
         'there are <b>the 24 letters the cartridge ever writes</b>, laid down '
         'as they were needed. And in the middle, a gift: tiles 0xD8 to 0xDE '
         'are <b>P L A Y E R S</b> in a row, which is what lets it write "1 '
         'PLAYER" and "2 PLAYERS" with no table at all.</p><p>The digits do run '
         'in order, 0xF0 plus the digit, which is why the scoreboard and the '
         'count are written with a plain <code>or 0f0h</code>.</p>'),
        ("It carries Konami's hidden mark",
         '<p>Konami hid its catalogue number and the katakana title at the end '
         'of many cartridges; <b>Manuel Pazos</b> (<a '
         'href="https://twitter.com/ManuelPazosMSX">@ManuelPazosMSX</a>) found '
         'it. This one carries it at 0x7FF6: <b>RC-724</b> and <b>YA KI U</b>, '
         'which is <b>&#37326;&#29699;</b> (<i>yakyu</i>), baseball.</p>'),
    ],
}

GALERIA = [
    ("rotulo.png",
     "El <b>rotulo del juego</b>, tal como lo pinta 0x44b7: no es un guion, "
     "son <b>46 tiles correlativos</b> del 0x40 al 0x6D en dos filas de 23. "
     "Como el dibujo es unico, basta con contar",
     "The <b>game's title</b>, exactly as 0x44b7 paints it: not a script but "
     "<b>46 consecutive tiles</b> from 0x40 to 0x6D in two rows of 23. Since "
     "the artwork is unique, counting is enough"),
    ("presentacion.png",
     "El <b>logotipo de Konami</b> subiendo por la pantalla. El bucle "
     "principal escribe tres filas de tiles correlativos en 0x7a8b y cada "
     "cuatro cuadros baja el puntero 0x20, que es una fila",
     "The <b>Konami logo</b> rising up the screen. The main loop writes three "
     "rows of consecutive tiles at 0x7a8b and every four frames drops the "
     "pointer by 0x20, which is one row"),
    ("menu.png",
     "La <b>pantalla de titulo</b> entera: el rotulo de 0x44b7 mas los tres "
     "guiones encadenados de 0x46d4, que escriben el aviso de copyright, PLAY "
     "SELECT y las dos lineas de jugadores",
     "The whole <b>title screen</b>: the 0x44b7 title plus the three chained "
     "scripts at 0x46d4, which write the copyright line, PLAY SELECT and the "
     "two player lines"),
    ("ligas.png",
     "La <b>eleccion de liga</b>. 0x41a5 la escribe DEBAJO del menu sin "
     "borrar nada: los guiones de 0x470c y 0x4718 van pegados uno detras del "
     "otro, asi que basta con pedirle dos al interprete",
     "The <b>league choice</b>. 0x41a5 writes it BELOW the menu without "
     "clearing anything: the scripts at 0x470c and 0x4718 sit back to back, so "
     "asking the interpreter for two is enough"),
    ("equipos_central.png",
     "La parrilla de la <b>Central League</b>: C D G S T W, o sea Carp, "
     "Dragons, Giants, Swallows, Tigers y Whales. El guion escribe las seis "
     "iniciales encima de la palabra CENTRAL y borra la fila de la otra liga",
     "The <b>Central League</b> grid: C D G S T W, that is Carp, Dragons, "
     "Giants, Swallows, Tigers and Whales. The script writes the six initials "
     "over the word CENTRAL and blanks the other league's row"),
    ("equipos_pacifico.png",
     "La de la <b>Pacific League</b>: B Bu F H L O -Braves, Buffaloes, "
     "Fighters, Hawks, Lions y Orions-. La <b>Bu</b> es un tile hecho a "
     "proposito, el 0xE8, para no repetir la B",
     "The <b>Pacific League</b> one: B Bu F H L O -Braves, Buffaloes, "
     "Fighters, Hawks, Lions and Orions-. The <b>Bu</b> is a tile made on "
     "purpose, 0xE8, so as not to repeat the B"),
    ("campo.png",
     "El <b>estadio</b>, montado como lo monta 0x4219: se borra la tabla de "
     "nombres, se descomprime el guion de 0x65ad -patrones y colores-, se "
     "replican los dos tercios que faltan y se dibuja la tabla de nombres con "
     "el guion de 0x6a1c",
     "The <b>stadium</b>, built the way 0x4219 builds it: clear the name "
     "table, decompress the script at 0x65ad -patterns and colours-, replicate "
     "the two missing thirds and draw the name table with the script at "
     "0x6a1c"),
    ("posturas.png",
     "Las <b>22 posturas</b> de los jugadores, con sus <b>tres capas de "
     "color</b> puestas en el sitio exacto que dicen sus desplazamientos. "
     "El cartucho no guarda estos patrones en VRAM: los sube desde la ROM "
     "cada vez que la postura cambia",
     "The players' <b>22 poses</b>, with their <b>three colour layers</b> "
     "placed exactly where their offsets say. The cartridge does not keep "
     "these patterns in VRAM: it uploads them from ROM every time the pose "
     "changes"),
    ("fuente.png",
     "La <b>fuente</b> con la que se escribe todo, los tiles 0xD0 a 0xFF. No "
     "es ASCII ni va en orden: son las 24 letras que el cartucho llega a "
     "escribir, puestas segun fueron haciendo falta. Fijarse en 0xD8..0xDE: "
     "<b>PLAYERS</b> seguidos",
     "The <b>font</b> everything is written with, tiles 0xD0 to 0xFF. It is "
     "neither ASCII nor in order: it is the 24 letters the cartridge ever "
     "writes, laid down as they were needed. Look at 0xD8..0xDE: "
     "<b>PLAYERS</b> in a row"),
]


def img64(ruta):
    with open(ruta, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    imgdir, salida, idioma = argv[1:4]
    t = TXT[idioma]

    # El "logotipo" de la cabecera no es un montaje ni una captura: es el rotulo
    # que el propio cartucho pinta en su pantalla de titulo, dibujado desde la
    # ROM por graficos.py. Si el PNG no esta, el trabajo NO esta hecho: se cae
    # al texto, y eso se ve.
    ruta_logo = os.path.join(imgdir, "rotulo.png")
    cabecera = (f'<img src="{img64(ruta_logo)}" alt="Konami&#39;s Baseball">'
                if os.path.exists(ruta_logo) else "<h1>Konami&#39;s Baseball</h1>")

    nav = "".join(f'<a href="{h}">{x}</a>' for h, x in t["nav"])
    nav += "".join(f'<a href="{h}">{x}</a>' for h, x in t["docnav"])
    nav += (f'<a href="{t["otro"][0]}" style="margin-left:auto;color:var(--oro)">'
            f'{t["otro"][1]}</a>')

    cifras = "".join(f'<div class="cifra"><b>{v}</b><span>{e}</span></div>'
                     for v, e in t["cifras"])
    halls = "".join(f'<div class="hall"><h3>{tit}</h3>{cuerpo}</div>'
                    for tit, cuerpo in HALLAZGOS[idioma])
    imgs = ""
    faltan = []
    for fich, es, en in GALERIA:
        ruta = os.path.join(imgdir, fich)
        if not os.path.exists(ruta):
            faltan.append(fich)
            continue
        pie = es if idioma == "es" else en
        imgs += (f'<figure><img src="{img64(ruta)}" alt="{pie}">'
                 f'<figcaption>{pie}</figcaption></figure>')
    if faltan:
        print("  (faltan %d imagenes: %s)" % (len(faltan), " ".join(faltan)))

    html = f"""<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t['titulo']}</title>
<style>{ESTILO}</style>
<header class="top">
  {cabecera}
  <p class="claim">{t['claim']}</p>
  <p class="ficha">{' - '.join(t['ficha'])}</p>
</header>
<p class="ficha" style="border:1px solid var(--oro);padding:.8em 1em;margin:1.5em 0">
{t['aviso']}</p>
<nav>{nav}</nav>
<section id="numbers">
  <h2>{t['h_num']}</h2>
  <div class="cifras">{cifras}</div>
</section>
<section id="findings"><h2>{t['h_find']}</h2>{halls}</section>
<section id="screens">
  <h2>{t['h_scr']}</h2>
  <p class="n">{t['nota_scr']}</p>
  <div class="galeria">{imgs}</div>
</section>
<footer><p>{t['pie_leg']}</p></footer>
"""
    with open(salida, "w", encoding="utf-8") as f:
        f.write(html)
    print("  %s: %d KB (%s)" % (salida, len(html) // 1024, idioma))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
