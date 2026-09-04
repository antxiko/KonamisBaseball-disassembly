#!/usr/bin/env python3
"""Dibuja para la web todo lo que el cartucho dibuja, desde sus propios bytes.

Aqui no hay ni una captura ni una ilustracion: cada PNG sale de ejecutar en
Python los mismos pasos que ejecuta el Z80 -los dos interpretes de pantalla de
`guiones.py`, la replica de VRAM de 0x442D y el descompresor de figuras de
0x5932- y de pintar la VRAM que queda con las reglas del TMS9918.

Y no se dan por buenos por mirarlos: `--comprueba` vuelca la VRAM del emulador
y la compara byte a byte con la que monta este fichero.

Uso: graficos.py <rom> <org> <carpeta>
     graficos.py --comprueba <rom> <org> <carpeta de volcados>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import guiones                                             # noqa: E402
import pantallas                                           # noqa: E402
import sprites                                             # noqa: E402

ORG = 0x4000
MARGEN_ROTULO = 4       # pixeles de aire alrededor del rotulo recortado


def recorta(img, y0, x0, alto, ancho):
    return [f[x0:x0 + ancho] for f in img[y0:y0 + alto]]


def marco_del_rotulo(v, margen=MARGEN_ROTULO):
    """Donde cae el rotulo, medido en la tabla de nombres y no a ojo.

    El rotulo son las DOS primeras filas de la portada que tienen algo escrito
    -las que la lista de tiles de 0x45D1 llena desde 0x3885 y 0x38A5-, y su
    ancho es el de la columna mas a la izquierda a la mas a la derecha con tile
    distinto de 0, que es el espacio. Sacarlo de aqui y no de cuatro numeros
    escritos a mano evita el fallo obvio: recortar dos pixeles dentro y comerse
    la fila de arriba, o quedarse corto de ancho y partir la ultima palabra.
    """
    celdas = [(i // 32, i % 32) for i in range(768) if v.b[0x3800 + i]]
    filas = sorted({f for f, _ in celdas})[:2]
    cols = [c for f, c in celdas if f in filas]
    y0, y1 = filas[0] * 8, (filas[-1] + 1) * 8
    x0, x1 = min(cols) * 8, (max(cols) + 1) * 8
    return (max(0, y0 - margen), max(0, x0 - margen),
            y1 - y0 + margen * 2, x1 - x0 + margen * 2)


def hoja_de_tiles(v, tercio, cuantos=256, cols=16):
    """Los patrones de un tercio con su color, como los ve el VDP."""
    fuera = []
    for t in range(cuantos):
        base = tercio * 0x800 + t * 8
        m = [[0] * 8 for _ in range(8)]
        for y in range(8):
            forma = v.b[pantallas.PATRONES + base + y]
            color = v.b[pantallas.COLORES + base + y]
            tinta, fondo = color >> 4, color & 0x0F
            for x in range(8):
                m[y][x] = tinta if (forma >> (7 - x)) & 1 else fondo
        fuera.append(m)
    return fuera


def rejilla(lienzos, cols, sep=1, fondo=1):
    """Pone una lista de matrices en una cuadricula, con separacion."""
    alto = max(len(l) for l in lienzos)
    ancho = max(len(l[0]) for l in lienzos)
    filas = (len(lienzos) + cols - 1) // cols
    an = cols * (ancho + sep) + sep
    al = filas * (alto + sep) + sep
    img = [[fondo] * an for _ in range(al)]
    for i, l in enumerate(lienzos):
        cx = (i % cols) * (ancho + sep) + sep
        cy = (i // cols) * (alto + sep) + sep
        for y, fila in enumerate(l):
            for x, c in enumerate(fila):
                img[cy + y][cx + x] = c
    return img


def dibuja_al_juez(rom, v):
    """Las tres caras del juez, que son 2x2 tiles de la tabla de nombres."""
    d = rom[0x715D - ORG:0x7169 - ORG]
    fuera = []
    for i in range(3):
        tiles = list(d[i * 4:i * 4 + 4])
        m = [[0] * 16 for _ in range(16)]
        for k, t in enumerate(tiles):
            cx, cy = (k % 2) * 8, (k // 2) * 8
            base = 0x800 + t * 8            # el juez cae en el tercio 1
            for y in range(8):
                forma = v.b[pantallas.PATRONES + base + y]
                color = v.b[pantallas.COLORES + base + y]
                tinta, fondo = color >> 4, color & 0x0F
                for x in range(8):
                    m[cy + y][cx + x] = tinta if (forma >> (7 - x)) & 1 else fondo
        fuera.append(m)
    return fuera


def dibuja_al_recogepelotas(rom):
    """Los cinco grupos de 0x776C, cada uno con sus capas superpuestas.

    Estos no llevan tabla de parejas: 0x78A0 los descomprime seguidos en la
    VRAM y luego les suma la misma posicion, asi que las capas se apilan.
    """
    colores = [11, 1, 4, 15, 11]
    fuera = []
    for i in range(5):
        g = sprites.pal(rom, 0x776C + i * 2)
        lienzo = [[0] * 16 for _ in range(16)]
        for k in range(4, -1, -1):
            p = sprites.pal(rom, g + 1 + k * 2)
            if p >> 8 == 0:
                continue
            m = sprites.rejilla(sprites.descomprime(rom, p - ORG)[0])
            for y in range(16):
                for x in range(16):
                    if m[y][x]:
                        lienzo[y][x] = colores[k]
        fuera.append(lienzo)
    return fuera


def fuente(v):
    """El alfabeto del cartucho: A=0xD1 y de ahi seguido, sin Q, con la X en 0xE8."""
    return [hoja_de_tiles(v, 0)[t] for t in list(range(0xD1, 0xEB))
            + list(range(0xF0, 0xFA))]


def main():
    if sys.argv[1] == "--comprueba":
        return comprueba(sys.argv[2], int(sys.argv[3], 0), sys.argv[4])
    rom = open(sys.argv[1], "rb").read()
    carpeta = sys.argv[3]
    os.makedirs(carpeta, exist_ok=True)

    def png(nombre, img, escala=3):
        pantallas.png(os.path.join(carpeta, nombre), img, escala)
        print("  %s" % nombre)

    portada = pantallas.portada(rom)
    pista = pantallas.pista(rom)
    ip, iq = pantallas.pinta(portada), pantallas.pinta(pista)

    png("rotulo.png", recorta(ip, *marco_del_rotulo(portada)), escala=4)
    png("portada.png", ip)
    png("pista.png", iq)
    png("juez.png", rejilla(dibuja_al_juez(rom, pista), 3, sep=2), escala=6)
    png("recogepelotas.png",
        rejilla(dibuja_al_recogepelotas(rom), 5, sep=2), escala=6)
    png("tiles.png", rejilla(hoja_de_tiles(pista, 0), 16, sep=1), escala=3)
    png("fuente.png", rejilla(fuente(portada), 15, sep=1), escala=4)

    # Las figuras: una hoja por ficha, que es donde estan los colores.
    vistas = [(p, q) for _, d, p, q in sprites.posturas(rom) if d]
    for j, col in enumerate(sprites.colores_de_las_fichas(rom)):
        lienzos = [l for l in (sprites.monta(rom, p, q, col)
                               for p, q in vistas) if l]
        sprites.png(os.path.join(carpeta, "posturas_%d.png" % (j + 1)),
                    lienzos, cols=13, escala=3)
        print("  posturas_%d.png (%d figuras)" % (j + 1, len(lienzos)))

    # La raqueta que no usa nadie: se descomprime a un sprite valido de 16x16
    # pero ninguna de las 37 descripciones de postura la apunta.
    huerfana = sprites.rejilla(sprites.descomprime(rom, 0x61F5 - ORG)[0])
    sprites.png(os.path.join(carpeta, "raqueta_sin_usar.png"),
                [[[11 if c else 0 for c in f] for f in huerfana]],
                cols=1, escala=10)
    print("  raqueta_sin_usar.png")

    bolas = []
    for a, b in sprites.pelotas(rom):
        for q in (a, b):
            bolas.append([[10 if c else 0 for c in f] for f in
                          sprites.rejilla(sprites.descomprime(rom, q - ORG)[0])])
    sprites.png(os.path.join(carpeta, "pelota.png"), bolas, cols=10, escala=5)
    print("  pelota.png")
    return 0


def comprueba(ruta_rom, org, carpeta):
    """Compara byte a byte lo que monta este fichero con la VRAM del emulador.

    Se saltan los volcados tomados antes de que INIT cargue los registros del
    VDP -ahi la pantalla todavia no esta montada- y los 32 bytes de color de
    los tiles 0xA5 a 0xA8, que son los del rotulo de falta: 0x746F alterna dos
    juegos de color sobre ellos cada siete cuadros, asi que su valor depende
    del cuadro exacto en que se tomo el volcado y no puede coincidir siempre.
    """
    import glob
    rom = open(ruta_rom, "rb").read()
    P = {"portada": pantallas.portada(rom), "pista": pantallas.pista(rom)}
    REGS = "02 E2 0E 7F 07 76 03 E1"
    PARPADEO = set(range(0x0528, 0x0548))       # color de los tiles 0xA5-0xA8

    total = distintos = usados = 0
    for f in sorted(glob.glob(os.path.join(carpeta, "vram_*.bin"))):
        info = f.replace("vram_", "info_").replace(".bin", ".txt")
        if not os.path.exists(info):
            continue
        lineas = open(info).read().splitlines()
        etiqueta = lineas[0].split()[1]
        if lineas[2].split(None, 1)[1].strip() != REGS:
            continue                            # aun arrancando
        v = P.get("portada" if etiqueta in ("portada", "menu") else "pista")
        if v is None:
            continue
        real = open(f, "rb").read()
        d = 0
        for i in list(range(0x0000, 0x1800)) + list(range(0x2000, 0x3800)):
            if not v.tocado[i] or i in PARPADEO:
                continue
            total += 1
            if v.b[i] != real[i]:
                d += 1
        if d:
            print("  %s (%s): %d distintos" % (os.path.basename(f), etiqueta, d))
        distintos += d
        usados += 1
    print("%d volcados, %d bytes comparados, %d distintos"
          % (usados, total, distintos))
    return 0 if distintos == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
