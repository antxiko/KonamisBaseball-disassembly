#!/usr/bin/env python3
"""Las pantallas del cartucho, montadas ejecutando lo que ejecuta la ROM.

No hay ninguna captura aqui dentro. Se reproduce la secuencia de arranque tal
como la hace el cartucho -guion, replica, borrado y tabla de nombres, en ese
orden- y se revela la VRAM que queda. Si el dibujo sale bien es porque el
interprete de `guiones.py` es correcto, no porque se haya mirado una foto.

LA PORTADA, como la monta 0x40cc:
    0x40d1  guion 0x47cf ................. patrones, colores y tabla de nombres
    0x40e2  guion 0x4a96
    0x40d6  guion 0x4a27 en VRAM 0x6680
    0x40e7  guion 0x49d4 en VRAM 0x6780
    0x40f9  replica de VRAM 0x0000 -> 0x0800 (4095 bytes) .......... colores
    0x4102  replica de VRAM 0x2000 -> 0x2800 (4095 bytes) ......... patrones

EL MENU, como lo monta 0x4167:
    0x4472  borrado de la tabla de nombres
    0x4464  los tres guiones encadenados que empiezan en 0x46d4

LA PARRILLA DE EQUIPOS, como la monta 0x41a5:
    0x46f3 o 0x46ff  el rotulo de uno o de dos jugadores
    0x470c y 0x4718  las dos filas de opciones
    0x4725 o 0x4745  la parrilla con los nombres de los equipos

EL CAMPO, como lo monta 0x4219:
    0x421e  borrado de la tabla de nombres
    0x4226  guion 0x65ad .................... patrones y colores del estadio
    0x4231  replica de VRAM 0x0000 -> 0x0800
    0x423a  replica de VRAM 0x2000 -> 0x2800
    0x4243  guion 0x6a1c ............................. la tabla de nombres

LA REPLICA es el truco mas bonito del cartucho, y es el mismo que usan sus
hermanos de la familia. 0x4485 copia byte a byte de VRAM a VRAM, y le mandan
copiar 4095 bytes de 0x0000 a 0x0800: como el origen alcanza al destino a
mitad de camino, lo que ya escribio se vuelve a leer y un solo bucle deja los
TRES tercios de la pantalla iguales. Un tercio de patrones y de colores vale
para los tres, y el cartucho se ahorra 4 KB. Se queda un byte corto: 4095 y no
4096, asi que el ultimo byte del tercer tercio no se llega a escribir.

Los registros del VDP los pone 0x40b7 con la tabla de 0x46cc:
    02 E2 0E 7F 07 76 03 E1
Y OJO CON ESTOS DOS, que es facil leerlos al reves. En SCREEN 2 el TMS9918 no
toma R3 y R4 como una direccion, sino como un bit de base y una mascara:

    R4 = 0x07  patrones = (R4 and 0x04) * 0x800 = 0x2000
    R3 = 0x7F  colores  = (R3 and 0x80) * 0x40  = 0x0000

o sea que este cartucho pone la tabla de COLORES DEBAJO de la de patrones, al
reves de la colocacion habitual. Leerlo del otro modo da una pantalla en la
que las formas se reconocen -porque los dos bloques son simetricos- pero los
colores salen a franjas, que es justo el sintoma.

El resto: nombres en 0x3800 (R2), patrones de sprite en 0x1800 (R6) y
atributos de sprite en 0x3B00 (R5).

Uso: pantallas.py <rom> <org> <carpeta>          dibuja los png
     pantallas.py <rom> <org> <carpeta> --vram   ademas vuelca la VRAM cruda
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import guiones                                            # noqa: E402
from guiones import Vram                                  # noqa: E402

NOMBRES = 0x3800
PATRONES = 0x2000
COLORES = 0x0000
SPR_PATRONES = 0x1800

PALETA = [
    (0, 0, 0), (0, 0, 0), (33, 200, 66), (94, 220, 120),
    (84, 85, 237), (125, 118, 252), (212, 82, 77), (66, 235, 245),
    (252, 85, 84), (255, 121, 120), (212, 193, 84), (230, 206, 128),
    (33, 176, 59), (201, 91, 186), (204, 204, 204), (255, 255, 255),
]


# ----------------------------------------------------------------- revelado
def revela(vram, x0=0, y0=0, ancho=32, alto=24):
    """Convierte la VRAM en una imagen: (ancho*8) x (alto*8) pixeles."""
    w, h = ancho * 8, alto * 8
    img = [[0] * w for _ in range(h)]
    for fila in range(alto):
        for col in range(ancho):
            f, c = y0 + fila, x0 + col
            tile = vram.b[NOMBRES + f * 32 + c]
            tercio = f // 8
            base = tercio * 0x800 + tile * 8
            for y in range(8):
                pat = vram.b[PATRONES + base + y]
                cl = vram.b[COLORES + base + y]
                tinta, fondo = cl >> 4, cl & 0x0F
                for x in range(8):
                    v = tinta if (pat >> (7 - x)) & 1 else fondo
                    img[fila * 8 + y][col * 8 + x] = v or 1
    return img


def revela_sprites(vram, cuantos=64, por_fila=8, grandes=True):
    """La hoja de patrones de sprite, tal como estan en 0x1800."""
    lado = 16 if grandes else 8
    filas = (cuantos + por_fila - 1) // por_fila
    w, h = por_fila * lado, filas * lado
    img = [[1] * w for _ in range(h)]
    for n in range(cuantos):
        fx, fy = (n % por_fila) * lado, (n // por_fila) * lado
        base = SPR_PATRONES + n * (32 if grandes else 8)
        for cuarto in range(4 if grandes else 1):
            dx = 8 if cuarto >= 2 else 0
            dy = 8 if cuarto % 2 else 0
            for y in range(8):
                b = vram.b[base + cuarto * 8 + y]
                for x in range(8):
                    if (b >> (7 - x)) & 1:
                        img[fy + dy + y][fx + dx + x] = 15
    return img


# --------------------------------------------------------------- escritura
def png(ruta, img, escala=2):
    """Escribe un PNG de color indexado sin depender de nada de fuera."""
    import struct
    import zlib

    alto, ancho = len(img), len(img[0])
    crudo = bytearray()
    for fila in img:
        for _ in range(escala):
            crudo.append(0)
            for v in fila:
                crudo.extend([v] * escala)
    paleta = bytearray()
    for r, g, b in PALETA:
        paleta.extend([r, g, b])

    def trozo(tipo, datos):
        return (struct.pack(">I", len(datos)) + tipo + datos
                + struct.pack(">I", zlib.crc32(tipo + datos) & 0xFFFFFFFF))

    with open(ruta, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(trozo(b"IHDR", struct.pack(">IIBBBBB", ancho * escala,
                                           alto * escala, 8, 3, 0, 0, 0)))
        f.write(trozo(b"PLTE", bytes(paleta)))
        f.write(trozo(b"IDAT", zlib.compress(bytes(crudo), 9)))
        f.write(trozo(b"IEND", b""))


# ------------------------------------------------------------- las escenas
def portada(rom):
    """La pantalla de titulo, montada como la monta 0x40cc."""
    v = Vram()
    guiones.encadena(rom, 0x47CF, v)
    guiones.encadena(rom, 0x4A96, v)
    v.sitio(0x6680)
    guiones.cuerpo(rom, 0x4A27, v)
    v.sitio(0x6780)
    guiones.cuerpo(rom, 0x49D4, v)
    guiones.replica(v, 0x0000, 0x0800)
    guiones.replica(v, 0x2000, 0x2800)
    return v


def presentacion(rom, subidas=0):
    """El logotipo que sube por la pantalla, como lo dibuja bucle_principal.

    0x4118 deja el puntero de escena en 0x7a8b y 0x4136 escribe ahi tres filas
    de tiles CORRELATIVOS -3, 11 y 12- mas una cuarta de relleno; cada cuatro
    cuadros el puntero baja 0x20, o sea una fila, y el bloque entero sube.
    """
    v = portada(rom)
    dir_ = 0x7A8B - 0x20 * subidas
    dir_ = guiones.tiles_correlativos(v, dir_, 0x00, 3)
    dir_ = guiones.tiles_correlativos(v, dir_, 0x03, 11)
    guiones.tiles_correlativos(v, dir_, 0x0E, 12)
    return v


def menu(rom):
    """El menu de uno o dos jugadores, como lo monta 0x4167."""
    v = portada(rom)
    guiones.borra_tabla_de_nombres(v)
    p = 0x46D4
    for _ in range(3):
        p = guiones.encadena(rom, p, v)
    # 0x44b7: el rotulo del juego, dos filas de 23 tiles correlativos.
    guiones.tiles_correlativos(v, 0x7885, 0x40, 23)
    guiones.tiles_correlativos(v, 0x78A5, 0x57, 23)
    return v


def ligas(rom, dos_jugadores):
    """La eleccion de liga, que 0x41a5 dibuja DEBAJO del menu sin borrarlo."""
    v = menu(rom)
    guiones.encadena(rom, 0x46FF if dos_jugadores else 0x46F3, v)
    p = 0x470C
    for _ in range(2):
        p = guiones.encadena(rom, p, v)
    return v


def parrilla(rom, pacifico):
    """La parrilla de equipos de una liga, como la monta 0x41c5 y 0x41de."""
    v = ligas(rom, False)
    guiones.encadena(rom, 0x4718 if pacifico else 0x470C, v)
    guiones.encadena(rom, 0x4745 if pacifico else 0x4725, v)
    return v


def campo(rom):
    """El estadio, como lo monta 0x4219."""
    v = Vram()
    guiones.borra_tabla_de_nombres(v)
    guiones.encadena(rom, 0x65AD, v)
    guiones.replica(v, 0x0000, 0x0800)
    guiones.replica(v, 0x2000, 0x2800)
    guiones.encadena(rom, 0x6A1C, v)
    return v


TABLA_POSTURAS = 0x5048


# Los tres colores con los que se pintan las tres capas de un jugador: salen
# de los registros de arranque de 0x5bd9, bytes 12, 16 y 20 (1 negro, 7 cian y
# 10 amarillo oscuro).
COLORES_CAPAS = (1, 7, 10)


def posturas(rom):
    """La hoja de posturas de los jugadores, sacada de sus propios guiones.

    Un jugador es TRES SPRITES DE 16x16 SUPERPUESTOS, uno por color, y cada
    postura trae los tres patrones enteros: el cartucho no los guarda todos en
    VRAM, los sube cada vez que la postura cambia.

    0x5dce coge de la tabla de 0x5048 un registro de cuatro palabras -tres
    guiones de 32 bytes, uno por capa, y un puntero a los desplazamientos-, los
    descomprime en 0x1880 y siguientes, y luego escribe los tres atributos con
    los desplazamientos sumados. Los colores vienen de la ficha del jugador.
    """
    def pal(a):
        return rom[a - guiones.ORG] | rom[a - guiones.ORG + 1] << 8

    def byt(a):
        return rom[a - guiones.ORG]

    vistas = []
    for i in range(32):
        t = pal(TABLA_POSTURAS + 2 * i)
        if t and t not in vistas:
            vistas.append(t)

    salida = []
    for t in vistas:
        capas = []
        for r in range(3):
            v = Vram()
            v.sitio(0x5800)                       # 0x1800 tras enmascarar
            guiones.cuerpo(rom, pal(t + 2 * r), v)
            capas.append(bytes(v.b[0x1800:0x1820]))
        at = pal(t + 6)
        desp = [(byt(at + 2 * k), byt(at + 2 * k + 1)) for k in range(3)]
        salida.append((capas, desp))
    return salida


def _pinta_sprite(img, patron, x0, y0, color):
    """Un sprite de 16x16 en la imagen: cuatro cuartos de ocho bytes."""
    for cuarto in range(4):
        dx = 8 if cuarto >= 2 else 0
        dy = 8 if cuarto % 2 else 0
        for y in range(8):
            b = patron[cuarto * 8 + y]
            for x in range(8):
                if (b >> (7 - x)) & 1:
                    fy, fx = y0 + dy + y, x0 + dx + x
                    if 0 <= fy < len(img) and 0 <= fx < len(img[0]):
                        img[fy][fx] = color


def hoja_de_posturas(rom, por_fila=6):
    """Las 22 posturas, cada una con sus tres capas puestas una encima de otra
    en el sitio exacto que dicen sus desplazamientos."""
    poses = posturas(rom)
    celda = 32
    filas = (len(poses) + por_fila - 1) // por_fila
    w, h = por_fila * celda, filas * celda
    img = [[14] * w for _ in range(h)]           # gris, para que el negro se vea
    for n, (capas, desp) in enumerate(poses):
        cx = (n % por_fila) * celda + 8
        cy = (n // por_fila) * celda + 8
        for k in range(3):
            dy, dx = desp[k]
            dy = dy - 256 if dy > 127 else dy
            dx = dx - 256 if dx > 127 else dx
            _pinta_sprite(img, capas[k], cx + dx, cy + dy, COLORES_CAPAS[k])
    return img


def fuente(rom):
    """La fuente entera, los tiles 0xD0 a 0xFF puestos en tres filas."""
    v = menu(rom)
    guiones.borra_tabla_de_nombres(v)
    for f in range(3):
        for c in range(16):
            v.b[0x3800 + f * 32 + c] = 0xD0 + f * 16 + c
    return v


ESCENAS = [
    ("presentacion", presentacion, None),
    ("menu", menu, None),
    ("rotulo", menu, (4, 4, 24, 2)),
    ("ligas", lambda r: ligas(r, False), None),
    ("equipos_central", lambda r: parrilla(r, False), None),
    ("equipos_pacifico", lambda r: parrilla(r, True), None),
    ("campo", campo, None),
    ("fuente", fuente, (0, 0, 16, 3)),
]


def main(rompath, org, carpeta, vuelca=False):
    rom = open(rompath, "rb").read()
    guiones.ORG = org
    os.makedirs(carpeta, exist_ok=True)
    for nombre, hacer, recorte in ESCENAS:
        v = hacer(rom)
        img = revela(v, *(recorte or (0, 0, 32, 24)))
        png(os.path.join(carpeta, nombre + ".png"), img)
        print(f"  {nombre}.png")
        if vuelca:
            open(os.path.join(carpeta, nombre + ".vram"), "wb").write(v.b)
    png(os.path.join(carpeta, "posturas.png"), hoja_de_posturas(rom), 3)
    print("  posturas.png")


if __name__ == "__main__":
    if len(sys.argv) < 4:
        print(__doc__)
        sys.exit(1)
    main(sys.argv[1], int(sys.argv[2], 0), sys.argv[3],
         "--vram" in sys.argv)
