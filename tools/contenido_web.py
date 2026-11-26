#!/usr/bin/env python3
"""EL CONTENIDO de la web de este juego: lo unico que es de este juego.

jekyll.py y make_web.py son la maquinaria y no llevan dentro el nombre de
ningun juego: lo leen de aqui.
"""

NOMBRE = "Konami's Baseball"
EDITOR = 'Konami'
ANIO = 1984
REPOSITORIO = 'https://github.com/antxiko/KonamisBaseball-disassembly'

CODIGO = 9618
DATOS = 6766
DENSIDAD = '44,5'
DENSIDAD_EN = '44.5'
ESTILO = '\n:root{--tinta:#cfd0d4;--suave:#83868f;--fondo:#000;--panel:#0c0e13;--linea:#23262e;\n  --rojo:#ff897d;--cyan:#65dbef;--verde:#3eb849;--oro:#ded087}\n@media (prefers-color-scheme:light){:root{--tinta:#191a1e;--suave:#5a5d66;--fondo:#e9e7e1;\n  --panel:#f7f6f2;--linea:#d0cdc5;--rojo:#b23f34;--cyan:#1c6b7c;--verde:#2b7734;--oro:#8a7420}}\n:root[data-theme="dark"]{--tinta:#cfd0d4;--suave:#83868f;--fondo:#000;--panel:#0c0e13;\n  --linea:#23262e;--rojo:#ff897d;--cyan:#65dbef;--verde:#3eb849;--oro:#ded087}\n:root[data-theme="light"]{--tinta:#191a1e;--suave:#5a5d66;--fondo:#e9e7e1;--panel:#f7f6f2;\n  --linea:#d0cdc5;--rojo:#b23f34;--cyan:#1c6b7c;--verde:#2b7734;--oro:#8a7420}\n*{box-sizing:border-box}\nbody{margin:0;background:var(--fondo);color:var(--tinta);padding:0 1.25rem 6rem;\n  font:15px/1.7 ui-monospace,"SF Mono",Menlo,Consolas,monospace}\n.w{max-width:1120px;margin:0 auto}\n.n{max-width:68ch}\nh1,h2,h3,h4{font-weight:400;text-wrap:balance}\na{color:var(--cyan)}\nimg{image-rendering:pixelated;max-width:100%;height:auto;display:block}\nheader.top{display:flex;flex-direction:column;align-items:center;gap:1.5rem;\n  padding:4rem 0 2rem;text-align:center}\nheader.top img{width:min(100%,642px)}\n.claim{max-width:60ch;color:var(--suave);font-size:1.05rem}\n.claim b{color:var(--tinta);font-weight:400}\n.ficha{display:flex;flex-wrap:wrap;justify-content:center;gap:0 1.5rem;width:100%;\n  font-size:12px;letter-spacing:.08em;text-transform:uppercase;color:var(--suave);\n  border-top:1px solid var(--linea);border-bottom:1px solid var(--linea);padding:.85rem 0}\n.ficha b{color:var(--rojo);font-weight:400}\nnav{display:flex;flex-wrap:wrap;gap:1.25rem;justify-content:center;padding:1.25rem 0;\n  font-size:12px;letter-spacing:.08em;text-transform:uppercase}\nnav a{color:var(--suave);text-decoration:none;border-bottom:1px solid transparent}\nnav a:hover,nav a:focus{color:var(--tinta);border-bottom-color:var(--rojo)}\nnav.docs{border-top:1px solid var(--linea);border-bottom:1px solid var(--linea);\n  margin-bottom:1rem}\nsection{margin-top:4.5rem;scroll-margin-top:1rem}\nsection>h2{font-size:1rem;letter-spacing:.1em;text-transform:uppercase;\n  border-left:3px solid var(--rojo);padding-left:.9rem;margin:0 0 1.5rem}\n.cifras{display:grid;gap:1px;background:var(--linea);border:1px solid var(--linea);\n  grid-template-columns:repeat(auto-fit,minmax(160px,1fr))}\n.cifra{background:var(--panel);padding:1.1rem}\n.cifra b{display:block;font-size:1.7rem;color:var(--oro);font-weight:400;\n  font-variant-numeric:tabular-nums;line-height:1.2}\n.cifra span{font-size:11px;letter-spacing:.07em;text-transform:uppercase;color:var(--suave)}\n.hall{border-top:1px solid var(--linea);padding-top:1.75rem;margin-top:2.5rem}\n.hall:first-of-type{border-top:0;padding-top:0;margin-top:0}\n.hall h3{margin:0 0 .75rem;font-size:1.15rem;color:var(--rojo)}\n.hall h4{color:var(--oro);margin:1.5rem 0 .5rem;font-size:.95rem}\n.hall p{margin:0 0 1rem}\npre.asm{background:var(--panel);border-left:2px solid var(--verde);margin:1.25rem 0;\n  padding:1rem 1.1rem;overflow-x:auto;font-size:13px;line-height:1.6;color:var(--tinta)}\n.par{display:grid;gap:1.25rem;grid-template-columns:1fr}\n@media(min-width:820px){.par{grid-template-columns:1fr 1fr}}\n.par figure{margin:0}\ntable{border-collapse:collapse;width:100%;margin:1.25rem 0;font-size:13px;display:block;\n  overflow-x:auto}\nth,td{text-align:left;padding:.5rem .75rem;border-bottom:1px solid var(--linea)}\nth{color:var(--suave);font-weight:400;font-size:11px;letter-spacing:.07em;text-transform:uppercase}\ntd.num{font-variant-numeric:tabular-nums;color:var(--oro)}\n.nivel{margin-top:2rem}\n.nivel h3{margin:0 0 .9rem;font-size:.95rem;letter-spacing:.06em;text-transform:uppercase}\n.nivel em{color:var(--cyan);font-style:normal}\n.sep{color:var(--suave);margin:0 .6rem}\n.rejilla{display:grid;gap:.9rem;grid-template-columns:repeat(auto-fill,minmax(250px,1fr))}\n.rejilla figure{margin:0;background:var(--panel);box-shadow:0 0 0 1px var(--linea)}\n.rejilla figcaption{display:flex;justify-content:space-between;padding:.45rem .65rem;\n  font-size:11px;color:var(--suave);border-top:1px solid var(--linea)}\n.dir{font-variant-numeric:tabular-nums;color:var(--verde)}\nfooter{margin-top:5rem;padding-top:1.5rem;border-top:1px solid var(--linea);\n  color:var(--suave);font-size:12px}\n\n/* Aviso de trabajo en curso: tiene que verse antes que las cifras, porque un\n   100% mal leido hace mas dano que no ponerlo. */\n.aviso{background:#3a2a10;border-left:3px solid var(--oro);margin:1.5rem auto;\n  padding:1rem 1.2rem;max-width:900px;border-radius:4px}\n.aviso p{margin:0;color:var(--tinta);font-size:15px;line-height:1.65}\n.galeria{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));\n  gap:1.5rem;margin:1.5rem 0}\n.galeria figure{margin:0}\n.galeria img{width:100%;height:auto;image-rendering:pixelated;\n  border:1px solid var(--linea);border-radius:3px}\n.galeria figcaption{color:var(--suave);font-size:13px;margin-top:.5rem}\naudio{display:block;width:100%;max-width:640px;margin:.75rem 0 1.5rem}\n'
POSTURAS = 22
RUTINAS = 629

