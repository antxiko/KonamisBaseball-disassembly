; ==========================================================================
; KONAMI'S BASEBALL - Konami - MSX1 - cartucho RC-724 de 16 KB en la pagina 1
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; Direcciones que solo aparecen como VALOR -en un `ld`, no en
; un salto-: son punteros que el codigo se pasa o numeros que
; casualmente coinciden con una direccion. No hay nada que
; trazar en ellas; el equ existe para que el listado ensamble.
; ----------------------------------------------------------------------
l766fh:	equ 0x0766f
l7670h:	equ 0x07670

; ----------------------------------------------------------------------
; DATOS cabecera_del_cartucho: AB y la direccion de INIT; el resto a cero
;   0x4000..0x4010  (16 bytes)
DATA_cabecera_del_cartucho:
	defw 04241h,04061h,00000h,00000h,00000h,00000h,00000h,00000h	; 4000

; ======================================================================
; CODIGO 0x4010..0x40d4  (196 bytes)
; ======================================================================


interrupcion:		; El manejador que INIT engancha en H.KEYI. Todo el juego corre aqui dentro, igual que en King's Valley. Lee el estado del VDP para reconocer la interrupcion, se protege con DOS candados (0xE01E y 0xE01F) para no reentrar mientras hay una escritura de VRAM a medias, lleva el contador de fotogramas de 0xE000 y despacha el trabajo del cuadro; al final vuelve a leer el estado del VDP y, si hay otra interrupcion pendiente, se re-ejecuta a si mismo
	call 0013eh		;4010   ; BIOS RDVDP - Reads VDP status register | lee el registro de estado del VDP: reconoce la interrupcion y la borra
	ld hl,0e01dh		;4013   ; (0xE01D) := 1: la senal de "estoy dentro de la interrupcion" que espera el bucle de L_4689
	ld (hl),001h		;4016
	inc hl			;4018   ; (0xE01E): si hay una escritura de VRAM a medias, la interrupcion no toca nada
	ld a,(hl)			;4019
	or a			;401a
	ret nz			;401b
	inc hl			;401c   ; (0xE01F): el segundo candado, contra la reentrada
	ld a,(hl)			;401d
	or a			;401e
	ret nz			;401f
	ld (hl),001h		;4020   ; y lo cierra para este cuadro
	ld hl,0e000h		;4022   ; HL = 0xE000, el contador de fotogramas
	inc (hl)			;4025   ; un fotograma mas
	ld a,(hl)			;4026
	and 01fh		;4027   ; cada 32 fotogramas, ademas...
	jr nz,L_402D		;4029
	inc hl			;402b
	dec (hl)			;402c   ; ...baja en uno el contador lento de 0xE001
L_402D:
	call lee_entrada_del_menu		;402d   ; el trabajo fijo de cada cuadro (0x43f5)
	ld a,(0e002h)		;4030   ; (0xE002) elige entre dos cuerpos de juego distintos
	or a			;4033
	jr z,L_403B		;4034
	call pilota_la_demostracion		;4036   ; con el puesto: 0x7fce
	jr L_403E		;4039
L_403B:
	call lee_entrada_de_los_jugadores		;403b   ; a cero: 0x43a6
L_403E:
	call mueve_el_sonido		;403e   ; el motor de sonido (0x6cae), que corre siempre
	di			;4041
	ld a,(0e003h)		;4042   ; (0xE003): solo con la partida en marcha corren las tres rutinas de abajo
	or a			;4045
	jr z,L_4051		;4046
	call dibuja_lo_que_se_ha_movido		;4048
	call lleva_el_medidor		;404b
	call lleva_los_contadores		;404e
L_4051:
	xor a			;4051   ; (0xE01F) := 0: se abre el candado de reentrada
	ld (0e01fh),a		;4052
	inc a			;4055   ; (0xE01D) := 1
	ld (0e01dh),a		;4056
	call 0013eh		;4059   ; BIOS RDVDP - Reads VDP status register | vuelve a leer el estado del VDP
	rlca			;405c   ; bit 7: si hay OTRA interrupcion pendiente, se re-ejecuta entera en vez de volver
	jp c,interrupcion		;405d
	ret			;4060
arranca_el_juego:		; El INIT que declara la cabecera. Engancha la interrupcion a mano -0xC3 en H.KEYI y 0x4010 detras-, borra 0xE000-0xE7FE con un ldir y deja la pila justo ahi, silencia el PSG, dibuja el guion de arranque y entra en el bucle principal. Mismo patron que King's Valley
	di			;4061   ; sin interrupciones hasta tener el gancho puesto
	ld hl,0fd9ah		;4062   ; HL = 0xFD9A, el gancho H.KEYI de la BIOS
	ld (hl),0c3h		;4065   ; un 0xC3 = `jp`, fabricado a mano
	ld hl,interrupcion		;4067   ; y detras la direccion del manejador
	ld (0fd9bh),hl		;406a
	ld hl,0e000h		;406d   ; borra 0xE000-0xE7FE propagando un cero con ldir
	ld de,0e001h		;4070
	ld bc,007feh		;4073
	ld (hl),l			;4076   ; el primer byte a cero: L vale 0x00 en este punto
	ldir		;4077
	ld sp,hl			;4079   ; la pila queda al final de lo borrado (0xE7FF)
	ld a,0b8h		;407a   ; (0xE660) := 0xB8, el valor del mezclador del PSG
	ld (0e660h),a		;407c
	call escribe_el_registro_7		;407f   ; arranca el motor de sonido
	ld a,008h		;4082   ; los registros 8, 9 y 10 del PSG (los tres volumenes) a cero
	ld e,000h		;4084
	ld b,003h		;4086
L_4088:
	call 00093h		;4088   ; BIOS WRTPSG - Writes data to PSG-register
	inc a			;408b
	djnz L_4088		;408c
	ld de,081a2h		;408e   ; DE = 0x81A2 como direccion de VRAM: arma la escritura ahi
	call arma_escritura_vram		;4091
	ld a,00fh		;4094   ; registro 15 del PSG
	ld e,0cfh		;4096
	call 00093h		;4098   ; BIOS WRTPSG - Writes data to PSG-register
	call 00132h		;409b   ; BIOS CHGCAP - Alternates the CAPS lamp status | enciende el piloto de CAPS
	im 1		;409e   ; modo de interrupcion 1
	di			;40a0
	ld de,04000h		;40a1   ; DE = 0x4000: borra los 16 KB de VRAM de un tiron
	call arma_escritura_vram		;40a4
L_40A7:
	ld b,e			;40a7
	ld a,e			;40a8
	call rellena_vram		;40a9
	dec d			;40ac
	jr nz,L_40A7		;40ad
	call 00096h		;40af   ; BIOS RDPSG - Reads value from PSG-register
	ld a,001h		;40b2
	ld (0e01eh),a		;40b4
	ld hl,046cch		;40b7   ; HL = tabla_registros_vdp, los ocho valores de R0 a R7
	ld d,008h		;40ba   ; D = 8 registros, C = el numero del primero
	ld c,000h		;40bc
carga_registros_vdp:		; Escribe los ocho valores de tabla_registros_vdp en R0 a R7, subiendo a la vez el puntero y el numero de registro
	ld b,(hl)			;40be   ; B = el valor de este registro
	call 00047h		;40bf   ; BIOS WRTVDP - Writes data in the VDP-register | WRTVDP: lo programa
	inc hl			;40c2   ; siguiente valor
	inc c			;40c3   ; siguiente numero de registro
	dec d			;40c4
	jr nz,carga_registros_vdp		;40c5   ; hasta los ocho
	xor a			;40c7
	ld (0e01eh),a		;40c8
	ei			;40cb
carga_los_graficos:		; Segunda mitad del arranque: descomprime en VRAM los cuatro guiones grandes de graficos -dos por el interprete y dos por 0x4485- y deja preparado el primer estado del juego
	ld a,001h		;40cc   ; A = 1 para 0x44ae
	call espera_pasos_de_contador		;40ce
	call dibuja_el_guion_de_aqui_al_lado		;40d1

; ----------------------------------------------------------------------
; DATOS guion_incrustado_40d4: Argumento del `call 0x4582` de 0x40d1: el guion
;   de 0x47cf, el primero que dibuja el arranque
;   0x40d4..0x40d6  (2 bytes)
DATA_guion_incrustado_40d4:
	defw 047cfh	; 40d4  -> DATA_guiones_de_los_graficos

; ======================================================================
; CODIGO 0x40d6..0x40e5  (15 bytes)
; ======================================================================


	ld de,06680h		;40d6   ; DE = VRAM 0x6680 (0x2680 tras enmascarar): destino del primer guion
	ld hl,04a27h		;40d9   ; HL = el guion de 0x4a27
	call arma_escritura_vram		;40dc   ; arma la escritura ahi
	call lee_comando_de_guion		;40df   ; y lo descomprime
	call dibuja_el_guion_de_aqui_al_lado		;40e2

; ----------------------------------------------------------------------
; DATOS guion_incrustado_40e5: Argumento del `call 0x4582` de 0x40e2: el guion
;   de 0x4a96
;   0x40e5..0x40e7  (2 bytes)
DATA_guion_incrustado_40e5:
	defw 04a96h	; 40e5

; ======================================================================
; CODIGO 0x40e7..0x4229  (322 bytes)
; ======================================================================


	ld de,06780h		;40e7   ; DE = VRAM 0x6780: destino del segundo
	call arma_escritura_vram		;40ea
	ld hl,049d4h		;40ed   ; HL = el guion de 0x49d4
	call lee_comando_de_guion		;40f0
	ld de,00000h		;40f3   ; DE = VRAM 0x0000: la tabla de COLOR entera
	ld hl,04800h		;40f6   ; HL = el guion de 0x4800
	call replica_el_tercio_en_los_otros_dos		;40f9
	ld de,02000h		;40fc   ; DE = VRAM 0x2000: la tabla de PATRON entera
	ld hl,06800h		;40ff   ; HL = el guion de 0x6800
	call replica_el_tercio_en_los_otros_dos		;4102
	ld de,bucle_principal		;4105
	ld c,030h		;4108
	ldir		;410a
	ld a,008h		;410c
	ld (0e001h),a		;410e   ; (0xE001) := 8, el contador lento que baja la interrupcion cada 32 cuadros
	ei			;4111
	ld a,(0e006h)		;4112   ; (0xE006): SUPOSICION, marca si ya se ha pasado por el menu
	or a			;4115
	jr nz,monta_el_menu		;4116
	ld hl,07a8bh		;4118   ; (0xE700) := 0x7a8b: el puntero de la escena que toca
	ld (0e700h),hl		;411b
bucle_principal:		; El bucle principal, que corre con la interrupcion suelta: cada cuatro fotogramas mira el puntero de escena de 0xE700 y, mientras no sea el de cierre (0x786b), redibuja las tres franjas de la pantalla
	ld hl,0e000h		;411e   ; HL = 0xE000, el contador de fotogramas
	ld a,(hl)			;4121
	and 003h		;4122   ; uno de cada cuatro
	jr nz,mira_si_alguien_pulsa		;4124
	inc (hl)			;4126   ; sube el contador dos veces mas: el ciclo es de cuatro en cuatro
	inc (hl)			;4127
	ld de,(0e700h)		;4128   ; DE = (0xE700), el puntero de la escena actual
	ld hl,0786bh		;412c   ; contra 0x786b, el puntero de cierre
	xor a			;412f
	sbc hl,de		;4130
	jr z,mira_si_se_acaba_la_presentacion		;4132   ; si coincide, no hay nada que redibujar
	di			;4134
	xor a			;4135
	ld b,003h		;4136   ; las tres franjas de la pantalla, una por llamada
	call escribe_tiles_correlativos		;4138
	ld b,00bh		;413b
	call escribe_tiles_correlativos		;413d
	ld b,00ch		;4140
	call escribe_tiles_correlativos		;4142
	ld b,00ch		;4145
	call arma_escritura_vram		;4147   ; y el relleno que las remata
	xor a			;414a
	call arma_y_rellena		;414b
	ei			;414e
	ld hl,0e700h		;414f
	ld a,(hl)			;4152
	sub 020h		;4153
	ld (hl),a			;4155
	jr nc,mira_si_se_acaba_la_presentacion		;4156
	inc hl			;4158
	dec (hl)			;4159
mira_si_se_acaba_la_presentacion:		; Al final de cada vuelta de la presentacion: mientras el contador lento de 0xE001 no llegue a cero se sigue con la escena, y si alguien pulsa algo se corta antes de tiempo
	ld a,(0e001h)		;415a   ; (0xE001), el contador lento que baja la interrupcion cada 32 cuadros
	or a			;415d
	jr z,monta_el_menu		;415e   ; a cero: se acabo el tiempo de la escena, al menu
mira_si_alguien_pulsa:		; Con tiempo de sobra, la presentacion solo se corta si hay algo pulsado: los seis bits utiles de 0xE005 son la lectura del cuadro
	ld a,(0e005h)		;4160   ; (0xE005), lo que dejo lee_entrada_del_menu en este cuadro
	and 03fh		;4163   ; los seis bits utiles: cuatro direcciones y dos botones
	jr z,bucle_principal		;4165   ; nada pulsado: otra vuelta de presentacion
monta_el_menu:		; Deja la pantalla lista para elegir: borra la tabla de nombres entera, dibuja los tres guiones de 0x46d4, pone la marca en su sitio, se da 8 pasos de contador -unos ocho segundos- y arranca los dos cursores en 4 y en 2
	di			;4167   ; sin interrupciones mientras se rehace la pantalla
	call borra_y_dibuja_el_menu		;4168   ; borra la pantalla y dibuja los tres guiones del menu
	call pinta_la_marca_del_menu		;416b   ; pinta la marca del jugador en la fila que le toca
	ld a,008h		;416e   ; (0xE001) := 8: el plazo del menu antes de volver a la presentacion
	ld (0e001h),a		;4170
	ei			;4173
	ld hl,0e441h		;4174   ; (0xE441) := 4 y (0xE442) := 2: la posicion de partida de los dos cursores
	ld (hl),004h		;4177
	inc hl			;4179
	ld (hl),002h		;417a
espera_en_el_menu:		; El bucle del menu. Cada vuelta pone 0xE002 a cero y solo lo sube a 1 si NO se ha pulsado el boton: con 0xE002 a 1 la interrupcion deja de leer los mandos y llama a 0x7fce, que es el piloto automatico de la demostracion. Si se agota el plazo de 0xE001 se salta a preparar la partida igual
	call decide_repeticion		;417c   ; mira el mando y decide si esta pulsada la repeticion
	ld hl,0e002h		;417f   ; (0xE002) := 0: la interrupcion vuelve a leer los mandos de verdad
	ld (hl),000h		;4182
	jr c,elige_numero_de_jugadores		;4184   ; con el boton pulsado, a elegir el numero de jugadores
	ld (hl),001h		;4186   ; (0xE002) := 1: manda el piloto automatico de 0x7fce
	ld a,(0e001h)		;4188   ; y si ademas se agoto el plazo, la partida arranca sola
	or a			;418b
	jp z,prepara_la_partida		;418c
	jr espera_en_el_menu		;418f   ; otra vuelta
elige_numero_de_jugadores:		; Del bit 0 de 0xE00A -el que mueve arriba y abajo decide_repeticion- sale el numero de jugadores en 0xE012 y el guion que hay que hacer parpadear encima de la linea elegida: 0x46f3 para 1 PLAYER y 0x46ff para 2 PLAYERS
	xor a			;4191
	ld hl,0e00ah		;4192   ; HL = 0xE00A, la opcion que se estaba moviendo en el menu
	ld a,(hl)			;4195
	and 001h		;4196   ; su bit 0 es el numero de jugadores...
	ld (0e012h),a		;4198   ; ...y va a 0xE012, que es lo que mira todo el resto del cartucho
	ld a,(hl)			;419b
	ld hl,046f3h		;419c   ; HL = el guion del rotulo de un jugador
	rrca			;419f   ; el bit 0 otra vez, ahora al acarreo
	jr nc,dibuja_la_eleccion_de_liga		;41a0
	ld hl,046ffh		;41a2   ; con el bit puesto, el rotulo de dos jugadores
dibuja_la_eleccion_de_liga:		; Hace parpadear la linea de jugadores elegida y, DEBAJO Y SIN BORRAR NADA, escribe las dos ligas: CENTRAL y PACIFIC. Los dos guiones van pegados -0x470c acaba justo donde empieza 0x4718-, asi que basta con pedirle dos a dibuja_varios_guiones
	call dibuja_parpadeando		;41a5   ; hace parpadear la linea elegida, 64 cuadros
	ld hl,0470ch		;41a8   ; HL = 0x470c, el guion de CENTRAL
	ld b,002h		;41ab   ; dos guiones: CENTRAL y, pegado, PACIFIC
	call dibuja_varios_guiones		;41ad
	call pinta_la_marca_del_menu		;41b0   ; y la marca encima
espera_a_que_pulsen:		; Se queda dando vueltas hasta que decide_repeticion devuelva acarreo, o sea hasta que alguien pulse el boton
	call decide_repeticion		;41b3   ; hasta que el acarreo diga que hay boton
	jr nc,espera_a_que_pulsen		;41b6
	ld a,(0e00ah)		;41b8
	ld hl,0470ch		;41bb
	and 001h		;41be
	jr z,elige_la_liga		;41c0
	ld hl,04718h		;41c2
elige_la_liga:		; Guarda la liga elegida en 0xE440 -0 la Central, 1 la Pacific-, la hace parpadear y deja los dos cursores de equipo en el primero y en el cuarto, para que los dos jugadores no empiecen encima del mismo
	ld (0e440h),a		;41c5   ; (0xE440) := el bit 0, la liga: de ahi salen las dos mitades de la tabla de iniciales
	call dibuja_parpadeando		;41c8
	ld hl,0e440h		;41cb   ; HL = 0xE440
	ld a,(hl)			;41ce
	inc hl			;41cf
	ld (hl),000h		;41d0   ; (0xE441) := 0, el equipo del primer jugador
	inc hl			;41d2
	ld (hl),003h		;41d3   ; (0xE442) := 3, el del segundo
	ld hl,04725h		;41d5   ; HL = 0x4725, la parrilla de la Central
	rrca			;41d8   ; el bit de la liga al acarreo otra vez
	jr nc,pinta_la_parrilla_de_equipos		;41d9
	ld hl,04745h		;41db   ; con la Pacific, la parrilla de 0x4745
pinta_la_parrilla_de_equipos:		; Dibuja la parrilla de la liga elegida -las seis iniciales espaciadas encima de la linea de la liga, y la otra liga borrada- y pone la marca del primer jugador en su equipo de partida
	call encadena_guion		;41de   ; dibuja la parrilla entera
	ld hl,0e441h		;41e1
	ld a,(hl)			;41e4
	ld c,001h		;41e5   ; C = +1: el paso del cursor del jugador 1
	call pinta_el_cursor		;41e7
elige_los_equipos:		; El bucle de eleccion: mete en 0x44dc los bits recien pulsados de cada jugador -0xE00E el primero, 0xE011 el segundo- y no sale hasta que los dos hayan confirmado. Con un solo jugador basta con el bit 6 de 0xE441
	ld hl,0e441h		;41ea   ; HL = 0xE441, el cursor del primer jugador
	ld a,(0e00eh)		;41ed   ; (0xE00E), los bits que el jugador 1 acaba de pulsar
	ld c,001h		;41f0   ; C = +1: su cursor avanza hacia arriba en la tabla
	ei			;41f2   ; la interrupcion tiene que seguir corriendo mientras se espera
	call mueve_un_cursor		;41f3
	ld hl,0e442h		;41f6   ; HL = 0xE442, el cursor del segundo
	ld a,(0e011h)		;41f9   ; (0xE011), los suyos
	ld c,0ffh		;41fc   ; C = -1: el segundo recorre la tabla al reves
	ei			;41fe
	call mueve_un_cursor		;41ff
	ld hl,0e441h		;4202
	bit 6,(hl)		;4205   ; el bit 6 es "confirmado": sin el, otra vuelta
	jr z,elige_los_equipos		;4207
	ld a,(0e012h)		;4209   ; (0xE012): con un solo jugador ya no hay nada que esperar
	or a			;420c
	jr z,limpia_los_confirmados		;420d
	inc hl			;420f
	bit 6,(hl)		;4210   ; con dos, tambien el segundo tiene que confirmar
	jr z,elige_los_equipos		;4212
limpia_los_confirmados:		; Baja el bit 6 de los dos cursores antes de seguir
	res 6,(hl)		;4214   ; el del segundo
	dec hl			;4216
	res 6,(hl)		;4217   ; y el del primero
prepara_la_partida:		; Siembra dos semillas de azar con el registro R del Z80, borra la pantalla, vuelve a cargar las dos tablas grandes de VRAM desde 0x4800 y 0x6800, dibuja el estadio y espera a que acabe la musica de 0x95
	ld a,r		;4219   ; A = el registro de refresco del Z80: el azar mas barato que hay
	ld (0e445h),a		;421b   ; (0xE445), la primera semilla
	call borra_la_tabla_de_nombres		;421e   ; borra la tabla de nombres entera
	ld a,r		;4221   ; R otra vez, ya con otro valor
	ld (0e446h),a		;4223   ; (0xE446), la segunda semilla
	call dibuja_el_guion_de_aqui_al_lado		;4226

; ----------------------------------------------------------------------
; DATOS guion_incrustado_4229: Argumento del `call 0x4582` de 0x4226: el guion
;   de 0x65ad, cabeza del segundo bloque grande de guiones
;   0x4229..0x422b  (2 bytes)
DATA_guion_incrustado_4229:
	defw 065adh	; 4229  -> DATA_guiones_65ad

; ======================================================================
; CODIGO 0x422b..0x4246  (27 bytes)
; ======================================================================


	ld de,00000h		;422b   ; DE = VRAM 0x0000: la tabla de COLOR
	ld hl,04800h		;422e   ; HL = 0x4800, su guion
	call replica_el_tercio_en_los_otros_dos		;4231
	ld de,02000h		;4234   ; DE = VRAM 0x2000: la tabla de PATRON
	ld hl,06800h		;4237   ; HL = 0x6800, el suyo
	call replica_el_tercio_en_los_otros_dos		;423a
	call traduce_los_equipos		;423d   ; pasa los dos equipos elegidos a 0xE443 y 0xE444
	call esconde_todos_los_sprites		;4240   ; rellena la franja de 0x7b00
	call dibuja_el_guion_de_aqui_al_lado		;4243

; ----------------------------------------------------------------------
; DATOS guion_incrustado_4246: Argumento del `call 0x4582` de 0x4243: el guion
;   de 0x6a1c
;   0x4246..0x4248  (2 bytes)
DATA_guion_incrustado_4246:
	defw 06a1ch	; 4246

; ======================================================================
; CODIGO 0x4248..0x425d  (21 bytes)
; ======================================================================


	call escribe_las_iniciales		;4248   ; escribe las iniciales de los dos equipos
	call monta_la_jugada		;424b
	ld a,004h		;424e   ; (0xE001) := 4: el plazo de la presentacion del partido
	ld (0e001h),a		;4250
	di			;4253
	ld a,095h		;4254   ; A = 0x95, la melodia de entrada
	call pide_un_sonido		;4256   ; se la pasa al motor de sonido
	ei			;4259
	call dibuja_el_guion_de_aqui_al_lado		;425a

; ----------------------------------------------------------------------
; DATOS guion_incrustado_425d: Argumento del `call 0x4582` de 0x425a: el guion
;   de 0x477f
;   0x425d..0x425f  (2 bytes)
DATA_guion_incrustado_425d:
	defw 0477fh	; 425d  -> DATA_guiones_del_marcador

; ======================================================================
; CODIGO 0x425f..0x426f  (16 bytes)
; ======================================================================


	ei			;425f
espera_el_plazo:		; No sigue hasta que el contador lento de 0xE001 se agote
	ld a,(0e001h)		;4260   ; (0xE001), que baja sola cada 32 cuadros
	or a			;4263
	jr nz,espera_el_plazo		;4264
espera_a_que_calle_la_musica:		; 0xE663 es la marca de "hay melodia sonando" del motor de sonido; hasta que no se apague, aqui no se sigue
	ld a,(0e663h)		;4266   ; (0xE663), la marca del motor de sonido
	or a			;4269
	jr nz,espera_a_que_calle_la_musica		;426a
	call dibuja_el_guion_de_aqui_al_lado		;426c

; ----------------------------------------------------------------------
; DATOS guion_incrustado_426f: Argumento del `call 0x4582` de 0x426c: el guion
;   de 0x47b3
;   0x426f..0x4271  (2 bytes)
DATA_guion_incrustado_426f:
	defw 047b3h	; 426f

; ======================================================================
; CODIGO 0x4271..0x42ac  (59 bytes)
; ======================================================================


abre_la_pantalla_de_juego:		; Enciende el interruptor de 0xE003 -que es lo que deja correr las tres rutinas de juego dentro de la interrupcion- y se da tres pasos de plazo
	ld a,001h		;4271   ; (0xE003) := 1: la partida esta en marcha
	ld (0e003h),a		;4273
	ld a,003h		;4276   ; (0xE001) := 3, el plazo de esta espera
	ld (0e001h),a		;4278
	ei			;427b
espera_el_saque:		; Espera a que el jugador pulse. Si por el camino 0xE002 se pone -o sea, si manda el piloto automatico-, copia 0xE005 a 0xE006 y, con algo pulsado, reinicia el cartucho entero saltando a INIT
	ld a,(0e002h)		;427c   ; (0xE002): con el piloto automatico puesto, sigue abajo
	or a			;427f
	jr z,mira_el_boton_de_saque		;4280
	ld a,(0e005h)		;4282   ; (0xE005) -> (0xE006): deja escrito lo ultimo que se pulso
	ld (0e006h),a		;4285
	or a			;4288
	jr nz,$+116		;4289   ; y con algo pulsado se vuelve a INIT: reinicio en frio
mira_el_boton_de_saque:		; El bit 7 de 0xE402 es el "ya" del partido; hasta que no se pone, otra vuelta
	ld a,(0e402h)		;428b   ; (0xE402), la palabra de estado del partido
	rlca			;428e   ; su bit 7 al acarreo
	jr nc,espera_el_saque		;428f
	di			;4291   ; con el bit puesto, se apaga la partida y se decide que sigue
	xor a			;4292
	ld (0e003h),a		;4293   ; (0xE003) := 0: las rutinas de juego se paran
	ld a,(0e002h)		;4296
	or a			;4299
	jp nz,arranca_el_juego		;429a   ; con el piloto automatico puesto, reinicio en frio
	di			;429d
	ld a,093h		;429e   ; A = 0x93, la melodia del final del partido
	call pide_un_sonido		;42a0
	ei			;42a3
	ld a,009h		;42a4   ; (0xE001) := 9, el plazo del marcador final
	ld (0e001h),a		;42a6
	call dibuja_el_guion_de_aqui_al_lado		;42a9

; ----------------------------------------------------------------------
; DATOS guion_incrustado_42ac: Argumento del `call 0x4582` de 0x42a9: el guion
;   de 0x4799
;   0x42ac..0x42ae  (2 bytes)
DATA_guion_incrustado_42ac:
	defw 04799h	; 42ac

; ======================================================================
; CODIGO 0x42ae..0x42fb  (77 bytes)
; ======================================================================


guarda_el_resultado:		; Pinta el marcador final, deja en el bit 0 de 0xE402 lo que devolvio 0x7ceb y copia los 32 bytes del bloque de 0xE410 al de 0xE700
	ei			;42ae
	call mira_si_hay_empate		;42af   ; calcula el resultado del partido
	ld hl,0e402h		;42b2   ; HL = 0xE402
	res 0,(hl)		;42b5   ; su bit 0 a cero...
	jr nc,L_42BB		;42b7
	set 0,(hl)		;42b9   ; ...o a uno, segun el acarreo que dejo 0x7ceb
L_42BB:
	ld de,0e700h		;42bb   ; los 32 bytes del marcador...
	ld hl,0e410h		;42be
	ld bc,00020h		;42c1   ; ...copiados de 0xE410 a 0xE700
	ldir		;42c4
ensena_el_marcador:		; Deja el marcador en pantalla mientras corre el plazo. Con el bit 6 de 0xE402 puesto no se toca nada; sin el, borra el bloque de 0xE410 y, cada vez que el bit 5 del contador de cuadros esta puesto, lo repone desde la copia de 0xE700: eso es lo que hace que parpadee
	ld a,(0e402h)		;42c6   ; (0xE402) otra vez
	bit 6,a		;42c9   ; con el bit 6 puesto no hay parpadeo
	jr nz,espera_el_plazo_del_marcador		;42cb
	ld hl,0e410h		;42cd   ; borra los 31 bytes del bloque de 0xE410
	ld bc,0001fh		;42d0
	call borra_bloque_de_ram		;42d3
	ld a,(0e000h)		;42d6   ; (0xE000), el contador de cuadros
	bit 5,a		;42d9   ; su bit 5: se enciende y se apaga cada 32 cuadros
	jr z,L_42E8		;42db
	ld hl,0e700h		;42dd   ; con el bit puesto, repone el bloque desde la copia
	ld de,0e410h		;42e0
	ld bc,00020h		;42e3
	ldir		;42e6
L_42E8:
	call vuelca_el_marcador		;42e8   ; y lo vuelca a la pantalla
	ei			;42eb
espera_el_plazo_del_marcador:		; El mismo plazo de siempre, el de 0xE001
	ld a,(0e001h)		;42ec   ; (0xE001)
	or a			;42ef
	jr nz,ensena_el_marcador		;42f0
espera_a_que_calle_el_final:		; Otra vez 0xE663, la marca del motor de sonido
	ld a,(0e663h)		;42f2   ; (0xE663)
	or a			;42f5
	jr nz,espera_a_que_calle_el_final		;42f6
	call dibuja_el_guion_de_aqui_al_lado		;42f8

; ----------------------------------------------------------------------
; DATOS guion_incrustado_42fb: Argumento del `call 0x4582` de 0x42f8: otra vez
;   el guion de 0x47b3, el mismo que 0x426f
;   0x42fb..0x42fd  (2 bytes)
DATA_guion_incrustado_42fb:
	defw 047b3h	; 42fb

; ======================================================================
; CODIGO 0x42fd..0x4396  (153 bytes)
; ======================================================================


vuelve_a_empezar:		; Reinicio en frio: salta a INIT con las interrupciones cortadas
	di			;42fd   ; nada de interrupciones durante el reinicio
	jp arranca_el_juego		;42fe
vuelca_el_marcador:		; Escribe los doce bytes del marcador en la fila que le toque: con el bit 0 de 0xE402 puesto, el bloque de 0xE410 en la fila 0x782b; sin el, el de 0xE420 en la 0x784b
	ld hl,0e410h		;4301   ; HL = 0xE410, el marcador de un lado
	ld de,0782bh		;4304   ; DE = VRAM 0x782b, su fila
	ld a,(0e402h)		;4307   ; (0xE402), el bit 0 al acarreo
	rrca			;430a
	jr c,L_4312		;430b
	ld hl,0e420h		;430d   ; el otro lado: 0xE420 en la fila 0x784b
	ld e,04bh		;4310
L_4312:
	ld b,00ch		;4312   ; doce columnas
	call copia_bytes_con_candado		;4314
	ret			;4317
lee_un_mando:		; Lee un puerto de joystick del PSG. El acarreo elige cual: sin acarreo el registro 15 se pone a 0x8F -bit 6 a cero, puerto A- y con acarreo a 0xCF -bit 6 puesto, puerto B-. Luego lee el registro 14 y lo invierte, porque el PSG da los bits a cero cuando estan pulsados
	ld e,08fh		;4318   ; E = 0x8F: bit 6 a cero, el primer puerto
	jr nc,L_431E		;431a   ; sin acarreo, ya vale
	ld e,0cfh		;431c   ; E = 0xCF: bit 6 puesto, el segundo puerto
L_431E:
	ld a,00fh		;431e   ; registro 15 del PSG, el de la seleccion
	call 00093h		;4320   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,00eh		;4323   ; registro 14, el de los datos del mando
	call 00096h		;4325   ; BIOS RDPSG - Reads value from PSG-register
	cpl			;4328   ; el PSG da 0 en lo pulsado: se invierte
	ret			;4329
lee_el_teclado_del_jugador_2:		; El segundo teclado del cartucho: W arriba, Z abajo, A izquierda, D derecha y SHIFT el boton. Se leen cuatro filas de la matriz -5, 2, 3 y 6-, se juntan sus bits en E y se recolocan con cuatro rotaciones y dos retoques hasta dejarlos en el orden del joystick (bit 0 arriba, 1 abajo, 2 izquierda, 3 derecha, 4 boton)
	ld de,00205h		;432a   ; D = fila 2 y E = fila 5
	ld hl,00306h		;432d   ; H = fila 3 y L = fila 6
	ld a,e			;4330   ; empieza por la fila 5
	call 00141h		;4331   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;4334   ; la matriz da 0 en lo pulsado: se invierte
	and 090h		;4335   ; bits 7 y 4 de esa fila: Z y W
	ld e,a			;4337
	ld a,d			;4338   ; la fila 2
	call 00141h		;4339   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;433c
	and 040h		;433d   ; su bit 6: A
	or e			;433f
	ld e,a			;4340
	ld a,h			;4341   ; la fila 3
	call 00141h		;4342   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;4345
	bit 1,a		;4346   ; su bit 1: D
	jr z,L_434C		;4348
	set 5,e		;434a   ; que se guarda en el bit 5
L_434C:
	ld a,e			;434c
	rlca			;434d   ; cuatro rotaciones: los cuatro bits altos bajan a los cuatro bajos
	rlca			;434e
	rlca			;434f
	rlca			;4350
	ld e,a			;4351
	and 005h		;4352   ; de ahi salen ya bien puestos arriba (W) e izquierda (A)
	bit 1,e		;4354   ; D estaba en el bit 1...
	jr z,L_435A		;4356
	set 3,a		;4358   ; ...y derecha es el bit 3
L_435A:
	bit 3,e		;435a   ; Z estaba en el bit 3...
	jr z,L_4360		;435c
	set 1,a		;435e   ; ...y abajo es el bit 1
L_4360:
	ld e,a			;4360
	ld a,l			;4361   ; y por ultimo la fila 6
	call 00141h		;4362   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;4365
	bit 0,a		;4366   ; su bit 0 es SHIFT
	jr z,L_436C		;4368
	set 4,e		;436a   ; que hace de boton, el bit 4
L_436C:
	ld a,e			;436c
	ret			;436d
lee_el_teclado_del_jugador_1:		; El primer teclado: las cuatro flechas y la barra espaciadora de la fila 8, mas la tecla de la fila 7 que hace de segundo boton. La fila 8 se recoloca en 0x4381 con la tabla de 0x4396
	ld a,e			;436e   ; la fila que venga en E, que siempre es la 8
	call 00141h		;436f   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;4372   ; invertida, como siempre
	call recoloca_la_fila_de_flechas		;4373   ; recoloca sus bits al orden del joystick
	ld e,a			;4376
	ld a,d			;4377   ; y ahora la fila de D, la 7
	call 00141h		;4378   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;437b
	and 040h		;437c   ; su bit 6
	rrca			;437e   ; que baja al bit 5: el segundo boton
	or e			;437f
	ret			;4380
recoloca_la_fila_de_flechas:		; En la fila 8 de la matriz el bit 0 es la barra espaciadora y los bits 4 a 7 son izquierda, arriba, abajo y derecha; el joystick los quiere en 0, 1, 2 y 3 y en otro orden. La barra se lleva al bit 4 a mano y las cuatro flechas se traducen de golpe con la tabla de 0x4396
	ld c,000h		;4381   ; C = 0 de momento
	rrca			;4383   ; saca el bit 0, la barra espaciadora
	jr nc,L_4388		;4384
	set 4,c		;4386   ; que en el joystick es el boton, el bit 4
L_4388:
	rrca			;4388   ; tres rotaciones mas: cuatro en total
	rrca			;4389
	rrca			;438a
	and 00fh		;438b   ; y se queda con las cuatro flechas
	ld hl,04396h		;438d   ; la tabla que las traduce
	call suma_a_hl		;4390
	ld a,(hl)			;4393
	or c			;4394   ; con la barra sumada
	ret			;4395

; ----------------------------------------------------------------------
; DATOS tabla_de_flechas: Traduce las cuatro flechas de la fila 8 del teclado
;   al orden en que las quiere el resto del cartucho, que es el del joystick.
;   El indice que entra lleva bit 3 derecha, bit 2 abajo, bit 1 arriba y bit 0
;   izquierda -asi las da la matriz-; lo que sale lleva bit 0 arriba, bit 1
;   abajo, bit 2 izquierda y bit 3 derecha. Las seis combinaciones imposibles
;   -arriba y abajo a la vez, izquierda y derecha a la vez- valen 0x0F
;   0x4396..0x43a6  (16 bytes)
DATA_tabla_de_flechas:
	defb 000h	; 4396
	defb 004h	; 4397
	defb 001h	; 4398
	defb 005h	; 4399
	defb 002h	; 439a
	defb 006h	; 439b
	defb 00fh	; 439c
	defb 00fh	; 439d
	defb 008h	; 439e
	defb 00fh	; 439f
	defb 009h	; 43a0
	defb 00fh	; 43a1
	defb 00ah	; 43a2
	defb 00fh	; 43a3
	defb 00fh	; 43a4
	defb 00fh	; 43a5

; ======================================================================
; CODIGO 0x43a6..0x4457  (177 bytes)
; ======================================================================


lee_entrada_de_los_jugadores:		; Lee el mando de cada jugador en su sitio -0xE00C el primero y 0xE00F el segundo, y solo hay segundo si 0xE012 lo dice-, le suma lo que venga del teclado y luego calcula los bits RECIEN pulsados de cada uno
	ld b,001h		;43a6   ; B = 1 jugador por defecto
	ld a,(0e012h)		;43a8   ; (0xE012): el numero de jugadores de la partida
	or a			;43ab
	jr z,L_43B0		;43ac
	ld b,002h		;43ae   ; con dos jugadores, dos lecturas
L_43B0:
	ld hl,0e00ch		;43b0   ; HL = 0xE00C, la entrada del primer jugador
lee_un_jugador:		; Lee un mando y lo guarda en el hueco de este jugador, dejando HL en el del siguiente
	call lee_un_mando		;43b3   ; lee el mando
	and 03fh		;43b6   ; los seis bits utiles
	ld (hl),a			;43b8   ; guardado
	ld hl,0e00fh		;43b9   ; HL = 0xE00F, la entrada del segundo jugador
	scf			;43bc   ; el jugador siguiente lee por la otra fuente
	djnz lee_un_jugador		;43bd
	ld de,00708h		;43bf   ; el teclado, filas 7 y 8
	call lee_el_teclado_del_jugador_1		;43c2
	ld d,a			;43c5
	ld a,(0e00ch)		;43c6   ; lo que dio el teclado se SUMA a lo que dio el joystick del jugador 1
	or d			;43c9
	ld (0e00ch),a		;43ca
	ld a,(0e012h)		;43cd   ; (0xE012) otra vez: sin segundo jugador no hay segunda suma
	or a			;43d0
	ld b,001h		;43d1
	jr z,calcula_flancos		;43d3
	call lee_el_teclado_del_jugador_2		;43d5   ; la otra mitad del teclado, para el jugador 2
	ld d,a			;43d8
	ld a,(0e00fh)		;43d9
	or d			;43dc
	ld (0e00fh),a		;43dd
	ld b,002h		;43e0
calcula_flancos:		; Para cada jugador, deja en el tercer byte de su bloque solo los bits RECIEN pulsados: compara la lectura de este fotograma con la del anterior
	ld hl,0e00ch		;43e2   ; HL = 0xE00C, el bloque del primer jugador
flanco_de_un_jugador:		; Compara la lectura nueva con la vieja y guarda el flanco de subida
	ld a,(hl)			;43e5   ; A = la lectura de este fotograma
	inc hl			;43e6
	cp (hl)			;43e7   ; contra la del fotograma anterior
	ld c,a			;43e8   ; C se la queda
	jr nz,L_43EE		;43e9
	inc hl			;43eb
	ld (hl),a			;43ec
	dec hl			;43ed
L_43EE:
	ld (hl),c			;43ee
	ld hl,0e00fh		;43ef
	djnz flanco_de_un_jugador		;43f2
	ret			;43f4
lee_entrada_del_menu:		; Lee el mando para el menu y deja en 0xE005 los seis bits utiles. Prueba primero el joystick y, si no da nada, repite con el acarreo puesto -que es como lee_un_mando elige la otra fuente-; si tampoco, cae en el teclado por 0x436e
	ld b,002h		;43f5   ; B = 2 intentos: joystick y luego la otra fuente
	or a			;43f7   ; el primer intento va sin acarreo
intenta_una_fuente:		; Un intento de lectura: se queda con los seis bits utiles y, si alguno esta puesto, ya vale
	call lee_un_mando		;43f8   ; lee un mando
	and 03fh		;43fb   ; solo los seis bits de direccion y botones
	ld (0e005h),a		;43fd   ; guardado en 0xE005
	or a			;4400
	ret nz			;4401   ; con algo pulsado, se acabo
	scf			;4402   ; acarreo puesto: el intento siguiente va por la otra fuente
	djnz intenta_una_fuente		;4403
	ld de,00708h		;4405   ; sin nada en ninguna de las dos: el teclado, filas 7 y 8
	call lee_el_teclado_del_jugador_1		;4408
	ld (0e005h),a		;440b
	ret			;440e
decide_repeticion:		; Con nada pulsado, limpia el biestable de repeticion de 0xE00B; con algo pulsado y el bit 0 ya puesto, no repite
	ld hl,0e00bh		;440f   ; HL = 0xE00B, el biestable de repeticion
	ld a,(0e005h)		;4412   ; (0xE005), lo que se acaba de leer
	or a			;4415
	jr nz,L_441A		;4416   ; con algo pulsado, sigue abajo
	ld (hl),a			;4418   ; sin nada: el biestable a cero y fuera
	ret			;4419
L_441A:
	bit 0,(hl)		;441a   ; con el bit 0 puesto, la tecla ya se conto: no se repite
	ret nz			;441c
	ld a,(0e005h)		;441d   ; los bits 4 y 5 de la lectura
	and 030h		;4420
	or a			;4422
	scf			;4423
	ret nz			;4424
	ld a,(0e005h)		;4425
	and 003h		;4428
	set 0,(hl)		;442a
	dec a			;442c
	jr nz,sube_la_opcion		;442d
	dec hl			;442f
	dec (hl)			;4430
	jr pinta_la_marca_del_menu		;4431
sube_la_opcion:		; El otro lado de decide_repeticion: la opcion de 0xE00A sube en uno
	dec hl			;4433   ; HL baja de 0xE00B a 0xE00A
	inc (hl)			;4434   ; una opcion mas
pinta_la_marca_del_menu:		; Escribe la marca de "aqui estas" del menu. El bit 0 de 0xE00A elige cual de los dos tramos de tabla_4457 se recorre; cada byte del tramo se escribe en VRAM en 0x7a29 y en las filas de 32 en 32 que van detras, y el 0xFF cierra
	ld hl,0e00ah		;4435   ; HL = 0xE00A, la opcion elegida
	di			;4438   ; sin interrupciones mientras se escribe
	ld a,(hl)			;4439
	ld de,07a29h		;443a   ; DE = VRAM 0x7a29, la primera fila de la marca
	ld hl,04457h		;443d   ; HL = el primer tramo de la tabla
	rrca			;4440   ; el bit 0 de la opcion al acarreo
	jr nc,escribe_una_fila_de_la_marca		;4441
	ld hl,0445ch		;4443   ; con el bit puesto, el segundo tramo
escribe_una_fila_de_la_marca:		; Un byte del tramo por fila; el 0xFF acaba
	ld a,(hl)			;4446   ; A = el byte que toca
	cp 0ffh		;4447   ; 0xFF cierra el tramo
	ret z			;4449
	ld b,002h		;444a   ; dos columnas por fila
	di			;444c
	call arma_y_copia		;444d   ; escritas en VRAM
	ei			;4450
	ld a,040h		;4451   ; DE += 0x40: dos filas de 32 mas abajo
	add a,e			;4453
	ld e,a			;4454
	jr escribe_una_fila_de_la_marca		;4455

; ----------------------------------------------------------------------
; DATOS tabla_4457: Dos tramos de bytes, leidos desde 0x443d y 0x4443
;   0x4457..0x4461  (10 bytes)
DATA_tabla_4457:
	defb 0a1h,0a2h,000h,000h,0ffh	; 4457
	defb 000h,000h,0a1h,0a2h,0ffh	; 445c

; ======================================================================
; CODIGO 0x4461..0x4649  (488 bytes)
; ======================================================================


borra_y_dibuja_el_menu:		; Monta la pantalla de titulo entera: borra la tabla de nombres, encadena los tres guiones que empiezan en 0x46d4 -el aviso de copyright, PLAY SELECT y las dos lineas de jugadores- y cae en 0x44b7, que remata con el rotulo del juego
	call borra_la_tabla_de_nombres		;4461   ; borra la tabla de nombres
	ld hl,046d4h		;4464   ; HL = 0x46d4, el primero de los tres guiones
	ld b,003h		;4467   ; tres guiones seguidos
dibuja_varios_guiones:		; Dibuja B guiones seguidos; cada uno deja HL justo detras del suyo, asi que la cuenta basta
	push bc			;4469   ; la cuenta a salvo del interprete
	call encadena_guion		;446a   ; un guion, con su direccion de VRAM dentro
	pop bc			;446d
	djnz dibuja_varios_guiones		;446e
	jr dibuja_el_rotulo		;4470   ; y al salir, el rotulo del juego
borra_la_tabla_de_nombres:		; Pone a cero las 768 posiciones de la tabla de nombres (VRAM 0x7800, o sea 0x3800 enmascarado): tres pasadas de 256 bytes. Como B entra a cero y el djnz cuenta 256 en ese caso, las tres pasadas suman 768 sin escribir la cuenta en ningun sitio
	di			;4472
	ld de,07800h		;4473   ; DE = VRAM 0x7800, la esquina de la tabla de nombres
	call arma_escritura_vram		;4476   ; arma la escritura ahi
	ld h,003h		;4479   ; tres pasadas
	xor a			;447b   ; A = 0, el byte con el que se borra
una_pasada_de_borrado:		; B tambien entra a cero, y el djnz cuenta 256 cuando entra asi
	ld b,a			;447c   ; B = 0, que para el djnz son 256 bytes
	call rellena_vram		;447d
	dec h			;4480   ; una pasada menos
	jr nz,una_pasada_de_borrado		;4481
	ei			;4483
	ret			;4484
replica_el_tercio_en_los_otros_dos:		; El truco de este cartucho para llenar SCREEN 2 con un solo tercio de datos: copia 4095 bytes de VRAM a VRAM con los rangos SOLAPADOS a proposito. Con DE=0x0000 y HL=0x4800 -que enmascarado es 0x0800- lo que sale es el primer tercio de la tabla repetido en el segundo y en el tercero, porque a mitad de camino ya esta releyendo lo que acaba de escribir. El arranque lo hace dos veces: una para COLOR y otra para PATRON. Se queda un byte corto: el ultimo del tercer tercio no se llega a escribir
	ld bc,00fffh		;4485   ; BC = 4095 bytes: los dos tercios que faltan, menos un byte
	exx			;4488   ; el juego de registros alterno guarda los dos puertos del VDP
	ld a,(00007h)		;4489   ; (0x0007) de la BIOS: el puerto por el que se ESCRIBE la VRAM
	ld d,a			;448c
	ld a,(00006h)		;448d   ; (0x0006) de la BIOS: el puerto por el que se LEE
	ld e,a			;4490
	exx			;4491   ; y vuelve al juego normal
copia_un_byte_de_vram_a_vram:		; Un byte por vuelta, rearmando la lectura y la escritura cada vez: es lo que hace falta para convivir con la interrupcion. DE lleva el origen y HL el destino, y los dos `ex de,hl` los intercambian a mitad de vuelta
	call arma_lectura_vram		;4492   ; arma la LECTURA en DE
	inc de			;4495   ; origen adelantado
	exx			;4496
	ld c,e			;4497   ; C = el puerto de lectura
	in a,(c)		;4498   ; A = el byte que habia en la VRAM
	exx			;449a
	ex de,hl			;449b   ; ahora DE es el destino y HL el origen
	push af			;449c
	call arma_escritura_vram		;449d   ; arma la ESCRITURA en el destino
	inc de			;44a0   ; destino adelantado
	pop af			;44a1
	exx			;44a2
	ld c,d			;44a3   ; C = el puerto de escritura
	out (c),a		;44a4   ; y ahi va el byte
	exx			;44a6
	ex de,hl			;44a7   ; los vuelve a cambiar para la vuelta siguiente
	dec bc			;44a8   ; un byte menos
	ld a,b			;44a9
	or c			;44aa
	jr nz,copia_un_byte_de_vram_a_vram		;44ab
	ret			;44ad
espera_pasos_de_contador:		; Deja A en 0xE001 y no vuelve hasta que la interrupcion lo haya bajado a cero. Cada paso son 32 cuadros, mas o menos medio segundo
	ld hl,0e001h		;44ae   ; HL = 0xE001, el contador lento
	ld (hl),a			;44b1   ; con los pasos que pide A
espera_a_que_llegue_a_cero:		; El bucle de espera; quien lo baja es la interrupcion, cada 32 cuadros
	ld a,(hl)			;44b2   ; A = lo que queda
	or a			;44b3
	jr nz,espera_a_que_llegue_a_cero		;44b4
	ret			;44b6
dibuja_el_rotulo:		; EL ROTULO DEL JUEGO. Dos filas de 23 tiles CORRELATIVOS: del 0x40 al 0x56 arriba y del 0x57 al 0x6D abajo, en las filas 4 y 5 de la pantalla desde la columna 5. Como el dibujo es unico y ocupa 46 tiles seguidos, no hace falta guion ninguno: basta con contar. Comprobado dibujandolo desde la ROM con tools/pantallas.py, que saca "Konami's Baseball" con el bate y la pelota haciendo de eles finales
	ld de,07885h		;44b7   ; DE = VRAM 0x7885, o sea fila 4 columna 5
	ld a,040h		;44ba   ; A = 0x40, el primer tile del rotulo
	call veintitres_columnas		;44bc
	ld a,057h		;44bf   ; A = 0x57, donde se quedo la fila de arriba
veintitres_columnas:		; El ancho del rotulo, el mismo para las dos filas
	ld b,017h		;44c1   ; B = 23 columnas
escribe_tiles_correlativos:		; Escribe B tiles en la fila de VRAM que trae DE, empezando por el numero que trae A y subiendo de uno en uno, y deja DE en la fila siguiente
	push af			;44c3   ; el primer tile a salvo
	call arma_escritura_vram		;44c4   ; arma la escritura en la fila
	pop af			;44c7   ; y lo recupera
un_tile_correlativo:		; Un tile por vuelta. A se guarda en el juego alterno mientras se recupera el puerto, porque no hay registro libre
	ex af,af'			;44c8   ; A a la sombra
	exx			;44c9
	ld a,(00007h)		;44ca   ; el puerto de escritura de la BIOS
	ld c,a			;44cd
	ex af,af'			;44ce   ; y A de vuelta
	out (c),a		;44cf   ; ahi va el tile
	exx			;44d1
	inc a			;44d2   ; el siguiente numero
	djnz un_tile_correlativo		;44d3
	ex de,hl			;44d5   ; DE += 0x20: la fila de abajo
	ld de,00020h		;44d6
	add hl,de			;44d9
	ex de,hl			;44da
	ret			;44db
mueve_un_cursor:		; Mueve el cursor de un jugador con lo que traiga A. Los bits 2 y 3 son izquierda y derecha: mueven una casilla y levantan el bit 7 de (HL), que impide repetir mientras se siga pulsando. Los bits 4 y 5 son los botones: levantan el bit 6, que es lo que espera 0x41ea para dar por elegido el equipo. C trae el paso -+1 para un jugador, -1 para el otro-, que aqui sirve para mirar el cursor del OTRO y no dejar que los dos caigan en el mismo equipo
	ld b,a			;44dc   ; B guarda la lectura entera
	and 00ch		;44dd   ; los bits 2 y 3: izquierda y derecha
	jr z,suelta_el_biestable		;44df   ; sin ninguno, no hay movimiento
	bit 7,(hl)		;44e1   ; el bit 7 ya puesto: la tecla sigue pulsada desde antes
	jr nz,mira_los_botones		;44e3
	ld d,001h		;44e5   ; D = +1, hacia delante
	bit 3,a		;44e7   ; el bit 3 es el que va hacia delante
	jr nz,mueve_y_esquiva_al_otro		;44e9
	ld d,0ffh		;44eb   ; D = -1, hacia atras
mueve_y_esquiva_al_otro:		; Da el paso y, si con el se cae encima del equipo que ya tiene el otro jugador, da otro mas en el mismo sentido
	set 7,(hl)		;44ed   ; levanta el bit 7: hasta que se suelte no se repite
	push de			;44ef
	call da_un_paso_circular		;44f0   ; el paso
	pop de			;44f3
	ld a,(hl)			;44f4   ; A = el equipo en el que se ha quedado
	and 00fh		;44f5
	ld e,a			;44f7
	ld a,l			;44f8   ; L += C: la casilla del OTRO jugador
	add a,c			;44f9
	ld l,a			;44fa
	ld a,(hl)			;44fb   ; la suya
	and 00fh		;44fc
	cp e			;44fe   ; iguales?
	push af			;44ff
	ld a,c			;4500   ; C cambia de signo para volver
	neg		;4501
	ld c,a			;4503
	pop af			;4504
	call z,da_un_paso_circular		;4505   ; si coincidian, otro paso mas
	ld a,c			;4508
	neg		;4509   ; y L vuelve a donde estaba
	add a,l			;450b
	ld l,a			;450c
	jr mira_los_botones		;450d
suelta_el_biestable:		; Sin nada pulsado, baja el bit 7 y el cursor vuelve a poder moverse
	res 7,(hl)		;450f   ; el bit 7 a cero
mira_los_botones:		; Los bits 4 y 5 de la lectura son los dos botones; cualquiera de los dos levanta el bit 6, la marca de "elegido"
	ld a,b			;4511   ; la lectura entera otra vez
	and 030h		;4512   ; los dos botones
	ret z			;4514   ; ninguno: nada que hacer
	set 6,(hl)		;4515   ; el bit 6: equipo elegido
	ret			;4517
da_un_paso_circular:		; Suma D al nibble bajo de (HL) dejandolo dentro de 0 a 5: el 6 vuelve a 0 y el -1 salta al 5. El nibble alto, que lleva los dos biestables, se conserva aparte
	ld a,(hl)			;4518   ; A = el byte entero del cursor
	and 0c0h		;4519   ; E se queda los bits 7 y 6, los biestables
	ld e,a			;451b
	ld a,(hl)			;451c   ; y ahora solo el numero de equipo
	and 00fh		;451d
	add a,d			;451f   ; el paso
	cp 006h		;4520   ; pasado el ultimo...
	jr nz,y_por_abajo_tambien		;4522
	xor a			;4524   ; ...vuelve al primero
y_por_abajo_tambien:		; Y por debajo del primero, al ultimo
	cp 0ffh		;4525   ; -1 en el nibble
	jr nz,guarda_el_cursor		;4527
	ld a,005h		;4529   ; A = 5, el ultimo equipo
guarda_el_cursor:		; Junta el numero nuevo con los dos biestables y lo guarda
	or e			;452b   ; los biestables de vuelta
	ld (hl),a			;452c
pinta_el_cursor:		; Dibuja la marca del jugador en la fila del equipo que tiene elegido. La fila sale de la tabla de 0x4765 y el dibujo -la marca mas seis huecos- de 0x4771 para un jugador y de 0x4778 para el otro. Luego repite la marca sola, 0xF1 o 0xF2 segun el jugador, en la fila que dice la tabla de 0x476b
	and 00fh		;452d   ; solo el numero de equipo
	push hl			;452f
	ld d,07ah		;4530   ; D = 0x7a: todas las filas del menu estan en 0x7axx
	ld hl,04765h		;4532   ; la tabla de filas
	call suma_a_hl		;4535
	ld e,(hl)			;4538   ; E = la fila que le toca
	ld hl,04771h		;4539   ; el dibujo del jugador 1
	ld a,c			;453c   ; C dice de que jugador se trata
	cp 001h		;453d
	jr z,escribe_los_siete_bytes		;453f
	ld hl,04778h		;4541   ; el del jugador 2
escribe_los_siete_bytes:		; Los siete bytes del dibujo, uno por columna
	push bc			;4544
	call arma_con_candado_y_da_el_puerto		;4545   ; arma la escritura y deja el puerto en C
	ld b,007h		;4548   ; siete columnas
una_columna_del_cursor:		; Byte a byte, vigilando el final de la fila
	ld a,(hl)			;454a   ; A = el byte que toca
	inc hl			;454b
	out (c),a		;454c   ; al puerto del VDP
	inc e			;454e   ; columna siguiente
	ld a,e			;454f
	cp 058h		;4550   ; pasada la columna 0x58...
	jr nz,repone_la_marca		;4552
	ld e,046h		;4554   ; ...se vuelve a la 0x46 y hay que rearmar la escritura
	push bc			;4556
	call arma_escritura_vram		;4557
	pop bc			;455a
repone_la_marca:		; Con el dibujo ya puesto, vuelve a escribir la marca sola -0xF1 el jugador 1, 0xF2 el jugador 2- en la fila que le corresponde al equipo del OTRO indice
	djnz una_columna_del_cursor		;455b
	pop bc			;455d
	pop hl			;455e
	push hl			;455f
	push bc			;4560
	ld b,0f1h		;4561   ; B = 0xF1, la marca del jugador 1
	ld a,c			;4563   ; C dice el jugador
	cp 001h		;4564
	jr nz,L_456A		;4566
	ld b,0f2h		;4568   ; B = 0xF2, la del jugador 2
L_456A:
	ld a,c			;456a   ; L += C: la casilla contigua
	add a,l			;456b
	ld l,a			;456c
	ld a,(hl)			;456d
	and 00fh		;456e   ; su numero de equipo
	ld hl,0476bh		;4570   ; la otra tabla de filas
	call suma_a_hl		;4573
	ld d,07ah		;4576   ; D = 0x7a otra vez
	ld e,(hl)			;4578
	call arma_con_candado_y_da_el_puerto		;4579   ; arma la escritura y deja el puerto en C
	ld a,b			;457c
	out (c),a		;457d   ; y ahi va la marca
	pop bc			;457f
	pop hl			;4580
	ret			;4581
dibuja_el_guion_de_aqui_al_lado:		; Dibuja el guion cuya direccion va ESCRITA DETRAS DEL PROPIO `call`. Coge la direccion de retorno de la pila con `ex (sp),hl`, lee de ahi la palabra, adelanta el retorno dos bytes para que no se ejecuten como codigo y cae dentro de encadena_guion. Nueve sitios del cartucho llaman asi
	ex (sp),hl			;4582   ; HL = la direccion de retorno, que es donde esta el argumento
	ld e,(hl)			;4583   ; E = el byte bajo del guion
	inc hl			;4584
	ld d,(hl)			;4585   ; D = el alto
	inc hl			;4586   ; el retorno, ya dos bytes mas alla
	ex (sp),hl			;4587   ; devuelto a la pila
	ex de,hl			;4588   ; y el guion a HL
encadena_guion:		; El comando 0x80 del interprete: lee del propio guion una direccion de VRAM nueva y sigue dibujando ahi. OJO al orden: aqui el byte ALTO va primero (`ld d,(hl)` antes que `ld e,(hl)`), al reves que en King's Valley
	ld d,(hl)			;4589   ; D = el byte ALTO de la direccion
	inc hl			;458a
	ld e,(hl)			;458b   ; E = el bajo
	inc hl			;458c
dibuja_guion:		; El interprete de guiones: arma la escritura de VRAM y ejecuta comandos de (HL). Es el mismo lenguaje que el de King's Valley (0x451a) mas un comando propio, el 0x01
	call arma_escritura_con_candado		;458d   ; prepara el puerto de datos del VDP y cierra el candado
	di			;4590   ; sin interrupciones mientras dura el tramo
lee_comando_de_guion:		; El cuerpo del interprete: un byte de comando por vuelta. El 0x01 es el comando extra de este cartucho; el resto es el lenguaje compartido -bit 7 puesto copia crudo, bit 7 a cero rellena, 0x00 acaba y 0x80 encadena-
	ld a,(hl)			;4591   ; A = el byte de comando
	inc hl			;4592
	cp 001h		;4593   ; el 0x01 es el comando de repeticion de bloque
	jr nz,despacha_comando_de_guion		;4595
	ld a,(hl)			;4597   ; nibble bajo del byte siguiente: cuantos bytes se saltan al final
	and 00fh		;4598
	ld b,a			;459a
	ld a,(hl)			;459b   ; nibble alto: cuantas veces se repite el tramo
	inc hl			;459c
	and 0f0h		;459d
	rrca			;459f
	rrca			;45a0
	rrca			;45a1
	rrca			;45a2
	ld c,a			;45a3
repite_tramo_de_guion:		; El comando 0x01: copia C veces el mismo tramo del guion, sin gastarlo, y al final salta los B bytes que ocupa
	push hl			;45a4
	push bc			;45a5
	call copia_bytes_a_vram		;45a6   ; copia el tramo a VRAM
	pop bc			;45a9
	pop hl			;45aa
	dec c			;45ab   ; una repeticion menos
	jr nz,repite_tramo_de_guion		;45ac
salta_el_tramo:		; Adelanta el guion los B bytes del tramo ya repetido y vuelve por el comando siguiente
	inc hl			;45ae   ; un byte mas
	djnz salta_el_tramo		;45af
	jr lee_comando_de_guion		;45b1   ; y al comando siguiente
despacha_comando_de_guion:		; Con la cuenta ya en A: distingue relleno de copia cruda comparando el byte enmascarado con el crudo -si son iguales, el bit 7 estaba a cero-, y trata aparte el caso de cuenta cero
	ld c,a			;45b3   ; C se queda el byte crudo, con su bit 7
	and 07fh		;45b4   ; A = la cuenta, sin el bit de modo
	jr z,fin_o_encadena		;45b6   ; cuenta cero: o es el fin o es el encadenado
	ld b,a			;45b8   ; B = la cuenta
	cp c			;45b9   ; iguales quiere decir bit 7 a cero: es un relleno
	jr nz,L_45C3		;45ba
	ld a,(hl)			;45bc   ; A = el byte a repetir, del propio guion
	inc hl			;45bd
	call rellena_vram		;45be   ; lo escribe B veces
	jr lee_comando_de_guion		;45c1
L_45C3:
	call copia_bytes_a_vram		;45c3   ; con el bit 7 puesto: copia B bytes crudos
	jr lee_comando_de_guion		;45c6
fin_o_encadena:		; Con la cuenta a cero: si el byte crudo era 0x00 se acaba el guion, y si era 0x80 se encadena a otra direccion
	cp c			;45c8   ; 0x00 exacto: fin del guion
	jr nz,encadena_guion		;45c9   ; 0x80: encadena leyendo una direccion nueva
	ret			;45cb
borra_bloque_de_ram:		; Pone a cero BC bytes desde (HL) propagando un cero con ldir, el truco de siempre
	push hl			;45cc
	pop de			;45cd   ; DE = HL+1: el destino va un byte por delante del origen
	inc de			;45ce
	ld (hl),000h		;45cf   ; el primer byte a cero...
	ldir		;45d1   ; ...y el ldir lo arrastra por el resto
	ret			;45d3
esconde_todos_los_sprites:		; Escribe 0xCF en los 128 bytes de la tabla de atributos de sprites (VRAM 0x7b00, o sea 0x3b00): los 32 sprites se van a la linea 207 y desaparecen de en medio
	ld de,07b00h		;45d4   ; DE = VRAM 0x7b00, la tabla de atributos
	ld bc,080cfh		;45d7   ; B = 128 bytes, C = 0xCF, la linea 207
	jp rellena_con_candado		;45da
dibuja_parpadeando:		; Dibuja un guion y lo borra alternandolo cada ocho cuadros, hasta que pasan 64. Pone el contador de cuadros a cero, y luego mira dos bits suyos: el 3 dice si toca borrar o dibujar y el 6 es el que corta a los 64 cuadros
	xor a			;45dd   ; (0xE000) := 0: el contador de cuadros empieza de nuevo
	ld (0e000h),a		;45de
una_vuelta_del_parpadeo:		; Con el bit 3 puesto -ocho cuadros de cada dieciseis- borra la fila; con el a cero, dibuja el guion
	ei			;45e1   ; la interrupcion tiene que correr para que el contador avance
	ld a,(0e000h)		;45e2   ; el contador de cuadros
	bit 3,a		;45e5   ; su bit 3 cambia cada ocho cuadros
	di			;45e7
	jr z,dibuja_y_mira_si_toca_parar		;45e8   ; a cero: toca dibujar
	push hl			;45ea
	ld d,(hl)			;45eb   ; D = el byte alto de la direccion de VRAM que trae el guion
	inc hl			;45ec
	ld e,(hl)			;45ed   ; E = el bajo
	inc hl			;45ee
	ld b,01ah		;45ef   ; 26 columnas...
	ld c,000h		;45f1   ; ...a cero: la fila borrada
	call arma_y_rellena		;45f3
	pop hl			;45f6
	jr una_vuelta_del_parpadeo		;45f7
dibuja_y_mira_si_toca_parar:		; Dibuja el guion entero y sale cuando el bit 6 del contador se pone, o sea a los 64 cuadros
	push hl			;45f9
	call encadena_guion		;45fa   ; dibuja el guion desde su direccion
	ld hl,0e000h		;45fd   ; el contador de cuadros
	bit 6,(hl)		;4600   ; su bit 6: 64 cuadros
	pop hl			;4602
	jr z,una_vuelta_del_parpadeo		;4603
	ret			;4605
escribe_las_iniciales:		; Pone en el marcador la inicial del equipo de cada jugador. El bit 0 de 0xE440 -la liga- elige cual de los dos tramos de iniciales_de_los_equipos se usa, y el numero de equipo de cada uno indexa dentro
	ld de,07829h		;4606   ; DE = VRAM 0x7829, el hueco del primer jugador
	ld hl,04649h		;4609   ; HL = el primer tramo de iniciales
	ld a,(0e440h)		;460c   ; (0xE440), la opcion del menu
	rrca			;460f
	jr nc,la_inicial_de_cada_uno		;4610
	ld hl,0464fh		;4612   ; con el bit puesto, el otro tramo
la_inicial_de_cada_uno:		; Primero la del jugador 1 y luego la del 2, cada una en su hueco
	ld a,(0e441h)		;4615   ; (0xE441), el equipo del primer jugador
	call escribe_una_inicial		;4618
	ld a,(0e442h)		;461b   ; (0xE442), el del segundo
	ld de,07849h		;461e   ; DE = VRAM 0x7849, su hueco
escribe_una_inicial:		; Un solo tile: el que dice la tabla para ese numero de equipo
	push hl			;4621
	and 00fh		;4622   ; solo el numero, sin los biestables
	call suma_a_hl		;4624
	ld c,(hl)			;4627   ; C = el tile de la inicial
	pop hl			;4628
	ld b,001h		;4629   ; un solo byte
	call rellena_con_candado		;462b
	ret			;462e
traduce_los_equipos:		; Pasa los dos numeros de cursor -0xE441 y 0xE442, de 0 a 5- por la tabla de 0x47c9 y deja el codigo de equipo de verdad en 0xE443 y 0xE444, que es lo que lee la partida
	ld a,(0e441h)		;462f   ; (0xE441), el cursor del primer jugador
	ld hl,047c9h		;4632   ; HL = 0x47c9, la tabla que traduce
	push hl			;4635   ; la direccion de la tabla, a salvo
	call suma_a_hl		;4636
	ld a,(hl)			;4639
	ld (0e443h),a		;463a   ; (0xE443), el equipo del primer jugador
	pop hl			;463d
	ld a,(0e442h)		;463e   ; (0xE442), el cursor del segundo
	call suma_a_hl		;4641
	ld a,(hl)			;4644
	ld (0e444h),a		;4645   ; (0xE444), el equipo del segundo
	ret			;4648

; ----------------------------------------------------------------------
; DATOS iniciales_de_los_equipos: LAS DOCE INICIALES, seis por liga, en el
;   orden en que salen en la parrilla. Son numeros de tile, y dibujando la
;   fuente desde la ROM se leen: el primer tramo es la Central -C, D, G, S, T,
;   W: Carp, Dragons, Giants, Swallows, Tigers, Whales- y el segundo la
;   Pacific -B, Bu, F, H, L, O: Braves, Buffaloes, Fighters, Hawks, Lions,
;   Orions-. Los doce equipos de la liga japonesa de 1984, cada uno por su
;   inicial y las dos bes distinguidas con un tile propio. La lee 0x4606 con
;   el tramo que diga el bit 0 de 0xE440, y otra vez 0x7c91/0x7c9a
;   0x4649..0x4655  (12 bytes)
DATA_iniciales_de_los_equipos:
	defb 0d6h,0d1h,0dfh,0deh,0d4h,0e3h	; 4649
	defb 0d0h,0e8h,0e4h,0e0h,0d9h,0d3h	; 464f

; ======================================================================
; CODIGO 0x4655..0x46cc  (119 bytes)
; ======================================================================


avanza_veintitres:		; HL += 23, el ancho de las filas del marcador
	ld a,017h		;4655   ; 23 columnas
	jr suma_a_hl		;4657
avanza_una_fila:		; HL += 32, que es una fila entera de la pantalla
	ld a,020h		;4659   ; 32 columnas
suma_a_hl:		; HL += A, con el acarreo propagado a H. El sumador de 8 bits que usan todas las tablas indexadas del cartucho
	add a,l			;465b   ; A += L
	ld l,a			;465c   ; y vuelve a L
	ret nc			;465d   ; sin desbordar, ya esta
	inc h			;465e   ; con desborde, H sube uno
	ret			;465f
arma_escritura_con_candado:		; Como arma_escritura_vram pero ademas cierra el candado de 0xE01E mientras dura la operacion: eso impide que la interrupcion escriba VRAM por su cuenta en medio de un guion largo
	xor a			;4660   ; (0xE01D) := 0, la marca de "no ha entrado la interrupcion"
	ld (0e01dh),a		;4661
	inc a			;4664
	ld (0e01eh),a		;4665   ; (0xE01E) := 1: el candado, cerrado
	ex de,hl			;4668   ; SETWRT quiere la direccion en HL
	call 00053h		;4669   ; BIOS SETWRT - Enables VDP to write
	di			;466c
	ex de,hl			;466d
	ld a,(0e01dh)		;466e   ; si la interrupcion ha entrado, 0xE01D esta a 1...
	or a			;4671
	jr nz,arma_escritura_con_candado		;4672   ; ...y hay que rehacerlo entero
	ld (0e01eh),a		;4674   ; y por fin se abre el candado
	ret			;4677
arma_lectura_vram:		; Lo mismo que arma_escritura_vram pero para leer: SETRD en vez de SETWRT, y el mismo reintento si la interrupcion se cuela
	xor a			;4678   ; (0xE01D) := 0
	ld (0e01dh),a		;4679
	ex de,hl			;467c   ; SETRD quiere la direccion en HL
	call 00050h		;467d   ; BIOS SETRD - Enables VDP to read
	di			;4680
	ex de,hl			;4681
	ld a,(0e01dh)		;4682   ; si la interrupcion ha entrado...
	or a			;4685
	jr nz,arma_lectura_vram		;4686   ; ...se repite
	ret			;4688
arma_escritura_vram:		; Arma la escritura de VRAM en la direccion que trae DE, y se protege de la interrupcion: pone 0xE01D a cero antes de SETWRT y, si al salir la interrupcion lo ha vuelto a poner, repite la operacion entera. Es el candado que hace que el juego pueda escribir VRAM con la interrupcion suelta
	xor a			;4689   ; (0xE01D) := 0: la marca de "no ha entrado la interrupcion"
	ld (0e01dh),a		;468a
	ex de,hl			;468d   ; SETWRT espera la direccion en HL
	call 00053h		;468e   ; BIOS SETWRT - Enables VDP to write | arma la escritura en la VRAM
	di			;4691   ; sin interrupciones para lo que venga detras
	ex de,hl			;4692
	ld a,(0e01dh)		;4693   ; si la interrupcion ha entrado entre medias, ha puesto 0xE01D a 1...
	or a			;4696
	jr nz,arma_escritura_vram		;4697   ; ...y entonces todo esto se repite
	ret			;4699
copia_bytes_con_candado:		; Arma la escritura con el candado cerrado y copia B bytes crudos desde (HL)
	call arma_escritura_con_candado		;469a   ; con candado, que puede ser largo
copia_bytes_a_vram:		; Copia B bytes desde (HL) al puerto de datos del VDP. El VDP autoincrementa la direccion despues de cada byte, asi que no hay que rearmar nada
	push bc			;469d   ; la cuenta, a salvo del que recupera el puerto
	call dame_el_puerto_de_datos		;469e   ; C = el puerto de datos
	ld a,(hl)			;46a1   ; A = el byte del origen
	out (c),a		;46a2   ; y al VDP
	inc hl			;46a4
	pop bc			;46a5
	djnz copia_bytes_a_vram		;46a6
	ret			;46a8
arma_y_copia:		; Arma la escritura en DE, sin candado, y copia B bytes desde (HL)
	call arma_escritura_vram		;46a9   ; sin candado: son pocos bytes
	jr copia_bytes_a_vram		;46ac
rellena_con_candado:		; Arma la escritura con candado y rellena B veces con el byte que trae C
	call arma_escritura_con_candado		;46ae   ; con candado
	ld a,c			;46b1   ; A = el byte con el que se rellena
rellena_vram:		; Escribe A en el puerto de datos del VDP B veces seguidas: el relleno solido. El VDP autoincrementa la direccion despues de cada byte
	push bc			;46b2
	push af			;46b3
	call dame_el_puerto_de_datos		;46b4   ; recupera el puerto de datos en C
	pop af			;46b7
	out (c),a		;46b8   ; escribe el byte
	pop bc			;46ba
	djnz rellena_vram		;46bb   ; hasta agotar la cuenta
	ret			;46bd
arma_y_rellena:		; Arma la escritura en DE, sin candado, y rellena B veces con el byte de C. OJO: pisa A con C nada mas entrar, asi que lo que trajera A da igual
	call arma_escritura_vram		;46be   ; sin candado
	ld a,c			;46c1   ; A = C, y lo que hubiera en A se pierde
	jr rellena_vram		;46c2
arma_con_candado_y_da_el_puerto:		; Arma la escritura con candado y deja el puerto de datos en C, listo para un `out (c),a`
	call arma_escritura_con_candado		;46c4   ; con candado
dame_el_puerto_de_datos:		; Deja en C el puerto de datos del VDP, leido de la tabla de la BIOS en 0x0007. El cartucho no lo escribe fijo en ningun sitio: siempre lo pide aqui
	ld a,(00007h)		;46c7   ; (0x0007) de la BIOS
	ld c,a			;46ca   ; y a C, que es donde lo quiere `out (c),a`
	ret			;46cb

; ----------------------------------------------------------------------
; DATOS tabla_registros_vdp: Los 8 valores crudos de R0 a R7 que carga 0x40b7;
;   identicos a los de King's Valley salvo R7
;   0x46cc..0x46d4  (8 bytes)
DATA_tabla_registros_vdp:
	defb 002h,0e2h,00eh,07fh,007h,076h,003h,0e1h	; 46cc  .....v..

; ----------------------------------------------------------------------
; DATOS guiones_del_titulo: Los guiones de la pantalla de titulo y de la
;   eleccion, en cadena: 0x46d4 el aviso de copyright, 0x46e4 PLAY SELECT,
;   0x46f3 y 0x46ff las dos lineas de jugadores en video inverso, 0x470c
;   CENTRAL, 0x4718 PACIFIC, y 0x4725 y 0x4745 las dos parrillas de seis
;   equipos
;   0x46d4..0x4765  (145 bytes)
DATA_guiones_del_titulo:
	defb 079h,00bh,08ch,0eah,0d7h,0d3h,0e6h,0dah,0e1h,0d5h,000h,0f1h,0f9h,0f8h,0f4h,080h	; 46d4  y...............
	defb 079h,0abh,08bh,0d8h,0d9h,0dah,0dbh,000h,0deh,0dch,0d9h,0dch,0d6h,0d4h,000h,07ah	; 46e4  y..............z
	defb 02ch,088h,0b6h,000h,0adh,0aeh,0afh,0b0h,0b1h,0b2h,000h,07ah,06ch,089h,0b7h,000h	; 46f4  ,..........zl...
	defb 0adh,0aeh,0afh,0b0h,0b1h,0b2h,0b3h,000h,07ah,02ch,088h,000h,0d6h,0dch,0e6h,0d4h	; 4704  ........z,......
	defb 0ddh,0dah,0d9h,000h,07ah,06ch,089h,000h,0d8h,0dah,0d6h,0d5h,0e4h,0d5h,0d6h,000h	; 4714  ....zl..........
	defb 000h,07ah,024h,097h,000h,000h,000h,000h,0d6h,000h,000h,0d1h,000h,000h,0dfh,000h	; 4724  .z$.............
	defb 000h,0deh,000h,000h,0d4h,000h,000h,0e3h,000h,000h,000h,080h,07ah,064h,017h,000h	; 4734  ............zd..
	defb 000h,07ah,024h,097h,000h,000h,000h,000h,0d0h,000h,000h,0e8h,000h,000h,0e4h,000h	; 4744  .z$.............
	defb 000h,0e0h,000h,000h,0d9h,000h,000h,0d3h,000h,000h,000h,080h,07ah,064h,017h,000h	; 4754  ............zd..
	defb 000h	; 4764

; ----------------------------------------------------------------------
; DATOS filas_del_cursor_a: Las seis filas de VRAM -solo el byte bajo, el alto
;   siempre es 0x7a- en las que 0x452d escribe el dibujo del cursor: 0x57 y
;   luego 0x48, 0x4b, 0x4e, 0x51 y 0x54, o sea tres columnas de separacion
;   entre equipo y equipo
;   0x4765..0x476b  (6 bytes)
DATA_filas_del_cursor_a:
	defb 057h,048h,04bh,04eh,051h,054h	; 4765

; ----------------------------------------------------------------------
; DATOS filas_del_cursor_b: Las mismas seis filas rotadas una posicion, que es
;   la tabla con la que 0x455f repone la marca en la casilla contigua
;   0x476b..0x4771  (6 bytes)
DATA_filas_del_cursor_b:
	defb 048h,04bh,04eh,051h,054h,057h	; 476b

; ----------------------------------------------------------------------
; DATOS dibujo_del_cursor_1: Los siete tiles que 0x452d escribe para el
;   jugador 1: la marca 0xF1 y seis huecos, que de paso borran donde estuviera
;   antes
;   0x4771..0x4778  (7 bytes)
DATA_dibujo_del_cursor_1:
	defb 000h,000h,000h,0f1h,000h,000h,000h	; 4771

; ----------------------------------------------------------------------
; DATOS dibujo_del_cursor_2: Lo mismo para el jugador 2, con la marca 0xF2
;   0x4778..0x477f  (7 bytes)
DATA_dibujo_del_cursor_2:
	defb 000h,000h,000h,0f2h,000h,000h,000h	; 4778

; ----------------------------------------------------------------------
; DATOS guiones_del_marcador: Tres guiones encadenados que escriben las tres
;   lineas del marcador -filas 9, 10 y 11 de la pantalla-, cada uno con su
;   version: 0x477f lo dibuja 0x425a, 0x4799 lo dibuja 0x42a9 y 0x47b3 lo
;   dibujan 0x426c y 0x42f8
;   0x477f..0x47c9  (74 bytes)
DATA_guiones_del_marcador:
	defb 079h,02ah,00ch,000h,080h,079h,04ah,08ch,000h,0d8h,0d9h,0dah,0dbh,000h,000h,0d0h	; 477f  y*...yJ.........
	defb 0dah,0d9h,0d9h,000h,080h,079h,06ah,00ch,000h,000h,079h,02ah,00ch,000h,080h,079h	; 478f  .....yj...y*...y
	defb 04ah,08ch,000h,000h,0dfh,0dah,0e1h,0dch,000h,0deh,0dch,0d4h,000h,000h,080h,079h	; 479f  J..............y
	defb 06ah,00ch,000h,000h,079h,02ah,00ch,04bh,080h,079h,04ah,00ch,04bh,080h,079h,06ah	; 47af  j...y*.K.yJ.K.yj
	defb 004h,04bh,084h,063h,062h,05eh,05fh,004h,04bh,000h	; 47bf  .K.cb^_.K.

; ----------------------------------------------------------------------
; DATOS traduccion_de_equipos: Los seis codigos de equipo de verdad, indexados
;   por la posicion del cursor (0 a 5). 0x462f los pasa a 0xE443 y 0xE444, que
;   es lo que lee la partida
;   0x47c9..0x47cf  (6 bytes)
DATA_traduccion_de_equipos:
	defb 0d9h,0abh,0bch,0c3h,0e6h,0d5h	; 47c9

; ----------------------------------------------------------------------
; DATOS guiones_de_los_graficos: El guion largo del arranque y sus reentradas.
;   0x47cf carga de una tirada los colores y los patrones del primer tercio y
;   acaba en 0x4a96; 0x49d4 y 0x4a27 son ENTRADAS A MITAD de ese mismo guion,
;   que el arranque vuelve a ejecutar con otra direccion de VRAM para repetir
;   su cola en otro sitio; y 0x4a96 es el ultimo tramo
;   0x47cf..0x4af0  (801 bytes)
DATA_guiones_de_los_graficos:
	defb 065h,008h,090h,000h,00fh,0bfh,0ffh,0ffh,0ffh,0bfh,00fh,000h,000h,0fch,0c0h,0c0h	; 47cf  e...............
	defb 080h,080h,000h,080h,067h,050h,088h,03ch,042h,099h,0a1h,0a1h,099h,042h,03ch,080h	; 47df  ....gP.<B....B<.
	defb 060h,00eh,082h,007h,00fh,006h,000h,082h,0f8h,0f0h,004h,03eh,004h,03fh,08bh,01fh	; 47ef  `..........>.?..
	defb 03fh,07fh,0ffh,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,003h,000h,002h,03eh,005h,000h	; 47ff  ?............>..
	defb 083h,01fh,07fh,0fbh,005h,000h,083h,00fh,0cfh,0efh,005h,000h,083h,078h,0fch,0bch	; 480f  .............x..
	defb 005h,000h,083h,03fh,07fh,0f3h,005h,000h,083h,087h,0c7h,0c7h,005h,000h,083h,0bch	; 481f  ...?............
	defb 0feh,0dfh,005h,000h,088h,078h,0fch,0bch,060h,0f0h,0f0h,060h,000h,003h,0f0h,002h	; 482f  .....x..`..`....
	defb 03fh,006h,03eh,088h,0f8h,0fch,0feh,07fh,03fh,01fh,00fh,007h,003h,03eh,085h,07eh	; 483f  ?.>.....?....>.~
	defb 0fch,0fch,0f8h,0e0h,005h,0f1h,083h,0fbh,07fh,01fh,006h,0efh,082h,0cfh,00fh,008h	; 484f  ................
	defb 01eh,088h,0e1h,003h,03fh,0f1h,0e1h,0f3h,07fh,01eh,007h,0e7h,081h,0f7h,008h,08fh	; 485f  ....?...........
	defb 008h,01eh,082h,0f1h,0f2h,004h,0f5h,08ah,0f2h,0f1h,0e0h,010h,0c8h,068h,0c8h,028h	; 486f  .............h.(
	defb 010h,0e0h,080h,062h,000h,08dh,0f0h,0f1h,0f3h,0f7h,0ffh,0ffh,0feh,0feh,0f8h,0f0h	; 487f  ...b............
	defb 0e0h,0c0h,080h,007h,000h,084h,01eh,07fh,0ffh,0f3h,005h,000h,083h,087h,0c7h,0c7h	; 488f  ................
	defb 005h,000h,083h,070h,0fch,09eh,005h,000h,083h,03fh,03fh,003h,005h,000h,083h,08eh	; 489f  ...p.....??.....
	defb 0cfh,0cfh,005h,000h,083h,073h,0ffh,07eh,090h,003h,005h,005h,003h,000h,083h,0e3h	; 48af  .....s.~........
	defb 0f3h,087h,047h,047h,083h,002h,080h,080h,080h,004h,000h,084h,00fh,01fh,01fh,01ch	; 48bf  ..GG............
	defb 004h,000h,084h,080h,0c0h,0c0h,040h,008h,007h,088h,0feh,0ffh,0ffh,007h,003h,003h	; 48cf  ......@.........
	defb 007h,0ffh,003h,000h,085h,080h,080h,08fh,08fh,000h,005h,000h,083h,0e1h,0f1h,0f1h	; 48df  ................
	defb 004h,000h,084h,0f8h,0fch,0fch,0c4h,005h,000h,083h,00fh,03fh,039h,006h,007h,082h	; 48ef  ...........?9...
	defb 0c7h,0e7h,006h,000h,082h,078h,0fch,005h,000h,083h,03fh,03fh,003h,08ah,007h,008h	; 48ff  .....x....??....
	defb 00fh,00fh,00fh,08fh,0cfh,0cfh,00eh,091h,006h,09fh,090h,0ffh,0ffh,0f7h,0f3h,0f1h	; 490f  ................
	defb 0f0h,0f0h,0f0h,001h,081h,0c1h,0e1h,0f0h,0f8h,07ch,03eh,004h,0e1h,084h,0f3h,0ffh	; 491f  .........|>.....
	defb 07fh,01eh,004h,0e7h,002h,0c7h,082h,087h,007h,008h,00eh,088h,001h,03fh,07fh,071h	; 492f  .............?.q
	defb 071h,07fh,07fh,03dh,007h,0ceh,081h,0eeh,008h,03ch,008h,073h,008h,080h,08ah,01fh	; 493f  q..=.....<.s....
	defb 00fh,007h,000h,030h,03fh,01fh,00fh,000h,0c0h,004h,0e0h,082h,0c0h,080h,008h,007h	; 494f  ...0?...........
	defb 0c8h,0ffh,007h,003h,003h,007h,0ffh,0ffh,0feh,000h,08fh,09fh,09ch,09ch,01fh,01fh	; 495f  ................
	defb 00fh,071h,0f0h,0f0h,070h,073h,0f3h,0f1h,078h,0f0h,0fch,07eh,00eh,00eh,0feh,0fch	; 496f  .q..ps..x..~....
	defb 0f8h,070h,07fh,07fh,070h,078h,03fh,03fh,00fh,0e7h,0e7h,0e7h,007h,027h,0e7h,0e7h	; 497f  .p..px??.....'..
	defb 0c7h,0fch,01eh,00eh,00eh,01eh,0fch,0fch,078h,001h,03fh,07fh,071h,071h,07fh,07fh	; 498f  ........x.?.qq..
	defb 03dh,0c7h,0c7h,0c7h,0c2h,0c2h,0c2h,0c2h,0e7h,003h,00eh,004h,004h,081h,00eh,080h	; 499f  =...............
	defb 040h,000h,07fh,0f0h,07fh,0f0h,080h,042h,000h,07fh,071h,07fh,071h,072h,071h,080h	; 49af  @......B..q.qrq.
	defb 045h,000h,018h,0f0h,07fh,070h,040h,070h,080h,047h,050h,040h,0f0h,080h,047h,080h	; 49bf  E....p@p.GP@..G.
	defb 050h,0f0h,080h,065h,0a8h,08bh,000h,01ch,022h,063h,063h,063h,022h,01ch,000h,018h	; 49cf  P..e...."ccc"...
	defb 038h,004h,018h,0c1h,07eh,000h,03eh,063h,003h,00eh,03ch,070h,07fh,000h,03eh,063h	; 49df  8...~.>c..<p..>c
	defb 003h,00eh,003h,063h,03eh,000h,00eh,01eh,036h,066h,066h,07fh,006h,000h,07fh,060h	; 49ef  ...c>...6ff....`
	defb 07eh,063h,003h,063h,03eh,000h,03eh,063h,060h,07eh,063h,063h,03eh,000h,07fh,063h	; 49ff  ~c.c>.>c`~cc>..c
	defb 006h,00ch,018h,018h,018h,000h,03eh,063h,063h,03eh,063h,063h,03eh,000h,03eh,063h	; 4a0f  ......>cc>cc>.>c
	defb 063h,03fh,003h,063h,03eh,080h,065h,028h,081h,000h,001h,023h,07eh,063h,063h,084h	; 4a1f  c?.c>.e(...#~cc.
	defb 07eh,000h,07ch,066h,003h,063h,084h,066h,07ch,000h,01fh,004h,006h,084h,066h,03ch	; 4a2f  ~.|f.c.f|.....f<
	defb 000h,03eh,005h,063h,083h,03eh,000h,07eh,006h,018h,082h,000h,03ch,005h,018h,084h	; 4a3f  .>.c.>.~....<...
	defb 03ch,000h,03eh,063h,003h,060h,08ch,063h,03eh,000h,063h,066h,06ch,078h,07ch,06eh	; 4a4f  <.>c.`.c>.cflx|n
	defb 067h,000h,07eh,003h,063h,084h,07eh,060h,060h,000h,006h,060h,08eh,07fh,000h,01ch	; 4a5f  g.~.c.~``..`....
	defb 036h,063h,063h,07fh,063h,063h,000h,066h,066h,07eh,03ch,003h,018h,098h,000h,07fh	; 4a6f  6cc.cc.ff~<.....
	defb 060h,060h,07eh,060h,060h,07fh,000h,07eh,063h,063h,062h,07ch,066h,063h,000h,03eh	; 4a7f  ``~``..~ccb|fc.>
	defb 063h,060h,03eh,003h,063h,03eh,000h,066h,0f8h,089h,000h,03eh,063h,060h,067h,063h	; 4a8f  c`>.c>.f...>c`gc
	defb 063h,03fh,000h,003h,063h,081h,07fh,003h,063h,089h,000h,063h,077h,07fh,07fh,06bh	; 4a9f  c?..c...c..cw..k
	defb 063h,063h,000h,004h,063h,0b3h,036h,01ch,008h,000h,063h,063h,06bh,06bh,07fh,077h	; 4aaf  cc..c.6...cckk.w
	defb 022h,000h,07fh,060h,060h,07eh,060h,060h,060h,000h,063h,063h,063h,063h,063h,063h	; 4abf  "..``~```.cccccc
	defb 03eh,000h,063h,073h,07bh,07fh,06fh,067h,063h,000h,042h,024h,018h,018h,024h,042h	; 4acf  >.cs{.ogc.B$..$B
	defb 000h,000h,0f0h,0c8h,0c8h,0f5h,0cdh,0cdh,0f2h,080h,046h,080h,07fh,0f0h,051h,0f0h	; 4adf  ..........F...Q.
	defb 000h	; 4aef

; ----------------------------------------------------------------------
; DATOS guion_huerfano: Guion valido que no dibuja nadie: carga cuatro
;   patrones de sprite en VRAM 0x1800, otros cuatro en 0x1d00 y cinco
;   atributos en 0x3b3c. Ver la explicacion de arriba
;   0x4af0..0x4b53  (99 bytes)
DATA_guion_huerfano:
	defb 05dh,000h,005h,000h,083h,0ffh,0ffh,0ffh,00eh,000h,082h,0ffh,0ffh,008h,000h,086h	; 4af0  ]...............
	defb 080h,0c0h,0e0h,090h,080h,080h,01ah,000h,006h,000h,082h,0ffh,0ffh,00dh,000h,083h	; 4b00  ................
	defb 0ffh,0ffh,0ffh,008h,000h,003h,010h,081h,0feh,003h,010h,019h,000h,080h,07bh,03ch	; 4b10  ..............{<
	defb 094h,0cfh,000h,0a4h,00fh,0cfh,000h,0a0h,003h,0cfh,000h,0a4h,00fh,0cfh,000h,0a8h	; 4b20  ................
	defb 003h,0cfh,000h,0ach,001h,080h,058h,000h,002h,000h,084h,018h,03ch,03ch,018h,01ah	; 4b30  ......X.....<<..
	defb 000h,002h,000h,084h,018h,03ch,03ch,018h,01ah,000h,002h,0c0h,01eh,000h,002h,0c0h	; 4b40  .....<<.........
	defb 01eh,000h,000h	; 4b50

; ======================================================================
; CODIGO 0x4b53..0x4d50  (509 bytes)
; ======================================================================


mueve_un_movil:		; Un cuadro de movimiento de la ficha que trae HL. Suma el paso al acumulador de subpixel, se queda con los pixeles enteros que salgan, y con ellos avanza por los dos ejes respetando los topes. Si al acabar no le queda nada por recorrer en el eje que manda, apaga la ficha
	push hl			;4b53   ; IX = la ficha, que es como se lee de aqui en adelante
	pop ix		;4b54
	bit 0,(hl)		;4b56   ; el bit 0: si esta parada, no hay nada que hacer
	ret z			;4b58
	xor a			;4b59
	ld (0e403h),a		;4b5a   ; (0xE403) := 0
	set 6,(hl)		;4b5d   ; el bit 6: esta ficha se ha tocado este cuadro
	inc hl			;4b5f
	push hl			;4b60
	ld e,(hl)			;4b61   ; DE = el acumulador de subpixel
	inc hl			;4b62
	ld d,(hl)			;4b63
	inc hl			;4b64
	ld c,(hl)			;4b65   ; BC = el paso de cada cuadro
	inc hl			;4b66
	ld b,(hl)			;4b67
	push bc			;4b68
	pop hl			;4b69
	or a			;4b6a
	adc hl,de		;4b6b   ; HL = acumulador + paso
	ex de,hl			;4b6d
	pop hl			;4b6e
	ld (hl),e			;4b6f   ; y de vuelta a la ficha
	inc hl			;4b70
	ld (hl),d			;4b71
	ld a,(hl)			;4b72   ; el byte ALTO son los pixeles enteros...
	or a			;4b73
	ret z			;4b74   ; ...y si no hay ninguno, se acabo el cuadro
	ld b,a			;4b75
	ld (hl),000h		;4b76   ; se gastan: el byte alto vuelve a cero
	dec hl			;4b78
	dec hl			;4b79
	push hl			;4b7a
	res 6,(hl)		;4b7b   ; el bit 6 se baja otra vez
	ld a,010h		;4b7d
	call suma_a_hl		;4b7f   ; HL = ficha + 0x10, la parte de la trayectoria
	call recorre_los_pixeles		;4b82
	pop hl			;4b85
	ld a,(ix+011h)		;4b86   ; lo que queda en X...
	bit 7,(ix+010h)		;4b89   ; ...o lo que queda en Y, segun el eje que mande
	jr z,L_4B92		;4b8d
	ld a,(ix+012h)		;4b8f
L_4B92:
	or a			;4b92
	ret nz			;4b93   ; mientras quede algo, la ficha sigue viva
	res 0,(hl)		;4b94   ; y si no queda nada, se apaga
	ret			;4b96
recorre_los_pixeles:		; Descuenta los B pixeles de este cuadro del tramo que queda (+0x16). Mientras haya tramo se mueve por el eje que manda; cuando el tramo se agota, si hay una curva declarada en +0x13 se recalcula el paso y se mueve tambien por el otro eje
	ld a,006h		;4b97   ; HL = ficha + 0x16, lo que queda del tramo
	call suma_a_hl		;4b99
	ld a,(hl)			;4b9c
	sub b			;4b9d   ; menos los pixeles de este cuadro
	ld (hl),a			;4b9e
	jr nc,mueve_por_el_eje_que_manda		;4b9f   ; sin pasarse, no hay nada mas que hacer
	push hl			;4ba1
	dec hl			;4ba2   ; HL = ficha + 0x14
	dec hl			;4ba3
	ld a,(hl)			;4ba4   ; 0xFF en los dos bytes quiere decir "sin curva"...
	inc a			;4ba5
	jr nz,rehace_el_paso		;4ba6
	dec hl			;4ba8
	ld a,(hl)			;4ba9
	inc a			;4baa
	jr nz,rehace_el_paso		;4bab
	pop hl			;4bad
	jr mueve_por_el_eje_que_manda		;4bae   ; ...y entonces solo se mueve por el eje que manda
rehace_el_paso:		; Con el tramo agotado y curva declarada: suma la curva de +0x13 al paso de +0x15, guarda el resultado y, si el byte alto se sale, lo pasa al bajo. Es como el movil dobla
	pop hl			;4bb0
	ld d,(hl)			;4bb1   ; DE = el paso actual, de +0x15 y +0x16
	dec hl			;4bb2
	ld e,(hl)			;4bb3
	push bc			;4bb4
	dec hl			;4bb5
	ld b,(hl)			;4bb6   ; BC = la curva, de +0x13 y +0x14
	dec hl			;4bb7
	ld c,(hl)			;4bb8
	ex de,hl			;4bb9
	or a			;4bba
	adc hl,bc		;4bbb   ; el paso nuevo
	ex de,hl			;4bbd
	inc hl			;4bbe
	inc hl			;4bbf
	ld (hl),e			;4bc0   ; guardado en +0x15
	inc hl			;4bc1
	bit 7,d		;4bc2   ; si el byte alto tiene el bit 7...
	ld e,000h		;4bc4
	jr z,guarda_el_paso_nuevo		;4bc6
	ld e,d			;4bc8   ; ...se baja al bajo y el alto se queda a cero
	ld d,000h		;4bc9
guarda_el_paso_nuevo:		; Deja el byte alto y decide con que cuenta se mueve por el otro eje
	ld (hl),d			;4bcb   ; el byte alto del paso nuevo
	pop bc			;4bcc
	push bc			;4bcd
	bit 7,e		;4bce   ; con el bit 7 puesto se mueve lo que diga B...
	jr nz,mueve_por_el_otro_eje		;4bd0
	ld b,001h		;4bd2   ; ...y si no, un solo pixel
mueve_por_el_otro_eje:		; Un paso por el eje que NO manda
	call elige_el_eje_secundario		;4bd4
	pop bc			;4bd7   ; y el paso por el eje que manda
mueve_por_el_eje_que_manda:		; La salida comun: mover por el eje principal
	call elige_el_eje_principal		;4bd8
	ret			;4bdb
elige_el_eje_secundario:		; El bit 7 de +0x10 dice cual de los dos ejes manda; aqui se quiere el OTRO
	bit 7,(ix+010h)		;4bdc   ; el bit 7: el eje que manda
	jr nz,mueve_en_x		;4be0   ; si manda Y, el secundario es X
	jr mueve_en_y		;4be2
elige_el_eje_principal:		; Lo mismo del reves: aqui se quiere el eje que manda
	bit 7,(ix+010h)		;4be4   ; el bit 7 otra vez
	jr z,mueve_en_x		;4be8   ; si manda X, por X
	jr mueve_en_y		;4bea
mueve_en_x:		; Suma B a la X, con el signo que diga el bit 5, y solo si el resultado cae dentro de los topes de +0x0c y +0x0d. Lo que se avanza se descuenta de lo que quedaba por recorrer, sin bajar de cero
	ld a,b			;4bec   ; A = los pixeles de este cuadro
	bit 5,(ix+010h)		;4bed   ; el bit 5 es el signo en X
	jr z,L_4BF5		;4bf1
	neg		;4bf3   ; hacia atras
L_4BF5:
	add a,(ix+007h)		;4bf5   ; sobre la X de ahora
	cp (ix+00ch)		;4bf8   ; por debajo del tope de abajo, no se mueve
	ret c			;4bfb
	cp (ix+00dh)		;4bfc   ; ni por encima del de arriba
	ret nc			;4bff
	ld (ix+007h),a		;4c00   ; la X nueva
	ld a,(ix+011h)		;4c03   ; y lo que le quedaba por recorrer...
	sub b			;4c06   ; ...menos lo andado
	jr nc,guarda_lo_que_queda_en_x		;4c07
	xor a			;4c09   ; sin bajar de cero
guarda_lo_que_queda_en_x:		; Lo que le queda por recorrer en X
	ld (ix+011h),a		;4c0a
	jr marca_la_ficha_movida		;4c0d
mueve_en_y:		; Igual que en X pero con la Y de +0x08, el signo del bit 6 y los topes de +0x0e y +0x0f
	ld a,b			;4c0f   ; A = los pixeles de este cuadro
	bit 6,(ix+010h)		;4c10   ; el bit 6 es el signo en Y
	jr z,L_4C18		;4c14
	neg		;4c16   ; hacia arriba
L_4C18:
	add a,(ix+008h)		;4c18   ; sobre la Y de ahora
	cp (ix+00eh)		;4c1b   ; los dos topes de Y
	ret c			;4c1e
	cp (ix+00fh)		;4c1f
	ret nc			;4c22
	ld (ix+008h),a		;4c23   ; la Y nueva
	ld a,(ix+012h)		;4c26   ; lo que le quedaba en Y...
	sub b			;4c29   ; ...menos lo andado
	jr nc,guarda_lo_que_queda_en_y		;4c2a
	xor a			;4c2c
guarda_lo_que_queda_en_y:		; Lo que le queda por recorrer en Y
	ld (ix+012h),a		;4c2d
marca_la_ficha_movida:		; El bit 6 de la ficha: alguien la ha movido este cuadro
	set 6,(ix+000h)		;4c30   ; el bit 6 de +0x00
	ret			;4c34
apunta_hacia_un_destino:		; Prepara la trayectoria de una ficha hacia un destino. Recibe la posicion de salida en (D,E) y la de llegada en (B,C), y deja en la ficha las dos distancias en valor absoluto, los signos en los bits 5 y 6, cual de los dos ejes es el largo en el bit 7, y la pendiente que sale de dividir el corto entre el largo. Es lo que hace que la pelota vaya recta a donde tiene que ir
	push hl			;4c35
	push bc			;4c36
	xor a			;4c37   ; los siete primeros bytes de la ficha, a cero
	ld b,007h		;4c38
L_4C3A:
	ld (hl),a			;4c3a
	inc hl			;4c3b
	djnz L_4C3A		;4c3c
	pop bc			;4c3e
	pop hl			;4c3f
	ld a,d			;4c40   ; la distancia en el primer eje
	cp b			;4c41
	jr z,la_distancia_del_otro_eje		;4c42   ; iguales: no hay distancia
	jr c,L_4C4B		;4c44
	set 5,(hl)		;4c46   ; el bit 5: hacia delante
	sub b			;4c48
	jr L_4C4F		;4c49
L_4C4B:
	res 5,(hl)		;4c4b   ; el bit 5 a cero: hacia atras
	ld a,b			;4c4d
	sub d			;4c4e
L_4C4F:
	inc hl			;4c4f
	cp 001h		;4c50   ; la distancia de 1 se cuenta como 2
	jr nz,guarda_la_distancia_larga		;4c52
	inc a			;4c54
guarda_la_distancia_larga:		; La distancia del primer eje, ya en valor absoluto
	ld (hl),a			;4c55
	dec hl			;4c56
la_distancia_del_otro_eje:		; Lo mismo para el segundo eje, con el signo en el bit 6
	ld a,e			;4c57
	cp c			;4c58   ; la distancia en el segundo eje
	jr z,decide_el_eje_que_manda		;4c59   ; iguales: no hay distancia
	jr c,L_4C62		;4c5b
	set 6,(hl)		;4c5d   ; el bit 6: hacia delante
	sub c			;4c5f
	jr L_4C66		;4c60
L_4C62:
	res 6,(hl)		;4c62   ; el bit 6 a cero: hacia atras
	ld a,c			;4c64
	sub e			;4c65
L_4C66:
	inc hl			;4c66
	inc hl			;4c67
	ld (hl),a			;4c68
	dec hl			;4c69
	dec hl			;4c6a
decide_el_eje_que_manda:		; De las dos distancias, la mayor es la que manda: su bit va al 7 de las banderas, y las dos se dejan en 0xE701 y 0xE702 para la division que viene
	inc hl			;4c6b
	ld b,(hl)			;4c6c   ; B = la primera distancia
	inc hl			;4c6d
	ld a,(hl)			;4c6e   ; A = la segunda
	cp b			;4c6f
	jr c,manda_el_otro		;4c70   ; si la segunda es menor, manda la primera
	dec hl			;4c72
	dec hl			;4c73
	set 7,(hl)		;4c74   ; el bit 7: manda el primer eje
	jr divide_y_guarda_la_pendiente		;4c76
manda_el_otro:		; Con la segunda distancia mas grande, manda el segundo eje
	ld b,a			;4c78
	dec hl			;4c79
	ld a,(hl)			;4c7a
	dec hl			;4c7b
	res 7,(hl)		;4c7c   ; el bit 7 a cero
divide_y_guarda_la_pendiente:		; Divide la distancia corta entre la larga -dos veces, para sacar tambien el segundo decimal- y guarda el resultado en la ficha como el paso de cada cuadro. Al final enciende el bit 0: la ficha ya esta en marcha
	ld (0e701h),a		;4c7e   ; (0xE701) = la distancia corta, que es el dividendo
	ld a,b			;4c81
	ld (0e702h),a		;4c82   ; (0xE702) = la larga, que es el divisor
	xor a			;4c85
	ld (0e700h),a		;4c86   ; (0xE700) = 0: el resto empieza vacio
	call divide_dos_veces		;4c89   ; las dos divisiones
	inc hl			;4c8c
	inc hl			;4c8d
	inc hl			;4c8e
	ld a,(0e701h)		;4c8f   ; el primer decimal
	ld (hl),a			;4c92
	inc hl			;4c93
	ld a,(0e703h)		;4c94   ; y el segundo
	ld (hl),a			;4c97
	ld de,00014h		;4c98   ; HL vuelve al principio de la ficha
	or a			;4c9b
	sbc hl,de		;4c9c
	set 0,(hl)		;4c9e   ; el bit 0: en marcha
	ret			;4ca0
divide_dos_veces:		; Divide una vez, se queda el cociente en 0xE703 y mete el resto de vuelta como dividendo, y vuelve a dividir. De ahi salen los dos bytes de la pendiente
	call divide_16_entre_8		;4ca1   ; la primera division
	push hl			;4ca4
	ld hl,0e700h		;4ca5
	ld b,(hl)			;4ca8   ; B = el resto
	inc hl			;4ca9
	ld a,(hl)			;4caa   ; A = el cociente
	ld (hl),b			;4cab   ; el resto pasa a ser el dividendo nuevo
	inc hl			;4cac
	inc hl			;4cad
	ld (hl),a			;4cae   ; y el cociente se guarda en 0xE703
	pop hl			;4caf
divide_16_entre_8:		; La division de siempre, de restar y desplazar, ocho vueltas. El dividendo esta en 0xE701 y se va convirtiendo en el cociente segun entran los bits por abajo; el resto se acumula en 0xE700 y el divisor esta en 0xE702
	push hl			;4cb0
	ld c,008h		;4cb1   ; ocho vueltas, una por bit
una_vuelta_de_la_division:		; Sube un bit del dividendo al resto y prueba a restarle el divisor
	ld hl,0e701h		;4cb3   ; HL = 0xE701, el dividendo
	or a			;4cb6
	rl (hl)		;4cb7   ; su bit de mas peso sale por el acarreo...
	dec hl			;4cb9
	rl (hl)		;4cba   ; ...y entra por abajo del resto
	ld a,(hl)			;4cbc   ; A = el resto
	inc hl			;4cbd
	inc hl			;4cbe
	sub (hl)			;4cbf   ; menos el divisor
	jr c,otra_vuelta_de_division		;4cc0   ; si no cabe, el bit del cociente se queda a cero
	dec hl			;4cc2
	set 0,(hl)		;4cc3   ; cabe: bit del cociente a uno
	dec hl			;4cc5
	ld (hl),a			;4cc6   ; y el resto se queda con lo que sobra
otra_vuelta_de_division:		; Hasta las ocho
	dec c			;4cc7   ; una vuelta menos
	jr nz,una_vuelta_de_la_division		;4cc8
	pop hl			;4cca
	ret			;4ccb
lleva_el_lanzamiento:		; El cuadro del lanzador. Mira los bits de 0xE100 en orden -aire, brazo, cuenta- y, si no hay ninguno, lee el mando: con direccion pulsada arma el lanzamiento, y con el boton lo tira ya
	ld hl,0e100h		;4ccc   ; HL = 0xE100, la palabra de estado
	bit 0,(hl)		;4ccf   ; sin el bit 0 no hay lanzamiento que llevar
	ret z			;4cd1
	bit 1,(hl)		;4cd2   ; el bit 1: la pelota ya va por el aire
	jp nz,lleva_la_pelota_en_el_aire		;4cd4
	bit 2,(hl)		;4cd7   ; el bit 2: el brazo se esta armando
	jp nz,pasa_las_posturas_del_brazo		;4cd9
	bit 3,(hl)		;4cdc   ; el bit 3: la jugada acabo y toca la cuenta
	jp nz,escribe_la_cuenta		;4cde
	ex de,hl			;4ce1
	call el_mando_del_que_ataca		;4ce2   ; lee el mando del jugador que lanza
	ld a,(hl)			;4ce5
	ld b,a			;4ce6
	and 0f0h		;4ce7   ; los cuatro bits altos: sin nada pulsado no pasa nada
	ret z			;4ce9
	bit 1,b		;4cea   ; el bit 1, abajo
	jr nz,arma_el_brazo		;4cec
	ld a,b			;4cee
	and 00dh		;4cef   ; los bits 0, 2 y 3
	jr z,arma_el_brazo		;4cf1
	ld hl,0e220h		;4cf3   ; (0xE220) bit 7
	set 7,(hl)		;4cf6
	ld a,001h		;4cf8
	ld (0e388h),a		;4cfa   ; (0xE388) y (0xE38A) := 1
	ld (0e38ah),a		;4cfd
	ld a,008h		;4d00
	ld (0e400h),a		;4d02   ; (0xE400) := 8, el estado de la jugada
	ex de,hl			;4d05
	res 0,(hl)		;4d06   ; el bit 0 de 0xE100 se apaga: este lanzamiento se anula
	push hl			;4d08
	call lleva_la_defensa		;4d09
	pop hl			;4d0c
	jp cierra_la_postura		;4d0d
arma_el_brazo:		; Enciende el bit 2 -el lanzador arma- y monta la ficha de la pelota: la velocidad sale de 0xE363 y el efecto de 0xE364, la pareja de bytes de tabla_4f97 da el paso de cada cuadro, y la potencia se recorta a 4
	ex de,hl			;4d10
	set 2,(hl)		;4d11   ; el bit 2: armando
	inc hl			;4d13
	ld (hl),004h		;4d14   ; cinco cuadros por postura
	ld hl,0e121h		;4d16   ; HL = 0xE121
	ld a,(0e364h)		;4d19   ; (0xE364), el efecto elegido
	ld (hl),a			;4d1c
	inc hl			;4d1d
	ld a,(0e363h)		;4d1e   ; (0xE363), la velocidad
	ld (hl),a			;4d21
	push af			;4d22
	ex de,hl			;4d23
	ld hl,04f97h		;4d24   ; tabla_4f97, indexada por la velocidad por dos
	rlca			;4d27
	call suma_a_hl		;4d28
	inc de			;4d2b
	inc de			;4d2c
	inc de			;4d2d
	ld a,(hl)			;4d2e   ; la pareja de bytes que sale de ahi...
	ld (de),a			;4d2f   ; ...es el paso de la pelota
	inc de			;4d30
	inc hl			;4d31
	ld a,(hl)			;4d32
	ld (de),a			;4d33
	ex de,hl			;4d34
	pop af			;4d35
	inc hl			;4d36
	ld (hl),003h		;4d37   ; tres
	inc hl			;4d39
	ld (hl),00ah		;4d3a   ; diez cuadros
	inc hl			;4d3c
	srl a		;4d3d   ; la velocidad partida por dos...
	cp 004h		;4d3f
	jr c,L_4D45		;4d41
	ld a,004h		;4d43   ; ...y recortada a 4 como mucho
L_4D45:
	ld (hl),a			;4d45   ; la potencia, ya recortada
	inc hl			;4d46
	xor a			;4d47   ; y los tres bytes siguientes de la ficha, a cero
	ld (hl),a			;4d48
	inc hl			;4d49
	ld (hl),a			;4d4a
	inc hl			;4d4b
	ld (hl),a			;4d4c
	call dibuja_el_guion_de_aqui_al_lado		;4d4d

; ----------------------------------------------------------------------
; DATOS guion_incrustado_4d50: Argumento del `call 0x4582` de 0x4d4d: el guion
;   de 0x5a28, el unico de los nueve que sale del bloque de arranque
;   0x4d50..0x4d52  (2 bytes)
DATA_guion_incrustado_4d50:
	defw 05a28h	; 4d50

; ======================================================================
; CODIGO 0x4d52..0x4f97  (581 bytes)
; ======================================================================


pone_la_pelota_en_la_mano:		; Coloca la pelota donde el lanzador la suelta -columna 0x70 y fila 0x7a, u 0x80 si el bit 4 de 0xE100 dice el otro lado- y, una vez de cada 64 por termino medio, levanta el bit 6 de 0xE430 usando el registro R como dado. SUPOSICION: el registro R no es un azar de verdad -depende de cuantas instrucciones se hayan ejecutado-, pero el cartucho lo usa como tal en cinco sitios
	ld hl,0e130h		;4d52   ; (0xE130) := 0x70, la columna de salida
	ld (hl),070h		;4d55
	inc hl			;4d57
	ld (hl),07ah		;4d58   ; (0xE131) := 0x7a, la fila
	ld a,(0e100h)		;4d5a
	bit 4,a		;4d5d   ; el bit 4 dice de que lado se lanza
	jr z,L_4D63		;4d5f
	ld (hl),080h		;4d61   ; y entonces la fila es 0x80
L_4D63:
	inc hl			;4d63
	ld (hl),000h		;4d64   ; (0xE132) := 0
	inc hl			;4d66
	ld (hl),00fh		;4d67   ; (0xE133) := 0x0f
	ld a,r		;4d69   ; el registro de refresco del Z80 hace de dado
	and 03fh		;4d6b   ; una de cada 64
	ret nz			;4d6d
	ld hl,0e430h		;4d6e
	set 6,(hl)		;4d71   ; el bit 6 de 0xE430
	ret			;4d73
pasa_las_posturas_del_brazo:		; Cada cinco cuadros cambia la postura del lanzador. Son seis, y al llegar a la sexta suelta la pelota
	inc hl			;4d74
	dec (hl)			;4d75   ; un cuadro menos de esta postura
	ret nz			;4d76
	push hl			;4d77
	ld (hl),005h		;4d78   ; cinco cuadros para la siguiente
	inc hl			;4d7a
	ld a,(hl)			;4d7b
	inc a			;4d7c   ; la postura siguiente
	ld b,a			;4d7d
	and 007h		;4d7e
	cp 006h		;4d80   ; la sexta es la de soltar
	pop hl			;4d82
	dec hl			;4d83
	jr z,suelta_la_pelota		;4d84
	set 6,(hl)		;4d86   ; el bit 6: hay que redibujar
	inc hl			;4d88
	inc hl			;4d89
	ld (hl),b			;4d8a   ; la postura nueva
	ret			;4d8b
suelta_la_pelota:		; La sexta postura: dos golpes de sonido y el bit 1 encendido, que es el que pasa el control a la pelota en vuelo
	xor a			;4d8c
	ld (0e650h),a		;4d8d   ; (0xE650) := 0
	inc a			;4d90
	call suena_ya		;4d91   ; el primer sonido
	ld a,002h		;4d94
	ld (0e650h),a		;4d96   ; (0xE650) := 2
	dec a			;4d99
	call pide_un_sonido		;4d9a   ; y el segundo
	set 1,(hl)		;4d9d   ; el bit 1: la pelota vuela
cierra_la_postura:		; Marca para redibujar, esconde el sprite poniendole la linea 0xCF y avisa a 0xE220
	set 6,(hl)		;4d9f   ; el bit 6: hay que redibujar
	inc hl			;4da1
	inc hl			;4da2
	inc hl			;4da3
	ld (hl),0cfh		;4da4   ; 0xCF: el sprite fuera de la pantalla
	ld hl,0e220h		;4da6
	set 6,(hl)		;4da9   ; el bit 6 de 0xE220
	ret			;4dab
lleva_la_pelota_en_el_aire:		; La pelota volando hacia el bateador. Suma el paso de 0xE124 al acumulador de 0xE123, y el byte entero que salga es lo que avanza la columna de 0xE130. Por el camino mira si entra en la franja del bate y si llega al plato
	ld a,(0e030h)		;4dac   ; (0xE030): con algo en marcha ahi, la pelota se queda quieta
	or a			;4daf
	ret nz			;4db0
	ld hl,0e120h		;4db1
	set 6,(hl)		;4db4   ; el bit 6 de 0xE120: hay que redibujar
	ld hl,0e123h		;4db6   ; HL = 0xE123, el acumulador
	ld a,(hl)			;4db9
	or a			;4dba
	jr nz,avanza_la_columna		;4dbb   ; con algo acumulado, no hay que sumar todavia
	push hl			;4dbd
	ld d,(hl)			;4dbe   ; DE = el acumulador
	inc hl			;4dbf
	ld e,(hl)			;4dc0
	inc hl			;4dc1
	ld a,(hl)			;4dc2   ; HL = el paso de 0xE125
	inc hl			;4dc3
	ld l,(hl)			;4dc4
	ld h,a			;4dc5
	or a			;4dc6
	adc hl,de		;4dc7   ; sumados
	ex de,hl			;4dc9
	pop hl			;4dca
	ld (hl),d			;4dcb   ; y de vuelta al acumulador
	inc hl			;4dcc
	ld (hl),e			;4dcd
	dec hl			;4dce
avanza_la_columna:		; El byte entero del acumulador se gasta y se le suma a la columna de la pelota
	ld a,(hl)			;4dcf   ; lo que hay acumulado
	or a			;4dd0
	ret z			;4dd1   ; nada entero: este cuadro no se mueve
	ld (hl),000h		;4dd2   ; gastado
	ld b,a			;4dd4
	push hl			;4dd5
	ld hl,0e130h		;4dd6   ; HL = 0xE130, la columna de la pelota
	add a,(hl)			;4dd9   ; mas lo andado
	ld (hl),a			;4dda
	inc hl			;4ddb
	ld c,(hl)			;4ddc   ; C = la fila, corrida tres pixeles
	inc c			;4ddd
	inc c			;4dde
	inc c			;4ddf
	pop hl			;4de0
	cp 0abh		;4de1   ; desde la columna 0xAB...
	jr c,mira_si_llega_al_plato		;4de3
	cp 0b2h		;4de5   ; ...hasta la 0xB2 es la franja del bate
	jr nc,mira_si_llega_al_plato		;4de7
	ld e,a			;4de9
	ld a,c			;4dea
	bit 7,a		;4deb   ; el signo de la fila
	jr z,L_4DF1		;4ded
	neg		;4def
L_4DF1:
	cp 07ch		;4df1   ; y a menos de 0x7c del centro
	jr c,mira_si_llega_al_plato		;4df3
	ld a,(0e380h)		;4df5   ; (0xE380) bit 0: la pelota ha pasado por donde se batea
	set 0,a		;4df8
	ld (0e380h),a		;4dfa
	ld a,e			;4dfd
mira_si_llega_al_plato:		; Pasada la columna 0xCE, la pelota llega: se apunta si fue bola o strike, se manda la pelota de vuelta al receptor con apunta_hacia_un_destino y se lanza el aviso
	cp 0ceh		;4dfe   ; la columna 0xCE es el plato
	jr c,sigue_la_pelota_en_vuelo		;4e00
	ld hl,0e100h		;4e02   ; HL = 0xE100
	ld a,(hl)			;4e05
	and 0c1h		;4e06   ; se queda el bit 0, el 6 y el 7...
	or 008h		;4e08   ; ...y enciende el bit 3: toca la cuenta
	ld (hl),a			;4e0a
	ld a,(0e142h)		;4e0b   ; (0xE142), los bits bajos de la jugada
	and 007h		;4e0e
	cp 002h		;4e10
	ld a,002h		;4e12   ; A = 2 por defecto
	jr nc,devuelve_la_pelota		;4e14
	ld a,(0e380h)		;4e16   ; (0xE380) bit 0: si la pelota paso por el bate...
	rrca			;4e19
	ld a,002h		;4e1a
	jr c,devuelve_la_pelota		;4e1c
	ld a,001h		;4e1e   ; ...vale 1 y si no, 2
devuelve_la_pelota:		; Deja el aviso en 0xE401, coloca la pelota en el plato y le calcula la trayectoria de vuelta al receptor
	ld (0e401h),a		;4e20   ; (0xE401), el aviso de la jugada
	ld hl,0e347h		;4e23
	ld (hl),0ceh		;4e26   ; (0xE347) := 0xce, la columna del plato
	inc hl			;4e28
	ld (hl),07ah		;4e29   ; (0xE348) := 0x7a, la fila
	ld hl,0e350h		;4e2b   ; HL = 0xE350, la ficha de la pelota devuelta
	ld bc,07880h		;4e2e   ; BC = el destino
	ld de,0cf7ch		;4e31   ; DE = la salida
	call apunta_hacia_un_destino		;4e34
	ld a,009h		;4e37
	ld (0e38ah),a		;4e39   ; (0xE38A) := 9
	ld hl,0e320h		;4e3c
	set 7,(hl)		;4e3f   ; el bit 7 de 0xE320
	ld a,001h		;4e41
	ld (0e388h),a		;4e43   ; (0xE388) := 1
	ld a,(0e402h)		;4e46   ; (0xE402), el bit 0: de quien es el turno
	rrca			;4e49
	jr c,L_4E56		;4e4a
	ld a,002h		;4e4c
	ld (0e430h),a		;4e4e   ; (0xE430) := 2
	ld hl,0e388h		;4e51
	set 5,(hl)		;4e54   ; y el bit 5 de 0xE388
L_4E56:
	jp avisa_del_golpe		;4e56
sigue_la_pelota_en_vuelo:		; Sin llegar al plato: baja el contador de 0xE127 y, cada vez que da la vuelta, cambia de postura la pelota y, cada tres vueltas, baja tambien el efecto de 0xE121 y le busca un paso nuevo en tabla_4f97. Asi es como la pelota describe la curva
	ld hl,0e127h		;4e59   ; HL = 0xE127, el contador de posturas
	ld a,(hl)			;4e5c
	sub b			;4e5d   ; menos lo andado
	ld (hl),a			;4e5e
	jr nc,mira_el_mando_del_bateador		;4e5f
	add a,003h		;4e61   ; al dar la vuelta, tres cuadros mas
	ld (hl),a			;4e63
	ld de,0e121h		;4e64   ; DE = 0xE121, el efecto que queda
	ld a,(de)			;4e67
	dec a			;4e68   ; uno menos
	ld (de),a			;4e69
	inc hl			;4e6a
	ld a,(hl)			;4e6b
	sub b			;4e6c
	ld (hl),a			;4e6d
	jr nc,mira_el_mando_del_bateador		;4e6e
	ld (hl),00ah		;4e70   ; diez cuadros para el siguiente
	inc de			;4e72
	ld a,(de)			;4e73
	dec a			;4e74
	cp 0ffh		;4e75   ; agotado el efecto, ya no se toca mas
	jr z,mira_el_mando_del_bateador		;4e77
	ld (de),a			;4e79
	ld hl,04f97h		;4e7a   ; tabla_4f97 otra vez, con la velocidad nueva
	rlca			;4e7d
	call suma_a_hl		;4e7e
	ld a,(hl)			;4e81
	inc hl			;4e82
	ld c,(hl)			;4e83
	ld hl,0e125h		;4e84   ; y el paso de la pelota se rehace
	ld (hl),a			;4e87
	inc hl			;4e88
	ld (hl),c			;4e89
mira_el_mando_del_bateador:		; Con 0xE12A a cero todavia no se ha empezado a batear: en cuanto se pulsa una direccion se guarda el sentido en el bit 0 de 0xE120 y arranca el recorrido del bate
	ld hl,0e12ah		;4e8a   ; HL = 0xE12A, la postura del bate
	ld a,(hl)			;4e8d
	or a			;4e8e
	jr nz,sigue_el_bate		;4e8f   ; empezado ya, por la otra rama
	push hl			;4e91
	call el_mando_del_que_ataca		;4e92   ; lee el mando del bateador
	ld a,(hl)			;4e95
	and 00eh		;4e96   ; los bits 1, 2 y 3
	pop hl			;4e98
	ret z			;4e99   ; sin nada pulsado, no se batea
	push hl			;4e9a
	ld hl,0e120h		;4e9b   ; HL = 0xE120
	ld b,000h		;4e9e
	bit 3,a		;4ea0   ; el bit 3 elige el sentido del bate
	jr z,L_4EA5		;4ea2
	inc b			;4ea4
L_4EA5:
	ld a,(hl)			;4ea5
	and 0feh		;4ea6   ; que se guarda en el bit 0
	or b			;4ea8
	ld (hl),a			;4ea9
	pop hl			;4eaa
	inc (hl)			;4eab   ; la primera postura del bate
	ld c,(hl)			;4eac
	dec hl			;4ead
	ld a,(hl)			;4eae
	inc hl			;4eaf
busca_la_postura_del_bate:		; Recorre tabla_4faa a saltos de cinco -una fila por tipo de golpe- y dentro coge la postura que toque, como mucho la cuarta. El tile que sale se guarda en los tres huecos siguientes de la ficha
	push hl			;4eb0
	ld hl,04faah		;4eb1   ; HL = 0x4faa, la tabla de posturas
	ld b,a			;4eb4   ; B = el tipo de golpe, mas uno
	inc b			;4eb5
salta_una_fila_de_posturas:		; Cinco bytes por fila
	inc hl			;4eb6
	inc hl			;4eb7
	inc hl			;4eb8
	inc hl			;4eb9
	inc hl			;4eba
	djnz salta_una_fila_de_posturas		;4ebb
	ld a,c			;4ebd   ; C = la postura que toca
	cp 005h		;4ebe   ; de la quinta en adelante...
	jr c,L_4EC4		;4ec0
	ld a,004h		;4ec2   ; ...se queda en la cuarta
L_4EC4:
	dec a			;4ec4
	call suma_a_hl		;4ec5
	ld b,(hl)			;4ec8   ; B = el tile de la postura
	pop hl			;4ec9
	inc hl			;4eca
	ld (hl),b			;4ecb   ; guardado
	inc hl			;4ecc
	ld a,(hl)			;4ecd   ; si el hueco siguiente estaba vacio...
	or a			;4ece
	jr nz,L_4ED2		;4ecf
	ld (hl),b			;4ed1   ; ...tambien
L_4ED2:
	inc hl			;4ed2
	ld (hl),b			;4ed3   ; y el tercero siempre
	ret			;4ed4
sigue_el_bate:		; Con el bate ya en marcha: mientras se siga pulsando, cada vuelta del contador cambia de postura
	push hl			;4ed5
	call el_mando_del_que_ataca		;4ed6   ; lee el mando otra vez
	ld a,(hl)			;4ed9
	and 00eh		;4eda   ; las tres direcciones
	pop hl			;4edc
	jr z,mueve_el_bate_de_fila		;4edd   ; soltado: solo queda dejar correr el contador
	inc hl			;4edf
	dec (hl)			;4ee0   ; un cuadro menos
	jr nz,mueve_el_bate_de_fila		;4ee1
	dec hl			;4ee3
	inc (hl)			;4ee4   ; la postura siguiente
	ld c,(hl)			;4ee5
	dec hl			;4ee6
	ld a,(hl)			;4ee7
	inc hl			;4ee8
	call busca_la_postura_del_bate		;4ee9   ; y su tile
mueve_el_bate_de_fila:		; El contador de 0xE12C manda: cada vez que da la vuelta, la fila de la pelota sube o baja un pixel segun el sentido guardado en el bit 0 de 0xE120
	ld hl,0e12ch		;4eec
	dec (hl)			;4eef   ; un cuadro menos
	ret nz			;4ef0
	inc hl			;4ef1
	ld b,(hl)			;4ef2   ; el contador se recarga con 0xE12D
	dec hl			;4ef3
	ld (hl),b			;4ef4
	ld b,001h		;4ef5   ; B = +1
	ld a,(0e120h)		;4ef7   ; (0xE120), el bit 0 es el sentido
	bit 0,a		;4efa
	jr nz,corrige_la_fila		;4efc
	ld b,0ffh		;4efe   ; hacia el otro lado, -1
corrige_la_fila:		; La fila de la pelota, un pixel arriba o abajo
	ld hl,0e131h		;4f00   ; HL = 0xE131, la fila
	ld a,(hl)			;4f03
	add a,b			;4f04   ; mas el paso
	ld (hl),a			;4f05
	ret			;4f06
escribe_la_cuenta:		; Pone en pantalla la cuenta de la jugada. Los tres digitos salen de los nibbles de 0xE361 y 0xE362, y se convierten en tiles con un simple `or 0xf0`, porque las cifras del 0 al 9 son justo los tiles 0xF0 a 0xF9. Detras van tres tiles seguidos, 0xA2, 0xA3 y 0xA4
	ld de,0e362h		;4f07   ; DE = 0xE362
	ld hl,0e700h		;4f0a   ; HL = 0xE700, el hueco de trabajo
	push hl			;4f0d
	ld a,(de)			;4f0e
	or 0f0h		;4f0f   ; el nibble entero, convertido en tile de cifra
	ld (hl),a			;4f11
	inc hl			;4f12
	dec de			;4f13
	ld a,(de)			;4f14
	and 0f0h		;4f15   ; ahora el nibble ALTO de 0xE361
	rrca			;4f17   ; bajado a la derecha
	rrca			;4f18
	rrca			;4f19
	rrca			;4f1a
	or 0f0h		;4f1b   ; y convertido en tile
	ld (hl),a			;4f1d
	inc hl			;4f1e
	ld a,(de)			;4f1f
	and 00fh		;4f20   ; y el nibble bajo
	or 0f0h		;4f22
	ld (hl),a			;4f24
	ld a,0a2h		;4f25   ; A = 0xA2, el primero de los tres tiles fijos
	inc hl			;4f27
	ld (hl),a			;4f28
	inc a			;4f29
	inc hl			;4f2a
	ld (hl),a			;4f2b
	inc hl			;4f2c
	inc a			;4f2d
	ld (hl),a			;4f2e
	pop hl			;4f2f
	ld de,07a6dh		;4f30   ; DE = VRAM 0x7a6d, donde va la cuenta
	ld b,006h		;4f33   ; seis tiles
	call copia_bytes_con_candado		;4f35
	ld a,008h		;4f38
	ld (0e400h),a		;4f3a   ; (0xE400) := 8
	ld a,(0e380h)		;4f3d
	bit 1,a		;4f40   ; (0xE380) bit 1
	jr z,cierra_la_jugada_por_tiempo		;4f42
	ld hl,0e100h		;4f44
	ld a,(hl)			;4f47
	and 010h		;4f48   ; de 0xE100 solo sobrevive el bit 4, el lado
	ld (hl),a			;4f4a
	jr borra_la_cuenta		;4f4b
cierra_la_jugada_por_tiempo:		; Sin el bit 4 de 0xE388 y con la pelota devuelta por encima de la columna 0xC0, la jugada se da por cerrada: se borra 0xE388, el estado vuelve a 2 y se enciende el bit 3 de 0xE380
	ld a,(0e388h)		;4f4d   ; (0xE388), su bit 4
	bit 4,a		;4f50
	jr nz,borra_la_cuenta		;4f52
	ld a,(0e347h)		;4f54   ; (0xE347), la columna de la pelota devuelta
	cp 0c0h		;4f57   ; pasada la 0xC0
	jr nc,espera_a_que_pare_la_pelota		;4f59
	xor a			;4f5b
	ld (0e388h),a		;4f5c   ; (0xE388) := 0
	ld a,002h		;4f5f
	ld (0e400h),a		;4f61   ; (0xE400) := 2
	ld hl,0e380h		;4f64
	set 3,(hl)		;4f67   ; el bit 3 de 0xE380
	ld a,(0e402h)		;4f69   ; (0xE402), de quien es el turno
	rrca			;4f6c
	jr c,espera_a_que_pare_la_pelota		;4f6d
	ld a,008h		;4f6f
	ld (0e430h),a		;4f71   ; (0xE430) := 8, el estado de la maquina
espera_a_que_pare_la_pelota:		; Mueve la ficha de 0xE340 -la pelota devuelta- y no da la jugada por cerrada hasta que se para. Cuando para, borra 0xE380, deja de 0xE100 solo los bits 0, 6 y 7 y vuelve a montar el estado de la jugada
	ld hl,0e340h		;4f74   ; HL = 0xE340, la ficha de la pelota devuelta
	push hl			;4f77
	call mueve_un_movil		;4f78   ; un cuadro de movimiento
	pop hl			;4f7b
	bit 0,(hl)		;4f7c   ; mientras el bit 0 siga puesto, sigue en el aire
	ret nz			;4f7e
	xor a			;4f7f
	ld (0e380h),a		;4f80   ; (0xE380) := 0
	ld hl,0e100h		;4f83
	and 0c1h		;4f86   ; de 0xE100 solo sobreviven los bits 0, 6 y 7
	ld (hl),a			;4f88
	call monta_la_jugada		;4f89   ; y se rehace el estado de la jugada
borra_la_cuenta:		; Tapa los seis tiles de la cuenta con el 0x4B, que es el hueco del marcador
	ld de,07a6dh		;4f8c   ; DE = VRAM 0x7a6d, donde estaba la cuenta
	ld b,006h		;4f8f   ; seis tiles
	ld c,04bh		;4f91   ; C = 0x4b, el tile de fondo del marcador
	call rellena_con_candado		;4f93
	ret			;4f96

; ----------------------------------------------------------------------
; DATOS pasos_de_la_pelota: Doce parejas de 16 bits: el paso por cuadro de la
;   pelota para cada velocidad de lanzamiento. Van de 0x0166 a 0x038e, o sea
;   de 1,4 a 3,55 pixeles por cuadro contando el byte bajo como fraccion. Las
;   leen 0x4d24 y 0x4e7a indexando por la velocidad por dos
;   0x4f97..0x4faf  (24 bytes)
DATA_pasos_de_la_pelota:
	defb 001h,066h	; 4f97
	defb 001h,094h	; 4f99
	defb 001h,0d0h	; 4f9b
	defb 002h,016h	; 4f9d
	defb 002h,042h	; 4f9f
	defb 002h,065h	; 4fa1
	defb 002h,088h	; 4fa3
	defb 002h,0c2h	; 4fa5
	defb 003h,00ch	; 4fa7
	defb 003h,034h	; 4fa9
	defb 003h,05ch	; 4fab
	defb 003h,08eh	; 4fad

; ----------------------------------------------------------------------
; DATOS posturas_del_bate: Cuatro filas de cinco tiles: la serie de posturas
;   del bate para cada tipo de golpe. Los recorre 0x4eb0 saltando de cinco en
;   cinco hasta la fila y luego indexando dentro, con tope en la cuarta
;   postura
;   0x4faf..0x4fc3  (20 bytes)
DATA_posturas_del_bate:
	defb 008h,004h,003h,002h,001h	; 4faf
	defb 008h,004h,003h,002h,001h	; 4fb4
	defb 008h,004h,003h,002h,001h	; 4fb9
	defb 008h,004h,003h,002h,001h	; 4fbe

; ======================================================================
; CODIGO 0x4fc3..0x5048  (133 bytes)
; ======================================================================


lleva_el_medidor:		; El medidor que se llena mientras el lanzador prepara. Solo corre en el hueco en que 0xE100 tiene el bit 0 puesto y los bits 1, 2 y 3 a cero, o sea antes de que pase nada. El bit 0 de 0xE360 dice si el medidor sube o baja
	ld hl,0e100h		;4fc3   ; HL = 0xE100, la palabra de estado
	ld a,(hl)			;4fc6
	rrca			;4fc7   ; el bit 0: sin lanzamiento no hay medidor
	ret nc			;4fc8
	rrca			;4fc9   ; el bit 1: con la pelota en el aire, tampoco
	ret c			;4fca
	rrca			;4fcb   ; ni con el brazo armandose
	ret c			;4fcc
	rrca			;4fcd   ; ni con la cuenta en pantalla
	ret c			;4fce
	ld hl,0e360h		;4fcf   ; HL = 0xE360, el mando del medidor
	bit 0,(hl)		;4fd2   ; su bit 0: puesto quiere decir que baja
	jr nz,baja_el_medidor		;4fd4
sube_el_medidor:		; Suma uno en BCD al contador de 0xE361 -las unidades dan la vuelta en 0x0A y las decenas en 0xA0- y enciende un tile mas de la barra
	inc hl			;4fd6
	ld a,(hl)			;4fd7   ; A = el contador de 0xE361, mas uno
	inc a			;4fd8
	ld b,a			;4fd9
	and 00fh		;4fda   ; las unidades...
	cp 00ah		;4fdc   ; ...que en BCD dan la vuelta en 0x0A
	ld a,b			;4fde
	jr nz,guarda_el_contador		;4fdf
	and 0f0h		;4fe1   ; se ponen a cero y suben las decenas
	add a,010h		;4fe3
	inc hl			;4fe5
	inc hl			;4fe6
	inc (hl)			;4fe7   ; (0xE363), un paso mas
	dec hl			;4fe8
	dec hl			;4fe9
	cp 0a0h		;4fea   ; y en 0xA0 dan la vuelta las decenas
	jr nz,guarda_el_contador		;4fec
	xor a			;4fee
	inc hl			;4fef
	inc (hl)			;4ff0   ; (0xE362), la vuelta entera
	dec hl			;4ff1
guarda_el_contador:		; Deja el contador nuevo y, si llego a 60, hace que a partir de ahora baje
	ld (hl),a			;4ff2   ; el contador nuevo
	cp 060h		;4ff3   ; en 60 se da la vuelta
	jr z,da_la_vuelta_el_medidor		;4ff5
	inc hl			;4ff7
	inc hl			;4ff8
	inc hl			;4ff9
	inc (hl)			;4ffa   ; (0xE364), un paso mas
	ld a,09fh		;4ffb   ; A = 0x9F, el tile de casilla llena
enciende_una_casilla:		; Recorre las casillas de la barra saltandose las que ya estan llenas y sube una la primera que no lo este
	inc hl			;4ffd
	cp (hl)			;4ffe   ; esta llena?
	jr z,enciende_una_casilla		;4fff
	inc (hl)			;5001   ; la primera que no, un paso mas
	jr pinta_la_barra		;5002
baja_el_medidor:		; Lo mismo del reves: resta uno en BCD -las unidades dan la vuelta en 0x0F y el contador entero en 0xF9, que vuelve a 0x99- y apaga un tile de la barra
	inc hl			;5004
	ld a,(hl)			;5005   ; A = el contador, menos uno
	dec a			;5006
	ld b,a			;5007
	and 00fh		;5008   ; las unidades...
	cp 00fh		;500a   ; ...que al bajar dan la vuelta en 0x0F
	ld a,b			;500c
	jr nz,guarda_el_contador_que_baja		;500d
	inc hl			;500f
	inc hl			;5010
	dec (hl)			;5011   ; (0xE363), un paso menos
	dec hl			;5012
	dec hl			;5013
	and 0f0h		;5014
	or 009h		;5016   ; se quedan en 9
	cp 0f9h		;5018   ; y por debajo de 0xF9...
	jr nz,guarda_el_contador_que_baja		;501a
	inc hl			;501c
	ld (hl),000h		;501d   ; ...(0xE362) a cero
	dec hl			;501f
	ld a,099h		;5020   ; y el contador vuelve a 0x99
guarda_el_contador_que_baja:		; Deja el contador nuevo y, en 0x70, se acabo el plazo
	ld (hl),a			;5022
	cp 070h		;5023   ; 0x70: se acabo
	jr z,se_acabo_el_plazo		;5025
	inc hl			;5027
	inc hl			;5028
	inc hl			;5029
	dec (hl)			;502a   ; (0xE364), un paso menos
	ld a,098h		;502b   ; A = 0x98, la casilla a medias
apaga_una_casilla:		; Busca la primera casilla que no este a medias y baja la de antes
	inc hl			;502d
	cp (hl)			;502e   ; a medias?
	jr nz,apaga_una_casilla		;502f
	dec hl			;5031
	dec (hl)			;5032   ; la de antes, un paso menos
pinta_la_barra:		; Los ocho tiles de la barra, de 0xE367 a la fila 0x7ae3 de la pantalla, abajo a la izquierda
	ld hl,0e367h		;5033   ; HL = 0xE367, las ocho casillas
	ld de,07ae3h		;5036   ; DE = VRAM 0x7ae3
	ld b,008h		;5039   ; ocho tiles
	call copia_bytes_con_candado		;503b
	ret			;503e
se_acabo_el_plazo:		; Con el medidor agotado, la jugada se resuelve sola
	jp pone_el_medidor_a_cero		;503f
da_la_vuelta_el_medidor:		; Llegado a 60, el bit 0 de 0xE360 hace que a partir de ahora baje
	ld hl,0e360h		;5042
	ld (hl),001h		;5045   ; (0xE360) := 1: de bajada
	ret			;5047

; ----------------------------------------------------------------------
; DATOS tabla_punteros_5048: 12 punteros de 16 bits que lee 0x5e75; dos de
;   ellos son 0x0000
;   0x5048..0x5060  (24 bytes)
DATA_tabla_punteros_5048:
	defw 05114h,0511ch,05124h,0512ch,05134h,05134h,00000h,00000h	; 5048
	defw 050ech,050f4h,050fch,05104h	; 5058

; ----------------------------------------------------------------------
; DATOS datos_y_guiones_5060: El bloque grande al que apuntan
;   tabla_punteros_5048 y los destinos de 0x64a7: guiones de graficos mas sus
;   tablas. Formato interno no separado bloque a bloque en esta pasada
;   0x5060..0x5a32  (2514 bytes)
DATA_datos_y_guiones_5060:
	defb 00ch,051h,00ch,051h,000h,000h,000h,000h,06ch,051h,074h,051h,07ch,051h,084h,051h	; 5060  .Q.Q....lQtQ|Q.Q
	defb 08ch,051h,094h,051h,000h,000h,000h,000h,03ch,051h,044h,051h,04ch,051h,054h,051h	; 5070  .Q.Q....<QDQLQTQ
	defb 05ch,051h,064h,051h,000h,000h,000h,000h,0f6h,058h,018h,059h,03ah,059h,05ch,059h	; 5080  \QdQ.....X.Y:Y\Y
	defb 07eh,059h,0a0h,059h,0c2h,059h,0e4h,059h,03ah,059h,05ch,059h,0c2h,059h,0e4h,059h	; 5090  ~Y.Y.Y.Y:Y\Y.Y.Y
	defb 0f6h,058h,018h,059h,03ah,059h,05ch,059h,063h,057h,085h,057h,01fh,057h,041h,057h	; 50a0  .X.Y:Y\YcW.W.WAW
	defb 0ebh,057h,00dh,058h,0a7h,057h,0c9h,057h,072h,058h,094h,058h,02fh,058h,051h,058h	; 50b0  .W.X.W.WrX.X/XQX
	defb 0b4h,058h,0b4h,058h,0d6h,058h,000h,000h,006h,05ah,006h,05ah,006h,05ah,006h,05ah	; 50c0  .X.X.X...Z.Z.Z.Z
	defb 006h,05ah,006h,05ah,006h,05ah,006h,05ah,006h,05ah,006h,05ah,006h,05ah,006h,05ah	; 50d0  .Z.Z.Z.Z.Z.Z.Z.Z
	defb 006h,05ah,006h,05ah,006h,05ah,006h,05ah,02ah,05ah,0fdh,056h,09ch,051h,0afh,051h	; 50e0  .Z.Z.Z.Z*Z.V.Q.Q
	defb 0c0h,051h,0c7h,051h,0cdh,051h,0e5h,051h,0f3h,051h,0fdh,051h,003h,052h,022h,052h	; 50f0  .Q.Q.Q.Q.Q.Q.R"R
	defb 038h,052h,048h,052h,04eh,052h,06bh,052h,080h,052h,090h,052h,096h,052h,0b0h,052h	; 5100  8RHRNRkR.R.R.R.R
	defb 0c2h,052h,0d3h,052h,0d9h,052h,0ech,052h,0f9h,052h,0ffh,052h,005h,053h,01dh,053h	; 5110  .R.R.R.R.R.R.S.S
	defb 02bh,053h,035h,053h,03bh,053h,059h,053h,071h,053h,081h,053h,087h,053h,0a3h,053h	; 5120  +S5S;SYSqS.S.S.S
	defb 0bbh,053h,0cbh,053h,0d1h,053h,0ech,053h,0feh,053h,00fh,054h,015h,054h,02eh,054h	; 5130  .S.S.S.S.S.T.T.T
	defb 03ch,054h,04ch,054h,052h,054h,066h,054h,073h,054h,086h,054h,08ch,054h,0a3h,054h	; 5140  <TLTRTfTsT.T.T.T
	defb 0b0h,054h,0c4h,054h,0cah,054h,0e6h,054h,0f4h,054h,006h,055h,00ch,055h,02ch,055h	; 5150  .T.T.T.T.T.U.U,U
	defb 03ah,055h,048h,055h,04eh,055h,06ah,055h,079h,055h,087h,055h,08dh,055h,0a6h,055h	; 5160  :UHUNUjUyU.U.U.U
	defb 0b4h,055h,0c4h,055h,0cah,055h,0deh,055h,0ebh,055h,0feh,055h,004h,056h,01ah,056h	; 5170  .U.U.U.U.U.U.V.V
	defb 027h,056h,039h,056h,03fh,056h,05ah,056h,068h,056h,078h,056h,07eh,056h,09dh,056h	; 5180  'V9V?VZVhVxV~V.V
	defb 0ach,056h,0bbh,056h,0c1h,056h,0d9h,056h,0e8h,056h,0f7h,056h,08fh,03ch,07eh,03ch	; 5190  .V.V.V.V.V.V.<~<
	defb 000h,000h,058h,0c3h,0e2h,03ch,038h,000h,020h,030h,00ch,00eh,011h,000h,000h,089h	; 51a0  ..X..<8. 0......
	defb 061h,0d3h,09eh,00eh,021h,023h,01eh,00ch,006h,007h,000h,002h,080h,00eh,000h,000h	; 51b0  a...!#..........
	defb 083h,084h,0fch,078h,01dh,000h,000h,001h,004h,005h,003h,003h,005h,090h,078h,0fch	; 51c0  ...x..........x.
	defb 048h,000h,000h,073h,007h,0e5h,0ebh,07ch,030h,000h,000h,000h,030h,038h,005h,000h	; 51d0  H..s...|0...08..
	defb 003h,080h,008h,000h,000h,08ah,040h,0c6h,0fch,08ch,088h,040h,066h,07ch,038h,018h	; 51e0  ......@....@f|8.
	defb 016h,000h,000h,087h,0b4h,0fch,07ch,000h,000h,002h,004h,019h,000h,000h,005h,004h	; 51f0  ......|.........
	defb 004h,002h,005h,083h,007h,00fh,002h,003h,000h,083h,070h,0f3h,0cch,005h,000h,089h	; 5200  ..........p.....
	defb 001h,001h,000h,082h,086h,076h,064h,000h,0c0h,004h,000h,085h,020h,038h,000h,080h	; 5210  .....vd..... 8..
	defb 0c0h,000h,08bh,006h,02eh,0ffh,03ch,033h,00fh,03fh,01ch,00ch,00ch,006h,00ah,000h	; 5220  ......<3.?......
	defb 084h,0c0h,0e0h,060h,040h,007h,000h,000h,088h,006h,007h,002h,000h,000h,000h,080h	; 5230  ...`@...........
	defb 0c0h,008h,000h,082h,080h,004h,00eh,000h,000h,002h,003h,004h,002h,001h,089h,007h	; 5240  ................
	defb 00fh,002h,000h,000h,000h,070h,0f3h,0cch,005h,000h,08ah,001h,001h,000h,082h,086h	; 5250  .....p..........
	defb 076h,064h,002h,0c6h,006h,006h,000h,082h,080h,0c0h,000h,08bh,006h,02eh,0ffh,03ch	; 5260  vd.............<
	defb 033h,00fh,03fh,01ch,00ch,00ch,006h,008h,000h,083h,060h,0e0h,0c0h,00ah,000h,000h	; 5270  3.?.......`.....
	defb 088h,006h,007h,002h,000h,000h,000h,080h,0c0h,008h,000h,082h,080h,004h,00eh,000h	; 5280  ................
	defb 000h,002h,003h,004h,002h,001h,08ah,03ch,07eh,025h,001h,000h,018h,000h,026h,0f7h	; 5290  .......<~%....&.
	defb 077h,004h,000h,083h,018h,03ch,000h,003h,080h,004h,000h,002h,080h,006h,000h,000h	; 52a0  w....<..........
	defb 08ah,003h,067h,0feh,0d8h,008h,000h,07fh,03eh,018h,018h,006h,000h,081h,080h,00fh	; 52b0  ..g.....>.......
	defb 000h,000h,003h,001h,084h,000h,0b4h,0fch,078h,004h,000h,081h,010h,004h,000h,002h	; 52c0  ........x.......
	defb 080h,00eh,000h,000h,004h,004h,004h,0feh,005h,011h,000h,08fh,03ch,07eh,03ch,000h	; 52d0  ............<~<.
	defb 000h,01ah,0c3h,047h,03ch,01ch,002h,006h,00ch,030h,070h,000h,089h,0c3h,075h,03ch	; 52e0  ...G<....0p...u<
	defb 038h,042h,062h,03ch,018h,030h,017h,000h,000h,01dh,000h,083h,021h,03fh,01eh,000h	; 52f0  8Bb<.0......!?..
	defb 0fch,005h,004h,0f6h,0fbh,005h,000h,003h,001h,008h,000h,090h,01eh,03fh,012h,000h	; 5300  .............?..
	defb 000h,0ceh,0e0h,0a7h,0d7h,03eh,00ch,000h,000h,000h,00ch,01ch,000h,08ah,004h,0c6h	; 5310  .....>..........
	defb 07eh,062h,022h,004h,0cch,07ch,038h,030h,016h,000h,000h,019h,000h,087h,02dh,03fh	; 5320  ~b"..|80......-?
	defb 01eh,000h,000h,040h,020h,000h,0fbh,004h,005h,0f9h,0fbh,087h,000h,041h,061h,06eh	; 5330  ...@ ........Aan
	defb 026h,000h,003h,004h,000h,08eh,004h,01ch,000h,001h,003h,0e0h,0f0h,040h,000h,000h	; 5340  &............@..
	defb 000h,00eh,0cfh,033h,005h,000h,002h,080h,000h,08bh,00ch,00eh,01fh,007h,019h,07eh	; 5350  ...3...........~
	defb 0ffh,0c7h,046h,006h,00ch,006h,000h,086h,080h,0e0h,080h,080h,000h,080h,009h,000h	; 5360  ..F.............
	defb 000h,008h,000h,082h,001h,010h,00eh,000h,088h,060h,0e0h,040h,000h,000h,000h,001h	; 5370  .........`.@....
	defb 003h,000h,0feh,003h,001h,0fah,0ffh,088h,000h,041h,061h,06eh,026h,040h,063h,060h	; 5380  .........Aan&@c`
	defb 006h,000h,08bh,001h,003h,0e0h,0f0h,040h,000h,000h,000h,00eh,0cfh,033h,005h,000h	; 5390  .......@.....3..
	defb 002h,080h,000h,08bh,00ch,00eh,01fh,0c7h,0f9h,07eh,01fh,007h,006h,006h,00ch,006h	; 53a0  .........~......
	defb 000h,086h,080h,0e0h,080h,080h,000h,080h,009h,000h,000h,008h,000h,082h,081h,021h	; 53b0  ...............!
	defb 00eh,000h,088h,060h,0e0h,040h,000h,000h,000h,001h,003h,000h,0feh,003h,001h,0fah	; 53c0  ...`.@..........
	defb 0ffh,081h,000h,003h,001h,004h,000h,002h,001h,006h,000h,08ah,03ch,07eh,0a4h,080h	; 53d0  ............<~..
	defb 000h,018h,000h,064h,0efh,0eeh,004h,000h,082h,018h,03ch,000h,081h,001h,00fh,000h	; 53e0  ...d......<.....
	defb 08ah,0c0h,0e6h,07fh,01bh,010h,000h,0feh,07ch,018h,018h,006h,000h,000h,004h,000h	; 53f0  ........|.......
	defb 002h,001h,00eh,000h,003h,080h,084h,000h,02dh,03fh,01fh,004h,000h,081h,008h,000h	; 5400  ........-?......
	defb 0fch,004h,0fch,0fah,0fbh,090h,03ch,0fch,01ch,00ch,000h,01ch,010h,03ch,07ch,07ch	; 5410  ......<......<||
	defb 000h,000h,030h,070h,003h,007h,005h,000h,082h,0c0h,040h,009h,000h,000h,08ah,004h	; 5420  ..0p......@.....
	defb 040h,0dch,080h,000h,006h,0fch,06ch,01ch,00eh,016h,000h,000h,081h,00ch,004h,00eh	; 5430  @.....l.........
	defb 002h,00ch,087h,08ch,0c4h,0f4h,00ch,006h,00ch,00ch,012h,000h,000h,004h,004h,005h	; 5440  ................
	defb 0fbh,006h,090h,03ch,0fch,01ch,00ch,000h,01ch,022h,067h,073h,038h,000h,000h,030h	; 5450  ...<....."gs8..0
	defb 070h,003h,007h,010h,000h,000h,089h,062h,0ddh,098h,00ch,000h,078h,036h,00eh,007h	; 5460  p......b....x6..
	defb 017h,000h,000h,089h,080h,0c0h,0f0h,000h,000h,000h,001h,01eh,018h,00ah,000h,084h	; 5470  ................
	defb 038h,078h,0e0h,080h,009h,000h,000h,004h,005h,004h,002h,006h,090h,01eh,07eh,00eh	; 5480  8x............~.
	defb 006h,000h,000h,04eh,0feh,078h,000h,000h,000h,018h,038h,001h,003h,00eh,000h,082h	; 5490  ...N.x....8.....
	defb 0c0h,080h,000h,089h,0ech,0c4h,006h,01eh,07eh,0ech,0dch,01ch,00eh,017h,000h,000h	; 54a0  ........~.......
	defb 005h,000h,085h,001h,00fh,039h,0f0h,0e0h,006h,000h,083h,010h,018h,01eh,003h,000h	; 54b0  .....9..........
	defb 002h,080h,008h,000h,000h,003h,005h,005h,002h,0fbh,090h,00fh,01fh,00fh,003h,000h	; 54c0  ................
	defb 030h,06ch,07eh,0fdh,000h,000h,000h,00ch,01ch,000h,001h,008h,000h,081h,080h,004h	; 54d0  0l~.............
	defb 000h,083h,020h,0e0h,0c0h,000h,08ah,080h,07ch,09ch,00eh,012h,07eh,0ech,0dch,01ch	; 54e0  .. .....|...~...
	defb 00eh,016h,000h,000h,004h,000h,083h,078h,0ffh,07fh,009h,000h,087h,002h,003h,003h	; 54f0  .......x........
	defb 000h,020h,0e0h,0c0h,009h,000h,000h,002h,004h,005h,002h,0f8h,08eh,007h,00fh,007h	; 5500  . ..............
	defb 003h,0f0h,07bh,030h,018h,000h,007h,000h,000h,006h,00eh,002h,000h,004h,080h,085h	; 5510  ..{0............
	defb 000h,080h,000h,000h,0c0h,004h,000h,083h,010h,070h,0e0h,000h,08bh,004h,086h,046h	; 5520  .........p.....F
	defb 0fch,07ch,070h,00ch,0ech,0dch,01ch,007h,015h,000h,086h,0c0h,0e0h,0e0h,070h,038h	; 5530  .|p...........p8
	defb 00ch,00fh,000h,082h,020h,03ch,009h,000h,000h,001h,003h,005h,0feh,0fch,090h,078h	; 5540  .... <.........x
	defb 0f8h,079h,03bh,001h,033h,003h,000h,006h,038h,000h,060h,020h,000h,003h,007h,005h	; 5550  .y;.3...8.` ....
	defb 000h,002h,080h,006h,000h,083h,080h,080h,000h,000h,08bh,002h,043h,076h,0feh,07fh	; 5560  ............Cv..
	defb 038h,006h,03eh,01ch,00eh,00fh,015h,000h,000h,083h,080h,0c1h,0f1h,00fh,000h,085h	; 5570  8.>.............
	defb 080h,0e0h,078h,038h,018h,009h,000h,000h,005h,003h,004h,002h,006h,005h,000h,082h	; 5580  ..x8............
	defb 003h,002h,009h,000h,090h,03ch,03fh,038h,030h,000h,038h,008h,03ch,03eh,03eh,000h	; 5590  .....<?80.8.<>>.
	defb 000h,00ch,00eh,0c0h,0e0h,000h,016h,000h,08ah,020h,002h,03bh,001h,000h,060h,03fh	; 55a0  ......... .;..`?
	defb 016h,038h,070h,000h,012h,000h,081h,030h,004h,070h,089h,030h,030h,031h,023h,02fh	; 55b0  .8p....0.p.001#/
	defb 030h,060h,030h,030h,000h,0fch,0feh,0fbh,0f9h,0fah,010h,000h,090h,03ch,03fh,038h	; 55c0  0`00.........<?8
	defb 030h,000h,038h,044h,0e6h,0ceh,01ch,000h,000h,00ch,00eh,0c0h,0e0h,000h,017h,000h	; 55d0  0.8D............
	defb 089h,046h,0bbh,019h,030h,000h,01eh,02ch,070h,0e0h,000h,00ah,000h,085h,070h,070h	; 55e0  .F..0..,p.....pp
	defb 01ch,006h,001h,008h,000h,083h,004h,00ch,03ch,004h,000h,082h,0e0h,060h,000h,0fch	; 55f0  ........<....`..
	defb 0feh,0fch,0fbh,0fch,00eh,000h,092h,003h,001h,078h,07eh,070h,060h,000h,000h,072h	; 5600  .........x~p`..r
	defb 07fh,01eh,000h,000h,000h,018h,01ch,080h,0e0h,000h,017h,000h,089h,03eh,023h,060h	; 5610  .............>#`
	defb 078h,07eh,037h,03bh,038h,070h,000h,006h,000h,083h,004h,00ch,03ch,003h,000h,002h	; 5620  x~7;8p......<...
	defb 001h,00dh,000h,085h,080h,0f0h,09ch,00fh,007h,000h,0fdh,0feh,0fbh,0fch,004h,008h	; 5630  ................
	defb 000h,081h,001h,004h,000h,093h,004h,007h,003h,0f0h,0f8h,0e0h,0c0h,000h,00ch,036h	; 5640  ...............6
	defb 07eh,0bfh,000h,040h,020h,030h,038h,000h,080h,000h,016h,000h,08ah,001h,03eh,039h	; 5650  ~..@ 08.......>9
	defb 070h,048h,07eh,037h,03bh,038h,070h,000h,009h,000h,087h,040h,0c0h,0c0h,000h,004h	; 5660  pH~7;8p....@....
	defb 007h,003h,00dh,000h,083h,01eh,0ffh,0feh,000h,0feh,0feh,0fbh,0f9h,008h,004h,001h	; 5670  ................
	defb 085h,000h,001h,000h,000h,003h,004h,000h,093h,008h,00eh,007h,0e0h,0f0h,0e0h,0c0h	; 5680  ................
	defb 00fh,0deh,00ch,018h,000h,0e0h,000h,000h,060h,070h,000h,000h,000h,015h,000h,08bh	; 5690  ........`p......
	defb 040h,061h,062h,03fh,03eh,00eh,030h,037h,03bh,038h,070h,000h,00eh,000h,082h,004h	; 56a0  @ab?>.07;8p.....
	defb 03ch,009h,000h,087h,003h,007h,007h,00eh,01ch,030h,000h,000h,0ffh,0feh,0fbh,0f5h	; 56b0  <........0......
	defb 004h,005h,000h,002h,001h,009h,000h,090h,01eh,01fh,09eh,0dch,080h,0cch,0c0h,000h	; 56c0  ................
	defb 030h,00eh,000h,003h,002h,080h,0e0h,070h,000h,015h,000h,08bh,040h,0c2h,067h,07fh	; 56d0  0......p....@.g.
	defb 0feh,01ch,060h,07ch,038h,070h,0f0h,000h,00bh,000h,085h,001h,007h,01eh,01ch,018h	; 56e0  ..`|8p..........
	defb 00ah,000h,082h,081h,08fh,004h,000h,000h,0fbh,0feh,0fch,0f9h,0fah,0a0h,000h,000h	; 56f0  ................
	defb 003h,007h,005h,007h,003h,00ch,017h,017h,01bh,00ch,00eh,00ch,004h,00eh,000h,000h	; 5700  ................
	defb 080h,0e0h,040h,0c0h,080h,060h,0f0h,090h,070h,0e0h,0b0h,070h,020h,070h,000h,0a0h	; 5710  ..@..`..p..p p..
	defb 000h,000h,003h,00fh,007h,007h,003h,00fh,01bh,01fh,00fh,003h,007h,007h,002h,007h	; 5720  ................
	defb 000h,000h,080h,0c0h,0c0h,0c0h,080h,0f0h,0f8h,0ech,0f8h,0e0h,070h,020h,070h,000h	; 5730  ............p p.
	defb 000h,0a0h,000h,000h,003h,00fh,007h,007h,003h,00fh,00bh,01fh,00fh,003h,007h,002h	; 5740  ................
	defb 007h,000h,000h,000h,080h,0c0h,0c0h,0c0h,080h,0f0h,0e8h,0fch,0dch,0e0h,070h,070h	; 5750  ..............pp
	defb 020h,070h,000h,0a0h,000h,000h,003h,007h,005h,007h,003h,00ch,01fh,037h,01fh,003h	; 5760   p...........7..
	defb 007h,006h,002h,007h,000h,000h,080h,0e0h,040h,0c0h,080h,070h,098h,00ch,008h,0f0h	; 5770  ........@..p....
	defb 070h,020h,070h,000h,000h,0a0h,000h,000h,003h,007h,005h,007h,003h,00ch,01fh,017h	; 5780  p p.............
	defb 03dh,01dh,007h,002h,007h,000h,000h,000h,080h,0e0h,040h,0c0h,080h,070h,098h,0dch	; 5790  =.........@..p..
	defb 0dch,0dch,070h,030h,020h,070h,000h,0a0h,003h,00fh,005h,007h,003h,004h,007h,01fh	; 57a0  ..p0 p..........
	defb 01bh,005h,00eh,00eh,01ch,018h,060h,020h,080h,0c0h,040h,0c0h,080h,060h,0d0h,010h	; 57b0  ......` ..@..`..
	defb 000h,0e4h,0eeh,0fah,070h,000h,000h,000h,000h,0a0h,000h,000h,003h,00fh,005h,007h	; 57c0  ....p...........
	defb 0c3h,0ech,0ffh,077h,003h,007h,00fh,00ch,004h,01ch,000h,000h,080h,0c0h,040h,0c0h	; 57d0  ...w..........@.
	defb 080h,070h,0f8h,0c8h,0dch,08ch,060h,030h,060h,000h,000h,0a0h,001h,003h,002h,003h	; 57e0  .p....`0`.......
	defb 001h,006h,00bh,008h,000h,027h,077h,05fh,00eh,000h,000h,000h,0c0h,0f0h,0a0h,0e0h	; 57f0  .....'w_........
	defb 0c0h,020h,0e0h,0f8h,0d8h,0a0h,070h,070h,038h,018h,006h,004h,000h,0a0h,000h,000h	; 5800  . ....pp8.......
	defb 001h,003h,002h,003h,001h,00eh,01fh,013h,03bh,031h,006h,00ch,006h,000h,000h,000h	; 5810  ........;1......
	defb 0c0h,0f0h,0a0h,0e0h,0c3h,037h,0ffh,0eeh,0c0h,0e0h,0f0h,030h,020h,038h,000h,0a0h	; 5820  .....7.....0 8..
	defb 000h,000h,0c1h,0efh,0e2h,0e3h,061h,01eh,00fh,003h,003h,005h,00eh,002h,006h,000h	; 5830  ......a.........
	defb 000h,000h,0c0h,0e0h,0e0h,0e0h,0c0h,030h,0f8h,098h,078h,030h,0f0h,078h,010h,038h	; 5840  .......0..x0.x.8
	defb 000h,003h,000h,09dh,001h,007h,002h,003h,000h,007h,01fh,071h,022h,007h,006h,002h	; 5850  ...........q"...
	defb 00eh,000h,000h,000h,0c0h,0e0h,0e0h,0e0h,0d8h,0d6h,0e4h,0e0h,0f0h,070h,03eh,01ah	; 5860  .............p>.
	defb 000h,000h,0a0h,000h,000h,003h,007h,005h,007h,003h,004h,00fh,018h,01eh,008h,00fh	; 5870  ................
	defb 006h,00ch,00eh,000h,000h,080h,0e0h,048h,0dch,09ch,06ch,0f8h,0b0h,060h,0f0h,030h	; 5880  .......H..l..`.0
	defb 060h,070h,000h,000h,003h,000h,08ch,003h,007h,007h,007h,01bh,06bh,027h,007h,00fh	; 5890  `p..........k'..
	defb 00eh,07ch,058h,004h,000h,08dh,080h,0e0h,040h,0c0h,000h,0e0h,0f8h,08eh,044h,0e0h	; 58a0  .|X.....@.....D.
	defb 060h,040h,070h,000h,0a0h,000h,000h,021h,036h,033h,013h,019h,00ah,007h,007h,001h	; 58b0  `@p....!63......
	defb 003h,007h,002h,007h,000h,000h,004h,0ceh,0aeh,0e6h,0e4h,0cch,028h,0f0h,0f0h,040h	; 58c0  ............(..@
	defb 0e0h,070h,030h,020h,078h,000h,003h,000h,08ch,001h,003h,003h,005h,00eh,01dh,00dh	; 58d0  .p0 x...........
	defb 006h,002h,007h,002h,007h,004h,000h,08dh,0c0h,0e0h,0e0h,0f0h,0d8h,02ch,0cch,03ch	; 58e0  .............,.<
	defb 0f8h,0dch,07eh,065h,003h,000h,0a0h,001h,003h,003h,003h,000h,003h,007h,006h,00eh	; 58f0  ..~e............
	defb 00bh,075h,05eh,00ch,000h,000h,000h,0c0h,0e0h,080h,040h,040h,0a0h,060h,0d8h,0f0h	; 5900  .u^.......@@.`..
	defb 040h,0f0h,078h,01ah,006h,004h,000h,000h,0a0h,000h,000h,001h,003h,003h,003h,01ch	; 5910  @.x.............
	defb 01bh,037h,033h,006h,007h,00eh,00ch,018h,01ch,000h,000h,0c0h,0e0h,080h,040h,046h	; 5920  .73...........@F
	defb 0f6h,074h,0bch,0d8h,0a0h,060h,040h,060h,000h,000h,0a0h,003h,007h,001h,002h,002h	; 5930  .t...`@`........
	defb 005h,006h,01bh,00fh,002h,00fh,01eh,058h,060h,020h,000h,080h,0c0h,0c0h,0c0h,000h	; 5940  .......X` ......
	defb 0c0h,0e0h,060h,070h,0d4h,0aeh,07ah,030h,000h,000h,000h,000h,0a0h,000h,000h,003h	; 5950  ..`p..z0........
	defb 007h,001h,002h,062h,06fh,02eh,03dh,01bh,005h,006h,002h,006h,000h,000h,000h,080h	; 5960  ...bo.=.........
	defb 0c0h,0c0h,0c0h,038h,0d8h,0ech,0cch,060h,0e0h,070h,030h,018h,038h,000h,0a0h,003h	; 5970  ...8...`.p0.8...
	defb 00fh,001h,003h,001h,002h,003h,00ch,007h,001h,003h,007h,006h,008h,018h,000h,0c0h	; 5980  ................
	defb 0e0h,060h,0e0h,0c0h,020h,070h,0e0h,010h,074h,0beh,09ah,000h,000h,000h,000h,000h	; 5990  .`.. p..t.......
	defb 0a0h,000h,003h,00fh,001h,003h,001h,002h,017h,035h,01ch,00dh,003h,007h,002h,001h	; 59a0  .........5......
	defb 006h,000h,0c0h,0e0h,060h,0e0h,0c0h,038h,0dch,0ech,0d8h,0c0h,0b0h,078h,008h,000h	; 59b0  ....`..8.....x..
	defb 000h,000h,0a0h,003h,007h,006h,007h,003h,004h,00eh,007h,008h,02eh,07dh,059h,000h	; 59c0  .............}Y.
	defb 000h,000h,000h,0c0h,0f0h,080h,0c0h,080h,040h,0c0h,030h,0e0h,080h,0c0h,0e0h,060h	; 59d0  ........@.0....`
	defb 010h,018h,000h,000h,0a0h,000h,003h,007h,006h,007h,003h,01ch,03bh,037h,01bh,003h	; 59e0  ............;7..
	defb 00dh,01eh,010h,000h,000h,000h,0c0h,0f0h,080h,0c0h,080h,040h,0e8h,0ach,038h,0b0h	; 59f0  ...........@..8.
	defb 0c0h,0e0h,040h,080h,060h,000h,0a0h,000h,000h,003h,00fh,005h,007h,003h,00ch,01fh	; 5a00  ..@.`...........
	defb 03fh,037h,045h,0afh,00eh,008h,018h,000h,000h,080h,0c0h,040h,0c0h,080h,060h,0f0h	; 5a10  ?7E........@..`.
	defb 0b8h,0d8h,044h,0eah,0e0h,020h,030h,000h,058h,000h,084h,030h,078h,078h,030h,01ch	; 5a20  ..D.. 0.X..0xx0.
	defb 000h,000h	; 5a30

; ======================================================================
; CODIGO 0x5a32..0x5b9c  (362 bytes)
; ======================================================================


monta_la_jugada:		; Deja el campo listo para la jugada siguiente: esconde los sprites, borra media docena de banderas, copia los dos registros de arranque a 0xE100 y 0xE140, despliega las QUINCE fichas de los jugadores desde 0x5c03, ajusta los dos equipos y pone el medidor a cero
	call esconde_todos_los_sprites		;5a32   ; los 32 sprites, fuera de la pantalla
	xor a			;5a35
	ld (0e197h),a		;5a36   ; (0xE197) := 0
	ld (0e388h),a		;5a39   ; (0xE388) := 0
	ld (0e430h),a		;5a3c   ; (0xE430) := 0
	ld (0e35fh),a		;5a3f   ; (0xE35F) := 0
	ld (0e389h),a		;5a42   ; (0xE389) := 0
	ld (0e38bh),a		;5a45   ; (0xE38B) := 0
	ld (0e40ch),a		;5a48   ; (0xE40C) := 0
	ld (0e011h),a		;5a4b   ; (0xE011) := 0, la entrada del segundo jugador
	ld a,002h		;5a4e
	ld (0e001h),a		;5a50   ; (0xE001) := 2, el plazo
	ld (0e400h),a		;5a53   ; (0xE400) := 2, el estado de la jugada
	ld de,0e100h		;5a56   ; DE = 0xE100, el registro del lanzador
	ld hl,05bd9h		;5a59   ; HL = 0x5bd9, los dos registros de arranque
	ld a,(de)			;5a5c   ; A se queda con lo que HABIA en 0xE100, antes de pisarlo
	ld bc,00015h		;5a5d   ; 21 bytes por registro
	ldir		;5a60
	ld de,0e140h		;5a62   ; y el segundo, a 0xE140
	ld c,015h		;5a65
	ldir		;5a67
	bit 3,a		;5a69   ; el bit 3 de lo que habia...
	jr z,copia_las_cuatro_marcas		;5a6b
	ld hl,0e100h		;5a6d
	set 3,(hl)		;5a70   ; ...se conserva: es el unico que sobrevive al reinicio
copia_las_cuatro_marcas:		; Se lleva a 0xE700 los cuatro bytes que estan a una fila de distancia dentro del bloque de 0xE180
	ld hl,0e180h		;5a72   ; HL = 0xE180
	ld de,0e700h		;5a75   ; DE = 0xE700, el hueco de trabajo
	ld b,004h		;5a78   ; cuatro
una_marca:		; Un byte, y HL sube 32 hasta el siguiente
	ld a,(hl)			;5a7a   ; el byte de esta ficha
	ld (de),a			;5a7b   ; al hueco de trabajo
	inc de			;5a7c
	call avanza_una_fila		;5a7d   ; 32 bytes hasta la ficha siguiente
	djnz una_marca		;5a80
	ld de,0e180h		;5a82
	ld b,00fh		;5a85
	ld a,(0e100h)		;5a87
	bit 3,a		;5a8a
	jr z,despliega_las_fichas		;5a8c
	ld b,00eh		;5a8e
despliega_las_fichas:		; Las fichas de los jugadores en el campo. En la ROM ocupan 21 bytes seguidos y en RAM 32, con dos huecos que se dejan sin tocar -uno de dos bytes y otro de ocho-, asi que hay que copiarlas en tres tramos. Son QUINCE, o catorce si el bit 3 de 0xE100 esta puesto, y quince por 32 bytes llenan exactamente 0xE180..0xE35F, justo hasta donde empieza el medidor
	ld hl,05c03h		;5a90   ; HL = 0x5c03, la primera ficha
despliega_una_ficha:		; Un byte, dos de hueco, trece bytes, ocho de hueco y siete bytes: 21 leidos y 32 escritos
	push bc			;5a93
	ld a,(hl)			;5a94   ; el primer byte de la ficha
	ld (de),a			;5a95
	inc hl			;5a96
	inc de			;5a97   ; y dos posiciones de hueco
	inc de			;5a98
	inc de			;5a99
	ld bc,0000dh		;5a9a   ; trece bytes seguidos
	ldir		;5a9d
	ex de,hl			;5a9f
	ld c,008h		;5aa0   ; ocho posiciones de hueco
	add hl,bc			;5aa2
	ex de,hl			;5aa3
	ld c,007h		;5aa4   ; y los siete ultimos
	ldir		;5aa6
	inc de			;5aa8   ; el byte 31, sin tocar
	pop bc			;5aa9
	djnz despliega_una_ficha		;5aaa
reparte_las_tres_marcas:		; Con las tres marcas guardadas en 0xE701: el bit 5 vale por el bit 1, y quien lo tenga puesto enciende los bits 1 y 6 de su ficha y se lleva un 1 en el byte 23
	ld hl,0e1a0h		;5aac   ; HL = 0xE1A0, la primera de las tres fichas
	ld de,0e701h		;5aaf   ; DE = 0xE701, las marcas
	ld b,003h		;5ab2   ; tres
una_marca_repartida:		; El bit 5 arrastra al bit 1
	ld a,(de)			;5ab4
	bit 5,a		;5ab5   ; el bit 5...
	jr z,marca_la_ficha		;5ab7
	set 1,a		;5ab9   ; ...enciende el 1
marca_la_ficha:		; Con el bit 1 puesto, la ficha se enciende y se le pone un 1 en el byte 23
	bit 1,a		;5abb
	ld a,000h		;5abd   ; A = 0 por defecto
	jr z,escribe_el_byte_23		;5abf
	set 1,(hl)		;5ac1   ; el bit 1 de la ficha
	set 6,(hl)		;5ac3   ; y el bit 6
	ld a,001h		;5ac5   ; A = 1 para el byte 23
escribe_el_byte_23:		; Guarda el 0 o el 1 veintitres bytes mas alla, sin perder A por el camino
	push hl			;5ac7
	ex af,af'			;5ac8   ; A a la sombra mientras HL avanza
	call avanza_veintitres		;5ac9   ; HL += 23
	ex af,af'			;5acc
	ld (hl),a			;5acd   ; ahi va
	pop hl			;5ace
	inc de			;5acf
	call avanza_una_fila		;5ad0   ; 32 bytes hasta la ficha siguiente
	djnz una_marca_repartida		;5ad3
remata_el_montaje:		; Cierra el reparto de fichas, borra los 143 bytes de 0xE030, elige los topes de los dos equipos y coloca lanzador y bateador segun de quien sea el turno
	call reparte_los_corredores		;5ad5
	ld hl,0e030h		;5ad8   ; HL = 0xE030
	ld bc,0008fh		;5adb   ; 143 bytes a cero
	call borra_bloque_de_ram		;5ade
	call elige_los_topes_de_los_equipos		;5ae1   ; los topes que le tocan a cada equipo
	ld hl,0e443h		;5ae4   ; HL = 0xE443, el equipo del primer jugador
	ld a,(0e402h)		;5ae7   ; (0xE402), el bit 0 dice de quien es el turno
	rrca			;5aea
	jr nc,coloca_al_bateador		;5aeb
	ld hl,0e444h		;5aed   ; y entonces el del segundo
coloca_al_bateador:		; El bit 0 del codigo de equipo decide de que lado batea: el bit 4 de 0xE140, el bit 3 de 0xE142 y el tile de 0xE144, que es 0x85 por un lado y 0x6D por el otro
	bit 0,(hl)		;5af0   ; el bit 0 del equipo
	ld hl,0e140h		;5af2
	set 4,(hl)		;5af5   ; el bit 4 de 0xE140
	jr z,L_5AFB		;5af7
	res 4,(hl)		;5af9   ; o apagado
L_5AFB:
	inc hl			;5afb
	inc hl			;5afc
	set 3,(hl)		;5afd   ; el bit 3 de 0xE142
	jr z,L_5B03		;5aff
	res 3,(hl)		;5b01
L_5B03:
	inc hl			;5b03
	inc hl			;5b04
	ld (hl),085h		;5b05   ; (0xE144) := 0x85, el tile del bateador
	jr z,coloca_al_lanzador		;5b07
	ld (hl),06dh		;5b09   ; o 0x6D
coloca_al_lanzador:		; Lo mismo para el lanzador, con las semillas de azar de 0xE445 y 0xE446 decidiendo el lado
	ld hl,0e445h		;5b0b   ; HL = 0xE445, la primera semilla
	ld a,(0e402h)		;5b0e   ; (0xE402) otra vez
	rrca			;5b11
	jr c,L_5B17		;5b12
	ld hl,0e446h		;5b14   ; o la segunda
L_5B17:
	bit 0,(hl)		;5b17   ; su bit 0
	ld hl,0e100h		;5b19
	set 4,(hl)		;5b1c   ; el bit 4 de 0xE100
	jr z,pone_el_bit_3_del_lanzador		;5b1e
	res 4,(hl)		;5b20   ; o apagado
pone_el_bit_3_del_lanzador:		; El bit 3 de 0xE102, del mismo bit de la semilla
	inc hl			;5b22
	inc hl			;5b23
	set 3,(hl)		;5b24   ; puesto...
	jr z,mira_si_hay_bateador_de_verdad		;5b26
	res 3,(hl)		;5b28   ; ...o quitado
mira_si_hay_bateador_de_verdad:		; Con un solo jugador y el turno del otro lado, 0x7ceb decide si el bateador es de los que pega, y entonces le pone el 0xA4 en 0xE143
	ld a,(0e012h)		;5b2a   ; (0xE012), el numero de jugadores
	or a			;5b2d
	jr nz,pone_el_medidor_a_cero		;5b2e   ; con dos jugadores, nada de esto
	ld a,(0e402h)		;5b30   ; (0xE402), de quien es el turno
	rrca			;5b33
	jr nc,pone_el_medidor_a_cero		;5b34
	call mira_si_hay_empate		;5b36   ; lo decide 0x7ceb
	jr nc,pone_el_medidor_a_cero		;5b39
	ld a,0a4h		;5b3b
	ld (0e143h),a		;5b3d   ; (0xE143) := 0xa4
pone_el_medidor_a_cero:		; Deja el medidor listo: contador en 0x70, las quince casillas de la barra al tile 0x98 -la casilla vacia- y la barra pintada
	ld hl,0e360h		;5b40   ; HL = 0xE360, el mando del medidor
	xor a			;5b43
	ld (hl),a			;5b44   ; (0xE360) := 0: de subida
	inc hl			;5b45
	ld (hl),070h		;5b46   ; (0xE361) := 0x70, el contador
	inc hl			;5b48
	ld (hl),a			;5b49   ; (0xE362) := 0
	inc hl			;5b4a
	ld (hl),a			;5b4b   ; (0xE363) := 0
	inc hl			;5b4c
	ld (hl),046h		;5b4d   ; (0xE364) := 0x46
	ld b,00fh		;5b4f   ; quince casillas
vacia_una_casilla:		; El tile 0x98, la casilla vacia
	inc hl			;5b51
	ld (hl),098h		;5b52   ; vacia
	djnz vacia_una_casilla		;5b54
	call pinta_la_barra		;5b56
	ret			;5b59
elige_los_topes_de_los_equipos:		; De la tabla de la liga que toque -0x5b9c la Central y 0x5ba8 la Pacific- saca dos numeros por equipo y los mete en los bytes 12 y 16 de la ficha del lanzador y de la del bateador. Son las caracteristicas del equipo elegido
	ld hl,05b9ch		;5b5a   ; HL = 0x5b9c, la tabla de la Central
	ld a,(0e440h)		;5b5d   ; (0xE440), la liga
	rrca			;5b60
	jr nc,L_5B66		;5b61
	ld hl,05ba8h		;5b63   ; o la de la Pacific
L_5B66:
	push hl			;5b66
	pop bc			;5b67
	ld hl,0e140h		;5b68   ; HL = 0xE140, la ficha del bateador
	ld de,0e100h		;5b6b   ; DE = 0xE100, la del lanzador
	ld a,(0e402h)		;5b6e   ; (0xE402), el turno
	rrca			;5b71
	ld a,(0e441h)		;5b72   ; (0xE441), el equipo del primer jugador
	call mete_dos_topes		;5b75
	ld a,(0e402h)		;5b78   ; el turno otra vez
	rrca			;5b7b
	ld a,(0e442h)		;5b7c   ; (0xE442), el del segundo
	ccf			;5b7f   ; y al reves para el segundo
mete_dos_topes:		; Con el acarreo se cambian las dos fichas de sitio; luego el equipo indexa la tabla por dos y los dos bytes van a +0x0c y +0x10
	push de			;5b80
	push hl			;5b81
	jr nc,L_5B85		;5b82   ; sin acarreo, cada ficha en su sitio
	ex de,hl			;5b84   ; con acarreo, cambiadas
L_5B85:
	and 00fh		;5b85   ; solo el numero de equipo
	push hl			;5b87
	pop ix		;5b88   ; IX = la ficha que toca
	push bc			;5b8a
	pop hl			;5b8b
	rlca			;5b8c   ; el equipo por dos
	call suma_a_hl		;5b8d
	ld a,(hl)			;5b90
	ld (ix+00ch),a		;5b91   ; el primer byte, al hueco 0x0c
	inc hl			;5b94
	ld a,(hl)			;5b95
	ld (ix+010h),a		;5b96   ; y el segundo, al 0x10
	pop hl			;5b99
	pop de			;5b9a
	ret			;5b9b

; ----------------------------------------------------------------------
; DATOS caracteristicas_de_la_central: Seis parejas, una por equipo de la
;   Central, en el orden C D G S T W. 0x5b5a las mete en los huecos 0x0c y
;   0x10 de las fichas del lanzador y del bateador: son lo unico que distingue
;   a un equipo de otro
;   0x5b9c..0x5ba8  (12 bytes)
DATA_caracteristicas_de_la_central:
	defb 008h,00fh	; 5b9c
	defb 004h,00fh	; 5b9e
	defb 001h,00fh	; 5ba0
	defb 005h,007h	; 5ba2
	defb 001h,007h	; 5ba4
	defb 005h,00fh	; 5ba6

; ----------------------------------------------------------------------
; DATOS caracteristicas_de_la_pacific: Las otras seis parejas, en el orden B
;   Bu F H L O
;   0x5ba8..0x5bb4  (12 bytes)
DATA_caracteristicas_de_la_pacific:
	defb 009h,00fh	; 5ba8
	defb 008h,00fh	; 5baa
	defb 00fh,009h	; 5bac
	defb 00fh,003h	; 5bae
	defb 005h,00fh	; 5bb0
	defb 001h,00fh	; 5bb2

; ======================================================================
; CODIGO 0x5bb4..0x5bd9  (37 bytes)
; ======================================================================


reparte_los_corredores:		; Recorre las tres fichas de 0xE1A0 buscando la primera que NO tenga el bit 1; a las que si lo tienen les baja el bit 6 veintitres bytes mas alla. Si las tres lo tenian, sube el bit 6 en tres sitios de 0xE1F7 hacia atras, de 32 en 32
	ld hl,0e1a0h		;5bb4   ; HL = 0xE1A0, la primera de las tres
	ld b,003h		;5bb7   ; tres
mira_una_ficha:		; Sin el bit 1, se para aqui
	bit 1,(hl)		;5bb9   ; el bit 1
	jr z,y_si_estaban_las_tres		;5bbb
	ld de,00017h		;5bbd   ; 23 bytes mas alla...
	add hl,de			;5bc0
	res 6,(hl)		;5bc1   ; ...el bit 6 se baja
	ld e,009h		;5bc3   ; y nueve mas: 32 hasta la siguiente
	add hl,de			;5bc5
	djnz mira_una_ficha		;5bc6
y_si_estaban_las_tres:		; Con las tres puestas, B llega a cero y no hay nada que hacer
	ld a,b			;5bc8   ; B es lo que quedo del recorrido
	or a			;5bc9
	ret z			;5bca
	ld hl,0e1f7h		;5bcb   ; HL = 0xE1F7
sube_el_bit_de_una:		; El bit 6, y 32 bytes hacia atras
	set 6,(hl)		;5bce   ; el bit 6
	or a			;5bd0
	ld de,00020h		;5bd1   ; 32 bytes hacia atras
	sbc hl,de		;5bd4
	djnz sube_el_bit_de_una		;5bd6
	ret			;5bd8

; ----------------------------------------------------------------------
; DATOS registro_del_lanzador: Los 21 bytes con los que arranca el registro de
;   0xE100. El primero es 0x40, o sea que el bit 3 -el que sobrevive al
;   reinicio- entra apagado
;   0x5bd9..0x5bee  (21 bytes)
DATA_registro_del_lanzador:
	defb 040h,004h,008h,068h,078h,080h,058h,010h,07bh,000h,000h,010h,001h,000h,000h,014h,007h,000h,000h,018h,00ah	; 5bd9  @..hx.X.{............

; ----------------------------------------------------------------------
; DATOS registro_del_bateador: Los 21 bytes de 0xE140, copiados con el mismo
;   ldir justo detras
;   0x5bee..0x5c03  (21 bytes)
DATA_registro_del_bateador:
	defb 052h,004h,018h,0a8h,083h,020h,058h,004h,07bh,000h,000h,004h,001h,000h,000h,008h,007h,000h,000h,00ch,00ah	; 5bee  R.... X.{............

; ----------------------------------------------------------------------
; DATOS fichas_de_los_jugadores: Las quince fichas de los jugadores de campo,
;   21 bytes cada una, que 0x5a90 despliega a 32 bytes en 0xE180. Ver arriba
;   lo de los tres bytes que se salen
;   0x5c03..0x5d3b  (312 bytes)
DATA_fichas_de_los_jugadores:
	defb 000h,0a8h,000h,01ch,07bh,0a8h,078h,01ch,00bh,048h,000h,0ffh,000h,0ffh,0b0h,0d8h,0e0h,058h,002h,000h,0aah	; 5c03  ....{.x..H.......X...
	defb 000h,0a8h,000h,020h,07bh,078h,0c6h,020h,00bh,04ah,000h,0ffh,000h,0ffh,0b8h,0b0h,000h,059h,003h,002h,0a0h	; 5c18  ... {x. .J.......Y...
	defb 000h,0a8h,000h,024h,07bh,058h,06fh,024h,00bh,04ch,000h,0ffh,000h,0ffh,05ah,064h,020h,059h,004h,003h,04fh	; 5c2d  ...${Xo$.L....Zd Y..O
	defb 080h,0a8h,000h,028h,07bh,08bh,028h,028h,00bh,04eh,000h,0ffh,000h,0ffh,038h,03ch,040h,059h,005h,004h,042h	; 5c42  ...({.((.N....8<@Y..B
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 5c57  .....................
	defb 008h,078h,000h,02ch,07bh,068h,078h,02ch,00fh,051h,067h,0a8h,048h,0a0h,000h,000h,060h,059h,003h,002h,000h	; 5c6c  .x.,{hx,.Qg.H...`Y...
	defb 040h,036h,000h,044h,07bh,048h,020h,044h,00fh,051h,020h,076h,000h,04ah,000h,000h,020h,05ah,004h,000h,000h	; 5c81  @6.D{H D.Q v.J.. Z...
	defb 048h,060h,000h,040h,07bh,058h,048h,040h,00fh,051h,052h,06ch,038h,088h,000h,000h,000h,05ah,003h,000h,000h	; 5c96  H`.@{XH@.QRl8....Z...
	defb 048h,078h,000h,03ch,07bh,078h,020h,03ch,00fh,051h,074h,096h,018h,046h,000h,000h,0e0h,059h,000h,000h,000h	; 5cab  Hx.<{x <.Qt..F...Y...
	defb 040h,036h,000h,04ch,07bh,048h,0d0h,04ch,00fh,051h,020h,076h,0a0h,0f3h,000h,000h,060h,05ah,002h,000h,000h	; 5cc0  @6.L{H.L.Q v....`Z...
	defb 048h,078h,000h,038h,07bh,058h,0b0h,038h,00fh,051h,052h,06ch,068h,0b8h,000h,000h,0c0h,059h,003h,000h,000h	; 5cd5  Hx.8{X.8.QRlh....Y...
	defb 048h,078h,000h,034h,07bh,078h,0d0h,034h,00fh,051h,074h,094h,0a0h,0d0h,000h,000h,0a0h,059h,000h,000h,000h	; 5cea  Hx.4{x.4.Qt......Y...
	defb 040h,036h,000h,048h,07bh,030h,078h,048h,00fh,051h,020h,048h,020h,0c0h,000h,000h,040h,05ah,003h,000h,000h	; 5cff  @6.H{0xH.Q H ...@Z...
	defb 048h,078h,000h,030h,07bh,0c0h,078h,030h,00fh,051h,0a0h,0cfh,068h,088h,000h,000h,080h,059h,000h,000h,000h	; 5d14  Hx.0{.x0.Q..h....Y...
	defb 000h,000h,001h,000h,07bh,068h,07ch,000h,00fh,050h,000h,0ffh,000h,0ffh,000h,000h,000h,058h	; 5d29  ....{h|..P.......X

; ======================================================================
; CODIGO 0x5d3b..0x61c0  (1157 bytes)
; ======================================================================


dibuja_lo_que_se_ha_movido:		; El repaso de dibujo de cada cuadro. Primero el lanzador y el bateador -0xE100 y 0xE140-, si tienen el bit 6 puesto; luego la pelota devuelta; luego el corrimiento de la cola de sombras; luego los quince jugadores de campo; y por ultimo la pelota
	ld hl,0e100h		;5d3b   ; HL = 0xE100, el lanzador
	ld b,002h		;5d3e   ; dos: el lanzador y el bateador
dibuja_uno_de_los_dos:		; Solo si tiene el bit 6, o sea si se ha movido
	bit 6,(hl)		;5d40   ; el bit 6: se ha movido este cuadro
	jr z,y_ahora_el_bateador		;5d42
	push hl			;5d44
	pop ix		;5d45   ; IX = su ficha
	push bc			;5d47
	call dibuja_un_jugador_grande		;5d48   ; y se dibuja
	pop bc			;5d4b
y_ahora_el_bateador:		; La segunda vuelta va por 0xE140
	ld hl,0e140h		;5d4c   ; HL = 0xE140, el bateador
	djnz dibuja_uno_de_los_dos		;5d4f
	ld a,(0e340h)		;5d51   ; (0xE340), la ficha de la pelota devuelta
	bit 6,a		;5d54   ; su bit 6
	jr z,corre_la_cola_de_sombras		;5d56
	ld hl,0e134h		;5d58   ; HL = 0xE134, el atributo del sprite de la pelota
	ld bc,(0e347h)		;5d5b   ; BC = (0xE347), donde esta
	call monta_el_atributo_de_la_sombra		;5d5f
corre_la_cola_de_sombras:		; Corre en cadena cinco bytes que estan a 0x20 de distancia dentro del bloque de 0xE200: 0xE245, 0xE265, 0xE2A5, 0xE2C5 y de vuelta, y aparte 0xE285 con 0xE2E5. SUPOSICION: que sea el rastro de lo que se mueve es lo que sugiere el corrimiento en cadena, pero no se ha medido en el emulador
	ld hl,0e245h		;5d62   ; HL = 0xE245, el primero de la cadena
	push hl			;5d65
	ld a,(hl)			;5d66
	ld l,065h		;5d67   ; L = 0x65: 0xE265
	ld b,(hl)			;5d69
	ld (hl),a			;5d6a
	ld l,0a5h		;5d6b   ; L = 0xA5: 0xE2A5
	ld a,(hl)			;5d6d
	ld (hl),b			;5d6e
	ld l,0c5h		;5d6f   ; L = 0xC5: 0xE2C5
	ld b,(hl)			;5d71
	ld (hl),a			;5d72
	pop hl			;5d73
	ld (hl),b			;5d74   ; y el primero se queda el ultimo
	ld l,085h		;5d75   ; L = 0x85: 0xE285
	ld a,(hl)			;5d77
	ld l,0e5h		;5d78   ; L = 0xE5: 0xE2E5
	ld b,(hl)			;5d7a
	ld (hl),a			;5d7b
	ld l,085h		;5d7c
	ld (hl),b			;5d7e   ; cambiados entre si
dibuja_a_los_quince:		; Los quince jugadores de campo, de 32 en 32 bytes. Los de la vuelta 2 a la 9 llevan el dibujo completo; el resto solo el sprite
	ld hl,0e180h		;5d7f   ; HL = 0xE180, la primera ficha
	ld b,00fh		;5d82   ; quince
dibuja_a_uno_de_campo:		; Decide con que rutina se dibuja segun el numero de ficha
	push hl			;5d84
	push hl			;5d85
	pop ix		;5d86   ; IX = la ficha
	push bc			;5d88
	ld a,b			;5d89
	cp 00ah		;5d8a   ; de la decima en adelante, solo el sprite
	jr nc,solo_el_sprite		;5d8c
	dec a			;5d8e   ; la primera tambien
	jr z,solo_el_sprite		;5d8f
	call dibuja_un_jugador_pequeno		;5d91   ; las demas, el dibujo entero
	jr la_ficha_siguiente		;5d94
solo_el_sprite:		; Las fichas que no llevan cuerpo de tiles
	call dibuja_solo_si_se_ha_movido		;5d96
la_ficha_siguiente:		; 32 bytes mas alla
	pop bc			;5d99
	pop hl			;5d9a
	call avanza_una_fila		;5d9b   ; 32 bytes hasta la siguiente
	djnz dibuja_a_uno_de_campo		;5d9e
	ld hl,0e120h		;5da0   ; HL = 0xE120, la ficha de la pelota
	bit 6,(hl)		;5da3   ; sin el bit 6 no hay nada que redibujar
	ret z			;5da5
	res 6,(hl)		;5da6   ; y se baja
	ld hl,0e130h		;5da8   ; HL = 0xE130, donde esta la pelota
	ld de,07b00h		;5dab   ; DE = VRAM 0x7b00, el primer sprite de la tabla
	call escribe_cuatro_bytes_de_sprite		;5dae
	ld hl,0e134h		;5db1   ; HL = 0xE134, el atributo del sprite de la sombra
	ld bc,(0e130h)		;5db4   ; BC = (0xE130), la posicion de la pelota
monta_el_atributo_de_la_sombra:		; Escribe los cuatro bytes del sprite de la sombra: la fila ocho pixeles mas abajo que la pelota, la misma columna, el patron 0 y el color 1
	push hl			;5db8   ; ocho pixeles mas abajo
	ld a,008h		;5db9
	add a,c			;5dbb
	ld (hl),a			;5dbc
	inc hl			;5dbd
	ld (hl),b			;5dbe   ; la misma columna
	inc hl			;5dbf
	ld (hl),000h		;5dc0   ; el patron 0
	inc hl			;5dc2
	ld (hl),001h		;5dc3   ; el color 1
	pop hl			;5dc5
	ld de,07b7ch		;5dc6   ; DE = VRAM 0x7b7c, el ultimo sprite de la tabla
escribe_cuatro_bytes_de_sprite:		; Los cuatro bytes de un atributo de sprite
	ld b,004h		;5dc9   ; cuatro bytes
	jp copia_bytes_con_candado		;5dcb
dibuja_un_jugador_grande:		; Sube a VRAM las TRES CAPAS de la postura del jugador y monta sus tres sprites. La postura es el byte 2 de la ficha; por dos entra en tabla_punteros_5048, que da un registro de cuatro palabras: tres guiones de 32 bytes -uno por capa- y el puntero a los desplazamientos. Los tres patrones van a 0x1880 y siguientes, de 32 en 32, que es justo lo que separa a dos patrones de sprite de 16x16
	ld e,(ix+005h)		;5dce   ; DE = el patron de sprite en VRAM, de los bytes 5 y 6
	ld d,(ix+006h)		;5dd1
	ld a,(ix+002h)		;5dd4   ; el byte 2, que es la postura
	rlca			;5dd7   ; por dos: la tabla lleva punteros
	call busca_el_guion_del_jugador		;5dd8   ; HL = el registro de esta postura
	ld b,003h		;5ddb   ; tres capas
sube_una_capa:		; Cada capa tiene su propio guion, y son 32 bytes: un patron de sprite de 16x16 entero
	push bc			;5ddd
	push hl			;5dde
	call lee_un_puntero		;5ddf   ; HL = el guion de esta capa
	call arma_escritura_con_candado		;5de2   ; arma la escritura en el patron
	call lee_comando_de_guion		;5de5   ; y se descomprime
	ld hl,00020h		;5de8   ; 32 bytes: el patron siguiente
	add hl,de			;5deb
	ex de,hl			;5dec
	pop hl			;5ded
	inc hl			;5dee   ; y el puntero al guion siguiente
	inc hl			;5def
	pop bc			;5df0
	djnz sube_una_capa		;5df1
monta_los_tres_sprites:		; Con los tres patrones ya en VRAM, los tres atributos. De la tabla salen las parejas (fila, columna) con signo de cada capa, y a ellas se les suma la posicion del jugador, que esta en los bytes 3 y 4 de la ficha. La fila 0xCF -la de esconder- se respeta tal cual, sin sumarle nada
	res 6,(ix+000h)		;5df3   ; el bit 6 se baja: ya esta dibujado
	ld e,(hl)			;5df7   ; DE = los desplazamientos, pegados al final del tercer guion
	inc hl			;5df8
	ld d,(hl)			;5df9
	push ix		;5dfa
	pop hl			;5dfc
	ld bc,00009h		;5dfd   ; HL = la ficha + 9, donde se guardan
	add hl,bc			;5e00
	exx			;5e01
	ld b,003h		;5e02   ; tres sprites
	exx			;5e04
	ld b,(ix+003h)		;5e05   ; B = el desplazamiento en fila
	ld c,(ix+004h)		;5e08   ; C = el desplazamiento en columna
	exx			;5e0b
monta_un_sprite:		; Fila, columna, y dos bytes que se saltan
	exx			;5e0c
	ld a,(de)			;5e0d   ; la fila del sprite
	cp 0cfh		;5e0e   ; 0xCF quiere decir escondido: no se toca
	jr z,L_5E13		;5e10
	add a,b			;5e12   ; y si no, se corre
L_5E13:
	ld (hl),a			;5e13
	inc hl			;5e14
	inc de			;5e15
	ld a,(de)			;5e16
	add a,c			;5e17   ; la columna, corrida tambien
	ld (hl),a			;5e18
	inc de			;5e19
	inc hl			;5e1a
	inc hl			;5e1b   ; el patron y el color, sin tocar
	inc hl			;5e1c
	exx			;5e1d
	djnz monta_un_sprite		;5e1e
vuelca_los_sprites:		; Los doce bytes de los tres atributos, del bloque de la ficha a la tabla de sprites, con outi
	ld e,(ix+007h)		;5e20   ; DE = el sitio en la tabla de sprites, de los bytes 7 y 8
	ld d,(ix+008h)		;5e23
	push ix		;5e26
	pop hl			;5e28
	call arma_escritura_con_candado		;5e29   ; arma la escritura ahi
	ld bc,00009h		;5e2c
	add hl,bc			;5e2f   ; HL = la ficha + 9
	ld e,003h		;5e30   ; tres atributos
saca_un_atributo:		; Recupera el puerto y suelta los cuatro bytes
	call dame_el_puerto_de_datos		;5e32
cuatro_bytes_de_golpe:		; outi cuatro veces: el modo mas rapido que hay de escribir en el VDP
	ld b,004h		;5e35   ; cuatro bytes
L_5E37:
	outi		;5e37   ; al puerto de datos, sin pasar por A
	jr nz,L_5E37		;5e39
	dec e			;5e3b   ; y el atributo siguiente
	jr nz,cuatro_bytes_de_golpe		;5e3c
	ret			;5e3e
dibuja_solo_si_se_ha_movido:		; La puerta del dibujo pequeno: sin el bit 6, nada
	bit 6,(ix+000h)		;5e3f   ; el bit 6 de la ficha
	ret z			;5e43
dibuja_un_jugador_pequeno:		; Los jugadores de campo son de UNA sola capa: un patron de 32 bytes y un sprite. Aqui la tabla de 0x5048 se usa de otra manera -lo que devuelve es el guion directamente, no un registro de cuatro palabras-, y el patron va a la direccion de los bytes 0x1a y 0x1b de la ficha
	ld e,(ix+01ah)		;5e44   ; DE = el patron de sprite en VRAM, de los bytes 0x1a y 0x1b
	ld d,(ix+01bh)		;5e47
	ld a,(ix+00bh)		;5e4a   ; el byte 0x0b, la postura
	rlca			;5e4d   ; por dos
	call busca_el_guion_del_jugador		;5e4e
	bit 6,(ix+000h)		;5e51   ; el bit 6 otra vez
	jr z,vuelca_su_sprite		;5e55
	call arma_escritura_con_candado		;5e57   ; arma la escritura en el patron
	call lee_comando_de_guion		;5e5a   ; y se descomprime
	res 6,(ix+000h)		;5e5d   ; el bit 6, bajado
vuelca_su_sprite:		; Un solo atributo de sprite, el de la ficha + 7
	ld e,(ix+005h)		;5e61   ; DE = el sitio en la tabla de sprites
	ld d,(ix+006h)		;5e64
	push ix		;5e67
	pop hl			;5e69
	ld bc,00007h		;5e6a   ; HL = la ficha + 7
	add hl,bc			;5e6d
	call arma_escritura_con_candado		;5e6e   ; arma la escritura
	ld e,001h		;5e71   ; un solo atributo
	jr saca_un_atributo		;5e73
busca_el_guion_del_jugador:		; Entra en tabla_punteros_5048 con el indice ya multiplicado por dos
	ld hl,05048h		;5e75   ; HL = 0x5048, la tabla de punteros
	call suma_a_hl		;5e78
lee_un_puntero:		; El puntero de 16 bits al que se apunta, en little-endian
	ld a,(hl)			;5e7b   ; el byte bajo
	inc hl			;5e7c
	ld h,(hl)			;5e7d   ; y el alto
	ld l,a			;5e7e
	ret			;5e7f
lleva_a_los_corredores:		; El cuadro de las bases. Segun los bits de 0xE380 se manda a los corredores atras (bit 4), se les deja seguir (bit 1) o no se toca nada (bit 3)
	ld hl,0e380h		;5e80   ; HL = 0xE380, la palabra de la carrera
	bit 4,(hl)		;5e83   ; el bit 4: hay que mandarlos atras
	jr nz,manda_atras_a_los_corredores		;5e85
	bit 1,(hl)		;5e87   ; el bit 1: hay carrera en marcha
	jr nz,repasa_las_cuatro_bases		;5e89
	bit 3,(hl)		;5e8b   ; el bit 3: la jugada esta cerrada
	ret nz			;5e8d
	jr repasa_las_cuatro_bases		;5e8e
manda_atras_a_los_corredores:		; Con el bit 4 puesto, a los corredores que estan en base y no van hacia delante se les enciende el bit 2, que es la orden de volver
	res 4,(hl)		;5e90   ; el bit 4, gastado
	ld hl,0e180h		;5e92   ; HL = 0xE180, la primera base
	ld b,004h		;5e95   ; las cuatro
manda_atras_a_uno:		; Solo a los que tienen corredor; el bit 4 marca a los que ya van hacia delante y a esos no se les toca
	bit 1,(hl)		;5e97   ; el bit 1: hay corredor?
	jr z,repasa_las_cuatro_bases		;5e99
	bit 4,(hl)		;5e9b   ; el bit 4: ya va hacia delante
	jr nz,la_base_siguiente		;5e9d
	set 2,(hl)		;5e9f   ; el bit 2: orden de volver
la_base_siguiente:		; 32 bytes mas alla
	call avanza_una_fila		;5ea1
	djnz manda_atras_a_uno		;5ea4
	ret			;5ea6
repasa_las_cuatro_bases:		; Recorre las cuatro bases. La que no tenga corredor -ni el bit 5 ni el bit 1- se esconde: se le guarda la fila, se le pone la 0xCF y se vuelca el atributo, con lo que su sprite desaparece de la pantalla
	ld hl,0e180h		;5ea7   ; HL = 0xE180, la primera base
	ld b,004h		;5eaa   ; las cuatro
esconde_o_marca_una_base:		; Sin corredor, el sprite fuera; con corredor, el bit 6 para que se redibuje
	push bc			;5eac
	bit 5,(hl)		;5ead   ; el bit 5: la base ya no cuenta
	jr nz,marca_la_base		;5eaf
	bit 1,(hl)		;5eb1   ; el bit 1: hay corredor
	jr nz,marca_la_base		;5eb3
	push hl			;5eb5
	ld a,007h		;5eb6   ; HL += 7: la fila del sprite
	call suma_a_hl		;5eb8
	ld a,(hl)			;5ebb   ; se guarda la que habia...
	ld (hl),0cfh		;5ebc   ; ...y se pone la 0xCF, la de esconder
	dec hl			;5ebe
	ld d,(hl)			;5ebf   ; DE = donde va el atributo en VRAM
	dec hl			;5ec0
	ld e,(hl)			;5ec1
	inc hl			;5ec2
	inc hl			;5ec3
	ld b,004h		;5ec4   ; cuatro bytes
	push hl			;5ec6
	push af			;5ec7
	call copia_bytes_con_candado		;5ec8
	pop af			;5ecb
	pop hl			;5ecc
	ld (hl),a			;5ecd   ; y la fila de verdad, de vuelta
	pop hl			;5ece
	jr y_la_base_siguiente		;5ecf
marca_la_base:		; Con corredor, solo hay que redibujarla
	set 6,(hl)		;5ed1   ; el bit 6
y_la_base_siguiente:		; 32 bytes mas alla
	call avanza_una_fila		;5ed3   ; la base siguiente
	pop bc			;5ed6
	djnz esconde_o_marca_una_base		;5ed7
	call el_mando_del_que_defiende		;5ed9   ; lee el mando del que corre
	ld a,(hl)			;5edc
	ld b,(hl)			;5edd
	and 030h		;5ede   ; los bits 4 y 5, los dos botones
	ld hl,0e380h		;5ee0   ; HL = 0xE380
	jr z,nadie_pulsa		;5ee3
	bit 7,(hl)		;5ee5   ; ya estaba puesto?
	jr z,recuerda_que_se_pulso		;5ee7
	ld b,000h		;5ee9   ; entonces la lectura no vale
recuerda_que_se_pulso:		; El bit 7 de 0xE380 recuerda que el boton seguia pulsado del cuadro anterior, para no contarlo dos veces
	set 7,(hl)		;5eeb   ; y queda puesto
	jr mueve_las_cuatro_bases		;5eed
nadie_pulsa:		; El bit 7 se cae
	res 7,(hl)		;5eef   ; el bit 7, a cero
mueve_las_cuatro_bases:		; Le da un cuadro a cada base con su numero: la primera con 0, la segunda con 8, la tercera con 1 y la cuarta con 4. IX recorre en paralelo la tabla de 0x61d2, cuatro bytes por base
	ld ix,061d2h		;5ef1   ; IX = 0x61d2, los datos de las bases
	ld c,000h		;5ef5   ; la primera base va con el 0
	ld hl,0e180h		;5ef7   ; HL = 0xE180
	push bc			;5efa
	call mueve_una_base_y_avanza		;5efb
	pop bc			;5efe
	push bc			;5eff
	ld hl,0e1a0h		;5f00   ; HL = 0xE1A0, la segunda
	ld c,008h		;5f03   ; que va con el 8
	call mueve_una_base_y_avanza		;5f05
	pop bc			;5f08
	push bc			;5f09
	ld hl,0e1c0h		;5f0a   ; HL = 0xE1C0, la tercera
	ld c,001h		;5f0d   ; con el 1
	call mueve_una_base_y_avanza		;5f0f
	pop bc			;5f12
	push bc			;5f13
	ld hl,0e1e0h		;5f14   ; HL = 0xE1E0, la cuarta
	ld c,004h		;5f17   ; con el 4, y sin adelantar IX
	call lleva_una_base		;5f19
	pop bc			;5f1c
	ld a,(0e388h)		;5f1d   ; (0xE388), el bit 7
	rlca			;5f20
	jr nc,recarga_el_contador_de_carrera		;5f21
	ld hl,0e389h		;5f23
	set 0,(hl)		;5f26   ; enciende el bit 0 de 0xE389
recarga_el_contador_de_carrera:		; El contador de 0xE033, que al llegar a 1 vuelve a 2
	ld a,(0e033h)		;5f28   ; (0xE033)
	dec a			;5f2b
	jr nz,mira_si_queda_alguien_corriendo		;5f2c
	ld a,002h		;5f2e
	ld (0e033h),a		;5f30   ; vuelve a 2
mira_si_queda_alguien_corriendo:		; Recorre las cuatro bases buscando una con el bit 0 puesto. Si no hay ninguna, baja el bit 1 de 0xE380 y la carrera se acaba
	ld hl,0e180h		;5f33   ; HL = 0xE180
	ld b,004h		;5f36   ; las cuatro
	ld de,0e380h		;5f38   ; DE = 0xE380
mira_una_base:		; El bit 0: se esta moviendo
	bit 0,(hl)		;5f3b   ; el bit 0
	jr nz,sigue_habiendo_carrera		;5f3d
	call avanza_una_fila		;5f3f   ; la base siguiente
	djnz mira_una_base		;5f42
	ex de,hl			;5f44
	res 1,(hl)		;5f45   ; nadie corre: el bit 1 se cae
	ret			;5f47
sigue_habiendo_carrera:		; Con alguien corriendo, el bit 1 se mantiene y cada ocho cuadros suena el paso
	ex de,hl			;5f48
	set 1,(hl)		;5f49   ; el bit 1 de 0xE380
	ld a,(0e401h)		;5f4b   ; (0xE401), el aviso de la jugada
	bit 6,a		;5f4e   ; con el bit 6 puesto, sin sonido
	ret nz			;5f50
	ld a,(0e000h)		;5f51   ; el contador de cuadros
	and 00eh		;5f54   ; uno de cada ocho
	ret nz			;5f56
	ld a,003h		;5f57   ; A = 3, el sonido del paso
	jp pide_un_sonido		;5f59
mueve_una_base_y_avanza:		; Le da su cuadro a la base y adelanta IX cuatro bytes, hasta los datos de la siguiente
	call lleva_una_base		;5f5c   ; el cuadro de esta base
	push ix		;5f5f
	pop hl			;5f61
	inc hl			;5f62   ; IX += 4: los datos de la base siguiente
	inc hl			;5f63
	inc hl			;5f64
	inc hl			;5f65
	push hl			;5f66
	pop ix		;5f67
	ret			;5f69
lleva_una_base:		; El cuadro de una base. Sin corredor no hay nada que hacer; con el bit 2 puesto se le manda ya; y si no, se mira lo que se acaba de pulsar: los dos botones deciden si el corredor arranca, y el numero de la base -que viene en C- tiene que cuadrar con la direccion pulsada
	bit 1,(hl)		;5f6a   ; el bit 1: hay corredor?
	ret z			;5f6c
	bit 2,(hl)		;5f6d   ; el bit 2: la orden ya esta dada
	jr nz,decide_hacia_donde		;5f6f
	bit 4,(hl)		;5f71   ; el bit 4: va hacia delante
	jr z,mira_si_le_toca_a_esta_base		;5f73
	ld a,(0e389h)		;5f75   ; (0xE389), su bit 0
	rrca			;5f78
	jr c,mira_si_le_toca_a_esta_base		;5f79
	ld a,(0e388h)		;5f7b   ; (0xE388), su bit 7
	rlca			;5f7e
	jr nc,mira_si_le_toca_a_esta_base		;5f7f
	ld b,012h		;5f81   ; B = 0x12: la orden se la da la maquina
mira_si_le_toca_a_esta_base:		; Los botones tienen que estar pulsados y la direccion tiene que ser la de esta base
	ld a,b			;5f83
	and 030h		;5f84   ; los dos botones
	jr z,no_arranca		;5f86   ; sin boton, no arranca
	ld a,c			;5f88   ; C = el numero de esta base
	or a			;5f89
	jr z,no_arranca		;5f8a
	ld a,b			;5f8c   ; la direccion pulsada
	and 00fh		;5f8d
	cp 002h		;5f8f   ; el 2 es un caso aparte
	jr nz,compara_la_direccion		;5f91
	ld a,c			;5f93
	cp 004h		;5f94   ; que solo vale para la cuarta base
	jr nz,decide_hacia_donde		;5f96
	jr decide_hacia_donde		;5f98
compara_la_direccion:		; La direccion pulsada tiene que ser justo la de esta base
	cp c			;5f9a   ; la de esta base?
	jr nz,no_arranca		;5f9b
decide_hacia_donde:		; Con la orden dada: si el corredor va hacia delante se avisa a la base de detras, y si va hacia atras se comprueba que la de delante este libre antes de dejarle salir
	ld de,00020h		;5f9d   ; DE = 32, lo que hay de una base a otra
	bit 4,(hl)		;5fa0   ; el bit 4: hacia delante
	jr z,arranca_hacia_atras		;5fa2
	bit 5,(hl)		;5fa4   ; el bit 5: ya no cuenta
	jr nz,no_arranca		;5fa6
	bit 3,(hl)		;5fa8   ; el bit 3
	jr z,mira_si_puede_salir		;5faa
	push hl			;5fac
	or a			;5fad
	sbc hl,de		;5fae   ; la base de detras...
	set 2,(hl)		;5fb0   ; ...tambien se pone en marcha
	pop hl			;5fb2
mira_si_puede_salir:		; Con la pelota en juego y sin el aviso de 0xE388, la base a la que va tiene que estar libre
	call la_pelota_esta_en_juego		;5fb3
	jr z,arranca_hacia_delante		;5fb6   ; la pelota esta donde tiene que estar
	ld a,(0e388h)		;5fb8   ; (0xE388), su bit 7
	rlca			;5fbb
	jr c,arranca_hacia_delante		;5fbc
	push hl			;5fbe
	call la_ficha_de_al_lado		;5fbf   ; la ficha de la base de al lado
	bit 6,(hl)		;5fc2   ; su bit 6
	pop hl			;5fc4
	jr z,no_arranca		;5fc5
arranca_hacia_delante:		; Con el aviso de 0xE401 sin el bit 6, el corredor sale y a la base de al lado se le baja el bit 7
	ld a,(0e401h)		;5fc7   ; (0xE401), el aviso de la jugada
	bit 6,a		;5fca   ; el bit 6: la jugada ya esta resuelta
	jr nz,no_arranca		;5fcc
	push hl			;5fce
	call la_ficha_de_al_lado		;5fcf
	res 7,(hl)		;5fd2   ; el bit 7 de la de al lado
	pop hl			;5fd4
	jr pone_en_marcha_al_corredor		;5fd5
arranca_hacia_atras:		; Volver solo se puede si la base de la que se viene no esta ocupada por otro que ya vaya en marcha
	bit 7,(hl)		;5fd7   ; el bit 7
	jr nz,pone_en_marcha_al_corredor		;5fd9
	push hl			;5fdb
	call avanza_veintitres		;5fdc   ; 23 bytes mas alla
	bit 5,(hl)		;5fdf   ; su bit 5
	pop hl			;5fe1
	jr nz,pone_en_marcha_al_corredor		;5fe2
	push hl			;5fe4
	add hl,de			;5fe5   ; la base de al lado
	bit 1,(hl)		;5fe6   ; su bit 1: hay corredor
	jr z,no_puede_volver		;5fe8
	bit 0,(hl)		;5fea   ; su bit 0: se esta moviendo
	jr z,si_puede_volver		;5fec
	bit 4,(hl)		;5fee   ; y su bit 4: hacia donde
	jr z,si_puede_volver		;5ff0
no_puede_volver:		; La base de al lado esta ocupada
	pop hl			;5ff2
	jr pone_en_marcha_al_corredor		;5ff3
si_puede_volver:		; Camino libre
	pop hl			;5ff5
no_arranca:		; Sin orden valida, solo queda dejar correr lo que ya estuviera en marcha
	jp decide_si_el_corredor_arranca_solo		;5ff6
pone_en_marcha_al_corredor:		; Baja las ordenes ya gastadas, le da la vuelta al bit 4 -que es el sentido-, y prepara la postura y la ficha de movimiento con los datos de la tabla de 0x61bc que le toquen a esa direccion
	res 2,(hl)		;5ff9   ; el bit 2, gastado
	res 5,(hl)		;5ffb   ; y el bit 5
	ld a,(hl)			;5ffd
	cpl			;5ffe   ; el bit 4 cambia de valor: se da la vuelta
	and 010h		;5fff
	ld b,a			;6001
	ld a,(hl)			;6002
	and 0efh		;6003
	or b			;6005
	ld (hl),a			;6006
	push hl			;6007
	ld a,(hl)			;6008
	push af			;6009
	ld a,00bh		;600a   ; HL += 11: la postura del corredor
	call suma_a_hl		;600c
	ld b,(hl)			;600f
	res 6,b		;6010   ; el bit 6 fuera
	set 5,b		;6012   ; el bit 5 y el 3 puestos
	set 3,b		;6014
	pop af			;6016
	bit 4,a		;6017   ; salvo que fuera hacia el otro lado
	jr z,guarda_la_postura		;6019
	res 3,b		;601b   ; y entonces el bit 3 se cae
guarda_la_postura:		; La postura nueva del corredor
	ld (hl),b			;601d
	pop hl			;601e
	push hl			;601f
	ld a,(hl)			;6020
	push af			;6021
	call avanza_una_fila		;6022   ; la ficha de al lado
	pop af			;6025
	set 3,(hl)		;6026   ; su bit 3, del mismo sentido
	bit 4,a		;6028
	jr nz,busca_el_destino		;602a
	res 3,(hl)		;602c   ; o apagado
busca_el_destino:		; Recorre la tabla de 0x61bc de cuatro en cuatro hasta dar con la entrada del bit de direccion que este puesto
	ld hl,no_esta_en_marcha		;602e   ; HL = 0x61bc, los destinos
	ld b,005h		;6031   ; cinco entradas
	ld a,c			;6033   ; A = la direccion
una_entrada_de_destino:		; Cuatro bytes por entrada, y el bit que salga por el acarreo manda
	inc hl			;6034
	inc hl			;6035
	inc hl			;6036
	inc hl			;6037
	rrca			;6038   ; el bit siguiente
	jr c,saca_el_destino		;6039   ; puesto: es esta
	djnz una_entrada_de_destino		;603b
saca_el_destino:		; De la entrada salen dos bytes -la esquina a la que va- y el sentido elige si son los dos primeros o los dos ultimos
	ex de,hl			;603d
	pop hl			;603e
	ld a,(hl)			;603f
	push hl			;6040
	ex de,hl			;6041
	bit 4,a		;6042   ; el bit 4, el sentido
	jr nz,L_6048		;6044
	inc hl			;6046   ; hacia el otro lado, los otros dos bytes
	inc hl			;6047
L_6048:
	ld b,(hl)			;6048   ; B = la fila del destino
	inc hl			;6049
	ld c,(hl)			;604a   ; C = la columna
	pop hl			;604b
	call calcula_la_trayectoria		;604c   ; y se le calcula la trayectoria
un_cuadro_del_corredor:		; Le da un cuadro de movimiento y, cada cuatro cuadros, le da la vuelta al bit 0 de su postura: es el paso
	push hl			;604f
	push ix		;6050
	call mueve_un_movil		;6052   ; un cuadro de movimiento
	pop ix		;6055
	ld a,(0e000h)		;6057   ; el contador de cuadros
	and 006h		;605a   ; uno de cada cuatro
	jr nz,mira_si_ha_llegado		;605c
	pop hl			;605e
	push hl			;605f
	bit 0,(hl)		;6060   ; el bit 0: solo si sigue en marcha
	jr z,mira_si_ha_llegado		;6062
	ld bc,0000bh		;6064   ; HL += 11: la postura
	add hl,bc			;6067
	or a			;6068
	rr (hl)		;6069   ; su bit 0 sale...
	ccf			;606b
	rl (hl)		;606c   ; ...y vuelve a entrar cambiado
mira_si_ha_llegado:		; Con el bit 0 todavia puesto, sigue corriendo
	pop hl			;606e
	bit 0,(hl)		;606f   ; el bit 0
	ret nz			;6071
	bit 4,(hl)		;6072   ; el bit 4: iba hacia delante
	jr z,marca_la_base_alcanzada		;6074
	push hl			;6076
	call la_ficha_de_al_lado		;6077   ; la ficha de al lado
	bit 7,(hl)		;607a   ; su bit 7
	res 7,(hl)		;607c   ; que se baja
	set 5,(hl)		;607e   ; y el bit 5 se sube
	pop hl			;6080
	ret z			;6081
	call la_pelota_esta_en_juego		;6082   ; mira si hay que avisar
	jr z,avisa_de_la_llegada		;6085
	call mira_el_contador_de_carrera		;6087   ; y si la jugada sigue
	ret z			;608a
avisa_de_la_llegada:		; El bit 2 de 0xE389: el corredor ha llegado
	push hl			;608b
	ld hl,0e389h		;608c   ; HL = 0xE389
	set 2,(hl)		;608f   ; el bit 2
	pop hl			;6091
marca_la_base_alcanzada:		; Volviendo hacia atras, se le pone el bit 1 a la ficha de 23 bytes mas alla
	bit 4,(hl)		;6092   ; el bit 4: hacia donde iba
	jr nz,compara_con_la_base_en_juego		;6094
	push hl			;6096
	call avanza_veintitres		;6097   ; 23 bytes mas alla
	set 1,(hl)		;609a   ; su bit 1
	pop hl			;609c
compara_con_la_base_en_juego:		; Los bytes 0x1c y 0x1d de la ficha dicen a que base se llega segun el sentido; si coincide con la que la pelota tiene marcada en 0xE35F y ademas 0xE38A dice algo, el corredor esta out
	push hl			;609d
	pop iy		;609e   ; IY = la ficha
	ld b,(iy+01ch)		;60a0   ; B = el byte 0x1c, la base hacia delante
	bit 4,(hl)		;60a3   ; el bit 4, el sentido
	jr nz,L_60AA		;60a5
	ld b,(iy+01dh)		;60a7   ; o el 0x1d, la de atras
L_60AA:
	ld a,(0e35fh)		;60aa   ; (0xE35F), la base que la pelota tiene tomada
	cp b			;60ad   ; la misma?
	jr nz,anota_la_llegada		;60ae
	ld a,(0e38ah)		;60b0   ; (0xE38A), el aviso de la pelota
	or a			;60b3
	jr z,anota_la_llegada		;60b4
mira_el_hueco_de_esa_base:		; Con B haciendo de indice, recorre 0xE200 de 32 en 32 y mira el bit 0 de la ficha que salga
	ld b,a			;60b6
	push hl			;60b7   ; HL = 0xE200
	ld hl,0e200h		;60b8
salta_una_ficha:		; 32 bytes por ficha
	call avanza_una_fila		;60bb
	djnz salta_una_ficha		;60be
	bit 0,(hl)		;60c0   ; su bit 0
	pop hl			;60c2
	jr nz,anota_la_llegada		;60c3
	ld a,(0e340h)		;60c5   ; (0xE340), la pelota devuelta
	rrca			;60c8
	jr c,anota_la_llegada		;60c9
	bit 5,(iy+020h)		;60cb   ; el bit 5 del byte 0x20 de la ficha
	jr nz,anota_la_llegada		;60cf
	ld a,(hl)			;60d1
	and 080h		;60d2   ; de la ficha solo sobrevive el bit 7
	ld (hl),a			;60d4
	ld a,004h		;60d5
	ld (0e401h),a		;60d7   ; (0xE401) := 4: el corredor esta eliminado
	ret			;60da
anota_la_llegada:		; Llegando hacia delante, se marca la ficha de al lado y, si nadie mas la reclama, se apunta la carrera en 0xE40C o en 0xE40E segun de quien sea el turno
	bit 4,(hl)		;60db   ; el bit 4: hacia delante
	ret z			;60dd
	push hl			;60de
	call avanza_una_fila		;60df   ; la ficha de al lado
	set 5,(hl)		;60e2   ; su bit 5
	bit 1,(hl)		;60e4   ; y su bit 1
	pop hl			;60e6
	ret nz			;60e7
	bit 7,(hl)		;60e8   ; el bit 7 de esta
	jr z,apaga_al_corredor		;60ea
	push hl			;60ec
	res 5,(iy+020h)		;60ed   ; el bit 5 del byte 0x20, apagado
	ld a,(0e388h)		;60f1   ; (0xE388), su bit 7
	rlca			;60f4
	jr nc,L_60FD		;60f5
	ld hl,0e40eh		;60f7
	inc (hl)			;60fa   ; (0xE40E), una carrera mas
	jr recoge_el_corredor		;60fb
L_60FD:
	ld hl,0e40ch		;60fd
	inc (hl)			;6100   ; (0xE40C), una carrera mas
	call la_pelota_esta_en_juego		;6101
	call z,suma_las_carreras		;6104
recoge_el_corredor:		; Vuelve por la ficha que se dejo en la pila
	pop hl			;6107
apaga_al_corredor:		; De la ficha solo sobreviven los bits 7, 5 y 3, le coloca el sprite en la esquina que le toque y, si tenia el bit 5, arrastra en cadena a la de detras
	ld a,(hl)			;6108   ; la ficha entera...
	and 0a8h		;6109   ; ...reducida a los bits 7, 5 y 3
	ld (hl),a			;610b
	push hl			;610c
	call coloca_el_sprite_de_la_base		;610d   ; le pone el sprite en su esquina
	pop hl			;6110
	bit 5,(hl)		;6111   ; el bit 5: hay que arrastrar a la de detras
	ret z			;6113
arrastra_la_de_detras:		; Se mete en la ficha de detras, la apaga igual, retrocede IX cuatro bytes y, si esa tambien tenia el bit 5, se llama a si misma. Es una cadena que puede recorrer las cuatro bases de una vez
	push ix		;6114
	push hl			;6116
	ld de,00020h		;6117   ; DE = 32, lo que va de una ficha a otra
	or a			;611a
	sbc hl,de		;611b   ; la de detras
	ld a,(hl)			;611d
	and 0a8h		;611e   ; reducida a los bits 7, 5 y 3
	ld (hl),a			;6120
	dec ix		;6121   ; IX, cuatro bytes atras: los datos de esa base
	dec ix		;6123
	dec ix		;6125
	dec ix		;6127
	bit 5,(hl)		;6129   ; y si esa tambien lo tenia, otra vuelta
	call nz,arrastra_la_de_detras		;612b
	call coloca_el_sprite_de_la_base		;612e   ; le coloca el sprite
	pop hl			;6131
	pop ix		;6132
	ret			;6134
coloca_el_sprite_de_la_base:		; Deja al corredor parado en su base: sin el bit 3 va a la esquina de partida (indice 0) y con el a la de llegada (indice 2), y de paso limpia las ordenes y avisa a la ficha de al lado
	xor a			;6135   ; A = 0, el indice de la esquina de partida
	bit 3,(hl)		;6136   ; el bit 3
	call z,escribe_la_esquina		;6138
	bit 7,(hl)		;613b   ; el bit 7, guardado para luego
	push af			;613d
	call avanza_una_fila		;613e   ; la ficha de al lado
	pop af			;6141
	jr nz,L_6146		;6142
	set 1,(hl)		;6144   ; su bit 1, si el 7 estaba a cero
L_6146:
	res 4,(hl)		;6146   ; el bit 4, fuera
	res 3,(hl)		;6148   ; y el bit 3
	push hl			;614a
	call la_ficha_de_al_lado		;614b
	set 6,(hl)		;614e   ; 23 bytes mas alla: el bit 6 puesto...
	res 5,(hl)		;6150   ; ...y el 5 quitado
	pop hl			;6152
	ld a,002h		;6153   ; A = 2, el indice de la esquina de llegada
escribe_la_esquina:		; De los datos de la base -los que apunta IX- saca la pareja fila/columna que toque y la mete en los bytes 7 y 8 de la ficha, que es donde el dibujo mira. La pareja 00 00 quiere decir "no la toques"
	push hl			;6155
	push hl			;6156
	pop iy		;6157   ; IY = la ficha
	push ix		;6159
	pop hl			;615b
	call suma_a_hl		;615c   ; HL = los datos de la base, mas el indice
	ld a,(hl)			;615f
	or a			;6160   ; la pareja 00 00 no vale
	jr z,L_616B		;6161
	ld (iy+007h),a		;6163   ; la fila, al byte 7
	inc hl			;6166
	ld a,(hl)			;6167
	ld (iy+008h),a		;6168   ; y la columna, al byte 8
L_616B:
	pop hl			;616b
	ret			;616c
decide_si_el_corredor_arranca_solo:		; Al corredor que va hacia delante, la maquina puede mandarlo sola: hay cinco cosas que tienen que dar permiso -que no haya llegado nadie, que la pelota este en juego, que la jugada no este resuelta, que 0xE40A no valga 2 y que 0xE388 no lo prohiba-
	bit 4,(hl)		;616d   ; el bit 4: hacia delante
	jr z,y_si_esta_en_marcha		;616f
	ld a,(0e389h)		;6171   ; (0xE389), el bit 2: alguien acaba de llegar
	bit 2,a		;6174
	jr nz,arranca_solo		;6176
	call la_pelota_esta_en_juego		;6178   ; la pelota en juego
	jr z,arranca_solo		;617b
	ld a,(0e401h)		;617d   ; (0xE401), el bit 6: la jugada resuelta
	bit 6,a		;6180
	jr nz,arranca_solo		;6182
	ld a,(0e40ah)		;6184   ; (0xE40A) valiendo 2 lo prohibe
	cp 002h		;6187
	jr z,arranca_solo		;6189
	ld a,(0e388h)		;618b   ; (0xE388), su bit 7
	rlca			;618e
	jr c,arranca_solo		;618f
	call mira_el_contador_de_carrera		;6191   ; y el contador de 0xE033
	jr z,y_si_esta_en_marcha		;6194
arranca_solo:		; Con el bit 7 de la ficha de al lado ya puesto no se repite; si no, se pone y el corredor sale hacia el destino de la tabla de 0x61e0
	push hl			;6196
	call la_ficha_de_al_lado		;6197   ; la ficha de al lado
	or a			;619a
	bit 7,(hl)		;619b   ; su bit 7: ya se conto
	jr z,L_61A0		;619d
	scf			;619f
L_61A0:
	set 7,(hl)		;61a0   ; y queda puesto
	pop hl			;61a2
	jr c,y_si_esta_en_marcha		;61a3
	push hl			;61a5
	ld a,c			;61a6   ; A = el numero de la base
	ld hl,061deh		;61a7   ; HL = 0x61de, los destinos de vuelta
	ld b,005h		;61aa   ; cinco entradas
una_entrada_de_vuelta:		; Dos bytes por entrada, y el bit que salga por el acarreo manda
	inc hl			;61ac
	inc hl			;61ad
	rrca			;61ae   ; el bit siguiente
	jr c,L_61B3		;61af
	djnz una_entrada_de_vuelta		;61b1
L_61B3:
	ld b,(hl)			;61b3   ; B = la fila del destino
	inc hl			;61b4
	ld c,(hl)			;61b5   ; C = la columna
	pop hl			;61b6
	call calcula_la_trayectoria		;61b7   ; y se le calcula la trayectoria
y_si_esta_en_marcha:		; Solo se le da cuadro al que tenga el bit 0
	bit 0,(hl)		;61ba   ; el bit 0
no_esta_en_marcha:		; Y si no, nada
	ret z			;61bc
	jp un_cuadro_del_corredor		;61bd   ; un cuadro de movimiento

; ----------------------------------------------------------------------
; DATOS destinos_de_las_bases: Cinco entradas de cuatro bytes -dos parejas
;   fila/columna, una por sentido- que 0x602e recorre buscando el bit de
;   direccion que este puesto. Es a donde sale corriendo el que arranca
;   0x61c0..0x61d2  (18 bytes)
DATA_destinos_de_las_bases:
	defb 068h,048h,058h,078h	; 61c0
	defb 000h,000h,000h,000h	; 61c4
	defb 098h,048h,080h,028h	; 61c8
	defb 068h,0a8h,080h,0c8h	; 61cc
	defb 08ch,0b0h	; 61d0

; ----------------------------------------------------------------------
; DATOS esquinas_de_las_bases: Cuatro entradas de cuatro bytes, una por base,
;   que 0x5ef1 recorre con IX: la pareja de partida y la de llegada donde
;   0x6155 aparca el sprite del corredor cuando se para. La pareja 00 00
;   quiere decir que no se toca
;   0x61d2..0x61e0  (14 bytes)
DATA_esquinas_de_las_bases:
	defb 000h,000h,078h,0c6h	; 61d2
	defb 078h,0c6h,058h,06ch	; 61d6
	defb 058h,06ch,08bh,026h	; 61da
	defb 08bh,026h	; 61de

; ----------------------------------------------------------------------
; DATOS destinos_de_vuelta: Cinco parejas fila/columna que lee 0x61a7: a donde
;   manda la maquina al corredor cuando decide que salga solo
;   0x61e0..0x61ea  (10 bytes)
DATA_destinos_de_vuelta:
	defb 07ch,024h	; 61e0
	defb 000h,000h	; 61e2
	defb 0a8h,074h	; 61e4
	defb 054h,07ah	; 61e6
	defb 07ch,0c8h	; 61e8

; ======================================================================
; CODIGO 0x61ea..0x6395  (427 bytes)
; ======================================================================


la_ficha_de_al_lado:		; HL += 23, que es donde vive la pareja de esta ficha. Un `jp` a avanza_veintitres, para poder llamarlo con `call`
	jp avanza_veintitres		;61ea
calcula_la_trayectoria:		; Saca de la ficha su posicion de ahora -bytes 7 y 8- y le calcula la trayectoria hasta (B,C) sobre el hueco que empieza 15 bytes mas alla
	push hl			;61ed
	ld a,007h		;61ee   ; HL += 7: la fila y la columna de ahora
	call suma_a_hl		;61f0
	ld d,(hl)			;61f3   ; D = la fila
	inc hl			;61f4
	ld e,(hl)			;61f5   ; E = la columna
	ld a,008h		;61f6   ; HL += 8 mas: el hueco de la trayectoria
	call suma_a_hl		;61f8
	call apunta_hacia_un_destino		;61fb   ; y ahi se calcula
	pop hl			;61fe
	ret			;61ff
la_pelota_esta_en_juego:		; Devuelve el cero puesto si 0xE030 esta a cero, que es la pregunta que se hace media docena de sitios
	ld a,(0e030h)		;6200   ; (0xE030)
	or a			;6203
	ret			;6204
mira_el_contador_de_carrera:		; Lo mismo con 0xE033
	ld a,(0e033h)		;6205   ; (0xE033)
	or a			;6208
	ret			;6209
lleva_la_pelota_bateada:		; El cuadro de la pelota bateada. Solo corre con 0xE039 puesto y la pelota en juego. Cada bote -que es cuando 0xE03B llega a cero- recalcula el rebote: le da la vuelta a 0xE038, saca dos bits del angulo de 0xE037 para decidir el lado en 0xE056, y vuelve a calcular la trayectoria
	ld a,(0e039h)		;620a   ; (0xE039): sin esto no hay pelota bateada
	or a			;620d
	ret z			;620e
	ld a,(0e030h)		;620f   ; la pelota tiene que estar en juego
	or a			;6212
	ret z			;6213
	ld hl,0e03bh		;6214   ; HL = 0xE03B, lo que queda para el bote
	xor a			;6217
	cp (hl)			;6218
	jp z,todavia_no_bota		;6219   ; todavia no bota: solo hay que moverla
	ld (hl),a			;621c   ; gastado
	ld (0e031h),a		;621d   ; (0xE031) := 0
	ld l,038h		;6220   ; L = 0x38: 0xE038
	ld a,(hl)			;6222
	cpl			;6223   ; que cambia de valor en cada bote
	ld (hl),a			;6224
	ld a,(0e037h)		;6225   ; (0xE037), el angulo de salida
	rrca			;6228   ; sus bits 4 y 5, bajados a la derecha
	rrca			;6229
	rrca			;622a
	rrca			;622b
	and 003h		;622c
	srl a		;622e   ; el de mas peso, al acarreo
	ld b,a			;6230
	ld a,000h		;6231
	rla			;6233
	xor b			;6234
	ld (0e056h),a		;6235   ; (0xE056): de que lado sale el rebote
	call saca_la_componente_del_angulo		;6238
calcula_el_vuelo:		; Con la altura de 0xE0A1 y las dos componentes de 0xE0A3 y 0xE0A5, dos multiplicaciones dan las dos coordenadas del punto de caida, que se guardan en 0xE0A7 y 0xE0A9. Luego divide entre 6, mide, y de ahi salen los desplazamientos que se le suman a la posicion de la pelota
	ld hl,(0e0a1h)		;623b   ; (0xE0A1), la altura
	ld (0e060h),hl		;623e
	ld hl,(0e0a3h)		;6241   ; (0xE0A3), la primera componente
	ld (0e062h),hl		;6244
	call multiplica_la_calculadora		;6247   ; multiplicadas
	ld hl,(0e060h)		;624a
	ld (0e0a7h),hl		;624d   ; el resultado, a 0xE0A7
	ld hl,(0e0a1h)		;6250   ; la altura otra vez
	ld (0e060h),hl		;6253
	ld hl,(0e0a5h)		;6256   ; (0xE0A5), la segunda componente
	ld (0e062h),hl		;6259
	call multiplica_la_calculadora		;625c
	ld hl,(0e060h)		;625f
	ld (0e0a9h),hl		;6262   ; y el resultado a 0xE0A9
	ld hl,00000h		;6265
	ld (0e034h),hl		;6268   ; (0xE034) := 0
	ld hl,0e062h		;626b
	ld (hl),000h		;626e   ; divisor 0x0600: entre seis
	inc hl			;6270
	ld (hl),006h		;6271
	call divide_la_calculadora		;6273   ; dividido
	ld a,(0e062h)		;6276
	ld (0e063h),a		;6279   ; el cociente, a 0xE063
	ld hl,(0e0a7h)		;627c   ; (0xE0A7), la primera coordenada
	ld (0e060h),hl		;627f
	xor a			;6282
	ld (0e062h),a		;6283
	call multiplica_la_calculadora		;6286   ; por el cociente
	ld hl,(0e061h)		;6289
	call parte_por_128		;628c   ; partido por 128
	ld a,(0e062h)		;628f
	ld c,a			;6292
	srl c		;6293   ; el resultado, menos su cuarta parte
	srl c		;6295
	sub c			;6297
	ld c,a			;6298
	call multiplica_por_a		;6299   ; y multiplicado por lo que valga la componente
	ld de,0e0b1h		;629c   ; DE = 0xE0B1 y HL = 0xE0B0, las dos coordenadas
	ld hl,0e0b0h		;629f
	ld a,(0e056h)		;62a2   ; (0xE056), el lado del rebote
	or a			;62a5
	jr nz,mira_el_otro_lado		;62a6
	ex de,hl			;62a8   ; con el lado cambiado, las dos coordenadas se cambian
	ld a,(0e037h)		;62a9   ; (0xE037), el nibble alto del angulo
	and 0f0h		;62ac
	or a			;62ae
	ld a,c			;62af
	jr nz,suma_la_primera_coordenada		;62b0
	jr cambia_el_signo		;62b2
mira_el_otro_lado:		; Con 0xE056 puesto manda 0xE038 en vez del angulo
	ld a,(0e038h)		;62b4   ; (0xE038)
	or a			;62b7
	ld a,c			;62b8
	jr nz,suma_la_primera_coordenada		;62b9
cambia_el_signo:		; El desplazamiento va hacia el otro lado
	neg		;62bb
suma_la_primera_coordenada:		; Se le suma a la coordenada de ahora y se guarda ocho bytes mas alla
	add a,(hl)			;62bd   ; sobre la coordenada de ahora
	push hl			;62be
	ld bc,00008h		;62bf   ; ocho bytes mas alla
	add hl,bc			;62c2
	ld (hl),a			;62c3
	pop hl			;62c4
	ld a,(0e061h)		;62c5   ; (0xE061), la otra mitad del producto
	ld c,a			;62c8
	ex de,hl			;62c9
decide_el_signo_de_la_segunda:		; Igual que arriba pero mirando el bit 4 del angulo
	ld a,(0e056h)		;62ca   ; (0xE056), el lado
	or a			;62cd
	jr z,y_si_manda_el_otro		;62ce
	ld a,(0e037h)		;62d0   ; (0xE037), su bit 4
	bit 4,a		;62d3
	ld a,c			;62d5
	jr z,suma_la_segunda_coordenada		;62d6
	jr cambia_el_signo_tambien		;62d8
y_si_manda_el_otro:		; Con 0xE056 a cero manda 0xE038
	ld a,(0e038h)		;62da   ; (0xE038)
	or a			;62dd
	ld a,c			;62de
	jr nz,suma_la_segunda_coordenada		;62df
cambia_el_signo_tambien:		; Hacia el otro lado
	neg		;62e1
suma_la_segunda_coordenada:		; Y se guarda ocho bytes mas alla, igual que la primera
	add a,(hl)			;62e3   ; sobre la coordenada de ahora
	ld bc,00008h		;62e4   ; ocho bytes mas alla
	add hl,bc			;62e7
	ld (hl),a			;62e8
	jr mueve_la_pelota_bateada		;62e9
rebota_la_pelota:		; El bote de verdad: un sonido, sube el contador de 0xE033, y a la altura de 0xE0A1 le resta 0x58 -con los bytes al reves, que es como se guarda-. Si al segundo bote 0xE388 tiene el bit 6, la altura se fija en 0xA800 de golpe
	call avisa_del_golpe		;62eb   ; el aviso del bote
	ld a,00ah		;62ee   ; A = 0x0a, el sonido del bote
	call pide_un_sonido		;62f0
	xor a			;62f3
	ld (0e031h),a		;62f4   ; (0xE031) := 0
	ld (0e057h),a		;62f7   ; (0xE057) := 0
	ld hl,0e033h		;62fa
	inc (hl)			;62fd   ; (0xE033), un bote mas
	ld hl,(0e0a1h)		;62fe   ; (0xE0A1), la altura
	ld a,l			;6301   ; con los bytes cambiados
	ld l,h			;6302
	ld h,a			;6303
	ld de,00058h		;6304   ; menos 0x58
	xor a			;6307
	sbc hl,de		;6308
	ld a,l			;630a   ; y otra vez cambiados
	ld l,h			;630b
	ld h,a			;630c
	ld a,(0e388h)		;630d   ; (0xE388), su bit 6
	bit 6,a		;6310
	jr z,L_631D		;6312
	ld a,(0e033h)		;6314   ; y solo en el segundo bote
	dec a			;6317
	jr nz,L_631D		;6318
	ld hl,0a800h		;631a   ; la altura se pone en 0xA800
L_631D:
	ld (0e0a1h),hl		;631d   ; la altura nueva
	jp nc,calcula_el_vuelo		;6320   ; y si no se paso, otra vuelta
se_para_la_pelota:		; La pelota deja de estar bateada
	xor a			;6323
	ld (0e039h),a		;6324   ; (0xE039) := 0
	ret			;6327
todavia_no_bota:		; Con 0xE031 puesto toca botar, y si no solo hay que seguir moviendola
	ld a,(0e031h)		;6328   ; (0xE031)
	or a			;632b
	jp nz,rebota_la_pelota		;632c
mueve_la_pelota_bateada:		; Le suma a la coordenada de 0xE0A7 lo que diga 0xE054, lo parte por 128 y de ahi saca la velocidad de este cuadro; la acumula en 0xE066/0xE068 y se la reparte a las dos coordenadas segun el angulo
	ld hl,0e0a7h		;632f   ; HL = 0xE0A7, la coordenada de caida
	ld d,(hl)			;6332
	inc hl			;6333
	ld e,(hl)			;6334
	ex de,hl			;6335
	ld a,(0e054h)		;6336   ; (0xE054), lo andado
	call suma_a_hl		;6339   ; sumado
	ld a,h			;633c   ; con los bytes cambiados
	ld h,l			;633d
	ld l,a			;633e
	call parte_por_128		;633f   ; partido por 128
	ld a,(0e060h)		;6342
	ld (0e054h),a		;6345   ; lo nuevo, a 0xE054
	ld a,(0e062h)		;6348   ; B = el cociente
	ld b,a			;634b
	ld a,(0e057h)		;634c   ; (0xE057): si esta puesto...
	or a			;634f
	jr z,acumula_el_recorrido		;6350
	srl b		;6352   ; ...el cociente se parte por dos
	jr nc,acumula_el_recorrido		;6354
	ld a,(0e054h)		;6356
	add a,080h		;6359   ; y a 0xE054 se le suma medio paso
	ld (0e054h),a		;635b
acumula_el_recorrido:		; Suma B veces el paso de 0xE066 sobre el acumulador de 0xE068, que es como se multiplica sin usar la calculadora
	ld hl,(0e066h)		;635e   ; (0xE066), el paso
	ex de,hl			;6361
	ld hl,(0e068h)		;6362   ; (0xE068), el acumulado
	ld a,b			;6365
suma_un_paso:		; B veces
	sub 001h		;6366   ; una vez menos
	jr c,reparte_el_recorrido		;6368
	add hl,de			;636a   ; un paso mas
	jr suma_un_paso		;636b
reparte_el_recorrido:		; El byte bajo del acumulado se queda, el alto es lo que hay que mover, y el angulo decide con que signo y a que coordenada le toca
	ld a,l			;636d
	ld (0e068h),a		;636e   ; el byte bajo se queda acumulado
	ld c,h			;6371   ; C = el alto, lo que se mueve
	ld hl,0e037h		;6372   ; HL = 0xE037, el angulo
	ld a,(0e056h)		;6375   ; (0xE056), el lado
	or a			;6378
	jr z,mira_el_nibble_del_angulo		;6379
	ld a,b			;637b
	ld b,c			;637c
	ld c,a			;637d
	ld a,(0e038h)		;637e
	or a			;6381
	jr z,mira_el_bit_del_angulo		;6382
mira_el_bit_del_angulo:		; El bit 4 del angulo decide el signo
	bit 4,(hl)		;6384   ; el bit 4
	jr z,$+21		;6386
	jr cambia_el_signo_del_paso		;6388
mira_el_nibble_del_angulo:		; Con 0xE056 a cero manda el nibble alto entero
	ld a,(hl)			;638a   ; el angulo
	and 0f0h		;638b   ; su nibble alto
	jr nz,$+14		;638d
cambia_el_signo_del_paso:		; Hacia el otro lado
	ld a,b			;638f
	neg		;6390   ; al reves
	ld b,a			;6392
	jr $+8		;6393

; ----------------------------------------------------------------------
; DATOS resto_6395: Cinco bytes entre dos rutinas; ningun salto aterriza en
;   ellos
;   0x6395..0x639b  (6 bytes)
DATA_resto_6395:
	defb 079h,0edh,044h,04fh,018h	; 6395
	defb 0efh	; 639a

; ======================================================================
; CODIGO 0x639b..0x64d4  (313 bytes)
; ======================================================================


reparte_el_paso_horizontal:		; Con el paso ya calculado en C, le pone el signo que diga 0xE038 y lo suma a la sombra y a la pelota
	ld a,(0e038h)		;639b   ; (0xE038), el sentido
	or a			;639e
	ld a,c			;639f   ; A = el paso
	ld d,000h		;63a0   ; DE = el paso con signo, en 16 bits
	ld e,a			;63a2
	jr nz,el_paso_cero		;63a3
	neg		;63a5   ; hacia el otro lado
	dec d			;63a7   ; y el byte alto, a 0xFF
	ld e,a			;63a8
el_paso_cero:		; Con el paso a cero, tambien el byte alto
	or a			;63a9
	jr nz,suma_el_paso		;63aa
	ld d,a			;63ac   ; D = 0
suma_el_paso:		; A la columna de la sombra le suma el paso, y a la pareja de 16 bits de la pelota le suma el paso con signo
	ld hl,0e0b0h		;63ad   ; HL = 0xE0B0, la fila de la sombra
	add a,(hl)			;63b0   ; mas el paso
	ld (hl),a			;63b1
	ld a,(0e0b4h)		;63b2   ; (0xE0B4), el byte bajo de la pelota
	ld l,a			;63b5
	ld a,(0e042h)		;63b6   ; (0xE042), el alto
	ld h,a			;63b9
	add hl,de			;63ba   ; mas el paso con signo
	ld a,l			;63bb
	ld (0e0b4h),a		;63bc   ; y de vuelta a los dos bytes
	ld a,h			;63bf
	ld (0e042h),a		;63c0
	ld hl,0e0b1h		;63c3   ; HL = 0xE0B1, la columna de la sombra
	ld a,b			;63c6
	add a,(hl)			;63c7   ; mas lo que traiga B
	ld b,a			;63c8
	ld a,(0e038h)		;63c9   ; (0xE038): valiendo 0xFF no hay tope que valga
	inc a			;63cc
	ld a,b			;63cd
	jr z,guarda_la_columna		;63ce
	ld a,(0e0b0h)		;63d0   ; (0xE0B0): por debajo de la fila 0x78 tampoco
	cp 078h		;63d3
	ld a,b			;63d5
	jr c,guarda_la_columna		;63d6
	cp 004h		;63d8   ; por la izquierda del todo, la pelota se para
	jp c,se_para_la_pelota		;63da
	cp 0fch		;63dd   ; y por la derecha, tambien
	jp nc,se_para_la_pelota		;63df
guarda_la_columna:		; La columna nueva, a la sombra y a la pelota, y de paso se acumulan catorce unidades de recorrido
	ld (hl),a			;63e2   ; la columna de la sombra
	ld (0e0b5h),a		;63e3   ; y la de la pelota
	ld hl,(0e034h)		;63e6   ; (0xE034), lo recorrido
	ld bc,0000eh		;63e9   ; catorce mas por cuadro
	add hl,bc			;63ec
	ld (0e034h),hl		;63ed
	ex de,hl			;63f0
	ld hl,(0e0a9h)		;63f1   ; (0xE0A9), la segunda coordenada de la caida
	ld a,l			;63f4   ; con los bytes cambiados
	ld l,h			;63f5
	ld h,a			;63f6
	ld a,(0e036h)		;63f7   ; (0xE036), lo que llevaba
	call suma_a_hl		;63fa
	xor a			;63fd
	ld (0e032h),a		;63fe   ; (0xE032) := 0: de momento, hacia arriba
	ld b,h			;6401
	ld c,l			;6402
	sbc hl,de		;6403   ; comparada con lo recorrido
	jr nc,saca_la_velocidad_vertical		;6405
	ld h,b			;6407
	ld l,c			;6408
	ex de,hl			;6409
	xor a			;640a
	sbc hl,de		;640b   ; la resta, del reves
	inc a			;640d
	ld (0e032h),a		;640e   ; (0xE032) := 1: la pelota va de bajada
	ld (0e057h),a		;6411   ; (0xE057) := 1
	inc a			;6414
	ld (0e650h),a		;6415   ; (0xE650) := 2, el canal de sonido
saca_la_velocidad_vertical:		; Lo que queda por recorrer, partido por 128: eso es lo que la pelota sube o baja este cuadro
	ex de,hl			;6418
	ld hl,0e060h		;6419   ; HL = 0xE060, el hueco de la calculadora
	ld (hl),d			;641c
	inc hl			;641d
	ld (hl),e			;641e
	inc hl			;641f
	call pon_divisor_y_divide		;6420   ; partido por 128
	ld a,(0e060h)		;6423
	ld (0e036h),a		;6426   ; el resto se guarda para el cuadro siguiente
	ld a,(0e062h)		;6429   ; (0xE062), el cociente
	ld d,000h		;642c   ; DE = el cociente en 16 bits
	ld e,a			;642e
	or a			;642f
	jr z,mueve_la_pelota_en_vertical		;6430   ; a cero, no hay nada que mover
	ld hl,0e032h		;6432
	bit 0,(hl)		;6435   ; (0xE032): de bajada, cambia de signo
	jr z,mueve_la_pelota_en_vertical		;6437
	neg		;6439   ; al reves
	dec d			;643b
	ld e,a			;643c
mueve_la_pelota_en_vertical:		; Le resta la velocidad a la pareja de 16 bits de la pelota y, si con eso alcanza a la sombra, marca el bote
	ld a,(0e0b0h)		;643d   ; (0xE0B0), la fila de la sombra
	cp 0d0h		;6440   ; pasada la 0xD0, la pelota se para
	jp nc,se_para_la_pelota		;6442
	ld b,a			;6445   ; B = la fila de la sombra
	ld a,(0e0b4h)		;6446   ; (0xE0B4), el byte bajo de la pelota
	ld l,a			;6449
	ld a,(0e042h)		;644a   ; (0xE042), el alto
	ld h,a			;644d
	xor a			;644e
	sbc hl,de		;644f   ; menos la velocidad
	ld a,l			;6451
	ld (0e0b4h),a		;6452   ; y de vuelta a los dos bytes
	ld a,h			;6455
	ld (0e042h),a		;6456
	or a			;6459   ; con el byte alto puesto sigue por el aire
	jr nz,elige_el_tamano_de_la_pelota		;645a
	ld a,l			;645c
	cp b			;645d   ; comparada con la de la sombra
	jr z,elige_el_tamano_de_la_pelota		;645e
	jr c,elige_el_tamano_de_la_pelota		;6460
	ld a,001h		;6462   ; (0xE031) := 1: bote
	ld (0e031h),a		;6464
	ld a,b			;6467
	ld (0e0b4h),a		;6468   ; y la pelota se queda pegada a la sombra
elige_el_tamano_de_la_pelota:		; El tamano sale de dos cosas: la ALTURA -la distancia entre la fila de la sombra y la de la pelota, que da hasta tres pasos de tamano- y lo LEJOS que esta -si la sombra esta por encima de la fila 0x40, uno mas-. B acaba valiendo de 0 (la mas grande) a 4 (la mas pequena)
	ld b,000h		;646b   ; B = 0, el tamano mas grande
	ld a,(0e042h)		;646d   ; (0xE042): con el byte alto puesto, la pelota esta muy arriba
	or a			;6470
	jr nz,dibuja_la_pelota_y_su_sombra		;6471
	ld a,(0e0b0h)		;6473   ; C = la fila de la sombra
	ld c,a			;6476
	cp 0d0h		;6477   ; en la 0xD0 no se dibuja
	ret z			;6479
	ld a,(0e0b4h)		;647a   ; la fila de la pelota
	cp 0d0h		;647d   ; tampoco
	ret z			;647f
	ld d,a			;6480
	ld a,c			;6481
	sub d			;6482   ; la altura: la sombra menos la pelota
	cp 021h		;6483   ; mas de 0x21 de altura: la mas grande
	jr nc,y_si_ademas_esta_lejos		;6485
	inc b			;6487   ; un tamano menos
	cp 00fh		;6488   ; mas de 0x0f
	jr nc,y_si_ademas_esta_lejos		;648a
	inc b			;648c   ; otro menos
	cp 006h		;648d   ; mas de 0x06
	jr nc,y_si_ademas_esta_lejos		;648f
	inc b			;6491   ; y otro
y_si_ademas_esta_lejos:		; Con la sombra por encima de la fila 0x40, un tamano menos todavia
	ld a,c			;6492
	cp 040h		;6493   ; la fila 0x40 es el fondo del campo
	jr nc,dibuja_la_pelota_y_su_sombra		;6495
	inc b			;6497   ; un tamano menos
dibuja_la_pelota_y_su_sombra:		; Sube a VRAM los dos patrones del tamano elegido -la pelota en 0x1800 y la sombra en 0x1be0- y vuelca los dos atributos. Con la pelota por las nubes, la sombra se manda a la fila 0xCF y desaparece
	ld hl,0655fh		;6498   ; HL = 0x655f, los tamanos
	ld a,b			;649b
	rlca			;649c   ; por cuatro: cuatro bytes por entrada
	rlca			;649d
	call suma_a_hl		;649e
	ld e,(hl)			;64a1   ; DE = el guion de la pelota
	inc hl			;64a2
	ld d,(hl)			;64a3
	inc hl			;64a4
	push hl			;64a5
	ex de,hl			;64a6
	ld de,05800h		;64a7   ; DE = VRAM 0x5800, o sea el patron 0
	call dibuja_guion		;64aa   ; descomprimido ahi
	pop hl			;64ad
	ld e,(hl)			;64ae   ; el guion de la sombra
	inc hl			;64af
	ld d,(hl)			;64b0
	ex de,hl			;64b1
	ld de,05be0h		;64b2   ; DE = VRAM 0x5be0, el patron 31
	call dibuja_guion		;64b5
	ld hl,0e0b0h		;64b8   ; HL = 0xE0B0, el atributo de la sombra
	ld de,07b7ch		;64bb   ; DE = VRAM 0x7b7c, el ultimo sprite
	ld b,004h		;64be
	call vuelca_un_atributo		;64c0
	ld a,(0e042h)		;64c3   ; (0xE042): con la pelota muy arriba...
	or a			;64c6
	jr z,y_ahora_la_pelota		;64c7
	ld hl,064d4h		;64c9   ; ...la sombra se esconde con el 0xCF de 0x64d4
y_ahora_la_pelota:		; El atributo de la pelota va al primer sprite de la tabla
	ld de,07b00h		;64cc   ; DE = VRAM 0x7b00, el primer sprite
vuelca_un_atributo:		; Los cuatro bytes de un atributo de sprite
	ld b,004h		;64cf   ; cuatro bytes
	jp copia_bytes_con_candado		;64d1

; ----------------------------------------------------------------------
; DATOS sprite_escondido: Un atributo de sprite con la fila 0xCF, que es la de
;   esconder. 0x64c9 lo usa para quitar la sombra de en medio cuando la pelota
;   esta demasiado alta
;   0x64d4..0x64d8  (4 bytes)
DATA_sprite_escondido:
	defb 0cfh,0cfh,000h,000h	; 64d4

; ======================================================================
; CODIGO 0x64d8..0x655f  (135 bytes)
; ======================================================================


multiplica_por_a:		; Coge (0xE066) con los bytes cambiados, lo deja de multiplicando y multiplica por lo que traiga A
	ld hl,(0e066h)		;64d8   ; (0xE066)
	ld b,l			;64db
	ld l,h			;64dc   ; con los bytes cambiados
	ld h,b			;64dd
	ld (0e060h),hl		;64de
	ld hl,0e062h		;64e1
	ld (hl),000h		;64e4
	inc hl			;64e6
	ld (hl),a			;64e7   ; A es el multiplicador
	jr multiplica_la_calculadora		;64e8
saca_la_componente_del_angulo:		; Del angulo de 0xE037 se queda con cinco bits -y con el bit 4 puesto le da la vuelta al signo-, lo multiplica por 16 y guarda el resultado en 0xE066/0xE067, con el acumulado de 0xE068 a cero
	ld a,(0e037h)		;64ea   ; (0xE037), el angulo
	ld b,01fh		;64ed   ; B = 0x1f, los cinco bits utiles
	bit 4,a		;64ef   ; el bit 4 dice de que lado
	jr z,L_64F5		;64f1
	neg		;64f3   ; y entonces el angulo va al reves
L_64F5:
	and b			;64f5   ; recortado a cinco bits
	ld hl,0e060h		;64f6
	ld (hl),000h		;64f9   ; (0xE060) := 0
	inc hl			;64fb
	ld (hl),a			;64fc   ; (0xE061) := el angulo
	inc hl			;64fd
	ld (hl),000h		;64fe   ; (0xE062) := 0
	inc hl			;6500
	ld (hl),010h		;6501   ; (0xE063) := 16, el multiplicador
	call multiplica_la_calculadora		;6503
	ld a,(0e062h)		;6506
	ld (0e066h),a		;6509   ; el resultado, a 0xE066
	ld a,(0e061h)		;650c
	ld (0e067h),a		;650f   ; y a 0xE067
	ld hl,00000h		;6512
	ld (0e068h),hl		;6515   ; el acumulado, a cero
	ret			;6518
divide_la_calculadora:		; La division de la calculadora: ocho vueltas de desplazar 24 bits a la izquierda y restar el divisor de 0xE063 cuando quepa. El cociente entra por abajo en 0xE062 y el resto se queda en 0xE060
	exx			;6519
	ld c,008h		;651a   ; ocho vueltas, una por bit
una_vuelta_de_la_calculadora:		; Desplaza los tres bytes y prueba a restar
	ld hl,0e062h		;651c   ; HL = 0xE062, el byte bajo
	or a			;651f
	ld b,003h		;6520   ; tres bytes
desplaza_un_byte:		; Los tres, de abajo arriba, con el acarreo encadenado
	rl (hl)		;6522
	dec hl			;6524
	djnz desplaza_un_byte		;6525
	inc hl			;6527
	ex de,hl			;6528
	ld hl,0e063h		;6529   ; HL = 0xE063, el divisor
	ld a,(de)			;652c
	sub (hl)			;652d   ; cabe?
	jr c,otra_vuelta_de_la_calculadora		;652e
	ld (de),a			;6530   ; el resto se queda con lo que sobra
	dec hl			;6531
	set 0,(hl)		;6532   ; y el bit del cociente, puesto
otra_vuelta_de_la_calculadora:		; Hasta las ocho
	dec c			;6534   ; una vuelta menos
	jr nz,una_vuelta_de_la_calculadora		;6535
	exx			;6537
	ret			;6538
multiplica_la_calculadora:		; La multiplicacion de la calculadora: dieciseis vueltas de desplazar 24 bits a la izquierda y, cuando salga acarreo, sumar el multiplicando de 0xE063 al producto. El resultado se queda en 0xE060..0xE062
	exx			;6539
	ld b,010h		;653a   ; dieciseis vueltas, una por bit
una_vuelta_de_la_multiplicacion:		; Desplaza y, si sale acarreo, suma
	ld hl,0e062h		;653c   ; HL = 0xE062
	or a			;653f
	rl (hl)		;6540   ; los tres bytes, encadenados
	dec hl			;6542
	rl (hl)		;6543
	dec hl			;6545
	rl (hl)		;6546
	jr nc,otra_vuelta_de_multiplicacion		;6548   ; sin acarreo no se suma
	ld hl,0e063h		;654a   ; HL = 0xE063, el multiplicando
	ld a,(hl)			;654d
	dec hl			;654e
	add a,(hl)			;654f   ; sumado por abajo...
	ld (hl),a			;6550
	dec hl			;6551
	ld a,(hl)			;6552
	adc a,000h		;6553   ; ...y el acarreo, arrastrado
	ld (hl),a			;6555
	dec hl			;6556
	ld a,(hl)			;6557
	adc a,000h		;6558   ; hasta el byte de mas peso
	ld (hl),a			;655a
otra_vuelta_de_multiplicacion:		; Hasta las dieciseis
	djnz una_vuelta_de_la_multiplicacion		;655b   ; una vuelta menos
	exx			;655d
	ret			;655e

; ----------------------------------------------------------------------
; DATOS tamanos_de_la_pelota: Cinco entradas de cuatro bytes: por cada altura,
;   el guion del dibujo de la pelota y el de su sombra. 0x6498 entra aqui con
;   el indice por cuatro, y de ahi salen los dos patrones que sube a VRAM
;   0x655f..0x6573  (20 bytes)
DATA_tamanos_de_la_pelota:
	defb 073h,065h,07eh,065h	; 655f
	defb 07eh,065h,088h,065h	; 6563
	defb 088h,065h,088h,065h	; 6567
	defb 090h,065h,090h,065h	; 656b
	defb 098h,065h,098h,065h	; 656f

; ----------------------------------------------------------------------
; DATOS dibujos_de_la_pelota: Los cinco tamanos de la pelota, cada uno un
;   guion que llena los 32 bytes de un patron de sprite: siete filas el mas
;   grande (0x6573), seis el siguiente (0x657e), cuatro (0x6588), cuatro mas
;   finas (0x6590) y dos el mas pequeno (0x6598). La pelota se hace chica al
;   alejarse, y son cinco dibujos, no un escalado
;   0x6573..0x659e  (43 bytes)
DATA_dibujos_de_la_pelota:
	defb 087h,038h,07ch,0feh,0feh,0feh,07ch,038h,019h,000h	; 6573  .8|...|8..
	defb 000h,086h,018h,03ch,07eh,07eh,03ch,018h,01ah,000h	; 657d  ...<~~<...
	defb 000h,084h,018h,03ch,03ch,018h,01ch,000h,000h,084h	; 6587  ...<<.....
	defb 008h,01ch,01ch,008h,01ch,000h,000h,082h,018h,018h	; 6591  ..........
	defb 01eh,000h,000h	; 659b

; ======================================================================
; CODIGO 0x659e..0x65ad  (15 bytes)
; ======================================================================


parte_por_128:		; Deja HL de dividendo y divide entre 128, que es la escala en la que trabaja toda la trayectoria
	ld (0e060h),hl		;659e   ; HL, al hueco de la calculadora
	ld hl,0e062h		;65a1
pon_divisor_y_divide:		; El divisor va en 0xE063, y a dividir
	ld (hl),000h		;65a4   ; (0xE062) := 0
	inc hl			;65a6
	ld (hl),080h		;65a7   ; (0xE063) := 0x80
	call divide_la_calculadora		;65a9
	ret			;65ac

; ----------------------------------------------------------------------
; DATOS guiones_65ad: Bloque grande de guiones de graficos, cargados desde
;   varios sitios del arranque y desde 0x70c9/0x720a. Formato interno no
;   separado en esta pasada
;   0x65ad..0x6c0e  (1633 bytes)
DATA_guiones_65ad:
	defb 040h,008h,008h,07ah,008h,070h,008h,074h,007h,0f7h,081h,074h,02dh,0f1h,003h,0a0h	; 65ad  @..z.p.t...t-...
	defb 005h,0f1h,003h,0a0h,005h,0f1h,003h,0a0h,07fh,0f4h,069h,0f4h,07fh,064h,011h,064h	; 65bd  ..........i..d.d
	defb 038h,0a4h,002h,064h,006h,0c6h,005h,064h,003h,0c6h,004h,064h,004h,0c6h,003h,064h	; 65cd  8..d...d...d...d
	defb 005h,0c6h,005h,064h,003h,0c6h,004h,064h,004h,0c6h,004h,064h,004h,0c6h,004h,064h	; 65dd  ...d...d...d...d
	defb 004h,0c6h,07fh,0c6h,07fh,0c6h,07ah,0c6h,07fh,0f6h,051h,0f6h,007h,0c6h,081h,0f6h	; 65ed  ......z...Q.....
	defb 007h,0c6h,081h,0f6h,010h,0f1h,048h,0a1h,008h,066h,018h,0f1h,080h,060h,008h,008h	; 65fd  ......H..f...`..
	defb 07fh,00fh,0ffh,081h,000h,007h,0e0h,081h,000h,008h,0d0h,084h,000h,000h,0ffh,000h	; 660d  ................
	defb 004h,0ffh,082h,000h,007h,003h,006h,08bh,007h,006h,006h,000h,0e0h,030h,030h,020h	; 661d  .............00 
	defb 0c0h,060h,030h,008h,000h,084h,0d0h,0d0h,0dfh,0c0h,004h,0ffh,084h,000h,000h,0ffh	; 662d  .`0.............
	defb 000h,004h,0ffh,084h,00bh,00bh,0fbh,003h,004h,0ffh,0ach,0ddh,088h,077h,077h,022h	; 663d  .............ww"
	defb 0ddh,0ddh,088h,0ddh,0d8h,0b7h,0b7h,0a2h,05dh,05dh,008h,077h,022h,0ddh,0ddh,088h	; 664d  ........]].w"...
	defb 077h,077h,022h,0f7h,0e2h,0ddh,0ddh,008h,003h,000h,000h,077h,022h,0ddh,0ddh,088h	; 665d  ww"........w"...
	defb 0ffh,01fh,003h,07dh,018h,007h,002h,004h,000h,091h,0ddh,088h,077h,037h,0e2h,03dh	; 666d  ...}........w7.=
	defb 018h,007h,0f7h,0e2h,03dh,00dh,004h,001h,000h,000h,001h,007h,000h,08bh,077h,022h	; 667d  ....=.........w"
	defb 0ddh,0ddh,088h,0f7h,077h,022h,00fh,003h,001h,005h,000h,0a4h,0ddh,088h,0f7h,063h	; 668d  ....w".........c
	defb 01eh,00ch,003h,000h,0bbh,01bh,0edh,0edh,045h,0bah,0bah,010h,0efh,047h,0bbh,0bbh	; 669d  ........E....G..
	defb 010h,0c0h,000h,000h,0eeh,044h,0bbh,0bbh,011h,0ffh,0f8h,0c0h,0beh,018h,0e0h,040h	; 66ad  .....D.........@
	defb 004h,000h,089h,0bbh,011h,0eeh,0ech,047h,0bch,018h,0e0h,080h,007h,000h,093h,0efh	; 66bd  .......G........
	defb 047h,0bch,0b0h,020h,080h,000h,000h,0eeh,044h,0bbh,0bbh,011h,0efh,0eeh,044h,0f0h	; 66cd  G.. ....D.....D.
	defb 0c0h,080h,005h,000h,092h,0bbh,011h,0efh,0c6h,078h,030h,0c0h,000h,000h,063h,066h	; 66dd  .........x0...cf
	defb 06ch,078h,07ch,06eh,067h,000h,03eh,005h,063h,09bh,03eh,000h,063h,073h,07bh,07fh	; 66ed  lx|ng.>.c.>.cs{.
	defb 06fh,067h,063h,000h,01ch,036h,063h,063h,07fh,063h,063h,000h,063h,077h,07fh,07fh	; 66fd  ogc..6cc.cc.cw..
	defb 06bh,063h,063h,000h,03ch,005h,018h,081h,03ch,008h,000h,005h,000h,083h,0c0h,0f8h	; 670d  kcc.<...<.......
	defb 0ffh,004h,000h,094h,0c0h,0f0h,0fch,0ffh,080h,0c0h,0c0h,0e0h,0f0h,0f0h,0f8h,0fch	; 671d  ................
	defb 080h,0c0h,0e0h,0f0h,0f8h,0fch,0feh,0ffh,004h,000h,08ch,080h,0c0h,0c0h,0e0h,0f0h	; 672d  ................
	defb 0f0h,0f8h,0fch,0fch,0feh,0ffh,0ffh,003h,080h,002h,0c0h,003h,0e0h,003h,0f0h,004h	; 673d  ................
	defb 0f8h,081h,0fch,002h,0fch,003h,0feh,003h,0ffh,005h,000h,083h,003h,01fh,0ffh,004h	; 674d  ................
	defb 000h,084h,003h,00fh,03fh,0ffh,090h,001h,003h,007h,00fh,01fh,03fh,07fh,0ffh,001h	; 675d  ....?.......?...
	defb 003h,003h,007h,00fh,00fh,01fh,03fh,004h,000h,08ch,001h,003h,003h,007h,00fh,00fh	; 676d  ......?.........
	defb 01fh,03fh,03fh,07fh,0ffh,0ffh,003h,001h,002h,003h,003h,007h,003h,00fh,004h,01fh	; 677d  .??.............
	defb 081h,03fh,002h,03fh,003h,07fh,003h,0ffh,008h,0ffh,003h,07fh,081h,0b0h,004h,000h	; 678d  .?.?............
	defb 083h,0ffh,0f8h,080h,005h,000h,081h,0e0h,007h,000h,081h,007h,007h,000h,083h,0ffh	; 679d  ................
	defb 01fh,001h,005h,000h,003h,0feh,081h,00dh,004h,000h,0c0h,0e0h,0fch,000h,000h,0e0h	; 67ad  ................
	defb 0fch,0ffh,0ffh,000h,000h,080h,0f0h,0feh,000h,080h,0f0h,0c0h,0f0h,0fch,0ffh,0c0h	; 67bd  ................
	defb 0f0h,0fch,0ffh,007h,03fh,0ffh,000h,007h,03fh,0ffh,0ffh,000h,000h,001h,00fh,07fh	; 67cd  ....?...?.......
	defb 000h,001h,00fh,003h,00fh,03fh,0ffh,003h,00fh,03fh,0ffh,0fch,0feh,0ffh,0ffh,080h	; 67dd  .....?...?......
	defb 0c0h,0c0h,0e0h,03fh,07fh,0ffh,0ffh,001h,003h,003h,007h,008h,0ffh,081h,0feh,007h	; 67ed  ...?............
	defb 0ffh,083h,000h,0c0h,0f8h,005h,0ffh,092h,080h,0c0h,0e0h,0f0h,0f8h,0fch,0feh,0ffh	; 67fd  ................
	defb 080h,0c0h,0e0h,0f0h,0f0h,0f8h,0fch,0fch,0fch,0feh,006h,0ffh,088h,0f0h,0f0h,0f8h	; 680d  ................
	defb 0fch,0fch,0feh,0ffh,0ffh,003h,080h,003h,0c0h,002h,0e0h,081h,0e0h,003h,0f0h,003h	; 681d  ................
	defb 0f8h,081h,0fch,002h,0fch,003h,0feh,084h,0fch,0f0h,0c0h,07fh,007h,0ffh,083h,000h	; 682d  ................
	defb 003h,01fh,005h,0ffh,092h,001h,003h,007h,00fh,01fh,03fh,07fh,0ffh,001h,003h,007h	; 683d  ..........?.....
	defb 00fh,00fh,01fh,03fh,03fh,03fh,07fh,006h,0ffh,088h,00fh,00fh,01fh,03fh,03fh,07fh	; 684d  ...???.......??.
	defb 0ffh,0ffh,003h,001h,003h,003h,002h,007h,081h,007h,003h,00fh,003h,01fh,081h,03fh	; 685d  ...............?
	defb 002h,03fh,003h,07fh,083h,03fh,00fh,003h,084h,0ffh,03fh,00fh,003h,004h,000h,005h	; 686d  .?...?....?.....
	defb 0ffh,087h,03fh,00fh,003h,0ffh,03fh,00fh,003h,004h,000h,084h,0ffh,0fch,0f0h,0c0h	; 687d  ..?...?.........
	defb 004h,000h,084h,0ffh,0fch,0f0h,0c0h,004h,000h,005h,0ffh,087h,0fch,0f0h,0c0h,000h	; 688d  ................
	defb 0c0h,0f0h,0fch,004h,0ffh,005h,000h,087h,0c0h,0f0h,0fch,000h,003h,00fh,03fh,004h	; 689d  ..............?.
	defb 0ffh,005h,000h,087h,003h,00fh,03fh,0ffh,03fh,00fh,003h,004h,000h,084h,0ffh,0fch	; 68ad  ......?.?.......
	defb 0f0h,0c0h,004h,000h,004h,0ffh,004h,000h,003h,000h,082h,030h,0fch,003h,0ffh,003h	; 68bd  ...........0....
	defb 000h,082h,00ch,03fh,003h,0ffh,090h,07fh,03fh,00fh,00fh,01fh,03fh,03fh,07fh,0feh	; 68cd  ...?....?...??..
	defb 0fch,0f0h,0f0h,0f8h,0fch,0fch,0feh,003h,0ffh,085h,0f8h,0f0h,0e0h,0c0h,080h,003h	; 68dd  ................
	defb 0ffh,08ah,01fh,00fh,007h,003h,001h,080h,0c0h,0e0h,0f0h,0f8h,003h,0ffh,006h,000h	; 68ed  ................
	defb 082h,0c0h,0ffh,006h,000h,087h,003h,0ffh,001h,003h,007h,00fh,01fh,003h,0ffh,002h	; 68fd  ................
	defb 0ffh,002h,07fh,002h,03fh,002h,01fh,002h,00fh,002h,007h,002h,003h,002h,001h,002h	; 690d  ....?...........
	defb 0ffh,002h,0feh,002h,0fch,002h,0f8h,002h,0f0h,002h,0e0h,002h,0c0h,002h,080h,003h	; 691d  ................
	defb 000h,005h,0ffh,084h,0c0h,030h,00ch,003h,004h,000h,004h,000h,088h,0c0h,030h,00ch	; 692d  .....0........0.
	defb 003h,003h,00ch,030h,0c0h,004h,000h,004h,000h,089h,003h,00ch,030h,0c0h,003h,00fh	; 693d  ...0........0...
	defb 03fh,0cfh,003h,003h,000h,085h,0c0h,0f0h,0fch,0f3h,0c0h,003h,000h,088h,003h,00ch	; 694d  ?...............
	defb 03fh,0ffh,0ffh,03fh,00ch,003h,003h,000h,002h,0c0h,003h,000h,003h,000h,002h,003h	; 695d  ?..?............
	defb 003h,000h,088h,0c0h,030h,0fch,0ffh,0ffh,0fch,030h,0c0h,004h,000h,086h,0c0h,030h	; 696d  ....0....0.....0
	defb 00dh,003h,000h,0ffh,005h,081h,081h,001h,082h,000h,0ffh,005h,081h,081h,080h,004h	; 697d  ................
	defb 000h,084h,003h,00ch,0b0h,0c0h,003h,001h,081h,003h,004h,002h,008h,001h,004h,00fh	; 698d  ................
	defb 084h,0cfh,03fh,00fh,003h,004h,0f0h,084h,0f3h,0fch,0f0h,0c0h,00bh,080h,081h,0c0h	; 699d  ..?.............
	defb 004h,040h,081h,006h,004h,004h,083h,00ch,008h,00fh,007h,001h,081h,0ffh,081h,001h	; 69ad  .@..............
	defb 007h,000h,081h,080h,007h,000h,007h,080h,081h,0ffh,081h,060h,004h,020h,085h,030h	; 69bd  ...........`. .0
	defb 010h,0f0h,0ffh,0c0h,005h,000h,081h,007h,082h,0ffh,003h,005h,000h,081h,0e0h,008h	; 69cd  ................
	defb 00bh,088h,000h,01ch,02eh,06dh,06bh,05bh,03ah,01ch,008h,000h,008h,040h,008h,060h	; 69dd  .....mk[:....@.`
	defb 008h,070h,008h,078h,008h,07ch,008h,07eh,008h,07fh,088h,0ffh,080h,0aah,080h,0d5h	; 69ed  .p.x.|.~........
	defb 080h,0aah,0ffh,008h,000h,098h,044h,048h,050h,060h,051h,048h,044h,000h,000h,000h	; 69fd  ......DHP`QHD...
	defb 000h,0a8h,054h,054h,055h,001h,020h,028h,048h,048h,08ah,08dh,009h,009h,000h,078h	; 6a0d  ..TTU. (HH.....x
	defb 000h,098h,002h,0a0h,0a0h,0a0h,0a0h,001h,002h,002h,005h,009h,009h,0f1h,0f2h,0f3h	; 6a1d  ................
	defb 0f4h,0f5h,0f6h,0f7h,0f8h,0f9h,009h,007h,008h,096h,003h,002h,004h,0a0h,082h,001h	; 6a2d  ................
	defb 002h,004h,0a0h,084h,001h,002h,002h,005h,00dh,009h,082h,0f0h,096h,003h,002h,004h	; 6a3d  ................
	defb 0a0h,08ah,001h,003h,003h,004h,003h,004h,003h,003h,003h,005h,00dh,009h,082h,0f0h	; 6a4d  ................
	defb 096h,004h,003h,084h,004h,003h,004h,003h,006h,00dh,086h,019h,03ch,00ah,00bh,00bh	; 6a5d  ............<...
	defb 006h,008h,00bh,086h,006h,00bh,00bh,00ch,03ch,00eh,006h,00dh,005h,00fh,096h,01bh	; 6a6d  ........<.......
	defb 01ah,03dh,03eh,03fh,029h,029h,029h,023h,024h,025h,026h,027h,028h,029h,029h,029h	; 6a7d  .=>?)))#$%&'()))
	defb 040h,041h,042h,010h,011h,005h,00fh,003h,00dh,087h,01dh,01ch,029h,029h,033h,047h	; 6a8d  @AB.........))3G
	defb 046h,00ch,079h,087h,043h,044h,02ah,029h,029h,012h,013h,003h,00dh,089h,00fh,020h	; 6a9d  F.y.CD*))...... 
	defb 01fh,01eh,029h,034h,048h,056h,055h,00eh,04bh,08fh,04ch,04dh,045h,02bh,029h,015h	; 6aad  ..)4HVU.K.LME+).
	defb 014h,016h,00fh,022h,021h,029h,029h,035h,057h,014h,04bh,086h,04eh,02dh,029h,029h	; 6abd  ..."!))5W.K.N-))
	defb 017h,018h,003h,029h,082h,035h,057h,016h,04bh,082h,04eh,02dh,005h,029h,082h,036h	; 6acd  ...).5W.K.N-.).6
	defb 058h,018h,04bh,082h,04fh,02ch,003h,029h,083h,037h,04ah,059h,018h,04bh,087h,050h	; 6add  X.K.O,.).7JY.K.P
	defb 049h,02eh,029h,029h,038h,05ah,00bh,04bh,084h,063h,062h,05eh,05fh,00bh,04bh,085h	; 6aed  I.))8Z.K.cb^_.K.
	defb 051h,02fh,029h,039h,05bh,00ah,04bh,088h,063h,062h,07dh,07eh,07fh,07bh,05eh,05fh	; 6afd  Q/)9[.K.cb}~.{^_
	defb 00ah,04bh,084h,052h,030h,03ah,05ch,008h,04bh,08ch,063h,062h,07dh,07ch,067h,06bh	; 6b0d  .K.R0:\.K.cb}|gk
	defb 06ch,065h,07ah,07bh,05eh,05fh,008h,04bh,084h,053h,031h,03bh,05dh,006h,04bh,08ah	; 6b1d  lez{^_.K.S1;].K.
	defb 063h,062h,07dh,07ch,067h,066h,06fh,094h,095h,070h,086h,064h,065h,07ah,07bh,05eh	; 6b2d  cb}|gfo..p.dez{^
	defb 05fh,006h,04bh,0ach,054h,032h,07ah,07bh,05eh,05fh,04bh,04bh,063h,062h,07dh,07ch	; 6b3d  _.K.T2z{^_KKcb}|
	defb 067h,066h,04bh,04bh,071h,072h,073h,074h,04bh,04bh,064h,065h,07ah,07bh,05eh,05fh	; 6b4d  gfKKqrstKKdez{^_
	defb 04bh,04bh,063h,062h,07dh,07ch,064h,065h,07ah,07bh,060h,061h,07dh,07ch,067h,066h	; 6b5d  KKcb}|dez{`a}|gf
	defb 00ch,04bh,093h,064h,065h,07ah,07bh,060h,061h,07dh,07ch,067h,066h,04bh,04bh,064h	; 6b6d  .K.dez{`a}|gfKKd
	defb 065h,07ah,080h,081h,0a1h,06dh,00eh,04bh,087h,06eh,0a1h,082h,083h,07ch,067h,066h	; 6b7d  ez...m.K.n...|gf
	defb 006h,04bh,086h,064h,065h,07ah,07bh,05eh,05fh,00ch,04bh,086h,063h,062h,07dh,07ch	; 6b8d  .K.dez{^_.K.cb}|
	defb 067h,066h,005h,04bh,081h,0deh,003h,009h,087h,04bh,064h,065h,07ah,07bh,05eh,05fh	; 6b9d  gf.K.....Kdez{^_
	defb 008h,04bh,086h,063h,062h,07dh,07ch,067h,066h,007h,04bh,081h,0d0h,003h,009h,003h	; 6bad  .K.cb}|gf.K.....
	defb 04bh,085h,064h,065h,07ah,07bh,068h,006h,06ah,085h,069h,07dh,07ch,067h,066h,008h	; 6bbd  K.dez{h.j.i}|gf.
	defb 009h,082h,04bh,0d3h,003h,009h,005h,04bh,08eh,064h,065h,07ah,084h,085h,0a1h,0a1h	; 6bcd  ..K....K.dez....
	defb 086h,087h,07ch,067h,066h,04bh,04bh,008h,009h,006h,04bh,08fh,0deh,0d8h,0dch,0dch	; 6bdd  ..|gfKK...K.....
	defb 0d1h,077h,0a1h,088h,089h,08ah,08bh,08ch,08dh,0a1h,075h,003h,04bh,008h,009h,003h	; 6bed  .w........u.K...
	defb 04bh,008h,009h,08ah,078h,0a1h,08eh,08fh,090h,091h,092h,093h,0a1h,076h,00bh,04bh	; 6bfd  K...x........v.K
	defb 000h	; 6c0d

; ======================================================================
; CODIGO 0x6c0e..0x6e74  (614 bytes)
; ======================================================================


pide_un_sonido:		; La puerta de entrada del motor: A trae el numero de sonido. Con la demostracion en marcha -0xE002 puesto- el cartucho se queda mudo, y por eso las escenas automaticas no suenan
	push af			;6c0e
	ld a,(0e002h)		;6c0f   ; (0xE002), el piloto automatico
	or a			;6c12
	jr z,pide_un_sonido_de_verdad		;6c13   ; con el a cero, sonido
	pop af			;6c15
	ret			;6c16
pide_un_sonido_de_verdad:		; Guarda los registros y llama al reparto
	pop af			;6c17   ; A trae el numero de sonido y hay que conservarlo
	push hl			;6c18   ; HL y DE, a salvo: el reparto los usa
	push de			;6c19
	call reparte_el_sonido		;6c1a   ; y a repartirlo entre los canales
	pop de			;6c1d
	pop hl			;6c1e
	ret			;6c1f
reparte_el_sonido:		; Decide en cuantos canales cabe el sonido -tres para el 0x97, el 0x90 y los que pasan de 0x8A, dos para el 0x01, y uno para el resto- y se lo queda solo si su numero es mayor que el que ya estaba sonando. Es una PRIORIDAD: los seis bits bajos del numero hacen de rango
	ld hl,0e663h		;6c20   ; HL = 0xE663, el sonido del primer canal
	ld c,a			;6c23   ; C se queda el numero pedido
	ld b,003h		;6c24   ; tres canales
	cp 097h		;6c26   ; el 0x97 va a tres
	jr z,mira_la_prioridad		;6c28
	cp 090h		;6c2a   ; y el 0x90 tambien
	jr z,mira_la_prioridad		;6c2c
	dec b			;6c2e   ; dos canales
	cp 08ah		;6c2f   ; de 0x8A para arriba, dos
	jr nc,mira_la_prioridad		;6c31
	cp 001h		;6c33   ; y el 0x01 tambien
	jr z,mira_la_prioridad		;6c35
	ld b,001h		;6c37   ; un solo canal
	ld hl,0e679h		;6c39   ; el del tercero, 0xE679
mira_la_prioridad:		; Compara los seis bits bajos del pedido con los del que ya suena. Si el nuevo es menor, ni se intenta
	ld e,(hl)			;6c3c   ; E = lo que hay sonando
	ld a,e			;6c3d
	and 03fh		;6c3e   ; sin los dos bits de modo
	ld (hl),a			;6c40
	ld a,c			;6c41   ; y el pedido, igual
	and 03fh		;6c42
	cp (hl)			;6c44   ; el nuevo tiene que ser mayor
	ld (hl),e			;6c45   ; y el viejo, de vuelta
	ret c			;6c46   ; si no lo es, no suena
	add a,a			;6c47   ; el numero por dos: la tabla lleva punteros
	ld de,06e8eh		;6c48   ; DE = 0x6e8e, los punteros de sonido
	ex de,hl			;6c4b
	call suma_a_hl		;6c4c
	ex de,hl			;6c4f
	dec hl			;6c50
	dec hl			;6c51
arranca_los_canales:		; Le da a cada canal su guion, con la nota a un cuadro y la caida a cero. Un sonido de tres canales ocupa tres punteros seguidos de la tabla
	ld (hl),001h		;6c52   ; un cuadro para la primera nota
	inc hl			;6c54
	ld (hl),001h		;6c55   ; y la duracion, a uno
	inc hl			;6c57
	ld (hl),c			;6c58   ; el numero de sonido
	inc hl			;6c59
	ld a,(de)			;6c5a   ; el byte bajo del guion
	ld (hl),a			;6c5b
	inc hl			;6c5c
	inc de			;6c5d
	ld a,(de)			;6c5e
	ld (hl),a			;6c5f   ; y el alto
	ld a,005h		;6c60   ; cinco bytes mas alla
	call suma_a_hl		;6c62
	ld (hl),000h		;6c65   ; la caida, a cero
	inc hl			;6c67
	inc hl			;6c68
	inc de			;6c69
	djnz arranca_los_canales		;6c6a   ; el canal siguiente
	ret			;6c6c
cierra_el_bucle_del_guion:		; El comando 0xFE: sube la cuenta de vueltas y, mientras no llegue a la que pide el byte siguiente, vuelve a pedir el mismo sonido desde el principio
	inc hl			;6c6d
	ld a,(ix+009h)		;6c6e   ; las vueltas dadas
	inc a			;6c71   ; una mas
	cp (hl)			;6c72   ; contra las que pide el guion
	jp z,calla_el_canal		;6c73   ; llegado el numero, se acaba
	jp m,repite_el_sonido		;6c76
	dec a			;6c79   ; y si se paso, se queda como estaba
repite_el_sonido:		; Pide otra vez el mismo numero, que es como el guion vuelve a empezar
	ex af,af'			;6c7a
	ld a,(ix+002h)		;6c7b   ; el numero de sonido de este canal
	push bc			;6c7e
	call reparte_el_sonido		;6c7f
	pop bc			;6c82
	ex af,af'			;6c83
	ld (ix+009h),a		;6c84   ; y la cuenta de vueltas, guardada
	ret			;6c87
abre_o_cierra_el_canal:		; Toca el bit del registro 7 del PSG que deja sonar a este canal: con D a 1 lo cierra y con D a 0 lo abre. Ademas fuerza el bit 2 -el ruido del tercer canal- salvo que el bit 5 diga lo contrario
	ld a,(0e660h)		;6c88   ; (0xE660), la copia del registro 7
	ld e,a			;6c8b
	ld a,c			;6c8c   ; C = el canal
	cp 001h		;6c8d
	jr z,L_6C92		;6c8f
	dec a			;6c91
L_6C92:
	rlca			;6c92   ; su bit, colocado en su sitio
	rlca			;6c93
	rlca			;6c94
	dec d			;6c95   ; D dice si se abre o se cierra
	jr z,L_6C9C		;6c96
	cpl			;6c98   ; cerrar es quitar el bit
	and e			;6c99
	jr remata_el_registro_7		;6c9a
L_6C9C:
	or e			;6c9c   ; y abrir, ponerlo
remata_el_registro_7:		; El bit 2 puesto y, si el 5 lo pide, quitado otra vez
	set 2,a		;6c9d   ; el bit 2
	bit 5,a		;6c9f   ; el bit 5 manda
	jr z,escribe_el_registro_7		;6ca1
	res 2,a		;6ca3   ; y entonces el 2 se cae
escribe_el_registro_7:		; La copia se guarda y se manda al PSG
	ld (0e660h),a		;6ca5   ; la copia
	ld e,a			;6ca8
	ld a,007h		;6ca9   ; registro 7 del PSG
	jp 00093h		;6cab   ; BIOS WRTPSG - Writes data to PSG-register
mueve_el_sonido:		; El cuadro de sonido, el que llama la interrupcion. Repone el registro 7 y le da un cuadro a cada uno de los tres canales, saltando de once en once bytes
	ld a,(0e660h)		;6cae   ; (0xE660), la copia del registro 7
	call escribe_el_registro_7		;6cb1
	di			;6cb4
	ld c,001h		;6cb5   ; C = 1, el primer canal
	ld ix,0e661h		;6cb7   ; IX = 0xE661, su estado
	exx			;6cbb
	ld b,003h		;6cbc   ; tres canales
	ld de,0000bh		;6cbe   ; once bytes por canal
un_cuadro_de_un_canal:		; Con el sonido 1 hay ademas un efecto aparte
	exx			;6cc1
	ld a,(ix+002h)		;6cc2   ; el numero de sonido de este canal
	push af			;6cc5
	cp 001h		;6cc6   ; el 1 lleva efecto
	call z,lleva_el_efecto		;6cc8
	pop af			;6ccb
	or a			;6ccc   ; callado no hay nada que hacer
	call nz,lleva_un_canal		;6ccd
	di			;6cd0
	inc c			;6cd1   ; el canal siguiente: C sube de dos en dos
	inc c			;6cd2
	exx			;6cd3
	add ix,de		;6cd4   ; y IX, once bytes
	djnz un_cuadro_de_un_canal		;6cd6
	ret			;6cd8
lleva_un_canal:		; Abre el canal si su bit 6 esta a cero, y baja el contador de la nota; mientras no llegue a cero, no se lee nada del guion
	di			;6cd9
	bit 6,a		;6cda   ; el bit 6 del numero de sonido
	ld d,001h		;6cdc   ; D = 1
	call z,abre_o_cierra_el_canal		;6cde
	di			;6ce1
	ld a,(ix+002h)		;6ce2   ; el numero otra vez
	or a			;6ce5
	jp m,lleva_una_nota_larga		;6ce6   ; con el bit 7 puesto, el modo largo
	dec (ix+000h)		;6ce9   ; un cuadro menos de esta nota
	ret nz			;6cec
lee_el_guion_del_sonido:		; Un byte del guion. 0xFF acaba, 0xFE cierra el bucle, y con el bit 7 del modo puesto se va por el camino largo; si no, se miran los prefijos 0x2n -duracion- y 0x1n -ruido- antes de la nota
	ld l,(ix+003h)		;6ced   ; HL = por donde va el guion
	ld h,(ix+004h)		;6cf0
	ld a,(hl)			;6cf3   ; el byte de comando
	cp 0feh		;6cf4   ; 0xFE cierra el bucle
	jp z,cierra_el_bucle_del_guion		;6cf6
	jr nc,calla_el_canal		;6cf9   ; 0xFF acaba
	bit 7,(ix+002h)		;6cfb   ; el bit 7: el modo largo
	jp nz,lee_una_nota_larga		;6cff
	and 0f0h		;6d02   ; el prefijo 0x2n
	cp 020h		;6d04
	jr nz,mira_si_hay_ruido		;6d06
	ld a,(hl)			;6d08   ; su nibble bajo es la duracion nueva
	and 00fh		;6d09
	ld (ix+001h),a		;6d0b   ; guardada
	inc hl			;6d0e
mira_si_hay_ruido:		; El prefijo 0x1n manda cinco bits al registro 6 del PSG, que es el periodo del ruido, y abre el canal en modo ruido
	ld a,(hl)			;6d0f   ; el byte otra vez
	and 0f0h		;6d10
	cp 010h		;6d12   ; el prefijo 0x1n
	jr nz,mira_el_modo_del_canal		;6d14
	ld a,(hl)			;6d16
	and 01fh		;6d17   ; cinco bits de periodo
	ld e,a			;6d19
	ld a,006h		;6d1a   ; registro 6 del PSG, el del ruido
	call 00093h		;6d1c   ; BIOS WRTPSG - Writes data to PSG-register
	di			;6d1f
	ld d,000h		;6d20   ; D = 0: el canal, abierto
	call abre_o_cierra_el_canal		;6d22
	di			;6d25
	inc hl			;6d26   ; y al byte siguiente
	ld a,(hl)			;6d27
mira_el_modo_del_canal:		; Con el bit 6 puesto y en el canal 5, el guion se lee de otra manera
	bit 6,(ix+002h)		;6d28   ; el bit 6 del modo
	jr z,toca_una_nota		;6d2c
	ld a,c			;6d2e
	cp 005h		;6d2f   ; solo el canal 5
	ld a,(hl)			;6d31
	jr nz,toca_una_nota		;6d32
	inc hl			;6d34
	ld (ix+003h),l		;6d35   ; el guion, adelantado
	ld (ix+004h),h		;6d38
	call arranca_la_nota		;6d3b
	ret			;6d3e
toca_una_nota:		; El nibble alto es la duracion y el bajo, junto con el byte siguiente, la frecuencia que va a los registros 0 y 1 del PSG
	and 0f0h		;6d3f   ; el nibble alto, la duracion
	ld b,a			;6d41
	xor (hl)			;6d42   ; y el bajo, parte de la frecuencia
	ld d,a			;6d43
	inc hl			;6d44
	ld e,(hl)			;6d45   ; E = el byte siguiente
	inc hl			;6d46
	ld (ix+003h),l		;6d47   ; el guion, adelantado
	ld (ix+004h),h		;6d4a
	ex de,hl			;6d4d
	call escribe_la_frecuencia		;6d4e   ; la frecuencia, al PSG
	ld a,b			;6d51
	rrca			;6d52   ; la duracion, bajada a la derecha
	rrca			;6d53
	rrca			;6d54
	rrca			;6d55
arranca_la_nota:		; Recarga el contador con la duracion y prepara la caida del volumen
	ld h,a			;6d56
	ld a,(ix+001h)		;6d57   ; la duracion
	ld (ix+000h),a		;6d5a   ; al contador
	add a,003h		;6d5d   ; mas tres: el contador de la caida
	ld (ix+008h),a		;6d5f
	jr escribe_el_volumen		;6d62
calla_el_canal:		; El comando 0xFF: cierra el canal, borra su numero de sonido y le pone el volumen a cero
	xor a			;6d64
	ld (ix+009h),a		;6d65   ; las vueltas, a cero
	ld d,001h		;6d68   ; D = 1: el canal se cierra
	call abre_o_cierra_el_canal		;6d6a
	di			;6d6d
	xor a			;6d6e
	ld (ix+002h),a		;6d6f   ; y el numero de sonido, borrado
	ld h,a			;6d72   ; volumen cero
	jr escribe_el_volumen		;6d73
lleva_una_nota_larga:		; El modo del bit 7: la nota dura varios cuadros y el volumen va cayendo. Cuando el contador de la nota se agota se lee el guion, y mientras tanto el contador de la caida decide cuando bajar un punto el volumen
	dec (ix+000h)		;6d75   ; un cuadro menos
	jp z,lee_el_guion_del_sonido		;6d78   ; agotada, al guion
	dec (ix+008h)		;6d7b   ; y el contador de la caida
	ld a,(ix+008h)		;6d7e
	cp (ix+000h)		;6d81   ; comparado con el de la nota
	jr nz,acelera_la_caida		;6d84
	cp 003h		;6d86   ; por debajo de tres, se baja el volumen
	jr c,baja_el_volumen		;6d88
	ret			;6d8a
acelera_la_caida:		; Un paso mas de caida
	dec (ix+008h)		;6d8b
baja_el_volumen:		; El volumen, un punto menos; a cero ya no se baja mas
	ld a,(ix+007h)		;6d8e   ; el volumen de ahora
	dec a			;6d91   ; uno menos
	ret m			;6d92   ; a cero, ya esta
	ld (ix+007h),a		;6d93
	ld h,a			;6d96
escribe_el_volumen:		; Al registro de volumen del canal: 8, 9 o 10 segun cual sea
	ld a,c			;6d97
	rrca			;6d98   ; C partido por dos
	add a,088h		;6d99   ; mas 0x88: el registro que le toca
	ld e,h			;6d9b
	jp 00093h		;6d9c   ; BIOS WRTPSG - Writes data to PSG-register | al PSG
lee_una_nota_larga:		; El camino largo del guion, con hasta tres prefijos delante de la nota: 0xDn la unidad de duracion, 0xFn la caida y 0xEn la octava
	and 0f0h		;6d9f   ; el nibble alto
	cp 0d0h		;6da1   ; el prefijo 0xDn
	ld a,(hl)			;6da3
	jr nz,mira_el_prefijo_de_caida		;6da4
	and 00fh		;6da6
	ld (ix+00ah),a		;6da8   ; su nibble bajo es la unidad de duracion
	inc hl			;6dab
	ld a,(hl)			;6dac
mira_el_prefijo_de_caida:		; El 0xFn deja la caida en el byte 6
	cp 0f0h		;6dad   ; el prefijo 0xFn
	jr c,mira_el_prefijo_de_octava		;6daf
	and 00fh		;6db1
	ld (ix+006h),a		;6db3   ; guardada
	inc hl			;6db6
	ld a,(hl)			;6db7
mira_el_prefijo_de_octava:		; El 0xEn deja la octava en el byte 5
	cp 0e0h		;6db8   ; el prefijo 0xEn
	jr c,calcula_la_duracion		;6dba
	and 00fh		;6dbc
	ld (ix+005h),a		;6dbe   ; guardada
	inc hl			;6dc1
	ld a,(hl)			;6dc2
calcula_la_duracion:		; El nibble bajo dice cuantas unidades dura la nota, y la unidad esta en el byte 0x0a: se multiplica sumando
	and 00fh		;6dc3   ; el nibble bajo
	ld b,a			;6dc5
	ld a,(ix+00ah)		;6dc6   ; la unidad de duracion
	jr z,saca_la_nota		;6dc9
suma_una_unidad:		; Una vez por unidad
	add a,(ix+00ah)		;6dcb
	djnz suma_una_unidad		;6dce
saca_la_nota:		; Guarda la duracion, coge el byte de la nota y le da la octava desplazando la frecuencia
	ld (ix+001h),a		;6dd0   ; la duracion de esta nota
	ld a,(hl)			;6dd3   ; el byte de la nota
	inc hl			;6dd4
	ld (ix+003h),l		;6dd5   ; el guion, adelantado
	ld (ix+004h),h		;6dd8
	and 0f0h		;6ddb   ; el nibble alto es el indice de la nota
	rrca			;6ddd
	rrca			;6dde
	rrca			;6ddf
	rrca			;6de0
	ld b,a			;6de1
	sub 00ch		;6de2   ; menos doce: la caida de partida
	ld (ix+007h),a		;6de4
	jr z,busca_la_frecuencia		;6de7
	ld a,(ix+006h)		;6de9   ; si no es cero, la del byte 6
	ld (ix+007h),a		;6dec
busca_la_frecuencia:		; El indice entra en la tabla de notas de 0x6e84 y el resultado se dobla tantas veces como diga la octava
	call arranca_la_nota		;6def   ; arranca la nota
	ld a,b			;6df2
	ld hl,06e84h		;6df3   ; HL = 0x6e84, la tabla de notas
	call suma_a_hl		;6df6
	ld l,(hl)			;6df9   ; la frecuencia de partida
	ld h,000h		;6dfa
	ld a,(ix+005h)		;6dfc   ; la octava
	or a			;6dff
	jr z,escribe_la_frecuencia		;6e00
	ld b,a			;6e02
dobla_la_frecuencia:		; Una vez por octava
	add hl,hl			;6e03
	djnz dobla_la_frecuencia		;6e04
escribe_la_frecuencia:		; Los dos bytes de la frecuencia, a los dos registros del canal
	ld a,c			;6e06
	ld e,h			;6e07   ; el byte alto primero
	call 00093h		;6e08   ; BIOS WRTPSG - Writes data to PSG-register
	di			;6e0b
	ld a,c			;6e0c
	dec a			;6e0d
	ld e,l			;6e0e   ; y luego el bajo
	call 00093h		;6e0f   ; BIOS WRTPSG - Writes data to PSG-register
	di			;6e12
	ret			;6e13
lleva_el_efecto:		; El efecto del sonido 1, que cambia segun lo que valga 0xE650 y segun el canal
	ld hl,0e653h		;6e14   ; HL = 0xE653
	ld de,06e77h		;6e17   ; DE = 0x6e77, la primera tabla del efecto
	ld a,c			;6e1a
	cp 003h		;6e1b   ; el canal 3 va por aqui
	jr z,elige_la_tabla_del_efecto		;6e1d
	ld hl,0e657h		;6e1f   ; y los demas por 0xE657 y 0x6e7b
	ld de,06e7bh		;6e22
elige_la_tabla_del_efecto:		; 0xE650 elige: con 1 va por un lado, por debajo por otro, y por encima mira el byte de antes
	ld a,(0e650h)		;6e25   ; (0xE650), el mando del efecto
	cp 001h		;6e28
	jr z,apaga_el_efecto		;6e2a
	jr c,corre_la_tabla_del_efecto		;6e2c
	dec hl			;6e2e
	ld a,(hl)			;6e2f
	or a			;6e30
	jr nz,corre_el_efecto		;6e31   ; el byte de antes
	inc hl			;6e33
	ld de,06e7fh		;6e34   ; DE = 0x6e7f
	ld a,c			;6e37
	cp 003h		;6e38
	jr z,corre_la_tabla_del_efecto		;6e3a
	ld de,06e83h		;6e3c   ; o 0x6e83
	jr corre_la_tabla_del_efecto		;6e3f
corre_el_efecto:		; Ocho unidades mas cada vez
	inc hl			;6e41
	ld a,(hl)			;6e42
	add a,008h		;6e43   ; ocho mas
	ld (hl),a			;6e45
	dec hl			;6e46
	jr nz,L_6E4A		;6e47
	inc (hl)			;6e49
L_6E4A:
	dec hl			;6e4a
	ld (ix+003h),l		;6e4b
	ld (ix+004h),h		;6e4e
	ret			;6e51
apaga_el_efecto:		; Pasado el 0x8F, el efecto se corta
	dec hl			;6e52
	ld a,08fh		;6e53   ; el tope, 0x8F
	cp (hl)			;6e55
	jr c,baja_el_efecto		;6e56
	xor a			;6e58
	ld (hl),a			;6e59   ; a cero
	jr L_6E4A		;6e5a
baja_el_efecto:		; Ocho unidades menos
	inc hl			;6e5c
	ld a,(hl)			;6e5d
	sub 008h		;6e5e   ; ocho menos
	ld (hl),a			;6e60
	dec hl			;6e61
	jr nz,L_6E4A		;6e62
	dec (hl)			;6e64   ; y el byte de al lado, si desborda
	jr L_6E4A		;6e65
corre_la_tabla_del_efecto:		; Cuatro bytes hacia atras con lddr, que es como el efecto avanza por su tabla
	push bc			;6e67
	ex de,hl			;6e68
	ld bc,00004h		;6e69   ; cuatro bytes
	lddr		;6e6c   ; copiados hacia atras
	ex de,hl			;6e6e
	pop bc			;6e6f
	inc hl			;6e70
	inc hl			;6e71
	jr L_6E4A		;6e72

; ----------------------------------------------------------------------
; DATOS resto_6e74: Tres bytes entre el codigo y las tablas del efecto;
;   ninguna lectura empieza en ellos
;   0x6e74..0x6e77  (3 bytes)
DATA_resto_6e74:
	defb 001h,021h,092h	; 6e74

; ----------------------------------------------------------------------
; DATOS tablas_del_efecto: Cuatro grupos que lee 0x6e14 -0x6e77, 0x6e7b,
;   0x6e7f y 0x6e83-, uno por combinacion de canal y valor de 0xE650. El
;   ultimo se mete ya en la tabla de notas
;   0x6e77..0x6e84  (13 bytes)
DATA_tablas_del_efecto:
	defb 0c0h,001h,021h,092h	; 6e77
	defb 0c8h,002h,021h,090h	; 6e7b
	defb 000h,002h,021h,090h	; 6e7f
	defb 008h	; 6e83

; ----------------------------------------------------------------------
; DATOS notas: Diez frecuencias de partida, indexadas por el nibble alto del
;   byte de la nota. La octava se consigue doblando el valor tantas veces como
;   diga el byte 5 del canal, que es lo que hace 0x6e03
;   0x6e84..0x6e8e  (10 bytes)
DATA_notas:
	defb 06ah	; 6e84
	defb 064h	; 6e85
	defb 05fh	; 6e86
	defb 059h	; 6e87
	defb 054h	; 6e88
	defb 050h	; 6e89
	defb 04bh	; 6e8a
	defb 047h	; 6e8b
	defb 043h	; 6e8c
	defb 03fh	; 6e8d

; ----------------------------------------------------------------------
; DATOS punteros_de_sonido: 28 punteros de 16 bits, uno por sonido. Un sonido
;   de tres canales se lleva tres seguidos, empezando por el numero que se
;   pidio
;   0x6e8e..0x6ec6  (56 bytes)
DATA_punteros_de_sonido:
	defb 03ch,038h	; 6e8e
	defb 07fh,070h	; 6e90
	defb 07fh,070h	; 6e92
	defb 01fh,06fh	; 6e94
	defb 0c6h,06eh	; 6e96
	defb 00ah,06fh	; 6e98
	defb 02eh,06fh	; 6e9a
	defb 024h,06fh	; 6e9c
	defb 0e8h,06eh	; 6e9e
	defb 013h,06fh	; 6ea0
	defb 0cah,06eh	; 6ea2
	defb 0ceh,06eh	; 6ea4
	defb 063h,06fh	; 6ea6
	defb 074h,06fh	; 6ea8
	defb 086h,06fh	; 6eaa
	defb 09ah,06fh	; 6eac
	defb 0b0h,06fh	; 6eae
	defb 0beh,06fh	; 6eb0
	defb 0cbh,06fh	; 6eb2
	defb 040h,070h	; 6eb4
	defb 05dh,070h	; 6eb6
	defb 0d8h,06fh	; 6eb8
	defb 004h,070h	; 6eba
	defb 07fh,070h	; 6ebc
	defb 07fh,070h	; 6ebe
	defb 07fh,070h	; 6ec0
	defb 07fh,070h	; 6ec2
	defb 07fh,070h	; 6ec4

; ----------------------------------------------------------------------
; DATOS guiones_de_sonido: Los guiones de los sonidos, a los que apunta
;   punteros_de_sonido
;   0x6ec6..0x7080  (442 bytes)
DATA_guiones_de_sonido:
	defb 023h,0a1h,010h,0ffh,022h,0a1h,000h,0ffh,022h,0a0h,090h,0a0h,000h,0c0h,070h,0b0h	; 6ec6  #..."...".....p.
	defb 070h,070h,070h,060h,070h,050h,070h,040h,070h,030h,070h,030h,070h,030h,070h,030h	; 6ed6  ppp`pPp@p0p0p0p0
	defb 070h,0ffh,0d1h,0fdh,0e2h,0b0h,0a0h,0b0h,0a0h,0b0h,0a0h,0b0h,0a0h,0b0h,0a0h,080h	; 6ee6  p...............
	defb 070h,060h,050h,040h,030h,020h,0fch,010h,000h,000h,0c0h,0fbh,0e3h,090h,0fah,070h	; 6ef6  p`P@0 .........p
	defb 040h,040h,040h,0ffh,024h,0d0h,0e5h,023h,000h,000h,0d0h,0edh,0ffh,023h,0d0h,0b4h	; 6f06  @@@.$..#.....#..
	defb 023h,0c0h,0bah,024h,000h,000h,0d0h,0f0h,0ffh,021h,011h,091h,0f0h,0ffh,026h,0a0h	; 6f16  #..$.....!....&.
	defb 078h,090h,078h,090h,025h,0a0h,078h,0ffh,0d1h,0fch,0e1h,050h,0e2h,050h,0e1h,050h	; 6f26  x.x.%.x....P.P.P
	defb 0e2h,050h,0e1h,050h,0c2h,070h,090h,0e2h,090h,0e1h,090h,0e2h,090h,0e1h,090h,0c3h	; 6f36  .P.P.p..........
	defb 090h,0e2h,090h,0e1h,090h,0e2h,090h,0e1h,090h,080h,070h,0e2h,070h,060h,0c5h,0e1h	; 6f46  ..........p.p`..
	defb 050h,0e2h,050h,0e1h,050h,040h,0e2h,030h,0e1h,020h,0e2h,020h,0ffh,0d6h,0fch,0e2h	; 6f56  P.P.P@.0. . ....
	defb 090h,0c0h,090h,090h,0b0h,0c0h,071h,090h,0c1h,0e1h,020h,0dch,02ah,0ffh,0d6h,0fah	; 6f66  ......q... .*...
	defb 0e3h,09fh,090h,0c0h,090h,090h,0b0h,090h,071h,090h,0c1h,0e2h,020h,0dch,022h,0ffh	; 6f76  ........q... .".
	defb 0d6h,0fch,0e2h,074h,020h,071h,090h,0b1h,070h,094h,070h,065h,044h,060h,072h,091h	; 6f86  ...t q..p.peD`r.
	defb 0b0h,09bh,0feh,0ffh,0d6h,0fah,0e3h,072h,062h,042h,022h,062h,022h,062h,092h,042h	; 6f96  .......rbB"b"b.B
	defb 062h,072h,092h,072h,061h,040h,062h,022h,0feh,0ffh,0d6h,0fdh,0e1h,072h,020h,062h	; 6fa6  br.ra@b".....r b
	defb 020h,042h,020h,000h,0c0h,0e2h,0b0h,0ffh,0d6h,0fbh,0e2h,0b2h,070h,092h,060h,092h	; 6fb6   B .........p.`.
	defb 060h,040h,0c0h,020h,0ffh,0d6h,0fch,0e2h,072h,0b0h,062h,0b0h,042h,020h,040h,0c0h	; 6fc6  `@. ....r.b.B @.
	defb 020h,0ffh,0d6h,0fch,0e2h,091h,0c1h,091h,0c1h,091h,0c1h,090h,080h,090h,0a0h,0e1h	; 6fd6   ...............
	defb 001h,0c1h,001h,0c1h,001h,0e2h,050h,090h,0e1h,000h,0e2h,090h,0e1h,000h,040h,052h	; 6fe6  ......P.......@R
	defb 000h,042h,000h,022h,0e2h,090h,081h,091h,0a9h,0e1h,0a0h,0c0h,0a0h,0ffh,0d6h,0fch	; 6ff6  .B."............
	defb 0e3h,050h,0c0h,090h,090h,000h,0c0h,091h,050h,0c0h,090h,0c0h,093h,050h,0c0h,090h	; 7006  .P......P....P..
	defb 090h,000h,0c0h,091h,050h,0c0h,090h,090h,090h,080h,090h,0e2h,000h,0e3h,050h,0c0h	; 7016  ....P.........P.
	defb 090h,090h,000h,0c0h,091h,050h,0c0h,090h,090h,000h,0c0h,091h,070h,0c0h,0a0h,0a0h	; 7026  .....P......p...
	defb 000h,0c0h,0a1h,070h,0c0h,0a0h,0c0h,0a0h,0ffh,0ffh,0d7h,0fch,0e2h,021h,0e3h,0a0h	; 7036  ...p.........!..
	defb 0a0h,0e2h,000h,010h,025h,031h,000h,000h,010h,020h,035h,094h,080h,074h,080h,090h	; 7046  ....%1... 5..t..
	defb 0c1h,0e1h,000h,0e2h,0c1h,0a0h,0ffh,0d7h,0fah,0e3h,051h,0c3h,0e2h,021h,0e3h,0a0h	; 7056  ..........Q..!..
	defb 0a0h,0e2h,000h,010h,0e3h,071h,0e2h,0c3h,031h,000h,000h,020h,030h,0e3h,054h,040h	; 7066  .....q..1.. 0.T@
	defb 034h,040h,050h,0c1h,090h,0c1h,0e2h,020h,0ffh,0ffh	; 7076  4@P.... ..

; ======================================================================
; CODIGO 0x7080..0x728a  (522 bytes)
; ======================================================================


lleva_al_bateador:		; El cuadro del bateador. El bit 0 de 0xE140 dice si ya esta bateando -y entonces se va por 0x70de-; con el bit 1 puesto o el bit 2 a cero no hay nada que hacer. Si no, se lee el mando: los cuatro bits altos arrancan el bateo y los cuatro bajos mueven al bateador por la caja
	ld hl,0e140h		;7080   ; HL = 0xE140, la ficha del bateador
	ld a,(hl)			;7083
	rrca			;7084   ; el bit 0: ya esta bateando
	jr c,lleva_el_bateo		;7085
	rrca			;7087   ; el bit 1
	ret nc			;7088
	rrca			;7089   ; el bit 2
	ret c			;708a
	call la_pelota_esta_en_juego		;708b   ; sin pelota en juego, nada
	ret nz			;708e
	ex de,hl			;708f
	call el_mando_del_que_defiende		;7090   ; lee el mando del bateador
	ld a,(hl)			;7093
	and 0f0h		;7094   ; los cuatro bits altos: los botones
	jr z,mueve_al_bateador		;7096
	ex de,hl			;7098
	set 0,(hl)		;7099   ; el bit 0: a batear
	ex de,hl			;709b
mueve_al_bateador:		; De los cuatro bits bajos del mando salen dos pasos, B en un eje y C en el otro, cada uno de -1, 0 o +1
	ld a,(hl)			;709c
	and 00fh		;709d   ; los cuatro bits de direccion
	ret z			;709f   ; sin ninguno, no se mueve
	xor a			;70a0
	ld b,a			;70a1   ; B = 0 y C = 0
	ld c,a			;70a2
	ld a,(hl)			;70a3
	and 00fh		;70a4
	rrca			;70a6   ; el bit 0
	jr nc,el_segundo_bit		;70a7
	dec b			;70a9   ; un paso atras
el_segundo_bit:		; El bit 1
	rrca			;70aa
	jr nc,el_tercer_bit		;70ab
	inc b			;70ad   ; un paso adelante
el_tercer_bit:		; El bit 2
	rrca			;70ae
	jr nc,el_cuarto_bit		;70af
	dec c			;70b1   ; un paso atras en el otro eje
el_cuarto_bit:		; El bit 3
	rrca			;70b2
	jr nc,aplica_los_pasos		;70b3
	inc c			;70b5   ; un paso adelante
aplica_los_pasos:		; Suma los dos pasos a la posicion del bateador, con dos topes por eje: 0xA0 y 0xB0 en uno, y 0x69/0x6E o 0x82/0x87 en el otro segun de que lado batee
	ex de,hl			;70b6
	set 6,(hl)		;70b7   ; el bit 6: hay que redibujarlo
	ld a,(hl)			;70b9
	inc hl			;70ba
	inc hl			;70bb
	inc hl			;70bc
	ld a,b			;70bd
	add a,(hl)			;70be   ; sobre la fila de ahora
	cp 0a0h		;70bf   ; el tope de arriba
	jr z,mueve_en_el_otro_eje		;70c1
	cp 0b0h		;70c3   ; y el de abajo
	jr z,mueve_en_el_otro_eje		;70c5
	ld (hl),a			;70c7   ; la fila nueva
mueve_en_el_otro_eje:		; Los topes de la columna dependen del lado
	inc hl			;70c8
	ld de,0696eh		;70c9   ; DE = 0x696e, los topes de un lado
	ld a,(0e140h)		;70cc   ; (0xE140), su bit 4
	bit 4,a		;70cf
	jr z,L_70D6		;70d1
	ld de,08287h		;70d3   ; y del otro, 0x8287
L_70D6:
	ld a,c			;70d6
	add a,(hl)			;70d7   ; sobre la columna de ahora
	cp d			;70d8   ; el primer tope
	ret z			;70d9
	cp e			;70da   ; y el segundo
	ret z			;70db
	ld (hl),a			;70dc   ; la columna nueva
	ret			;70dd
lleva_el_bateo:		; Con el bateo ya en marcha: mientras el mando siga pulsado el bate avanza de postura cada tres cuadros, y en cuanto suelta o llega a la sexta se acaba
	inc hl			;70de
	ex de,hl			;70df
	call el_mando_del_que_defiende		;70e0   ; lee el mando
	ld a,(hl)			;70e3
	and 030h		;70e4   ; los botones
	ex de,hl			;70e6
	jr nz,pasa_la_postura_del_bate		;70e7
	inc hl			;70e9
	ld a,(hl)			;70ea   ; la postura del bate
	and 007h		;70eb   ; sus tres bits bajos
	cp 005h		;70ed   ; la quinta es el final del recorrido
	dec hl			;70ef
	jp z,acaba_el_bateo		;70f0
	jr mira_si_le_da_a_la_pelota		;70f3
pasa_la_postura_del_bate:		; Cada tres cuadros, una postura mas; la sexta cierra el bateo
	dec (hl)			;70f5   ; un cuadro menos
	jr nz,mira_si_le_da_a_la_pelota		;70f6
	dec hl			;70f8
	set 6,(hl)		;70f9   ; el bit 6: hay que redibujar
	inc hl			;70fb
	ld (hl),003h		;70fc   ; tres cuadros para la siguiente
	inc hl			;70fe
	ld a,(hl)			;70ff
	inc a			;7100   ; la postura siguiente
	ld b,a			;7101
	and 007h		;7102
	cp 006h		;7104   ; la sexta acaba
	ret z			;7106
	ld (hl),b			;7107
	dec hl			;7108
mira_si_le_da_a_la_pelota:		; Con el bate en la postura 2, 3 o 4 y la pelota dentro de la caja de contacto de 0x72cc, hay golpe
	call la_pelota_esta_en_juego		;7109   ; sin pelota en juego, nada
	ret nz			;710c
	dec hl			;710d
	bit 4,(hl)		;710e   ; el bit 4: de que lado batea
	inc hl			;7110
	inc hl			;7111
	ld de,(0e130h)		;7112   ; DE = (0xE130), donde esta la pelota
	ld bc,(0e143h)		;7116   ; BC = (0xE143), donde esta el bate
	ld a,000h		;711a   ; A = 0, la caja de un lado
	jr z,prueba_la_caja		;711c
	inc a			;711e   ; o la del otro
prueba_la_caja:		; Sin acarreo, la pelota esta fuera de la caja y no hay golpe
	push hl			;711f
	call mira_si_esta_en_la_caja		;7120   ; la prueba
	pop hl			;7123
	ret nc			;7124   ; fuera: no hay golpe
	ld a,(hl)			;7125
	and 007h		;7126   ; la postura del bate
	cp 002h		;7128   ; antes de la 2 no hay golpe
	ret c			;712a
	cp 005h		;712b   ; y de la 5 en adelante, tampoco
	ret nc			;712d
	dec a			;712e
	dec hl			;712f
	ld c,(hl)			;7130   ; C = la columna del bate
	ld b,a			;7131
	ld hl,07285h		;7132   ; HL = 0x7285, los angulos de un lado
	ld a,(0e140h)		;7135   ; (0xE140), su bit 4
	bit 4,a		;7138
	jr z,busca_el_angulo		;713a
	ld hl,07294h		;713c   ; o los del otro, 0x7294
busca_el_angulo:		; Salta de cinco en cinco hasta la fila de la postura y luego indexa por la columna. Al angulo que sale se le suman dos bits del registro R del Z80, o sea que no hay dos golpes exactamente iguales
	ld a,005h		;713f   ; cinco por fila
	call suma_a_hl		;7141
	djnz busca_el_angulo		;7144
	ld a,c			;7146
	call suma_a_hl		;7147   ; mas la columna
	ld b,(hl)			;714a   ; B = el angulo
	ld a,r		;714b   ; el registro de refresco, de dado
	and 003h		;714d   ; dos bits de azar
	or b			;714f
	ld (0e037h),a		;7150   ; (0xE037), el angulo del golpe
	call mide_donde_da_en_el_bate		;7153   ; mide donde le da la pelota al bate
	ld b,a			;7156
	ld a,(0e012h)		;7157   ; (0xE012), el numero de jugadores
	or a			;715a
	jr nz,monta_el_golpe		;715b
	ld a,(0e402h)		;715d   ; (0xE402), de quien es el turno
	rrca			;7160
	jr nc,monta_el_golpe		;7161
	ld a,b			;7163
	or a			;7164
	jr z,L_716B		;7165
	cp 008h		;7167   ; con la maquina bateando, el golpe se ajusta
	jr c,monta_el_golpe		;7169
L_716B:
	ld b,006h		;716b   ; B = 6, un golpe del monton
monta_el_golpe:		; Con la fuerza por debajo de 10, la pelota sale: se marca el estado 4, se enciende el bit 5 del bateador, y de las dos tablas salen la altura de partida y las dos componentes
	ld a,b			;716d
	cp 00ah		;716e   ; de 10 para arriba no hay golpe
	ret nc			;7170
	push af			;7171
	ld a,004h		;7172   ; (0xE400) := 4, la pelota bateada
	ld (0e400h),a		;7174
	ld hl,0e140h		;7177
	set 5,(hl)		;717a   ; el bit 5 del bateador
	pop af			;717c
	push af			;717d
	ld hl,072a8h		;717e   ; HL = 0x72a8, las alturas
	rlca			;7181   ; por dos: son palabras
	call suma_a_hl		;7182
	ld de,0e0a1h		;7185   ; DE = 0xE0A1, la altura
	ld a,(hl)			;7188
	ld (de),a			;7189
	inc hl			;718a
	inc de			;718b
	ld a,(hl)			;718c
	ld (de),a			;718d
	pop af			;718e
	and 003h		;718f   ; los dos bits bajos de la fuerza
	rlca			;7191   ; por dos
	ld hl,072bah		;7192   ; HL = 0x72ba, las componentes
	ld b,a			;7195
	ld a,r		;7196   ; y un bit mas de azar
	and 001h		;7198
	or b			;719a
	push hl			;719b
	bit 0,a		;719c
	jr z,busca_la_componente		;719e
	ld hl,0e388h		;71a0
	set 6,(hl)		;71a3   ; el bit 6 de 0xE388
	ld hl,0e700h		;71a5
	ld (hl),000h		;71a8   ; (0xE700) := 0
	cp 002h		;71aa
	jr c,busca_la_componente		;71ac
	ld (hl),001h		;71ae   ; o 1, si la fuerza llega a dos
busca_la_componente:		; Salta de dos en dos hasta la entrada que toque
	pop hl			;71b0
	ld b,a			;71b1
	inc b			;71b2
salta_una_componente:		; Dos bytes por entrada
	inc hl			;71b3
	inc hl			;71b4
	djnz salta_una_componente		;71b5
	ld de,0e0a4h		;71b7   ; DE = 0xE0A4, la primera componente
	ld a,(hl)			;71ba   ; los dos bytes...
	ld (de),a			;71bb
	inc de			;71bc
	inc de			;71bd
	inc hl			;71be
	ld a,(hl)			;71bf
	ld (de),a			;71c0   ; ...uno en 0xE0A4 y otro en 0xE0A6
	ld bc,(0e130h)		;71c1   ; BC = (0xE130), donde estaba la pelota
	ld hl,0e0b0h		;71c5   ; HL = 0xE0B0, el atributo de la sombra
	ld a,008h		;71c8   ; ocho pixeles mas abajo
	add a,c			;71ca
	ld (hl),a			;71cb
	inc hl			;71cc
	ld (hl),b			;71cd
	inc hl			;71ce
	ld (hl),07ch		;71cf   ; el patron 0x7c
	inc hl			;71d1
	ld (hl),001h		;71d2   ; y el color 1
	inc hl			;71d4
	ld (hl),c			;71d5   ; la pelota, en la misma esquina
	inc hl			;71d6
	ld (hl),b			;71d7
	inc hl			;71d8
	inc hl			;71d9
	ld (hl),00fh		;71da   ; y su color, el 0x0f
	ld hl,0e0a2h		;71dc   ; HL = 0xE0A2
	ld a,(0e388h)		;71df   ; (0xE388), su bit 6
	bit 6,a		;71e2
	jr z,baja_la_altura		;71e4
	ld b,080h		;71e6   ; B = 0x80, medio paso
	ld a,(0e700h)		;71e8
	or a			;71eb
	jr nz,corrige_la_altura		;71ec
	ld b,0ffh		;71ee
corrige_la_altura:		; Con el bit 6 de 0xE388 la altura sube; sin el, baja 0x50
	ld a,(hl)			;71f0
	add a,b			;71f1   ; mas el paso
	ld (hl),a			;71f2
	jr nc,mira_el_boton_al_golpear		;71f3
	dec hl			;71f5
	inc (hl)			;71f6   ; con acarreo, el byte alto sube
	dec hl			;71f7
	jr mira_el_boton_al_golpear		;71f8
baja_la_altura:		; Lo normal: 0x50 menos
	ld a,(hl)			;71fa
	sub 050h		;71fb   ; 0x50 menos
	ld (hl),a			;71fd
	jr nc,mira_el_boton_al_golpear		;71fe
	dec hl			;7200
	dec (hl)			;7201   ; y el byte alto baja
mira_el_boton_al_golpear:		; Con los botones sueltos en el momento del golpe, la altura se fija en 0x6800: la pelota sale mas plana
	call el_mando_del_que_defiende		;7202
	ld a,(hl)			;7205   ; lo que se acaba de pulsar
	and 030h		;7206   ; los dos botones
	jr nz,lanza_la_pelota_bateada		;7208
	ld hl,06800h		;720a   ; (0xE0A1) := 0x6800
	ld (0e0a1h),hl		;720d
lanza_la_pelota_bateada:		; Deja el estado listo para que 0x620a se haga cargo: borra el lanzador, pone los tres interruptores de la pelota bateada, esconde la pelota vieja y suena el golpe
	call ajusta_el_golpe_de_la_maquina		;7210   ; el ajuste de la maquina
	xor a			;7213
	ld (0e100h),a		;7214   ; (0xE100) := 0: el lanzador ya no manda
	ld a,001h		;7217
	ld (0e03bh),a		;7219   ; (0xE03B) := 1, el plazo hasta el bote
	ld (0e030h),a		;721c   ; (0xE030) := 1
	ld (0e039h),a		;721f   ; (0xE039) := 1: hay pelota bateada
	ld a,0ffh		;7222
	ld (0e038h),a		;7224   ; (0xE038) := 0xff
	ld hl,0e140h		;7227
	set 6,(hl)		;722a   ; el bit 6 del bateador
	ld hl,0e388h		;722c
	set 2,(hl)		;722f   ; el bit 2 de 0xE388
	ld a,0cfh		;7231
	ld (0e130h),a		;7233   ; (0xE130) := 0xcf: la pelota vieja, escondida
	ld a,00bh		;7236   ; A = 0x0b, el sonido del bate
	call pide_un_sonido		;7238
	xor a			;723b
	ld (0e650h),a		;723c   ; (0xE650) := 0
	ld a,001h		;723f   ; y el sonido 1 encima
	call pide_un_sonido		;7241
	ld hl,0e1a0h		;7244   ; HL = 0xE1A0, las tres bases
	ld b,003h		;7247   ; tres
pone_en_marcha_a_los_de_base:		; El bit 1 de cada base pasa a ser el bit 0 de su pareja de 23 bytes mas alla: los que estaban en base echan a correr
	ld c,(hl)			;7249   ; C = la ficha
	push hl			;724a
	call avanza_veintitres		;724b   ; 23 bytes mas alla
	res 0,(hl)		;724e   ; el bit 0, a cero
	bit 1,c		;7250   ; el bit 1 de la ficha
	jr z,L_7256		;7252
	set 0,(hl)		;7254   ; y entonces el bit 0, puesto
L_7256:
	pop hl			;7256
	call avanza_una_fila		;7257   ; la base siguiente
	djnz pone_en_marcha_a_los_de_base		;725a
acaba_el_bateo:		; Sin golpe: el bit 0 del bateador se apaga, se marca para redibujar y se limpian los tres bits bajos de su postura. Si tenia el bit 5 es que ya habia dado, y entonces hay que recogerlo
	ld hl,0e140h		;725c
	res 0,(hl)		;725f   ; el bit 0, apagado
	set 6,(hl)		;7261   ; el bit 6: hay que redibujar
	ld a,(hl)			;7263
	inc hl			;7264
	inc hl			;7265
	push af			;7266
	ld a,(hl)			;7267
	and 0f8h		;7268   ; los tres bits bajos de la postura, fuera
	ld (hl),a			;726a
	pop af			;726b
	bit 5,a		;726c   ; el bit 5: ha habido golpe
	jr nz,recoge_al_bateador		;726e
	ld a,(0e100h)		;7270   ; (0xE100), su bit 1
	bit 1,a		;7273
	ret z			;7275
	ld hl,0e380h		;7276
	set 0,(hl)		;7279   ; el bit 0 de 0xE380
	ret			;727b
recoge_al_bateador:		; Con el golpe dado: el bateador se esconde, la primera base se pone a 2 y se avisa por el bit 4 de 0xE380
	inc hl			;727c
	ld (hl),0cfh		;727d   ; la fila 0xCF: escondido
	ld hl,0e180h		;727f
	ld (hl),002h		;7282   ; (0xE180) := 2, la primera base
	ld hl,0e380h		;7284
	set 4,(hl)		;7287   ; el bit 4 de 0xE380
	ret			;7289

; ----------------------------------------------------------------------
; DATOS angulos_del_golpe: Dos tandas de quince, una por lado del bateador:
;   por cada postura del bate (tres) y cada columna (cinco), el angulo con el
;   que sale la pelota. Van de 0x3c a 0x04 y vuelven a 0x3c, o sea del extremo
;   de un lado al del otro. 0x713f los recorre de cinco en cinco
;   0x728a..0x72a8  (30 bytes)
DATA_angulos_del_golpe:
	defb 03ch,038h,034h,030h,02ch	; 728a
	defb 028h,024h,020h,01ch,018h	; 728f
	defb 014h,010h,00ch,008h,004h	; 7294
	defb 004h,008h,00ch,010h,014h	; 7299
	defb 018h,01ch,020h,024h,028h	; 729e
	defb 02ch,030h,034h,038h,03ch	; 72a3

; ----------------------------------------------------------------------
; DATOS alturas_del_golpe: Diez palabras: la altura de partida de la pelota
;   segun la fuerza del golpe, de 0x0110 a 0x0200. La ultima se mete dos bytes
;   en la tabla de al lado
;   0x72a8..0x72ba  (18 bytes)
DATA_alturas_del_golpe:
	defb 001h,010h	; 72a8
	defb 001h,030h	; 72aa
	defb 001h,058h	; 72ac
	defb 001h,0a8h	; 72ae
	defb 002h,000h	; 72b0
	defb 001h,0d8h	; 72b2
	defb 001h,068h	; 72b4
	defb 001h,048h	; 72b6
	defb 001h,010h	; 72b8

; ----------------------------------------------------------------------
; DATOS componentes_del_golpe: Parejas con signo que 0x7192 elige con dos bits
;   de la fuerza y uno de azar: las dos componentes con las que la pelota sale
;   despedida
;   0x72ba..0x72cc  (18 bytes)
DATA_componentes_del_golpe:
	defb 000h,0f0h	; 72ba
	defb 0fbh,02ch	; 72bc
	defb 02ch,0fbh	; 72be
	defb 0f0h,057h	; 72c0
	defb 057h,0f0h	; 72c2
	defb 0e7h,06ch	; 72c4
	defb 0c3h,0a4h	; 72c6
	defb 0ddh,080h	; 72c8
	defb 0d1h,092h	; 72ca

; ======================================================================
; CODIGO 0x72cc..0x730a  (62 bytes)
; ======================================================================


mira_si_esta_en_la_caja:		; Prueba si el punto (D,E) cae dentro de la caja del punto (B,C). La caja son cuatro bytes -dos limites por eje, con el bit 7 marcando los negativos- que salen de la tabla de 0x730a indexada por A por cuatro. Devuelve el acarreo puesto cuando esta dentro
	ld hl,0730ah		;72cc   ; HL = 0x730a, las cajas
	or a			;72cf
	rlca			;72d0   ; por cuatro
	rlca			;72d1
	call suma_a_hl		;72d2
	ld a,d			;72d5   ; la distancia en el primer eje
	sub b			;72d6
	push hl			;72d7
	call prueba_un_eje		;72d8   ; probada
	pop hl			;72db
	ret nc			;72dc   ; fuera por el primer eje
	inc hl			;72dd   ; los dos limites del segundo
	inc hl			;72de
	ld a,e			;72df   ; la distancia en el segundo eje
	sub c			;72e0
prueba_un_eje:		; Con la distancia positiva se compara con los dos limites; con la negativa, se va por el otro lado
	jr c,prueba_el_lado_negativo		;72e1   ; negativa: por el otro camino
	inc hl			;72e3
	bit 7,(hl)		;72e4   ; el limite de arriba, si es positivo
	jr nz,esta_fuera		;72e6
	cp (hl)			;72e8   ; pasada, esta fuera
	ret nc			;72e9
	dec hl			;72ea
	bit 7,(hl)		;72eb   ; el de abajo
	ret nz			;72ed
	cp (hl)			;72ee   ; por debajo, fuera
	jr c,esta_fuera		;72ef
	scf			;72f1   ; dentro
	ret			;72f2
esta_fuera:		; Sin acarreo
	or a			;72f3
	ret			;72f4
prueba_el_lado_negativo:		; Con la distancia negativa, los limites se leen al reves
	bit 7,(hl)		;72f5   ; el limite de abajo tiene que ser negativo
	jr z,L_7308		;72f7
	inc hl			;72f9
	bit 7,(hl)		;72fa   ; y el de arriba
	jr nz,L_7302		;72fc
	dec hl			;72fe
	cp (hl)			;72ff
	ccf			;7300
	ret			;7301
L_7302:
	cp (hl)			;7302   ; comparado
	jr c,L_7308		;7303
	dec hl			;7305
	cp (hl)			;7306
	ret c			;7307
L_7308:
	or a			;7308
	ret			;7309

; ----------------------------------------------------------------------
; DATOS cajas_de_contacto: Tres cajas de cuatro bytes -dos limites por eje,
;   con el bit 7 marcando los negativos- que 0x72cc usa para decidir si la
;   pelota entra en el bate. Una por cada lado del bateador, mas otra
;   0x730a..0x7316  (12 bytes)
DATA_cajas_de_contacto:
	defb 0e0h,020h,001h,00ah	; 730a
	defb 0e0h,005h,001h,00ah	; 730e
	defb 0f3h,004h,0feh,0f2h	; 7312

; ======================================================================
; CODIGO 0x7316..0x7676  (864 bytes)
; ======================================================================


el_mando_del_que_defiende:		; Devuelve en HL el hueco de los bits recien pulsados del jugador que defiende -0xE00E o 0xE011- segun de quien sea el turno
	ld a,(0e402h)		;7316   ; (0xE402), de quien es el turno
	rrca			;7319
	jr elige_el_hueco_del_mando		;731a
el_mando_del_que_ataca:		; Lo mismo pero para el otro, con el acarreo cambiado
	ld a,(0e402h)		;731c   ; (0xE402)
	rrca			;731f
	ccf			;7320   ; al reves
elige_el_hueco_del_mando:		; Con acarreo, el del segundo jugador
	ld hl,0e00eh		;7321   ; HL = 0xE00E, los flancos del primero
	ret nc			;7324
	ld hl,0e011h		;7325   ; o 0xE011, los del segundo
	ret			;7328
ajusta_el_golpe_de_la_maquina:		; Con un solo jugador y siendo el turno del otro, 0x7ceb decide si el golpe de la maquina se corrige: el angulo se rehace con el registro R y la altura sube 0x38
	ld a,(0e012h)		;7329   ; (0xE012), el numero de jugadores
	or a			;732c
	ret nz			;732d
	ld a,(0e402h)		;732e   ; (0xE402), el turno
	rrca			;7331
	ret nc			;7332
	call mira_si_hay_empate		;7333   ; y lo que diga 0x7ceb
	ret nc			;7336
	ld a,r		;7337   ; el registro de refresco, de dado
	and 00fh		;7339
	ld b,a			;733b
	ld a,008h		;733c   ; A = 8 de partida
suma_tres_veces:		; Tres por cada vuelta del dado
	add a,003h		;733e
	djnz suma_tres_veces		;7340
	ld (0e037h),a		;7342   ; (0xE037), el angulo nuevo
	ld hl,0e0a2h		;7345   ; HL = 0xE0A2, la altura
	ld a,(hl)			;7348
	add a,038h		;7349   ; 0x38 mas
	ld (hl),a			;734b
	ret nc			;734c   ; y el byte alto, si desborda
	dec hl			;734d
	inc (hl)			;734e
	ret			;734f
mide_donde_da_en_el_bate:		; La distancia entre la fila de la pelota y el punto del bate, con el desplazamiento que le toca a cada lado -0x10 o 0x02- y el signo cambiado si batea del otro lado. Es lo que decide la fuerza del golpe
	ld a,(0e131h)		;7350   ; (0xE131), la fila de la pelota
	add a,003h		;7353   ; tres mas
	ld b,a			;7355
	ld a,(0e144h)		;7356   ; (0xE144), el punto del bate
	ld c,a			;7359
	ld d,010h		;735a   ; D = 0x10, el desplazamiento de un lado
	ld a,(0e140h)		;735c   ; (0xE140), su bit 4
	bit 4,a		;735f
	jr z,L_7365		;7361
	ld d,002h		;7363   ; o 0x02, el del otro
L_7365:
	ld a,c			;7365
	add a,d			;7366
	ld c,a			;7367
	ld a,b			;7368
	sub c			;7369   ; la distancia
	ld hl,0e140h		;736a
	bit 4,(hl)		;736d   ; el bit 4 otra vez
	ret z			;736f
	neg		;7370   ; y del otro lado, al reves
	ret			;7372
lleva_la_defensa:		; Los tres bits bajos de 0xE388 mandan: el 0 lleva el lanzamiento entre bases, el 1 mueve a los nueve, y el 2 -la pelota recien bateada- enciende el 1 y los pone a correr
	ld hl,0e388h		;7373   ; HL = 0xE388, la palabra de la defensa
	ld a,(hl)			;7376
	rrca			;7377   ; el bit 0
	jr c,lanza_entre_bases		;7378
	rrca			;737a   ; el bit 1
	jr c,mueve_a_los_nueve		;737b
	rrca			;737d   ; el bit 2
	ret nc			;737e
	set 1,(hl)		;737f   ; el bit 1, encendido
	jp persigue_la_pelota		;7381
mueve_a_los_nueve:		; Un cuadro de movimiento a cada uno de los nueve
	ld hl,0e220h		;7384   ; HL = 0xE220, el primero
	ld b,009h		;7387   ; nueve
mueve_a_uno_de_los_nueve:		; Un cuadro, y 32 bytes hasta el siguiente
	push bc			;7389
	push hl			;738a
	call mueve_un_movil		;738b   ; un cuadro de movimiento
	pop hl			;738e
	call avanza_una_fila		;738f   ; la ficha siguiente
	pop bc			;7392
	djnz mueve_a_uno_de_los_nueve		;7393
	jp persigue_la_pelota		;7395
lanza_entre_bases:		; El que tiene la pelota se la lanza a otro. La direccion pulsada elige la base: bit 0 la tercera, bit 1 la primera, bit 2 la cuarta y bit 3 la segunda, y de la tabla de 0x7676 salen el destino y a quien se le pide que la recoja
	bit 4,(hl)		;7398   ; el bit 4: ya hay una pelota en el aire
	jp nz,lleva_la_pelota_entre_bases		;739a
	call el_mando_del_que_ataca		;739d   ; lee el mando del que defiende
	ld a,(hl)			;73a0
	and 030h		;73a1   ; sin boton no se lanza
	jp z,no_hay_nada_que_hacer		;73a3
	ld a,(hl)			;73a6
	and 00fh		;73a7   ; y sin direccion, tampoco
	ret z			;73a9
	cp 00fh		;73aa   ; ni con las cuatro a la vez
	ret z			;73ac
	ld b,a			;73ad
	ld a,(0e358h)		;73ae   ; (0xE358), la direccion de antes
	cp b			;73b1   ; la misma: no se repite
	ret z			;73b2
	ld a,b			;73b3
	ld (0e358h),a		;73b4   ; guardada
	ld c,003h		;73b7   ; C = 3, la tercera base
	rrca			;73b9
	jr c,busca_la_base_de_destino		;73ba
	ld c,001h		;73bc   ; C = 1, la primera
	rrca			;73be
	jr c,busca_la_base_de_destino		;73bf
	ld c,004h		;73c1   ; C = 4, la cuarta
	rrca			;73c3
	jr c,busca_la_base_de_destino		;73c4
	ld c,002h		;73c6   ; y si no, C = 2
busca_la_base_de_destino:		; Entra en la tabla de 0x7676 saltando de siete en siete
	ld hl,l7670h		;73c8   ; HL = la tabla de destinos, un paso antes
	ld b,c			;73cb
	ld de,00007h		;73cc   ; siete bytes por base
salta_una_base:		; Siete bytes
	add hl,de			;73cf
	djnz salta_una_base		;73d0
	ld b,(hl)			;73d2   ; B = el primer byte de la entrada
	ld hl,0e200h		;73d3   ; HL = 0xE200
	ld a,(0e38ah)		;73d6   ; (0xE38A), quien tiene la pelota
	push bc			;73d9
	ld b,a			;73da
	ld de,00020h		;73db   ; 32 bytes por ficha
busca_al_que_la_tiene:		; 32 bytes por ficha hasta llegar a la suya
	add hl,de			;73de
	djnz busca_al_que_la_tiene		;73df
	pop bc			;73e1
	set 6,(hl)		;73e2   ; el bit 6 y el bit 7, puestos
	set 7,(hl)		;73e4
	res 5,(hl)		;73e6   ; y el bit 5, quitado
	ld de,00220h		;73e8   ; DE = 0x0220, el paso de partida
	bit 3,(hl)		;73eb   ; el bit 3 de su ficha
	jr nz,mira_si_ya_esta_en_esa_base		;73ed
	dec d			;73ef   ; y si no, 0x0120
mira_si_ya_esta_en_esa_base:		; Los bytes 0x1c y 0x1d de la ficha dicen a que bases da; si una de las dos es la pedida, el lanzamiento es mas corto
	push hl			;73f0
	ld a,01ch		;73f1   ; HL += 0x1c
	call suma_a_hl		;73f3
	ld a,(hl)			;73f6
	cp c			;73f7   ; la primera base a la que da
	jr z,L_73FF		;73f8
	inc hl			;73fa   ; y la segunda
	ld a,(hl)			;73fb
	cp c			;73fc
	jr nz,guarda_el_paso_del_lanzamiento		;73fd
L_73FF:
	ld de,00130h		;73ff   ; DE = 0x0130, el paso corto
	pop hl			;7402
	push hl			;7403
	bit 3,(hl)		;7404   ; el bit 3
	jr nz,guarda_el_paso_del_lanzamiento		;7406
	ld de,000c0h		;7408   ; o 0x00c0, mas corto todavia
guarda_el_paso_del_lanzamiento:		; El paso va a 0xE343, la ficha de la pelota lanzada
	ld hl,0e343h		;740b   ; HL = 0xE343
	ld (hl),e			;740e
	inc hl			;740f
	ld (hl),d			;7410
	pop hl			;7411
	ld a,008h		;7412   ; HL += 8: la fila del que lanza
	call suma_a_hl		;7414
	ld a,(hl)			;7417
	ld d,03bh		;7418   ; D = 0x3b, la postura de lanzar
	cp b			;741a
	jr nc,L_741F		;741b   ; y 0x39 si el destino esta por encima
	ld d,039h		;741d
L_741F:
	inc hl			;741f
	inc hl			;7420
	inc hl			;7421
	ld (hl),d			;7422   ; la postura, guardada
	ld hl,0e388h		;7423
	set 4,(hl)		;7426   ; el bit 4 de 0xE388: pelota en el aire
	ld hl,l766fh		;7428   ; HL = la tabla, otra vez
	ld b,c			;742b   ; la base pedida
salta_otra_base:		; Siete bytes por base
	ld de,00007h		;742c
	add hl,de			;742f
	djnz salta_otra_base		;7430
	ld b,(hl)			;7432   ; B = la fila del destino
	inc hl			;7433
	ld c,(hl)			;7434   ; C = la columna
	inc hl			;7435
	ld a,(hl)			;7436   ; A = el numero de base que se apunta
	inc hl			;7437
	push hl			;7438
	ld hl,0e340h		;7439   ; HL = 0xE340, la pelota lanzada
	push hl			;743c
	ex af,af'			;743d
	ld a,01fh		;743e   ; HL += 0x1f
	call suma_a_hl		;7440
	ex af,af'			;7443
	ld (hl),a			;7444   ; ahi se apunta a que base va
	pop hl			;7445
	call apunta_desde_la_ficha		;7446   ; y se le calcula la trayectoria
	pop hl			;7449
	ld a,(0e038h)		;744a   ; (0xE038): por debajo de 0x20...
	cp 020h		;744d
	jr nc,avisa_al_que_la_recoge		;744f
	inc hl			;7451   ; ...se leen los otros dos bytes de la entrada
	inc hl			;7452
avisa_al_que_la_recoge:		; De la entrada sale un puntero a la ficha del jugador que tiene que ir a por ella; se le enciende el bit 5 y, si tenia el 7, se le manda ya a por la pelota
	ld e,(hl)			;7453   ; E = el byte bajo del puntero
	inc hl			;7454
	ld d,(hl)			;7455   ; y el alto
	inc hl			;7456
	ex de,hl			;7457
	bit 7,(hl)		;7458   ; su bit 7
	res 5,(hl)		;745a   ; el bit 5, quitado
	jr z,arranca_el_lanzamiento		;745c
	bit 3,(hl)		;745e   ; su bit 3
	push hl			;7460
	ld hl,0e388h		;7461
	res 5,(hl)		;7464   ; el bit 5 de 0xE388, quitado
	jr z,manda_al_receptor		;7466
	set 5,(hl)		;7468   ; o puesto, segun el bit 3
manda_al_receptor:		; Le calcula el camino y le deja el destino en los bytes 7 y 8 de la pelota
	pop hl			;746a
	push hl			;746b
	push bc			;746c
	call esconde_la_pelota		;746d   ; le busca el sitio
	pop bc			;7470
	ld hl,0e340h		;7471
	res 0,(hl)		;7474   ; el bit 0 de la pelota, quitado
	res 6,(hl)		;7476   ; y el bit 6
	ld a,007h		;7478
	call suma_a_hl		;747a   ; HL += 7
	ld (hl),b			;747d   ; la fila del destino
	inc hl			;747e
	ld (hl),c			;747f   ; y la columna
	pop hl			;7480
	res 6,(hl)		;7481   ; el bit 6 del receptor, quitado
arranca_el_lanzamiento:		; El bit 5 puesto y el paso de la pelota a 0x0140
	set 5,(hl)		;7483   ; el bit 5
	push hl			;7485
	inc hl			;7486
	inc hl			;7487
	inc hl			;7488
	ld (hl),040h		;7489   ; el paso: 0x40 el bajo...
	inc hl			;748b
	ld (hl),001h		;748c   ; ...y 1 el alto
	pop hl			;748e
apunta_desde_la_ficha:		; Coge la posicion de ahora de los bytes 7 y 8 de la ficha y le calcula la trayectoria hasta (B,C) sobre el hueco de 16 bytes mas alla
	push hl			;748f
	pop ix		;7490   ; IX = la ficha
	ld d,(ix+007h)		;7492   ; D = la fila de ahora
	ld e,(ix+008h)		;7495   ; E = la columna
	push ix		;7498
	pop hl			;749a
	ld a,010h		;749b   ; HL += 0x10, el hueco de la trayectoria
	call suma_a_hl		;749d
	push bc			;74a0
	call apunta_hacia_un_destino		;74a1   ; y ahi se calcula
	pop bc			;74a4
	ret			;74a5
lleva_la_pelota_entre_bases:		; Con el bit 4 de 0xE388 puesto: le da cuadro a las diez fichas de 0xE220 y, a la que se para teniendo el bit 5, le pone la postura de recoger segun de que lado le llegue
	ld bc,00a00h		;74a6   ; B = 10 fichas, C = 0
	ld hl,0e220h		;74a9   ; HL = 0xE220
lleva_una_ficha_de_campo:		; El bit 7 se baja y se le da un cuadro
	push hl			;74ac
	push bc			;74ad
	res 7,(hl)		;74ae   ; el bit 7, fuera
	push hl			;74b0
	call mueve_un_movil		;74b1   ; un cuadro de movimiento
	pop hl			;74b4
	push hl			;74b5
	bit 0,(hl)		;74b6   ; el bit 0: sigue en marcha
	jr nz,y_si_sigue_en_marcha		;74b8
	bit 5,(hl)		;74ba   ; el bit 5: es la que va a por la pelota
	jr z,y_si_sigue_en_marcha		;74bc
	ld a,008h		;74be   ; HL += 8: su fila
	call suma_a_hl		;74c0
	ld a,(0e348h)		;74c3   ; (0xE348), la fila de la pelota
	cp (hl)			;74c6
	ld a,03ah		;74c7   ; A = 0x3a, la postura de recoger por arriba
	jr c,guarda_la_postura_de_recoger		;74c9
	ld a,038h		;74cb
guarda_la_postura_de_recoger:		; 0x38 si le llega por debajo
	inc hl			;74cd   ; tres bytes mas alla
	inc hl			;74ce
	inc hl			;74cf
	ld (hl),a			;74d0   ; la postura
	pop hl			;74d1
	jr la_ficha_de_campo_siguiente		;74d2
y_si_sigue_en_marcha:		; A la que no es la primera y sigue moviendose, se le rehace el camino
	pop hl			;74d4
	pop bc			;74d5
	push bc			;74d6
	dec b			;74d7   ; la primera no
	jr z,la_ficha_de_campo_siguiente		;74d8
	bit 0,(hl)		;74da   ; el bit 0: en marcha
	jr z,la_ficha_de_campo_siguiente		;74dc
	ld a,010h		;74de   ; HL += 0x10, el hueco de la trayectoria
	call suma_a_hl		;74e0
	call elige_la_postura_del_que_corre		;74e3
la_ficha_de_campo_siguiente:		; 32 bytes mas alla
	pop bc			;74e6
	pop hl			;74e7
	call avanza_una_fila		;74e8   ; la siguiente
	djnz lleva_una_ficha_de_campo		;74eb
	ld hl,0e220h		;74ed   ; HL = 0xE220, otra vez desde el principio
	ld b,009h		;74f0   ; los nueve
	ld de,00020h		;74f2   ; 32 bytes por ficha
busca_al_que_ya_la_tiene:		; El que tenga el bit 5 y NO el bit 0 -o sea, el que iba a por ella y ya ha llegado- es el que la coge. Si no hay ninguno, 0xE38A se pone a cero
	bit 5,(hl)		;74f5   ; el bit 5
	jr z,L_74FD		;74f7
	bit 0,(hl)		;74f9   ; el bit 0: todavia se mueve
	jr z,ya_la_tiene_uno		;74fb
L_74FD:
	add hl,de			;74fd   ; la ficha siguiente
	djnz busca_al_que_ya_la_tiene		;74fe
	xor a			;7500
	ld (0e38ah),a		;7501   ; (0xE38A) := 0: no la tiene nadie
	ret			;7504
ya_la_tiene_uno:		; Apunta en 0xE38A quien la ha cogido y, si la pelota sigue en marcha, no se toca mas
	ld a,009h		;7505   ; el numero de la ficha, contando desde el final
	sub b			;7507
	inc a			;7508
	ld (0e38ah),a		;7509   ; (0xE38A), quien la tiene
	ld hl,0e340h		;750c
	bit 0,(hl)		;750f   ; el bit 0 de la pelota
	jr z,mira_a_quien_elimina		;7511
	ret			;7513
mira_a_quien_elimina:		; De la ficha del que la ha cogido saca a que base apunta y busca al corredor de esa base, para decidir si esta eliminado
	call esconde_la_pelota		;7514
	ld a,01fh		;7517   ; HL += 0x1f: la base a la que apunta
	call suma_a_hl		;7519
	ld b,(hl)			;751c   ; B = esa base
	ld hl,0e160h		;751d   ; HL = 0xE160
busca_la_base_apuntada:		; 32 bytes por base
	call avanza_una_fila		;7520
	djnz busca_la_base_apuntada		;7523
	ld a,(0e388h)		;7525   ; (0xE388), su bit 7
	rlca			;7528
	jr nc,decide_si_hay_eliminacion		;7529
	push hl			;752b
	call avanza_veintitres		;752c   ; 23 bytes mas alla
	ld a,(hl)			;752f
	pop hl			;7530
	rrca			;7531   ; su bit 0
	jr nc,cierra_el_lanzamiento		;7532
	rrca			;7534   ; y su bit 1
	jr c,decide_si_hay_eliminacion		;7535
cuenta_los_corredores:		; Recorre las bases hacia atras contando cuantas siguen en marcha, y luego busca en 0xE1A0 la que le toca al que se elimina
	ld b,001h		;7537
	call avanza_veintitres		;7539   ; 23 bytes mas alla
	res 0,(hl)		;753c   ; su bit 0, quitado
	ld de,00020h		;753e   ; 32 bytes por base
una_base_hacia_atras:		; Cuenta las que estan en marcha
	or a			;7541
	sbc hl,de		;7542
	bit 0,(hl)		;7544   ; el bit 0
	jr z,L_7549		;7546
	inc b			;7548   ; una mas
L_7549:
	ld a,l			;7549
	cp 077h		;754a   ; hasta llegar a 0xE177
	jr nz,una_base_hacia_atras		;754c
busca_al_eliminado:		; De las bases con corredor, la que hace el numero contado
	ld hl,0e1a0h		;754e
L_7551:
	bit 1,(hl)		;7551   ; el bit 1: hay corredor
	jr z,L_7558		;7553
	dec b			;7555   ; una menos
	jr z,limpia_la_base		;7556
L_7558:
	call avanza_una_fila		;7558   ; la base siguiente
	ld a,l			;755b
	or a			;755c
	jr nz,L_7551		;755d
	ld a,(0e40eh)		;755f   ; (0xE40E), las carreras del otro
	or a			;7562
	jr z,limpia_la_base		;7563
	dec a			;7565   ; una menos, si habia alguna
	ld (0e40eh),a		;7566
	jr limpia_la_base		;7569
decide_si_hay_eliminacion:		; Segun los bits de la base alcanzada, el aviso de 0xE401 vale 8 -eliminado- o 4
	bit 1,(hl)		;756b   ; el bit 1
	jr z,L_7573		;756d
	bit 0,(hl)		;756f   ; el bit 0
	jr z,aviso_de_eliminado		;7571
L_7573:
	push hl			;7573
	ld de,00009h		;7574   ; DE = 9
	or a			;7577
	sbc hl,de		;7578
	bit 6,(hl)		;757a   ; el bit 6 nueve bytes antes
	pop hl			;757c
	jr nz,cierra_el_lanzamiento		;757d
	call la_pelota_esta_en_juego		;757f   ; la pelota tiene que estar en juego
	jr z,cierra_el_lanzamiento		;7582
	bit 3,(hl)		;7584   ; el bit 3
	jr z,cierra_el_lanzamiento		;7586
	bit 5,(hl)		;7588   ; y el bit 5
	jr z,avisa_a_la_base_de_atras		;758a
aviso_de_eliminado:		; El 8
	ld a,008h		;758c   ; A = 8
	jr guarda_el_aviso		;758e
avisa_a_la_base_de_atras:		; Baja el bit 3 y avisa a la de 32 bytes antes
	res 3,(hl)		;7590   ; el bit 3, fuera
	ld de,00020h		;7592   ; 32 bytes atras
	or a			;7595
	sbc hl,de		;7596
	call limpia_si_toca		;7598
limpia_la_base:		; De la base solo sobreviven los bits 7, 6 y 3, y su pareja de 23 bytes se borra
	ld a,(hl)			;759b
	and 0c8h		;759c   ; los bits 7, 6 y 3
	ld (hl),a			;759e
	call avanza_veintitres		;759f   ; 23 bytes mas alla
	xor a			;75a2
	ld (hl),a			;75a3   ; borrada
	ld a,004h		;75a4   ; A = 4, el aviso normal
guarda_el_aviso:		; En 0xE401
	ld (0e401h),a		;75a6
cierra_el_lanzamiento:		; Baja el bit 4 de 0xE388, suena el 4 y deja quietas las diez fichas de campo
	ld hl,0e388h		;75a9
	res 4,(hl)		;75ac   ; el bit 4, fuera
	ld a,004h		;75ae   ; A = 4, el sonido de la recogida
	call pide_un_sonido		;75b0
	ld hl,0e220h		;75b3   ; HL = 0xE220
	ld b,00ah		;75b6   ; diez fichas
para_una_ficha_de_campo:		; Los bits 0 y 5, quitados
	res 0,(hl)		;75b8   ; el bit 0
	res 5,(hl)		;75ba   ; y el bit 5
	call avanza_una_fila		;75bc   ; la ficha siguiente
	djnz para_una_ficha_de_campo		;75bf
no_hay_nada_que_hacer:		; La salida vacia de 0x7398
	ret			;75c1
persigue_la_pelota:		; Manda a los defensores a por la pelota bateada. Primero el de 0xE300, luego tres seguidos empezando por 0xE240 o por 0xE2A0 -segun a que lado haya salido, que lo dicen 0xE037 y 0xE038-, luego el de 0xE220 y por ultimo el de 0xE320
	ld hl,0e300h		;75c2   ; HL = 0xE300
	call manda_a_uno_a_por_la_pelota		;75c5
	ld hl,0e240h		;75c8   ; HL = 0xE240, los de un lado
	ld de,0e2a0h		;75cb   ; DE = 0xE2A0, los del otro
	ld a,(0e037h)		;75ce   ; (0xE037), el angulo del golpe
	cp 020h		;75d1   ; pasado el 0x20 es del otro lado
	jr c,L_75D6		;75d3
	ex de,hl			;75d5   ; y entonces se cambian
L_75D6:
	ld a,(0e038h)		;75d6   ; (0xE038), el sentido
	inc a			;75d9
	jr nz,L_75DD		;75da
	ex de,hl			;75dc   ; con 0xFF, cambiados otra vez
L_75DD:
	ld b,003h		;75dd   ; tres seguidos
persigue_con_uno:		; Uno de los tres, y 32 bytes hasta el siguiente
	push bc			;75df
	push hl			;75e0
	call manda_a_uno_a_por_la_pelota		;75e1   ; a por ella
	pop hl			;75e4
	call avanza_una_fila		;75e5   ; la ficha siguiente
	pop bc			;75e8
	djnz persigue_con_uno		;75e9
	ld hl,0e220h		;75eb   ; HL = 0xE220
	call manda_a_uno_a_por_la_pelota		;75ee
	ld hl,0e320h		;75f1   ; y HL = 0xE320, el ultimo
manda_a_uno_a_por_la_pelota:		; Le calcula a la ficha el camino hasta donde va a caer la pelota. Con el contador de carrera a cero y sin rebote se apunta al punto de caida de 0xE0B8, corrigiendolo por el angulo; si no, se va derecho a donde esta la sombra
	push hl			;75f4
	pop ix		;75f5   ; IX = la ficha
	ld a,(0e033h)		;75f7   ; (0xE033), el contador de carrera
	or a			;75fa
	ld bc,(0e0b0h)		;75fb   ; BC = (0xE0B0), donde esta la sombra
	jr nz,mira_si_le_pilla_cerca		;75ff
	ld bc,(0e0b8h)		;7601   ; BC = (0xE0B8), donde va a caer
	ld a,(0e038h)		;7605   ; (0xE038), el sentido
	or a			;7608
	jr nz,mira_si_le_pilla_cerca		;7609
	ld a,(0e037h)		;760b   ; (0xE037), el angulo
	cp 020h		;760e   ; por debajo de 0x20 va por el otro camino
	jr c,corrige_por_el_otro_lado		;7610
	cp 025h		;7612   ; entre 0x20 y 0x25 no se corrige
	jr c,mira_si_le_pilla_cerca		;7614
	bit 7,b		;7616   ; el signo de la fila
	jr nz,mira_si_le_pilla_cerca		;7618
	ld b,0ffh		;761a   ; y si no, se pega al borde
	jr mira_si_le_pilla_cerca		;761c
corrige_por_el_otro_lado:		; Lo mismo con el angulo del otro lado
	cp 01ah		;761e   ; por encima de 0x1a no se corrige
	jr nc,mira_si_le_pilla_cerca		;7620
	bit 7,b		;7622   ; el signo de la fila
	jr z,mira_si_le_pilla_cerca		;7624
	ld b,000h		;7626   ; y si no, al otro borde
mira_si_le_pilla_cerca:		; Si la pelota le cae a mas de 0x20 por delante o a mas de 0x48 por detras, este no va
	ld a,(ix+007h)		;7628   ; su fila
	sub c			;762b   ; contra la de la caida
	jr c,L_7633		;762c
	cp 020h		;762e   ; mas de 0x20 por delante: no le da tiempo
	ret nc			;7630
	jr recorta_la_llegada		;7631
L_7633:
	cp 0b8h		;7633   ; ni mas de 0x48 por detras
	ret c			;7635
recorta_la_llegada:		; Cinco pixeles menos por cada eje: se para justo antes, no encima
	ld a,b			;7636
	sub 005h		;7637   ; cinco menos
	jr c,recorta_el_otro_eje		;7639
	ld b,a			;763b
recorta_el_otro_eje:		; Y cinco menos en el otro
	ld a,c			;763c
	sub 005h		;763d   ; cinco menos
	jr c,le_calcula_el_camino		;763f
	ld c,a			;7641
le_calcula_el_camino:		; Cambia B con C -la trayectoria los quiere al reves- y calcula
	ld a,b			;7642   ; B y C, cambiados
	ld b,c			;7643
	ld c,a			;7644
	ld d,(ix+007h)		;7645   ; D = su fila de ahora
	ld e,(ix+008h)		;7648   ; E = su columna
	push ix		;764b
	pop hl			;764d
	ld a,010h		;764e   ; HL += 0x10, el hueco de la trayectoria
	call suma_a_hl		;7650
	push hl			;7653
	call apunta_hacia_un_destino		;7654   ; y ahi se calcula
	pop hl			;7657
elige_la_postura_del_que_corre:		; De los bits de direccion de la ficha sale la postura -0x30 o 0x34 de base, mas dos si va hacia arriba- y el contador de cuadros le da la vuelta al bit 0 cada cuatro cuadros, que es el paso
	ld a,(hl)			;7658   ; los bits de direccion
	ld b,034h		;7659   ; B = 0x34, la postura de un lado
	rlca			;765b
	jr c,L_7661		;765c
	ld b,030h		;765e   ; o 0x30, la del otro
	rlca			;7660
L_7661:
	rlca			;7661
	jr nc,L_7666		;7662
	inc b			;7664   ; dos mas si va hacia arriba
	inc b			;7665
L_7666:
	dec hl			;7666   ; cinco bytes atras: la postura
	dec hl			;7667
	dec hl			;7668
	dec hl			;7669
	dec hl			;766a
	ld a,(0e000h)		;766b   ; el contador de cuadros
	rrca			;766e
L_766F:
	rrca			;766f
L_7670:
	rrca			;7670
	and 001h		;7671   ; su bit 2, que cambia cada cuatro cuadros
	or b			;7673
	ld (hl),a			;7674   ; y ahi va la postura
	ret			;7675

; ----------------------------------------------------------------------
; DATOS destinos_de_los_lanzamientos: Cuatro entradas de siete bytes, una por
;   base: los dos primeros son la esquina a la que va la pelota, el tercero el
;   numero de base que se apunta, y los cuatro ultimos dos punteros a la ficha
;   del jugador que tiene que ir a recogerla, uno por sentido. Los recorren
;   0x73c8 y 0x742c saltando de siete en siete
;   0x7676..0x7692  (28 bytes)
DATA_destinos_de_los_lanzamientos:
	defb 0a8h,078h,005h,020h,0e3h,020h,0e3h	; 7676
	defb 07ah,0cah,002h,0e0h,0e2h,0e0h,0e2h	; 767d
	defb 056h,078h,003h,0c0h,0e2h,060h,0e2h	; 7684
	defb 07ah,020h,004h,080h,0e2h,080h,0e2h	; 768b

; ======================================================================
; CODIGO 0x7692..0x7881  (495 bytes)
; ======================================================================


lleva_la_recogida:		; Las tres partes de recoger la pelota: mirar si alguien la ha alcanzado, decidir si se para, y comprobar si se sale del campo
	ld a,(0e401h)		;7692   ; (0xE401), su bit 6: la jugada ya esta resuelta
	bit 6,a		;7695
	ret nz			;7697
	call mira_si_alguien_alcanza_la_pelota		;7698   ; mira si alguien la alcanza
	call decide_si_la_pelota_se_para		;769b   ; decide si se para
	jp mira_si_se_sale_del_campo		;769e   ; y si se sale del campo
mira_si_alguien_alcanza_la_pelota:		; Recorre a los nueve y prueba la caja de contacto de cada uno contra la posicion de la sombra. Solo cuenta si la pelota esta baja -menos de diez pixeles de altura- o ya no vuela
	call la_pelota_esta_en_juego		;76a1   ; sin pelota en juego, nada
	ret z			;76a4
	ld a,(0e388h)		;76a5   ; (0xE388), su bit 0: hay lanzamiento
	rrca			;76a8
	ret c			;76a9
	ld c,000h		;76aa   ; C = 0, la altura de partida
	ld a,(0e039h)		;76ac   ; (0xE039): sin pelota bateada, se salta la altura
	or a			;76af
	jr z,mira_quien_puede_cogerla		;76b0
	ld a,(0e0b4h)		;76b2   ; (0xE0B4), la fila de la pelota
	ld b,a			;76b5
	ld a,(0e0b0h)		;76b6   ; (0xE0B0), la de la sombra
	sub b			;76b9
	ld c,a			;76ba   ; C = la altura
	cp 00ah		;76bb   ; por encima de diez pixeles no se coge
	ret nc			;76bd
mira_quien_puede_cogerla:		; Con la carrera en marcha o con un solo jugador, hay condiciones de mas
	call mira_el_contador_de_carrera		;76be   ; el contador de carrera
	jr z,prueba_a_los_nueve		;76c1
	ld a,(0e012h)		;76c3   ; (0xE012), el numero de jugadores
	or a			;76c6
	jr nz,L_76CE		;76c7
	call mira_si_hay_empate		;76c9   ; y lo que diga 0x7ceb
	jr c,prueba_a_los_nueve		;76cc
L_76CE:
	ld a,c			;76ce
	dec a			;76cf   ; a dos o a tres pixeles de altura, no se coge
	dec a			;76d0
	ret z			;76d1
	dec a			;76d2
	ret z			;76d3
prueba_a_los_nueve:		; Uno por uno, con la caja numero 2
	ld hl,0e227h		;76d4   ; HL = 0xE227, la fila del primero
	ld b,009h		;76d7   ; los nueve
prueba_a_uno:		; Su posicion contra la de la sombra
	push bc			;76d9
	ld bc,(0e0b0h)		;76da   ; BC = (0xE0B0), donde esta la sombra
	ld e,(hl)			;76de   ; E = su fila
	inc hl			;76df
	ld d,(hl)			;76e0   ; D = su columna
	ld a,002h		;76e1   ; A = 2, la caja de recoger
	push hl			;76e3
	call mira_si_esta_en_la_caja		;76e4   ; dentro?
	pop hl			;76e7
	pop bc			;76e8
	jr c,la_coge_este		;76e9
	call avanza_una_fila		;76eb   ; la ficha siguiente
	dec hl			;76ee
	djnz prueba_a_uno		;76ef
	ret			;76f1
la_coge_este:		; Apunta en 0xE38A quien la tiene, le pone la postura de recoger -0x3c o 0x3e segun la altura- y cierra la jugada
	ld a,009h		;76f2   ; el numero de ficha, contando desde el final
	sub b			;76f4
	inc a			;76f5
	ld (0e38ah),a		;76f6   ; (0xE38A), quien la tiene
	push hl			;76f9
	ld a,l			;76fa
	and 0f0h		;76fb   ; el principio de su ficha
	ld l,a			;76fd
	bit 3,(hl)		;76fe   ; su bit 3
	ld hl,0e388h		;7700
	res 5,(hl)		;7703   ; el bit 5 de 0xE388, quitado
	jr z,pone_la_postura_de_recoger		;7705
	set 5,(hl)		;7707   ; o puesto
pone_la_postura_de_recoger:		; 0x3c si la pelota llega alta, 0x3e si llega baja
	pop hl			;7709
	inc hl			;770a
	inc hl			;770b
	inc hl			;770c
	ld b,03ch		;770d   ; B = 0x3c
	ld a,c			;770f
	cp 005h		;7710   ; por debajo de cinco de altura...
	jr nc,cierra_la_recogida		;7712
	ld b,03eh		;7714   ; ...la otra postura
cierra_la_recogida:		; Guarda la postura, marca la ficha, deja el estado en 8 y apunta la pelota donde se cogio
	ld (hl),b			;7716   ; la postura
	ld a,l			;7717
	and 0f0h		;7718
	ld l,a			;771a
	set 6,(hl)		;771b   ; el bit 6 de su ficha
	set 7,(hl)		;771d   ; y el bit 7
	ld a,008h		;771f
	ld (0e400h),a		;7721   ; (0xE400) := 8
	ld bc,(0e0b0h)		;7724   ; BC = donde esta la sombra
	ld hl,0e347h		;7728
	ld (hl),c			;772b   ; (0xE347), la columna
	inc hl			;772c
	ld (hl),b			;772d   ; y (0xE348), la fila
	ld hl,0e388h		;772e
	ld a,(hl)			;7731
	and 0e0h		;7732   ; de 0xE388 solo sobreviven los tres bits altos...
	or 007h		;7734   ; ...y se encienden los tres bajos
	ld (hl),a			;7736
	call esconde_la_pelota		;7737
	xor a			;773a
	ld (0e039h),a		;773b   ; (0xE039) := 0: ya no hay pelota bateada
	ld a,002h		;773e
	ld (0e430h),a		;7740   ; (0xE430) := 2
	add a,a			;7743
	call pide_un_sonido		;7744   ; y suena el 4
	call mira_el_contador_de_carrera		;7747   ; el contador de carrera
	push af			;774a
	call z,resuelve_al_vuelo		;774b
	pop af			;774e
	jr z,para_a_los_nueve		;774f
	ld a,(0e401h)		;7751   ; (0xE401), su bit 5
	bit 5,a		;7754
	jr z,para_a_los_nueve		;7756
	xor a			;7758
	ld (0e039h),a		;7759   ; (0xE039) := 0
	ld a,004h		;775c
	ld (0e400h),a		;775e   ; (0xE400) := 4
para_a_los_nueve:		; Les quita el bit 0 a las nueve fichas de campo
	ld hl,0e220h		;7761   ; HL = 0xE220
	ld b,009h		;7764   ; los nueve
para_a_uno:		; El bit 0, fuera
	res 0,(hl)		;7766   ; el bit 0
	call avanza_una_fila		;7768   ; la ficha siguiente
	djnz para_a_uno		;776b
	ret			;776d
resuelve_al_vuelo:		; La pelota cogida sin botar: aviso 4, el contador de carrera a 1, se reparten las bases y se enciende el bit 7 de 0xE388
	call avisa_del_golpe		;776e   ; el aviso de la jugada
	ld a,004h		;7771
	ld (0e401h),a		;7773   ; (0xE401) := 4
	ld hl,0e1a0h		;7776
	res 3,(hl)		;7779   ; el bit 3 de la primera base
	ld a,001h		;777b
	ld (0e033h),a		;777d   ; (0xE033) := 1
	call limpia_la_cuenta		;7780
	ld hl,0e180h		;7783   ; (0xE180) := 0
	ld (hl),000h		;7786
	ld b,003h		;7788   ; las tres bases de detras
	ld de,00020h		;778a   ; 32 bytes por base
repasa_una_base:		; A la que tenga corredor pero no este en marcha se le pone el bit 1 de su pareja
	add hl,de			;778d
	ld a,(hl)			;778e
	rrca			;778f   ; su bit 0
	jr c,L_77A0		;7790
	rrca			;7792   ; y su bit 1
	jr nc,L_77A0		;7793
	push hl			;7795
	call avanza_veintitres		;7796   ; 23 bytes mas alla
	bit 5,(hl)		;7799   ; su bit 5
	jr nz,L_779F		;779b
	set 1,(hl)		;779d   ; y el bit 1, puesto
L_779F:
	pop hl			;779f
L_77A0:
	djnz repasa_una_base		;77a0
	ld hl,0e388h		;77a2
	set 7,(hl)		;77a5   ; el bit 7 de 0xE388
	ret			;77a7
decide_si_la_pelota_se_para:		; Con el bit 2 de 0xE400 y sin el bit 5 de 0xE401: si la pelota bateada esta baja y cerca de la fila 0x78, se da por parada
	ld hl,0e400h		;77a8   ; HL = 0xE400
	bit 2,(hl)		;77ab   ; su bit 2
	ret z			;77ad
	inc hl			;77ae
	bit 5,(hl)		;77af   ; (0xE401), su bit 5
	ret nz			;77b1
	ld a,(0e039h)		;77b2   ; (0xE039), la pelota bateada
	or a			;77b5
	jr z,y_si_no_esta_bateada		;77b6
	call mira_el_contador_de_carrera		;77b8   ; el contador de carrera
	ret z			;77bb
	call mide_la_altura		;77bc   ; mide la altura
	ld b,a			;77bf
	ld a,c			;77c0
	sub 078h		;77c1   ; desde la fila 0x78
	ret c			;77c3
	rlca			;77c4   ; por dos
	cp b			;77c5   ; contra la altura
	jr nc,marca_la_pelota_parada		;77c6
	ret			;77c8
y_si_no_esta_bateada:		; Sin pelota bateada, tambien se para
	call mira_el_contador_de_carrera		;77c9   ; el contador de carrera
	ret nz			;77cc
	call esconde_la_pelota		;77cd   ; la pelota se esconde
marca_la_pelota_parada:		; El bit 5 de 0xE401
	ld hl,0e401h		;77d0
	set 5,(hl)		;77d3   ; el bit 5
	ret			;77d5
mira_si_se_sale_del_campo:		; Compara la columna de la sombra con la valla, que sale de la tabla de 0x7883 en cinco tramos, y con la altura de la pelota: por debajo rebota, por encima es un HOME RUN
	ld hl,0e400h		;77d6   ; HL = 0xE400
	bit 2,(hl)		;77d9   ; su bit 2
	ret z			;77db
	ld a,(0e038h)		;77dc   ; (0xE038): con 0xFF no hay valla
	inc a			;77df
	ret z			;77e0
	call mide_la_altura		;77e1   ; mide la altura
	cp 009h		;77e4   ; por debajo de nueve, no cuenta
	jr nc,L_77E9		;77e6
	xor a			;77e8
L_77E9:
	ld b,a			;77e9
	ld a,(0e0b4h)		;77ea   ; (0xE0B4), la fila de la pelota
	ld e,a			;77ed
	ld a,c			;77ee
	sub e			;77ef   ; la distancia
	ld e,a			;77f0
	ld a,c			;77f1
	cp 078h		;77f2   ; por debajo de la fila 0x78 no hay valla
	ret nc			;77f4
	ld d,001h		;77f5   ; D = 1, el primer tramo
	ld hl,07883h		;77f7   ; HL = 0x7883, los tramos de la valla
	push bc			;77fa
	ld b,005h		;77fb   ; cinco tramos
busca_el_tramo_de_la_valla:		; El primero que la columna no pase
	cp (hl)			;77fd   ; la columna
	jr nc,mide_la_valla		;77fe
	inc d			;7800   ; el tramo siguiente
	inc hl			;7801
	djnz busca_el_tramo_de_la_valla		;7802
	pop bc			;7804
	ld a,e			;7805
	cp 007h		;7806   ; con siete o menos de altura, rebota
	jr c,rebota_en_la_valla		;7808
	jr sale_del_campo		;780a
mide_la_valla:		; Del tramo salen la columna y la altura de partida y, saltando de cinco en cinco, se van sumando los dos incrementos hasta pasar de la columna de la pelota
	pop bc			;780c
	ld hl,07883h		;780d   ; HL = 0x7883, otra vez
salta_un_tramo:		; Cinco bytes por tramo
	ld a,005h		;7810
	call suma_a_hl		;7812   ; cinco por tramo
	dec d			;7815
	jr nz,salta_un_tramo		;7816
	push de			;7818
	ld d,(hl)			;7819   ; D = la columna del tramo
	inc hl			;781a
	ld e,(hl)			;781b   ; E = su altura
	inc hl			;781c
sube_por_la_valla:		; Los dos incrementos, hasta llegar a la columna de la pelota
	ld a,d			;781d
	cp c			;781e   ; comparada con la de la pelota
	jr c,compara_con_la_valla		;781f
	ld a,(hl)			;7821   ; el incremento de columna...
	add a,d			;7822
	ld d,a			;7823
	inc hl			;7824
	ld a,(hl)			;7825   ; ...y el de altura
	add a,e			;7826
	ld e,a			;7827
	dec hl			;7828
	jr sube_por_la_valla		;7829
compara_con_la_valla:		; Con la pelota mas baja que la valla, rebota; mas alta, sale del campo
	ld a,b			;782b
	or a			;782c   ; sin altura, rebota
	jr z,mira_el_ultimo_tramo		;782d
	cp e			;782f   ; por debajo de la valla, rebota
	jr c,mira_el_ultimo_tramo		;7830
	pop de			;7832
	ret			;7833
mira_el_ultimo_tramo:		; El quinto byte del tramo es el tope de altura
	pop de			;7834
	inc hl			;7835
	inc hl			;7836
	ld a,(hl)			;7837   ; el tope
	cp e			;7838   ; por encima, HOME RUN
	jr c,sale_del_campo		;7839
rebota_en_la_valla:		; Suena el golpe y la pelota sale disparada al reves: el angulo nuevo es 0x40 menos el que traia, que es el rebote especular
	call avisa_del_golpe		;783b   ; el aviso del golpe
	ld a,00ah		;783e   ; A = 0x0a, el sonido del rebote
	call pide_un_sonido		;7840
	xor a			;7843
	ld (0e038h),a		;7844   ; (0xE038) := 0
	ld (0e0a1h),a		;7847   ; (0xE0A1) := 0
	inc a			;784a
	ld (0e039h),a		;784b   ; (0xE039) := 1: sigue bateada
	ld (0e03bh),a		;784e   ; (0xE03B) := 1
	ld a,060h		;7851
	ld (0e0a2h),a		;7853   ; (0xE0A2) := 0x60, la altura nueva
	ld a,(0e037h)		;7856   ; (0xE037), el angulo de ahora
	ld b,a			;7859
	ld a,040h		;785a   ; 0x40 menos el angulo: el rebote
	sub b			;785c
	and 03fh		;785d
	ld (0e037h),a		;785f   ; guardado
	ld hl,0e033h		;7862
	inc (hl)			;7865   ; (0xE033), un bote mas
	jp lleva_la_pelota_bateada		;7866   ; y a seguir volando
sale_del_campo:		; Con carrera en marcha, la pelota sigue en el aire desde la valla; si no, la jugada se cierra y es HOME RUN
	call mira_el_contador_de_carrera		;7869   ; el contador de carrera
	jr z,cierra_la_jugada_por_home_run		;786c
	ld a,c			;786e
	sub d			;786f   ; la altura de la valla
	ld (0e0b4h),a		;7870   ; la pelota se pone ahi
	jr rebota_en_la_valla		;7873
cierra_la_jugada_por_home_run:		; El bit 6 de 0xE401, 0xE388 a cero y todos quietos
	ld hl,0e401h		;7875
	set 6,(hl)		;7878   ; el bit 6 de 0xE401
	xor a			;787a
	ld (0e388h),a		;787b   ; (0xE388) := 0
	jp para_a_los_nueve		;787e

; ----------------------------------------------------------------------
; DATOS resto_7881: Dos bytes entre el codigo y la valla; ninguna lectura
;   empieza en ellos
;   0x7881..0x7883  (2 bytes)
DATA_resto_7881:
	defb 0d1h,0c9h	; 7881

; ----------------------------------------------------------------------
; DATOS la_valla: Cinco tramos de cinco bytes que describen el borde del
;   campo: columna, altura, incremento de columna, incremento de altura y
;   tope. 0x77f7 busca el tramo comparando la columna y 0x781d lo recorre a
;   base de sumar los dos incrementos. Es lo que decide si una pelota rebota o
;   es HOME RUN
;   0x7883..0x78a1  (30 bytes)
DATA_la_valla:
	defb 060h,048h,038h,030h,028h	; 7883
	defb 078h,000h,0fdh,001h,036h	; 7888
	defb 060h,008h,0fdh,002h,01ch	; 788d
	defb 048h,018h,0ffh,001h,013h	; 7892
	defb 038h,028h,0ffh,002h,010h	; 7897
	defb 030h,038h,0ffh,003h,00ah	; 789c

; ======================================================================
; CODIGO 0x78a1..0x7c20  (895 bytes)
; ======================================================================


avisa_del_golpe:		; Calla el efecto y suena el 0x9a
	xor a			;78a1
	ld (0e650h),a		;78a2   ; (0xE650) := 0
	ld a,09ah		;78a5   ; A = 0x9a
suena_ya:		; Pide el sonido y le da un cuadro en el acto, sin esperar a la interrupcion
	call pide_un_sonido		;78a7   ; el sonido
	push hl			;78aa
	call mueve_el_sonido		;78ab   ; y un cuadro de motor, ya
	di			;78ae
	pop hl			;78af
	ret			;78b0
mide_la_altura:		; La distancia entre la fila de la sombra y la de la pelota, corrida cuatro pixeles, siempre en positivo
	ld bc,(0e0b0h)		;78b1   ; BC = las dos filas
	inc b			;78b5   ; cuatro pixeles de correccion
	inc b			;78b6
	inc b			;78b7
	inc b			;78b8
	ld a,b			;78b9
	bit 7,a		;78ba   ; el signo
	ret z			;78bc
	neg		;78bd   ; y siempre en positivo
	ret			;78bf
lleva_los_contadores:		; El cuadro de contabilidad de la partida. Si 0xE38B esta puesto se borran los dos mandos, se quita el cartel si toca, se repinta la inicial del equipo que batea, y luego los cuatro bits bajos de 0xE400 eligen que parte de la jugada se resuelve
	ld a,(0e38bh)		;78c0   ; (0xE38B): la partida esta en pausa
	or a			;78c3
	jr z,reparte_el_estado_de_la_jugada		;78c4
	xor a			;78c6
	ld (0e00eh),a		;78c7   ; los dos mandos, borrados
	ld (0e011h),a		;78ca   ; el del segundo tambien
reparte_el_estado_de_la_jugada:		; Los bits de 0xE400: el 0 el fin de entrada, el 1 el lanzamiento, el 2 la pelota bateada y el 3 la resolucion
	ld a,(0e40dh)		;78cd   ; (0xE40D): con plazo de cartel, se le da un cuadro
	or a			;78d0
	call nz,quita_el_cartel		;78d1
	call repinta_la_inicial		;78d4   ; repinta la inicial del equipo que batea
	ld hl,0e400h		;78d7   ; HL = 0xE400
	ld a,(hl)			;78da
	rrca			;78db   ; el bit 0
	jp c,cambia_el_turno		;78dc
	rrca			;78df   ; el bit 1
	jp c,monta_el_lanzamiento_siguiente		;78e0
	rrca			;78e3   ; el bit 2
	jp c,resuelve_el_lanzamiento		;78e4
	rrca			;78e7   ; y el bit 3
	ret nc			;78e8
	inc hl			;78e9
resuelve_la_jugada:		; El aviso de 0xE401 dice que ha pasado: con el bit 6 hay eliminacion, con el 3 sale el cartel 3, con el 2 se cuentan los eliminados -y al tercero se cambia de entrada- y si no, se deja correr el plazo
	ld a,(hl)			;78ea   ; el aviso de la jugada
	bit 6,a		;78eb   ; su bit 6
	jp nz,acaba_la_entrada		;78ed
	ld (hl),000h		;78f0   ; gastado
	bit 3,a		;78f2   ; el bit 3
	jr nz,cartel_de_safe		;78f4
	bit 2,a		;78f6   ; el bit 2
	jr z,deja_correr_el_plazo		;78f8
	ld hl,0e180h		;78fa   ; las cuatro bases
	ld b,004h		;78fd
	call mira_una_ficha		;78ff   ; repartidas
	ld hl,0e40ah		;7902
	inc (hl)			;7905   ; (0xE40A), un eliminado mas
	ld a,(hl)			;7906
	cp 003h		;7907   ; al tercero se cambia de entrada
	ld a,002h		;7909   ; A = 2, el cartel de OUT
	jr nz,saca_el_cartel		;790b
cambia_de_entrada:		; Tres eliminados: se borra 0xE380, el estado vuelve a 1 y sale el cartel de CHANGE
	xor a			;790d
	ld (0e380h),a		;790e   ; (0xE380) := 0
	ld hl,0e400h		;7911
	inc a			;7914
	ld (hl),a			;7915   ; (0xE400) := 1
	inc hl			;7916
	ld (hl),010h		;7917   ; (0xE401) := 0x10
	inc a			;7919
	jp ensena_un_cartel		;791a   ; y el cartel 4, el de CHANGE
cartel_de_safe:		; El cartel 3
	ld a,003h		;791d   ; A = 3, el de SAFE
saca_el_cartel:		; Y se dibuja
	call ensena_un_cartel		;791f
y_a_seguir:		; Vuelve al cuerpo del partido
	jp un_cuadro_de_partido		;7922
deja_correr_el_plazo:		; Sin nada que resolver, se deja correr el contador de 0xE403; a los 0x80 cuadros la jugada se cierra sola y se apuntan las carreras
	call apunta_las_carreras		;7925   ; apunta las carreras
	ld hl,0e403h		;7928
	inc (hl)			;792b   ; un cuadro mas
	ld a,080h		;792c   ; a los 0x80
	cp (hl)			;792e
	jr nz,y_a_seguir		;792f
	xor a			;7931
	ld (hl),a			;7932   ; el contador, a cero
	ld hl,0e401h		;7933
	ld (hl),a			;7936   ; (0xE401) := 0
	dec hl			;7937
	inc a			;7938
	ld (hl),a			;7939   ; (0xE400) := 1
	call mira_el_contador_de_carrera		;793a   ; el contador de carrera
	call nz,limpia_la_cuenta		;793d
	ld hl,0e40eh		;7940   ; HL = 0xE40E, las carreras del otro
	jr suma_las_carreras		;7943
apunta_las_carreras:		; Con dos eliminados y la primera base ocupada no se apunta nada; si no, se cuentan las de 0xE40C
	ld b,a			;7945
	ld a,(0e40ah)		;7946   ; (0xE40A), los eliminados
	cp 002h		;7949   ; dos
	jr nz,L_7953		;794b
	ld a,(0e180h)		;794d   ; (0xE180), su bit 1
	bit 1,a		;7950
	ret nz			;7952
L_7953:
	ld hl,0e40ch		;7953   ; HL = 0xE40C, las carreras de este
suma_las_carreras:		; Si el contador trae algo, se le suma al marcador y se vuelca a la pantalla
	ld a,(hl)			;7956   ; lo que hay que apuntar
	or a			;7957
	ret z			;7958
	ld (hl),000h		;7959   ; gastado
	ld b,a			;795b
escribe_el_marcador:		; Suma B carreras a la casilla de la entrada que toque y al total, las dos en cifras BCD de un digito, y vuelca las doce casillas de la fila a la pantalla
	ld hl,0e410h		;795c   ; HL = 0xE410, la fila de un equipo
	ld de,0782bh		;795f   ; DE = VRAM 0x782b, donde va
	ld a,(0e402h)		;7962
	rrca			;7965
	jr nc,elige_la_fila_del_marcador		;7966
	ld hl,0e420h		;7968
	ld e,04bh		;796b
elige_la_fila_del_marcador:		; Segun de quien sea el turno, la de 0xE420 y la fila 0x784b
	push hl			;796d
	ld a,(0e40bh)		;796e   ; (0xE40B), la entrada
	call suma_a_hl		;7971
	ld a,(hl)			;7974   ; la casilla de esa entrada
	add a,b			;7975   ; mas las carreras
	or 0f0h		;7976   ; convertida en tile de cifra
	cp 0fah		;7978   ; pasada del 9...
	jr c,guarda_la_casilla		;797a
	sub 00ah		;797c   ; ...se le quitan diez
guarda_la_casilla:		; La casilla de la entrada, y ahora el total
	ld (hl),a			;797e   ; la casilla
	pop hl			;797f
	push hl			;7980
	ld a,00bh		;7981   ; HL += 11: el total
	call suma_a_hl		;7983
	ld a,(hl)			;7986
	add a,b			;7987   ; mas las carreras
	or 0f0h		;7988   ; en tile de cifra
	cp 0fah		;798a
	jr c,vuelca_la_fila		;798c
	sub 00ah		;798e   ; pasado del 9, acarreo a las decenas
	ld b,a			;7990
	dec hl			;7991
	ld a,(hl)			;7992   ; la cifra de las decenas
	inc a			;7993   ; una mas
	or 0f0h		;7994
	cp 0fah		;7996   ; y si tambien se pasa...
	jr c,guarda_las_decenas		;7998
	ld a,0f9h		;799a   ; ...se queda en 99
	ld b,a			;799c
guarda_las_decenas:		; Las decenas, y detras las unidades
	ld (hl),a			;799d   ; las decenas
	inc hl			;799e
	ld a,b			;799f
vuelca_la_fila:		; Las doce casillas de la fila, a la pantalla; y en la novena entrada se mira si el partido esta decidido
	ld (hl),a			;79a0   ; las unidades
	pop hl			;79a1
	ld b,00ch		;79a2   ; doce casillas
	call copia_bytes_con_candado		;79a4
	ld a,(0e40bh)		;79a7   ; (0xE40B), la entrada
	cp 008h		;79aa   ; la octava
	ret nz			;79ac
	ld a,(0e402h)		;79ad   ; (0xE402), el turno
	rrca			;79b0
	ret nc			;79b1
	call mira_si_hay_empate		;79b2   ; mira si hay empate
	ret c			;79b5
	ld a,080h		;79b6
	ld (0e402h),a		;79b8   ; (0xE402) := 0x80: partido acabado
	ret			;79bb
acaba_la_entrada:		; Suena el aviso, se marca 0xE389, y se cuenta cuantas bases quedan ocupadas: si no queda ninguna, se borra el hueco del rotulo y suena el 0x97
	ld a,(0e663h)		;79bc   ; (0xE663), la marca del motor de sonido
	or a			;79bf
	jr nz,L_79C7		;79c0
	ld a,08eh		;79c2   ; A = 0x8e, el aviso
	call pide_un_sonido		;79c4
L_79C7:
	ld hl,0e389h		;79c7
	set 2,(hl)		;79ca   ; el bit 2 de 0xE389
	ld a,001h		;79cc
	ld (0e033h),a		;79ce   ; (0xE033) := 1
	ld bc,00400h		;79d1   ; B = 4 bases, C = 0
	ld hl,0e180h		;79d4   ; HL = 0xE180
cuenta_una_base:		; Con los dos bits bajos, una ocupada mas
	ld a,(hl)			;79d7
	and 003h		;79d8   ; los dos bits bajos
	jr z,manda_a_los_de_base		;79da
	inc c			;79dc   ; una mas
manda_a_los_de_base:		; A los que estan en base y no corren, se les da la orden de correr
	bit 1,(hl)		;79dd   ; el bit 1: hay corredor
	jr z,la_base_siguiente_del_recuento		;79df
	bit 0,(hl)		;79e1   ; el bit 0: ya corre
	jr nz,la_base_siguiente_del_recuento		;79e3
	set 2,(hl)		;79e5   ; el bit 2: la orden
	res 4,(hl)		;79e7   ; y el bit 4, fuera
la_base_siguiente_del_recuento:		; 32 bytes mas alla, y si no quedaba ninguna se cierra
	call avanza_una_fila		;79e9   ; la base siguiente
	djnz cuenta_una_base		;79ec
	ld a,c			;79ee
	or a			;79ef
	jr nz,parpadea_el_rotulo		;79f0
	ld (0e401h),a		;79f2   ; (0xE401) := 0
	call apunta_las_carreras		;79f5
	ld de,04068h		;79f8   ; DE = VRAM 0x4068
	ld b,0b0h		;79fb   ; 0xB0 tiles de relleno
	ld c,0f4h		;79fd
	call rellena_con_candado		;79ff   ; borrados
	ld a,097h		;7a02   ; y suena el 0x97
	call suena_ya		;7a04
	jr el_marco_vacio		;7a07
parpadea_el_rotulo:		; Con bases ocupadas, el color del rotulo cambia con los bits 4 y 5 del contador de cuadros: cuatro colores que se van turnando
	ld a,(0e000h)		;7a09   ; el contador de cuadros
	and 030h		;7a0c   ; sus bits 4 y 5
	cp 030h		;7a0e
	jr nz,el_segundo_color		;7a10
	ld c,0f0h		;7a12   ; los dos puestos: 0xF0
el_segundo_color:		; El 0xA0
	cp 020h		;7a14
	jr nz,el_tercer_color		;7a16
	ld c,0a0h		;7a18   ; 0xA0
el_tercer_color:		; El 0x70
	cp 010h		;7a1a
	jr nz,el_cuarto_color		;7a1c
	ld c,070h		;7a1e   ; 0x70
el_cuarto_color:		; El 0x90
	or a			;7a20
	jr nz,pinta_el_rotulo		;7a21
	ld c,090h		;7a23   ; 0x90
pinta_el_rotulo:		; Al color se le suma el 4 y, cada dieciseis cuadros, se repinta el fondo entero
	ld a,c			;7a25
	or 004h		;7a26   ; el 4 de la tinta
	ld c,a			;7a28
	ld a,(0e000h)		;7a29   ; el contador de cuadros
	and 00fh		;7a2c   ; uno de cada dieciseis
	jr nz,elige_el_texto		;7a2e
	ld de,04068h		;7a30   ; DE = VRAM 0x4068
	ld b,0b0h		;7a33   ; 0xB0 tiles
	call rellena_con_candado		;7a35
elige_el_texto:		; El bit 5 del contador alterna entre HOME RUN y el marco vacio
	ld a,(0e000h)		;7a38   ; el contador de cuadros
	ld hl,07c70h		;7a3b   ; HL = 0x7c70, HOME RUN
	bit 5,a		;7a3e   ; su bit 5
	jr nz,L_7A45		;7a40
el_marco_vacio:		; El de 0x7c66
	ld hl,07c66h		;7a42   ; HL = 0x7c66, el marco
L_7A45:
	ld de,0786bh		;7a45   ; DE = VRAM 0x786b
	ld b,00ah		;7a48   ; diez tiles
	call copia_bytes_con_candado		;7a4a
vuelve_al_partido:		; Y a seguir
	jp un_cuadro_de_partido		;7a4d
resuelve_el_lanzamiento:		; El estado 4: con el bit 2 se resuelve como jugada, con el 6 se pasa a la siguiente y con el 5 se cierra el turno del bateador
	inc hl			;7a50
	bit 2,(hl)		;7a51   ; el bit 2
	jp nz,resuelve_la_jugada		;7a53
	bit 6,(hl)		;7a56   ; el bit 6
	jr nz,resuelve_el_golpe		;7a58
	bit 5,(hl)		;7a5a   ; el bit 5
	jr z,vuelve_al_partido		;7a5c
	ld a,(0e039h)		;7a5e   ; (0xE039), la pelota bateada
	or a			;7a61
cierra_el_turno:		; Deja el estado en 1 y reparte a los corredores segun las cuatro marcas de 0xE197
	jr nz,vuelve_al_partido		;7a62
	ld (hl),a			;7a64   ; el aviso, a cero
	dec hl			;7a65
	ld (hl),001h		;7a66   ; (0xE400) := 1
	ld hl,0e180h		;7a68   ; HL = 0xE180, las bases
	ld de,0e197h		;7a6b   ; DE = 0xE197, las marcas
	ld b,004h		;7a6e   ; cuatro
reparte_una_marca:		; El bit 0 de la marca decide si la base queda ocupada
	ld a,(de)			;7a70   ; la marca
	rrca			;7a71
	set 1,(hl)		;7a72   ; el bit 1, puesto
	jr c,la_base_y_la_marca_siguientes		;7a74
	res 1,(hl)		;7a76   ; o quitado, y el 5 tambien
	res 5,(hl)		;7a78
la_base_y_la_marca_siguientes:		; 32 bytes cada una
	call avanza_una_fila		;7a7a   ; la base siguiente
	ex de,hl			;7a7d
	call avanza_una_fila		;7a7e   ; y la marca siguiente
	ex de,hl			;7a81
	djnz reparte_una_marca		;7a82
	push hl			;7a84
	call avisa_del_golpe		;7a85   ; el aviso de sonido
	pop hl			;7a88
	ld a,005h		;7a89   ; A = 5, el cartel de FOUL
	call ensena_un_cartel		;7a8b
	ld hl,0e408h		;7a8e   ; (0xE408), los strikes
	ld a,(hl)			;7a91
	cp 002h		;7a92   ; con dos ya no sube mas
	ret z			;7a94
	inc (hl)			;7a95   ; y si no, uno mas
	ret			;7a96
resuelve_el_golpe:		; El estado 8: el marcador a 2, se le da la vuelta a la semilla de azar y suena el 0x8c
	dec hl			;7a97
	ld (hl),008h		;7a98   ; (0xE400) := 8
	ld a,002h		;7a9a
	ld (0e380h),a		;7a9c   ; (0xE380) := 2
	ld hl,0e445h		;7a9f   ; HL = 0xE445, la primera semilla
	ld a,(0e402h)		;7aa2   ; (0xE402), el turno
	rrca			;7aa5
	jr c,gira_la_semilla		;7aa6
	ld hl,0e446h		;7aa8
gira_la_semilla:		; La semilla, rotada un bit
	ld a,(hl)			;7aab
	rrca			;7aac   ; rotada
	ld (hl),a			;7aad
	call esconde_la_pelota		;7aae   ; la pelota, escondida
	ld (0e0b0h),a		;7ab1
	ld a,08ch		;7ab4   ; A = 0x8c, el sonido
	jp pide_un_sonido		;7ab6
monta_el_lanzamiento_siguiente:		; El estado 2: en cuanto se agota el plazo de 0xE001, el lanzador se enciende y su contador sube
	ld a,(0e100h)		;7ab9   ; (0xE100), su bit 0
	rrca			;7abc
	jr c,cuenta_strike_o_bola		;7abd
	ld a,(0e001h)		;7abf   ; (0xE001), el plazo
	or a			;7ac2
	ret nz			;7ac3
	ld a,008h		;7ac4   ; (0xE430) := 8, el estado de la maquina
	ld (0e430h),a		;7ac6
	push hl			;7ac9
	ld hl,0e100h		;7aca
	set 0,(hl)		;7acd   ; el bit 0 del lanzador
	set 6,(hl)		;7acf   ; y el bit 6
	inc hl			;7ad1
	inc hl			;7ad2
	inc (hl)			;7ad3   ; su contador, uno mas
	pop hl			;7ad4
cuenta_strike_o_bola:		; Del aviso de 0xE401 sale que se apunta: el bit 0 una bola y el bit 1 un strike. Al tercer strike el bateador esta eliminado y a la cuarta bola hay base por bolas
	inc hl			;7ad5
	ld a,(hl)			;7ad6   ; el aviso
	rrca			;7ad7   ; el bit 0: bola
	jr c,cuenta_una_bola		;7ad8
	rrca			;7ada   ; el bit 1: strike
	jp nc,un_cuadro_de_partido		;7adb
	ld (hl),000h		;7ade   ; el aviso, gastado
	ld hl,0e408h		;7ae0   ; (0xE408), los strikes
	inc (hl)			;7ae3   ; uno mas
	ld a,003h		;7ae4
	cp (hl)			;7ae6   ; al tercero
	jr nz,cartel_de_strike		;7ae7
	call limpia_la_cuenta		;7ae9
	inc hl			;7aec
	inc hl			;7aed
	inc (hl)			;7aee   ; (0xE40A), un eliminado mas
	ld a,(hl)			;7aef
	cp 003h		;7af0   ; y al tercero, cambio de entrada
	jp z,cambia_de_entrada		;7af2
	ld a,002h		;7af5   ; A = 2, el cartel de OUT
	jr saca_el_cartel_que_toque		;7af7
cartel_de_strike:		; El cartel 0
	ld a,000h		;7af9   ; A = 0, el de STRIKE
saca_el_cartel_que_toque:		; Y se dibuja
	jr dibuja_y_cierra		;7afb
cuenta_una_bola:		; La cuarta bola es base por bolas: la partida se para, el bateador se recoge y sale el cartel de "4 BALL"
	ld (hl),000h		;7afd   ; el aviso, gastado
	ld hl,0e409h		;7aff   ; (0xE409), las bolas
	inc (hl)			;7b02   ; una mas
	ld a,(hl)			;7b03
	cp 004h		;7b04   ; a la cuarta
	jr nz,cartel_de_bola		;7b06
	ld a,001h		;7b08
	ld (0e38bh),a		;7b0a   ; (0xE38B) := 1: la partida, en pausa
	call limpia_la_cuenta		;7b0d
	ld hl,0e400h		;7b10
	ld (hl),008h		;7b13   ; (0xE400) := 8
	inc hl			;7b15
	ld (hl),080h		;7b16   ; (0xE401) := 0x80
	ld hl,0e140h		;7b18
	set 5,(hl)		;7b1b   ; el bit 5 del bateador
	call acaba_el_bateo		;7b1d   ; y se le recoge
	ld hl,0e100h		;7b20
	ld a,(hl)			;7b23
	and 0c1h		;7b24   ; de 0xE100 solo sobreviven los bits 0, 6 y 7
	ld (hl),a			;7b26
	ld a,006h		;7b27   ; A = 6, el cartel de "4 BALL"
	jr dibuja_y_cierra		;7b29
cartel_de_bola:		; El cartel 1
	ld a,001h		;7b2b   ; A = 1, el de BALL
dibuja_y_cierra:		; Saca el cartel y baja el bit 0 de 0xE380
	call ensena_un_cartel		;7b2d   ; el cartel
	ld hl,0e380h		;7b30
	res 0,(hl)		;7b33   ; el bit 0 de 0xE380
	ret			;7b35
cambia_el_turno:		; El estado 1: repinta el marcador, borra strikes, bolas, eliminados y carreras, le da la vuelta al bit 0 de 0xE402 y, si el que acaba es el segundo, sube la entrada. A las nueve entradas el partido se acaba
	ld a,(0e40dh)		;7b36   ; (0xE40D): con cartel en pantalla, se espera
	or a			;7b39
	ret nz			;7b3a
	ld hl,0e401h		;7b3b
	bit 4,(hl)		;7b3e   ; (0xE401), su bit 4
	jr z,empieza_la_jugada_siguiente		;7b40
	res 4,(hl)		;7b42   ; gastado
	push hl			;7b44
	ld b,a			;7b45
	call escribe_el_marcador		;7b46   ; vuelca el marcador
	call escribe_las_iniciales		;7b49   ; y repinta las iniciales
	ld hl,0e408h		;7b4c
	xor a			;7b4f   ; (0xE408) := 0, los strikes
	ld (hl),a			;7b50
	inc hl			;7b51
	ld (hl),a			;7b52   ; (0xE409) := 0, las bolas
	inc hl			;7b53
	ld (hl),a			;7b54   ; (0xE40A) := 0, los eliminados
	ld (0e40ch),a		;7b55   ; (0xE40C) := 0
	ld (0e40eh),a		;7b58   ; (0xE40E) := 0
	pop hl			;7b5b
	ld a,(0e002h)		;7b5c   ; (0xE002): en la demostracion el turno no cambia
	or a			;7b5f
	jr nz,acaba_el_partido		;7b60
	inc hl			;7b62
	rr (hl)		;7b63   ; el bit 0 de 0xE402, del reves
	ccf			;7b65
	rl (hl)		;7b66
	bit 0,(hl)		;7b68
	ld hl,0e40bh		;7b6a   ; HL = 0xE40B, la entrada
	jr nz,mira_si_hay_prorroga		;7b6d
	inc (hl)			;7b6f   ; una entrada mas
	ld a,(hl)			;7b70
	cp 009h		;7b71   ; a la novena se acaba
	jr nz,limpia_las_bases		;7b73
acaba_el_partido:		; (0xE402) := 0x80, que es lo que mira el bucle de fuera
	ld hl,0e402h		;7b75
	ld (hl),080h		;7b78   ; (0xE402) := 0x80
	ret			;7b7a
mira_si_hay_prorroga:		; En la octava, si el marcador esta empatado, se pinta un 0xE7 en la casilla y el partido sigue
	ld a,(hl)			;7b7b
	cp 008h		;7b7c   ; la octava entrada
	jr nz,limpia_las_bases		;7b7e
	call mira_si_hay_empate		;7b80   ; mira si hay empate
	jr c,limpia_las_bases		;7b83
	ld a,0e7h		;7b85
	ld (0e428h),a		;7b87   ; (0xE428) := 0xe7
	jr acaba_el_partido		;7b8a
limpia_las_bases:		; Las cuatro bases a cero, los sprites escondidos y del lanzador solo sobrevive el bit 4
	ld hl,0e180h		;7b8c   ; HL = 0xE180
	ld b,004h		;7b8f   ; las cuatro
borra_una_base:		; A cero
	ld (hl),000h		;7b91   ; a cero
	call avanza_una_fila		;7b93   ; la siguiente
	djnz borra_una_base		;7b96
	call esconde_todos_los_sprites		;7b98   ; y los sprites, fuera
	ld hl,0e100h		;7b9b
	ld a,(hl)			;7b9e
	and 010h		;7b9f   ; de 0xE100 solo sobrevive el bit 4
	ld (hl),a			;7ba1
	ld a,004h		;7ba2   ; A = 4, el cartel de CHANGE
	call ensena_un_cartel		;7ba4
	ret			;7ba7
empieza_la_jugada_siguiente:		; Estado 2 y a montar la jugada
	ld a,002h		;7ba8   ; (0xE400) := 2
	ld (0e400h),a		;7baa
	jp monta_la_jugada		;7bad
un_cuadro_de_partido:		; El cuerpo del partido, partido en dos mitades que se turnan cuadro a cuadro: en los pares la pelota bateada, el lanzamiento y los corredores; en los impares la defensa, el bateador, la recogida y la maquina
	ld a,(0e000h)		;7bb0   ; el contador de cuadros
	rrca			;7bb3   ; su bit 0 decide la mitad
	jr c,la_otra_mitad_del_cuadro		;7bb4
	call lleva_la_pelota_bateada		;7bb6   ; la pelota bateada
	call lleva_el_lanzamiento		;7bb9   ; el lanzamiento
	jp lleva_a_los_corredores		;7bbc   ; y los corredores
la_otra_mitad_del_cuadro:		; Los cuadros impares
	call lleva_la_defensa		;7bbf   ; la defensa
	call lleva_al_bateador		;7bc2   ; el bateador
	call lleva_la_recogida		;7bc5   ; la recogida
	jp juega_la_maquina		;7bc8   ; y la maquina
ensena_un_cartel:		; Saca el cartel numero A: copia sus siete tiles al hueco de la pantalla, pide su sonido y arranca el plazo de 0x40 cuadros de 0xE40D. OJO: el `ld de,L_7AB9` del listado NO es un salto, es la direccion de VRAM 0x7ab9 -que el desensamblador ha bautizado con el nombre de la rutina que vive en esa direccion de ROM-
	ld b,a			;7bcb
	ld hl,0e40dh		;7bcc   ; (0xE40D) := 0x40, el plazo del cartel
	ld (hl),040h		;7bcf
	inc b			;7bd1
	ld hl,otro_contador		;7bd2   ; HL = la tabla de carteles, un paso antes
salta_un_cartel:		; Tres bytes por cartel
	inc hl			;7bd5
	inc hl			;7bd6
	inc hl			;7bd7
	djnz salta_un_cartel		;7bd8
	ld a,(hl)			;7bda   ; el puntero al texto
	inc hl			;7bdb
	push hl			;7bdc
	ld h,(hl)			;7bdd
	ld l,a			;7bde
	ld de,monta_el_lanzamiento_siguiente		;7bdf   ; DE = VRAM 0x7ab9, el hueco del cartel
	ld b,007h		;7be2   ; siete tiles
	call copia_bytes_con_candado		;7be4
	pop hl			;7be7
	inc hl			;7be8
	ld a,(hl)			;7be9   ; y el sonido que le toca
	call pide_un_sonido		;7bea
quita_el_cartel:		; Cuando el plazo se agota y el sonido ha callado, borra los siete tiles y repinta los tres contadores
	ld a,(0e663h)		;7bed   ; (0xE663), la marca del motor de sonido
	or a			;7bf0
	ret nz			;7bf1
	ld hl,0e40dh		;7bf2
	dec (hl)			;7bf5   ; un cuadro menos de plazo
	ret nz			;7bf6
	ld de,monta_el_lanzamiento_siguiente		;7bf7   ; DE = VRAM 0x7ab9
	ld bc,00700h		;7bfa   ; siete tiles a cero
	call rellena_con_candado		;7bfd
pinta_los_contadores:		; Las tres filas de strikes, bolas y eliminados: por cada contador, tantos tiles 0x97 como lleve, y si esta a cero, tres huecos
	ld hl,0e408h		;7c00   ; HL = 0xE408, los tres contadores
	ld de,cierra_el_turno		;7c03   ; DE = VRAM 0x7a62, la primera fila
	ld b,003h		;7c06   ; tres contadores
pinta_un_contador:		; Tantas marcas como diga el contador
	push bc			;7c08
	ld b,(hl)			;7c09   ; B = lo que lleva
	ld c,097h		;7c0a   ; C = 0x97, la marca
	ld a,b			;7c0c
	or a			;7c0d
	jr nz,escribe_las_marcas		;7c0e
	ld bc,00300h		;7c10   ; a cero, tres huecos
escribe_las_marcas:		; Y la fila siguiente
	call rellena_con_candado		;7c13   ; las marcas
	inc hl			;7c16
	ex de,hl			;7c17
	call avanza_una_fila		;7c18   ; 32 columnas: la fila de abajo
	ex de,hl			;7c1b
	pop bc			;7c1c
otro_contador:		; Hasta los tres
	djnz pinta_un_contador		;7c1d
	ret			;7c1f

; ----------------------------------------------------------------------
; DATOS carteles: Siete entradas de tres bytes: el puntero al texto de siete
;   tiles y el sonido que lo acompana. 0x7bcb entra aqui con el numero de
;   cartel. Leidos con la fuente del cartucho son STRIKE, BALL, OUT, SAFE,
;   CHANGE, FOUL y "4 BALL" -la base por bolas, con el tile 0xF4 del cuatro
;   delante-
;   0x7c20..0x7c35  (21 bytes)
DATA_carteles:
	defb 035h,07ch,086h	; 7c20
	defb 03ch,07ch,005h	; 7c23
	defb 043h,07ch,009h	; 7c26
	defb 04ah,07ch,088h	; 7c29
	defb 051h,07ch,090h	; 7c2c
	defb 058h,07ch,007h	; 7c2f
	defb 05fh,07ch,005h	; 7c32

; ----------------------------------------------------------------------
; DATOS textos_de_los_carteles: Los siete textos, siete tiles cada uno, con
;   los blancos que los centran
;   0x7c35..0x7c66  (49 bytes)
DATA_textos_de_los_carteles:
	defb 0deh,0d4h,0ddh,0d5h,0d7h,0dch,000h	; 7c35
	defb 000h,0d0h,0dah,0d9h,0d9h,000h,000h	; 7c3c
	defb 000h,000h,0d3h,0e5h,0d4h,000h,000h	; 7c43
	defb 000h,0deh,0dah,0e4h,0dch,000h,000h	; 7c4a
	defb 0d6h,0e0h,0dah,0e6h,0dfh,0dch,000h	; 7c51
	defb 000h,0e4h,0d3h,0e5h,0d9h,000h,000h	; 7c58
	defb 0f4h,000h,0d0h,0dah,0d9h,0d9h,000h	; 7c5f

; ----------------------------------------------------------------------
; DATOS marco_del_cartel: Diez tiles que tapan el hueco del cartel cuando no
;   hay nada que decir
;   0x7c66..0x7c70  (10 bytes)
DATA_marco_del_cartel:
	defb 006h,00bh,00bh,00bh,00bh,00bh,00bh,00bh,00bh,006h	; 7c66  ..........

; ----------------------------------------------------------------------
; DATOS home_run: Los diez tiles de HOME RUN, que van al mismo hueco que el
;   marco
;   0x7c70..0x7c7a  (10 bytes)
DATA_home_run:
	defb 000h,0e0h,0d3h,0e1h,0dch,000h,0ddh,0e5h,0e6h,000h	; 7c70  ..........

; ======================================================================
; CODIGO 0x7c7a..0x7cc2  (72 bytes)
; ======================================================================


esconde_la_pelota:		; Borra la pelota lanzada y la bateada y manda los dos sprites -el primero y el ultimo- a la fila 0xCF
	xor a			;7c7a
	ld (0e340h),a		;7c7b   ; (0xE340) := 0
	ld (0e039h),a		;7c7e   ; (0xE039) := 0
	ld de,07b00h		;7c81   ; DE = VRAM 0x7b00, el primer sprite
	call esconde_un_sprite		;7c84
	ld e,07ch		;7c87
esconde_un_sprite:		; La fila 0xCF, la de esconder
	call arma_con_candado_y_da_el_puerto		;7c89
	ld a,0cfh		;7c8c   ; 0xCF
	out (c),a		;7c8e
	ret			;7c90
repinta_la_inicial:		; Cada 16 cuadros hace parpadear la inicial del equipo que batea, escribiendo el tile o un cero
	ld hl,04649h		;7c91   ; HL = las iniciales de la Central
	ld a,(0e440h)		;7c94   ; (0xE440), la liga
	rrca			;7c97
	jr nc,elige_el_hueco_de_la_inicial		;7c98
	ld hl,0464fh		;7c9a   ; o las de la Pacific
elige_el_hueco_de_la_inicial:		; Segun el turno, el hueco de uno o el del otro
	ld de,07829h		;7c9d   ; DE = VRAM 0x7829
	ld a,(0e402h)		;7ca0   ; (0xE402), el turno
	rrca			;7ca3
	ld a,(0e441h)		;7ca4   ; (0xE441), el equipo del primero
	jr nc,parpadea_la_inicial		;7ca7
	ld a,(0e442h)		;7ca9   ; o (0xE442), el del segundo
	ld e,049h		;7cac   ; y su hueco
parpadea_la_inicial:		; El bit 4 del contador de cuadros decide si se ve o no
	and 00fh		;7cae   ; solo el numero de equipo
	call suma_a_hl		;7cb0
	ld c,000h		;7cb3   ; C = 0, o sea borrado
	ld a,(0e000h)		;7cb5   ; el contador de cuadros
	bit 4,a		;7cb8   ; su bit 4
	jr z,L_7CBD		;7cba
	ld c,(hl)			;7cbc   ; y entonces, la inicial
L_7CBD:
	ld b,001h		;7cbd
	jp rellena_con_candado		;7cbf

; ----------------------------------------------------------------------
; DATOS resto_7cc2: Un byte suelto entre dos rutinas
;   0x7cc2..0x7cc3  (1 bytes)
DATA_resto_7cc2:
	defb 0c9h	; 7cc2

; ======================================================================
; CODIGO 0x7cc3..0x7f78  (693 bytes)
; ======================================================================


limpia_si_toca:		; Solo limpia si HL acaba en 0x80
	ld a,l			;7cc3   ; el byte bajo de HL
	cp 080h		;7cc4   ; tiene que ser 0x80
	ret nz			;7cc6
limpia_la_cuenta:		; Pone strikes y bolas a cero, gira el codigo del equipo que batea y repinta los tres contadores
	push hl			;7cc7
	ld hl,0e408h		;7cc8   ; HL = 0xE408
	xor a			;7ccb
	ld (hl),a			;7ccc   ; los strikes, a cero
	inc hl			;7ccd
	ld (hl),a			;7cce   ; y las bolas
	ld hl,0e443h		;7ccf   ; HL = 0xE443, el equipo del primero
	ld a,(0e402h)		;7cd2   ; (0xE402), el turno
	rrca			;7cd5
	jr nc,gira_el_bateador		;7cd6
	ld hl,0e444h		;7cd8
gira_el_bateador:		; A cero, se rehacen los codigos de equipo; luego el codigo se desplaza un bit, que es como va rotando el orden de bateo
	ld a,(hl)			;7cdb   ; el codigo de equipo
	or a			;7cdc
	call z,traduce_los_equipos		;7cdd   ; a cero, se rehacen
	srl (hl)		;7ce0   ; desplazado un bit
	push de			;7ce2
	push bc			;7ce3
	call pinta_los_contadores		;7ce4   ; y los contadores, repintados
	pop bc			;7ce7
	pop de			;7ce8
	pop hl			;7ce9
	ret			;7cea
mira_si_hay_empate:		; Compara las dos casillas de total de los dos equipos -0xE41A y 0xE42A, con sus dos cifras- y devuelve el acarreo puesto cuando son iguales
	ld hl,0e41ah		;7ceb   ; HL = 0xE41A, el total de uno
	ld de,0e42ah		;7cee   ; DE = 0xE42A, el del otro
	ld a,(de)			;7cf1
	cp (hl)			;7cf2   ; la primera cifra
	jr z,la_segunda_cifra_del_total		;7cf3
	ret			;7cf5
la_segunda_cifra_del_total:		; Las decenas
	inc hl			;7cf6
	inc de			;7cf7
	ld a,(de)			;7cf8
	cp (hl)			;7cf9   ; iguales?
	jr z,hay_empate		;7cfa
	ret			;7cfc
hay_empate:		; Acarreo puesto y el bit 6 de 0xE402
	scf			;7cfd   ; acarreo: empate
	ld hl,0e402h		;7cfe
	set 6,(hl)		;7d01   ; el bit 6 de 0xE402
	ret			;7d03
juega_la_maquina:		; El cerebro del rival. Solo corre con un jugador. Segun el turno se ocupa de batear (0x7e8f) o de defender, y en este caso los bits de 0xE430 eligen: el 1 correr las bases, el 2 lanzar la pelota entre bases, el 3 elegir el lanzamiento y el 4 soltarlo
	ld a,(0e012h)		;7d04   ; (0xE012), el numero de jugadores
	or a			;7d07
	ret nz			;7d08
	xor a			;7d09
	ld (0e011h),a		;7d0a   ; (0xE011) := 0: el mando de la maquina, limpio
	ld a,(0e402h)		;7d0d   ; (0xE402), el turno
	rrca			;7d10
	jp c,batea_la_maquina		;7d11   ; con el turno del otro, a batear
	ld hl,0e430h		;7d14   ; HL = 0xE430, el estado de la maquina
	ld a,(hl)			;7d17
	rrca			;7d18   ; el bit 1
	rrca			;7d19
	jp c,elige_a_donde_lanzar		;7d1a
	rrca			;7d1d   ; el bit 2
	jp c,apunta_a_la_base		;7d1e
	rrca			;7d21   ; el bit 3
	ret nc			;7d22
	rrca			;7d23   ; y el bit 4
	jr c,suelta_el_lanzamiento		;7d24
	ld a,(0e380h)		;7d26   ; (0xE380), su bit 1: hay carrera
	bit 1,a		;7d29
	jp nz,vuelve_al_estado_2		;7d2b
	ld a,(0e100h)		;7d2e   ; (0xE100), su bit 3
	bit 3,a		;7d31
	ret nz			;7d33
	inc hl			;7d34
	ld a,(hl)			;7d35
	and 003h		;7d36
	jr nz,elige_el_lanzamiento		;7d38
	push hl			;7d3a
	call mira_si_hay_empate		;7d3b
	ld b,01fh		;7d3e
	ld a,r		;7d40
	jr nc,L_7D46		;7d42
	ld b,00fh		;7d44
L_7D46:
	and b			;7d46
	pop hl			;7d47
	ld (hl),a			;7d48
elige_el_lanzamiento:		; De la tabla de 0x7f78 o de 0x7f98 -segun de que lado lance- saca un byte con los cuatro datos del lanzamiento: el nibble alto va a 0xE364 y del bajo salen los dos bits de velocidad y los dos de efecto
	ld a,(hl)			;7d49   ; el indice de ahora
	inc (hl)			;7d4a   ; uno mas para la vez siguiente
	push hl			;7d4b
	push af			;7d4c
	ld hl,07f78h		;7d4d   ; HL = 0x7f78, una de las dos tablas
	ld a,(0e100h)		;7d50   ; (0xE100), su bit 4
	bit 4,a		;7d53
	jr nz,reparte_el_lanzamiento		;7d55
	ld hl,07f98h		;7d57   ; o la de 0x7f98
reparte_el_lanzamiento:		; El nibble alto a 0xE364, y los dos pares de bits del bajo a 0xE363 y 0xE365
	pop af			;7d5a
	call suma_a_hl		;7d5b   ; el byte que toca
	ld a,(hl)			;7d5e
	pop hl			;7d5f
	ld b,a			;7d60   ; B se lo queda entero
	and 0f0h		;7d61   ; el nibble alto
	inc hl			;7d63
	inc hl			;7d64
	ld (hl),a			;7d65   ; a (0xE364)
	ld a,r		;7d66   ; el registro de refresco, de dado
	and 007h		;7d68
	or a			;7d6a
	jr nz,guarda_el_efecto		;7d6b
	ld a,010h		;7d6d
guarda_el_efecto:		; Con el dado a cero, un 0x10
	inc hl			;7d6f
	ld (hl),a			;7d70   ; el efecto
	ld a,b			;7d71
	and 003h		;7d72   ; los dos bits bajos
	inc hl			;7d74
	inc hl			;7d75
	ld (hl),a			;7d76   ; a (0xE366)
	ld a,b			;7d77
	rrca			;7d78
	rrca			;7d79
	and 003h		;7d7a   ; los dos siguientes
	inc hl			;7d7c
	inc hl			;7d7d
	ld (hl),a			;7d7e   ; a (0xE368)
	ld hl,0e430h		;7d7f
	set 4,(hl)		;7d82   ; el bit 4 de 0xE430: ya esta elegido
	ret			;7d84
suelta_el_lanzamiento:		; Espera a que el contador de 0xE365 llegue a cero teniendo el nibble alto de 0xE364, y entonces mete un 0x10 en el mando de la maquina: eso es pulsar el boton
	ld a,(0e380h)		;7d85   ; (0xE380), su bit 1
	bit 1,a		;7d88
	jr nz,vuelve_al_estado_2		;7d8a
	inc hl			;7d8c
	inc hl			;7d8d
	inc hl			;7d8e
	ld a,(0e364h)		;7d8f   ; (0xE364), el nibble alto
	and 0f0h		;7d92
	cp (hl)			;7d94   ; tiene que coincidir
	ret nz			;7d95
	inc hl			;7d96
	dec (hl)			;7d97   ; un cuadro menos
	ret nz			;7d98
	ld a,010h		;7d99   ; (0xE011) := 0x10: boton pulsado
	ld (0e011h),a		;7d9b
	ld hl,0e430h		;7d9e
	ld (hl),004h		;7da1   ; (0xE430) := 4
	ret			;7da3
vuelve_al_estado_2:		; Con carrera en marcha, la maquina se pone en el estado 2
	ld hl,0e430h		;7da4
	ld (hl),002h		;7da7   ; (0xE430) := 2
	ret			;7da9
apunta_a_la_base:		; Compara la columna de la pelota con la casilla que le toca y, si ya la ha pasado, manda la direccion de esa base al mando de la maquina
	ld a,006h		;7daa   ; HL += 6
	call suma_a_hl		;7dac
	ld a,(hl)			;7daf   ; a cero no hay nada que hacer
	or a			;7db0
	ret z			;7db1
	ld b,a			;7db2
	inc hl			;7db3
	inc hl			;7db4
	ld a,(0e130h)		;7db5   ; (0xE130), la columna de la pelota
	add a,018h		;7db8   ; corrida 0x18
	and 030h		;7dba   ; los dos bits que interesan
	rrca			;7dbc   ; bajados a la derecha
	rrca			;7dbd
	rrca			;7dbe
	rrca			;7dbf
	cp (hl)			;7dc0   ; contra la casilla
	ret c			;7dc1
	ld a,b			;7dc2
	sla a		;7dc3   ; la direccion, por cuatro
	sla a		;7dc5
	jr manda_la_orden		;7dc7
elige_a_donde_lanzar:		; De los bits de 0xE388 sale a que base conviene lanzar: la primera si esta ocupada y hay dos eliminados, y si no, la que decida el recorrido de las cuatro
	ld a,(0e388h)		;7dc9   ; (0xE388)
	ld b,a			;7dcc
	rrca			;7dcd   ; su bit 0
	jr nc,mira_si_hay_que_esperar		;7dce
	bit 3,a		;7dd0   ; y su bit 3
	ret nz			;7dd2
mira_si_hay_que_esperar:		; Con el bit 7 de 0xE388 se va por otro camino; y si ya se decidio, tambien
	bit 7,b		;7dd3   ; el bit 7
	jp nz,busca_al_que_esta_a_medias		;7dd5
	bit 5,(hl)		;7dd8   ; el bit 5: ya esta decidido
	jr nz,busca_al_corredor_mas_adelantado		;7dda
	set 5,(hl)		;7ddc   ; que queda puesto
	ld a,b			;7dde
	bit 5,a		;7ddf   ; el bit 5 de 0xE388
	ld c,001h		;7de1   ; C = 1, la primera base
	jr z,pone_el_boton		;7de3
	ld a,(0e180h)		;7de5   ; (0xE180), su bit 1
	bit 1,a		;7de8
	jr z,busca_al_corredor_mas_adelantado		;7dea
	ld c,008h		;7dec   ; C = 8, la cuarta
	ld a,(0e40ah)		;7dee   ; (0xE40A), los eliminados
	cp 002h		;7df1   ; dos
	jr nz,busca_al_corredor_mas_adelantado		;7df3
pone_el_boton:		; Al numero de base se le suma el bit 4, que es el boton
	set 4,c		;7df5   ; el bit 4: boton
	ld a,c			;7df7
manda_la_orden:		; Y al mando de la maquina
	jr y_a_mandarlo		;7df8
busca_al_corredor_mas_adelantado:		; Recorre las cuatro bases y, de los que estan corriendo, se queda con el que va mas adelantado por cada sentido; el bit 5 de 0xE388 decide cual de los dos manda
	ld a,(0e1e0h)		;7dfa   ; (0xE1E0), su bit 0
	rrca			;7dfd
	ld a,012h		;7dfe   ; A = 0x12 si la cuarta ya corre
	jr c,manda_la_orden		;7e00
	ld de,00000h		;7e02   ; DE = 0, los dos candidatos
	ld hl,0e180h		;7e05   ; HL = 0xE180
	ld b,004h		;7e08   ; las cuatro
mira_a_un_corredor:		; Solo cuentan los que tienen corredor y estan en marcha
	push bc			;7e0a
	push hl			;7e0b
	pop ix		;7e0c   ; IX = la base
	bit 1,(hl)		;7e0e   ; el bit 1: hay corredor
	jr z,la_base_siguiente_del_repaso		;7e10
	bit 0,(hl)		;7e12   ; el bit 0: en marcha
	jr z,la_base_siguiente_del_repaso		;7e14
	ld a,(ix+018h)		;7e16   ; el byte 0x18, la base a la que va
	call compara_con_la_base		;7e19   ; comparada con donde esta
	jr nz,L_7E24		;7e1c
	jr c,mira_el_otro_sentido		;7e1e
	ld d,b			;7e20
	inc d			;7e21   ; el candidato de un sentido
	jr mira_el_otro_sentido		;7e22
L_7E24:
	jr nc,mira_el_otro_sentido		;7e24
	ld e,b			;7e26
mira_el_otro_sentido:		; Con el byte 0x19, el del otro
	ld a,(ix+019h)		;7e27   ; el byte 0x19
	call compara_con_la_base		;7e2a   ; comparado
	jr nz,L_7E35		;7e2d
	jr c,la_base_siguiente_del_repaso		;7e2f
	ld e,b			;7e31
	inc e			;7e32   ; el candidato del otro sentido
	jr la_base_siguiente_del_repaso		;7e33
L_7E35:
	jr nc,la_base_siguiente_del_repaso		;7e35
	ld d,b			;7e37
la_base_siguiente_del_repaso:		; 32 bytes mas alla
	call avanza_una_fila		;7e38   ; la siguiente
	pop bc			;7e3b
	djnz mira_a_un_corredor		;7e3c
	ld a,(0e388h)		;7e3e   ; (0xE388), su bit 5
	bit 5,a		;7e41
	ld a,d			;7e43   ; D, el candidato de un sentido
	jr nz,elige_al_candidato		;7e44
	ld a,e			;7e46   ; o E, el del otro
elige_al_candidato:		; Si el elegido no vale, se prueban los otros dos, y si tampoco, la primera base
	or a			;7e47
	jr nz,traduce_la_base		;7e48   ; vale
	ld a,d			;7e4a   ; D
	or a			;7e4b
	jr nz,traduce_la_base		;7e4c
	ld a,e			;7e4e   ; E
	or a			;7e4f
	jr nz,traduce_la_base		;7e50
	ld a,(0e180h)		;7e52   ; (0xE180), su bit 0
	bit 0,a		;7e55
	ret z			;7e57
	ld c,001h		;7e58   ; C = 1, la primera base
traduce_la_base:		; De 1 a 4, el bit de direccion que le corresponde: 2, 4, 1 y 8
	ld c,002h		;7e5a   ; C = 2
	dec a			;7e5c
	jr z,pone_el_boton_tambien		;7e5d
	ld c,004h		;7e5f   ; C = 4
	dec a			;7e61
	jr z,pone_el_boton_tambien		;7e62
	ld c,001h		;7e64   ; C = 1
	dec a			;7e66
	jr z,pone_el_boton_tambien		;7e67
	ld c,008h		;7e69   ; y C = 8
pone_el_boton_tambien:		; El bit 4 encima
	ld a,010h		;7e6b   ; el bit 4: boton
	or c			;7e6d
y_a_mandarlo:		; Al mando de la maquina
	jp escribe_en_el_mando_de_la_maquina		;7e6e
busca_al_que_esta_a_medias:		; Con el bit 7 de 0xE388, busca en 0xE1B7 la base con corredor pero parada
	set 5,(hl)		;7e71   ; el bit 5, puesto
	ld hl,0e1b7h		;7e73   ; HL = 0xE1B7
	ld b,003h		;7e76   ; tres
mira_una_de_las_tres:		; Con el bit 0 a cero o el bit 1 puesto, es esta
	bit 0,(hl)		;7e78   ; el bit 0
	jr z,L_7E80		;7e7a
	bit 1,(hl)		;7e7c   ; el bit 1
	jr z,esa_es		;7e7e
L_7E80:
	call avanza_una_fila		;7e80   ; la siguiente
	djnz mira_una_de_las_tres		;7e83
	ld hl,0e388h		;7e85
	res 7,(hl)		;7e88   ; y si no hay ninguna, el bit 7 se cae
	ret			;7e8a
esa_es:		; El numero de base, mas uno
	inc b			;7e8b
	ld a,b			;7e8c   ; el numero de base
	jr traduce_la_base		;7e8d
batea_la_maquina:		; El otro lado del cerebro: cuando le toca batear. Con la pelota en juego decide si le da y con que punto del bate; sin ella, mueve a los corredores
	call la_pelota_esta_en_juego		;7e8f   ; la pelota en juego
	jp nz,mueve_a_sus_corredores		;7e92
	ld hl,0e100h		;7e95   ; HL = 0xE100, el lanzador
	ld a,(hl)			;7e98
	rrca			;7e99   ; su bit 0
	ret nc			;7e9a
	rrca			;7e9b   ; su bit 1
	jr c,decide_si_batear		;7e9c
	rrca			;7e9e   ; y su bit 2
	jr nc,decide_si_batear		;7e9f
	ld a,r		;7ea1   ; el registro de refresco, de dado
	and 00fh		;7ea3   ; una de cada dieciseis
	jr nz,decide_si_batear		;7ea5
	ld a,(0e362h)		;7ea7   ; (0xE362), la cuenta
	or a			;7eaa
	jr nz,decide_si_batear		;7eab
	ld a,(0e1a0h)		;7ead   ; (0xE1A0), su bit 1
	bit 1,a		;7eb0
	jr z,decide_si_batear		;7eb2
	ld a,(0e1e0h)		;7eb4   ; (0xE1E0), su bit 1
	bit 1,a		;7eb7
	jr nz,decide_si_batear		;7eb9
	ld a,012h		;7ebb   ; A = 0x12: robar base
	jp escribe_en_el_mando_de_la_maquina		;7ebd
decide_si_batear:		; Solo se batea cuando la pelota esta entre las columnas 0x87 y 0xBA, y solo cuando llega al punto que da la velocidad de 0xE363
	bit 2,(hl)		;7ec0   ; el bit 2 del lanzador
	ret z			;7ec2
	ld a,(0e130h)		;7ec3   ; (0xE130), la columna de la pelota
	cp 087h		;7ec6   ; antes de la 0x87, todavia no
	ret c			;7ec8
	cp 0bah		;7ec9   ; y pasada la 0xBA, ya no
	ret nc			;7ecb
	ld a,(0e363h)		;7ecc   ; (0xE363), la velocidad
	ld b,a			;7ecf
	inc b			;7ed0
	ld a,0a0h		;7ed1   ; A = 0xa0 de partida
calcula_el_punto_de_golpeo:		; Dos menos por cada punto de velocidad: cuanto mas rapido llega la pelota, antes hay que empezar el bate
	dec a			;7ed3   ; dos menos
	dec a			;7ed4
	djnz calcula_el_punto_de_golpeo		;7ed5
	ld hl,0e130h		;7ed7   ; contra la columna de la pelota
	cp (hl)			;7eda
	ld c,010h		;7edb   ; C = 0x10, el boton
	inc hl			;7edd
	jr nc,mueve_el_bate		;7ede   ; todavia no ha llegado
	ld a,(hl)			;7ee0
	add a,003h		;7ee1
	bit 7,a		;7ee3
	jr z,mira_si_la_pelota_va_alta		;7ee5
	neg		;7ee7
mira_si_la_pelota_va_alta:		; Con la jugada avanzada o la pelota lejos del centro, no se batea
	ex af,af'			;7ee9   ; la distancia, a la sombra
	ld a,(0e142h)		;7eea   ; (0xE142), los tres bits bajos
	and 007h		;7eed
	cp 002h		;7eef   ; de dos en adelante, se batea igual
	jr nc,quita_el_boton_si_toca		;7ef1
	ex af,af'			;7ef3
	cp 07ch		;7ef4   ; y si no, a menos de 0x7c del centro
	ret c			;7ef6
	jr quita_el_boton_si_toca		;7ef7
mueve_el_bate:		; Antes de llegar, la maquina coloca el bate arriba o abajo segun donde vaya a caer la pelota
	ld c,000h		;7ef9   ; C = 0, sin boton
	ld b,c			;7efb
	ld de,00804h		;7efc   ; DE = 0x0804, los dos sentidos
	ld a,(0e140h)		;7eff   ; (0xE140), su bit 4
	bit 4,a		;7f02
	jr z,elige_el_sentido		;7f04
	ld de,00408h		;7f06   ; y del otro lado, al reves
elige_el_sentido:		; Mide donde daria la pelota y elige subir o bajar el bate
	push bc			;7f09
	push de			;7f0a
	call mide_donde_da_en_el_bate		;7f0b   ; la medida
	pop de			;7f0e
	pop bc			;7f0f
	cp 005h		;7f10   ; justo en el 5 no se mueve
	jr z,L_7F18		;7f12
	ld b,e			;7f14   ; hacia un lado
	jr c,L_7F18		;7f15
	ld b,d			;7f17   ; o hacia el otro
L_7F18:
	ld a,c			;7f18
	or b			;7f19
	ld c,a			;7f1a
quita_el_boton_si_toca:		; Con el bit 6 de 0xE430 puesto, el bit 4 -el boton- se cae
	ld a,(0e430h)		;7f1b   ; (0xE430), su bit 6
	bit 6,a		;7f1e
	jr z,L_7F24		;7f20
	res 4,c		;7f22   ; el boton, fuera
L_7F24:
	jp manda_la_orden_de_correr		;7f24
mueve_a_sus_corredores:		; Sin pelota en juego, la maquina se ocupa de una base por cuadro, rotando entre la cuarta, la tercera y la segunda con los bits 1 y 2 del contador de cuadros
	ld a,(0e000h)		;7f27   ; el contador de cuadros
	and 006h		;7f2a   ; sus bits 1 y 2
	rrca			;7f2c
	ld hl,0e1e0h		;7f2d   ; HL = 0xE1E0, la cuarta base
	ld c,014h		;7f30   ; C = 0x14, su orden
	dec a			;7f32
	jr z,mira_si_le_conviene_correr		;7f33
	ld hl,0e1c0h		;7f35   ; HL = 0xE1C0, la tercera
	ld c,011h		;7f38   ; C = 0x11, la suya
	dec a			;7f3a
	jr z,mira_si_le_conviene_correr		;7f3b
	ld hl,0e1a0h		;7f3d   ; HL = 0xE1A0, la segunda
	ld c,018h		;7f40   ; C = 0x18, la suya
mira_si_le_conviene_correr:		; Con lanzamiento en marcha, el corredor solo sale si ya ha pasado el punto de no retorno que dice el byte 0x1e de su ficha
	ld a,(0e388h)		;7f42   ; (0xE388), su bit 0
	rrca			;7f45
	jr nc,mira_si_puede_salir_ya		;7f46
	push hl			;7f48
	pop ix		;7f49   ; IX = la base
	bit 6,(ix+017h)		;7f4b   ; el bit 6 de su byte 0x17
	ret z			;7f4f
	bit 4,(hl)		;7f50   ; su bit 4
	ret z			;7f52
	ld a,(ix+008h)		;7f53   ; el byte 8, donde esta
	cp (ix+01eh)		;7f56   ; contra el byte 0x1e
	bit 7,(hl)		;7f59   ; el bit 7 decide el sentido
	jr nz,L_7F5E		;7f5b
	ccf			;7f5d
L_7F5E:
	ret nc			;7f5e
	jr y_si_hay_alguien		;7f5f
mira_si_puede_salir_ya:		; Sin lanzamiento: no sale si ya esta en marcha, ni si el de delante no ha despejado
	bit 0,(hl)		;7f61   ; el bit 0: ya corre
	ret nz			;7f63
	bit 7,(hl)		;7f64   ; el bit 7
	jr nz,y_si_hay_alguien		;7f66
	push hl			;7f68
	call avanza_una_fila		;7f69   ; la base siguiente
	bit 5,(hl)		;7f6c   ; su bit 5
	pop hl			;7f6e
	ret nz			;7f6f
y_si_hay_alguien:		; Solo sale si hay corredor
	bit 1,(hl)		;7f70   ; el bit 1
	ret z			;7f72
manda_la_orden_de_correr:		; El valor de C
	ld a,c			;7f73
escribe_en_el_mando_de_la_maquina:		; Y ahi esta el truco: la orden se deja en 0xE011, el mismo byte donde 0x43e2 pone los bits recien pulsados del segundo jugador
	ld (0e011h),a		;7f74   ; (0xE011), el mando del segundo jugador
	ret			;7f77

; ----------------------------------------------------------------------
; DATOS lanzamientos_desde_un_lado: 32 bytes: la lista de lanzamientos que la
;   maquina va sacando en orden. En cada byte, el nibble alto es el momento de
;   soltar y el bajo lleva dos bits de velocidad y dos de efecto
;   0x7f78..0x7f98  (32 bytes)
DATA_lanzamientos_desde_un_lado:
	defb 091h,092h,049h,06eh,075h,07ah,05eh,086h,081h,071h,096h,059h,091h,049h,096h,04eh	; 7f78  ..Inuz^..q.Y.I.N
	defb 081h,071h,09ah,096h,075h,06eh,079h,06ah,045h,075h,04ah,095h,06eh,08ah,075h,085h	; 7f88  .q..unyjEuJ.n.u.

; ----------------------------------------------------------------------
; DATOS lanzamientos_desde_el_otro: Los otros 32, para cuando lanza del otro
;   lado; son los mismos mas uno
;   0x7f98..0x7fb8  (32 bytes)
DATA_lanzamientos_desde_el_otro:
	defb 092h,091h,04ah,06dh,076h,079h,05dh,085h,082h,072h,095h,05ah,092h,04ah,095h,04dh	; 7f98  ..Jmvy]..r.Z.J.M
	defb 082h,072h,099h,095h,076h,06dh,07ah,069h,046h,076h,049h,096h,06dh,089h,076h,086h	; 7fa8  .r..vmziFvI.m.v.

; ======================================================================
; CODIGO 0x7fb8..0x7ff6  (62 bytes)
; ======================================================================


compara_con_la_base:		; Devuelve puesto o no el acarreo segun si el corredor de esta ficha ha pasado ya de la posicion que trae A, teniendo en cuenta el sentido -bit 7- y en que mitad del bloque esta la ficha
	ld c,a			;7fb8   ; C = la posicion a comparar
	ld a,(ix+008h)		;7fb9   ; el byte 8, donde esta
	cp c			;7fbc
	bit 7,(hl)		;7fbd   ; el bit 7, el sentido
	jr z,mira_en_que_base_esta		;7fbf
	ccf			;7fc1   ; al reves
mira_en_que_base_esta:		; Los bits 5 y 6 del byte bajo de HL dicen en cual de las cuatro esta
	bit 5,l		;7fc2   ; el bit 5
	jr nz,devuelve_el_sentido		;7fc4
	bit 6,l		;7fc6   ; y el bit 6
	jr nz,devuelve_el_sentido		;7fc8
	ccf			;7fca   ; al reves otra vez
devuelve_el_sentido:		; Y de paso, el bit 4 de la ficha
	bit 4,(hl)		;7fcb   ; el bit 4
	ret			;7fcd
pilota_la_demostracion:		; El piloto automatico del menu. Solo corre con 0xE002 puesto -o sea, cuando manda la demostracion- y lo unico que hace es meter un 0x10 en 0xE00E, el hueco de los bits recien pulsados del PRIMER jugador, en el momento en que la pelota llega a donde tiene que batearse. La demostracion se juega sola pisando el mando
	ld a,(0e002h)		;7fce   ; (0xE002), la demostracion
	or a			;7fd1
	ret z			;7fd2
	ld a,(0e030h)		;7fd3   ; (0xE030), la pelota en juego
	or a			;7fd6
	ret nz			;7fd7
	ld (0e00eh),a		;7fd8   ; (0xE00E) := 0, el mando del primero
	ld a,(0e130h)		;7fdb   ; (0xE130), la columna de la pelota
	cp 087h		;7fde   ; antes de la 0x87, todavia no
	ret c			;7fe0
	ld a,(0e363h)		;7fe1   ; (0xE363), la velocidad
	ld b,a			;7fe4
	ld a,09ch		;7fe5   ; A = 0x9c de partida
el_punto_de_la_demostracion:		; Dos menos por cada punto de velocidad
	dec a			;7fe7   ; dos menos
	dec a			;7fe8
	djnz el_punto_de_la_demostracion		;7fe9
	ld hl,0e130h		;7feb
	cp (hl)			;7fee   ; contra la columna de la pelota
	ret nc			;7fef
	ld a,010h		;7ff0   ; A = 0x10: boton pulsado
	ld (0e00eh),a		;7ff2   ; en el mando del primer jugador
	ret			;7ff5

; ----------------------------------------------------------------------
; DATOS marca_oculta_konami: RC-724 y el titulo en katakana (YA KI U = 野球,
;   beisbol), cerrando en 0x7FFF
;   0x7ff6..0x8000  (10 bytes)
DATA_marca_oculta_konami:
	defb 0ffh,0ffh,0ffh,082h,0b2h,086h,0a3h,004h,024h,0aah	; 7ff6  ........$.