PIE_LEGAL = {'es': "<em>Konami's Baseball</em> lo publico Konami para MSX; su numero de catalogo es RC-724 y son 16 KB. Todos los derechos sobre el juego siguen siendo de sus titulares. Este trabajo es de preservacion, estudio y documentacion, y la imagen del cartucho no se distribuye.", 'en': "<em>Konami's Baseball</em> was published by Konami for the MSX; its catalogue number is RC-724 and it is 16 KB. All rights in the game remain with their holders. This is preservation, study and documentation work, and the cartridge image is not distributed."}

PORTADA = {
    'es': dict(
        titulo="Konami's Baseball - desensamblado comentado",
        claim='Los tres tercios de la pantalla pintados con un solo bucle que se lee a si mismo, los doce equipos de la liga japonesa de 1984 escondidos en doce letras, y una maquina que juega escribiendo en el hueco del mando.',
        ficha=['Konami - <b>(c) Konami 1984</b>', 'Cartucho <b>RC-724</b>, 16 KB', 'MSX1 - <b>pagina 1</b>', 'Volcado <b>06504efb...</b>'],
        h_num='El cartucho en cifras',
        cifras=[('100 %', 'del binario explicado'), ('629', 'rutinas con nombre'), ('44,5 %', 'del listado comentado'), ('9.618', 'bytes de codigo'), ('6.766', 'bytes de datos'), ('0', 'bytes sin identificar')],
        pie_leg='Esto es trabajo de documentacion y preservacion: el codigo y los graficos siguen siendo de sus autores y de Konami, y la imagen del cartucho no se distribuye.',
        aviso='<b>Aqui no hay ninguna captura.</b> Todas las imagenes estan <b>dibujadas desde los bytes de la ROM</b>, ejecutando en Python el mismo interprete de guiones que corre el Z80. El listado y las cifras se reproducen con <code>make</code>.',
    ),
    'en': dict(
        titulo="Konami's Baseball - a commented disassembly",
        claim="The screen's three thirds painted with a single loop that reads its own output, the twelve teams of the 1984 Japanese league hidden in twelve letters, and a computer opponent that plays by writing into the joystick slot.",
        ficha=['Konami - <b>(c) Konami 1984</b>', 'An <b>RC-724</b> 16 KB cartridge', 'MSX1 - <b>page 1</b>', 'Dump <b>06504efb...</b>'],
        h_num='The cartridge in numbers',
        cifras=[('100%', 'of the binary explained'), ('629', 'named routines'), ('44.5%', 'of the listing commented'), ('9,618', 'bytes of code'), ('6,766', 'bytes of data'), ('0', 'bytes unidentified')],
        pie_leg='This is documentation and preservation work: the code and artwork still belong to their authors and to Konami, and the cartridge image is not distributed.',
        aviso='<b>Not one capture here.</b> Every picture is <b>drawn from the bytes of the ROM</b>, by running in Python the same script interpreter the Z80 runs. The listing and the numbers are reproducible with <code>make</code>.',
    ),
}

PAGINAS = [
    [('THE-GAME.html', 'EL-JUEGO.html', 'The game', 'El juego',
      'what the game is and how it plays',
      'qu&eacute; es el juego y c&oacute;mo se juega'),
     ('THE-PICTURES.html', 'LAS-IMAGENES.html', 'What the cartridge draws', 'Lo que el cartucho dibuja',
      'every picture drawn from the ROM, with its caption',
      'todas las im&aacute;genes dibujadas desde la ROM, con su pie'),
     ('THE-MUSIC.html', 'LA-MUSICA.html', 'The music', 'La m&#250;sica',
      'the tunes, from its own sound engine',
      'las m&uacute;sicas, de su propio motor de sonido')],
    [('CURIOSITIES.html', 'CURIOSIDADES.html', 'Curiosities', 'Curiosidades',
      'what turned up when taking it apart, and what is still open',
      'lo que apareci&oacute; al desmontarlo y lo que queda abierto')],
    [('UNDER-THE-HOOD.html', 'POR-DENTRO.html', 'Under the hood', 'Por dentro',
      'getting started, the cartridge, the code and the emulator',
      'empezar, el cartucho, el c&oacute;digo y el emulador')],
]

VIEJAS = {
    'FINDINGS.html': 'CURIOSITIES.html',
    'HALLAZGOS.html': 'CURIOSIDADES.html',
    'GETTING-STARTED.html': 'UNDER-THE-HOOD.html',
    'EMPEZAR.html': 'POR-DENTRO.html',
    'IN-THE-EMULATOR.html': 'UNDER-THE-HOOD.html',
    'EN-EL-EMULADOR.html': 'POR-DENTRO.html',
    'OPEN-QUESTIONS.html': 'CURIOSITIES.html',
    'PREGUNTAS-ABIERTAS.html': 'CURIOSIDADES.html',
    'THE-CARTRIDGE.html': 'UNDER-THE-HOOD.html',
    'EL-CARTUCHO.html': 'POR-DENTRO.html',
    'THE-CODE.html': 'UNDER-THE-HOOD.html',
    'EL-CODIGO.html': 'POR-DENTRO.html',
}

LOGOTIPO = 'rotulo.png'
