; File Name   :	d:\hobby3\z1013_hb_programme\C.ZAEHLERMODUL.z80
; Format      :	Binary file
; Base Address:	0000h Range: 3BE0h - 3EA0h Loaded length: 02C0h

		cpu	z80undoc

; bws(zeile 0..31, spalte 0..31) analog print_at
bws		function z,s,z*32+s+0EC00h

		org 4000h

freqz:		ld	hl, iotab	; Port-Initialisierung
		ld	bc, 303h
		otir
		ld	sp, 3EEDh
		call	cls		; clear	screen
		call	rahmen
		ld	hl, aBedienungsanle ; "Bedienungsanleitung ?"
		ld	de, 0EE06h	; bws(16,6)
		ld	bc, 15h
		ldir
		rst	20h
		db    1			; INCH
		cp	0Dh		; ENTER ?
		call	z, hilfe	; Hilfetext anzeigen
		call	cls		; clear	screen
		call	rahmen
		ld	hl, aFrequenzHz	; "FREQUENZ:	   Hz"
		ld	de, 0EE88h	; bws(20,8)
		ld	bc, 12h
		ldir
		
; Messung		
f1:		ld	de, 3218h	; Takt Zeitkonstante ZK	(2MHz)
		ld	hl, 3EEDh	; Konvertierungsbuffer
		ld	(hl), '0'
		ld	hl, 0		; Takt Vorzaehler VZ
		ld	b, h
f2:		ld	a, e
		or	d
		jr	z, todez	; Ende Messung-> Anzeige
; Messschleife		
		in	a, (2)
		ld	c, a
		add	a, b
		ld	b, c
		bit	6, a
		jp	z, f3
		inc	hl
		dec	de
		jp	f2
f3:		dec	de
		nop
		jr	f2

; Zahl HL dezimal anzeigen
todez:		dec	hl
		ld	ix, 0EE92h	; bws(20,18)
		ld	de, 10000
		call	todez1
		ld	de, 1000
		call	todez1
		ld	de, 100
		call	todez1
		ld	de, 10
		call	todez1
		ld	de, 1
		call	todez1
		jp	f1		; weiter messen
;
todez1:		xor	a
		ld	b, 0FFh
todez2:		inc	b
		sbc	hl, de
		jr	nc, todez2
		add	hl, de
		ld	a, b
		add	a, 30h ; '0'
		cp	30h ; '0'
		jr	z, todez4
		ld	(3EEDh), a
todez3:		ld	(ix+0),	a
		inc	ix
		ret
todez4:		push	hl
		ld	hl, 3EEDh
		cp	(hl)
		pop	hl
		jr	nz, todez3
		ld	a, 20h ; ' '
		jr	todez3

; Ausgabe einer Linie
; d. B x volles Kästchen (FF), Abstand in DE
line:		ld	(hl), 0FFh
		add	hl, de
		djnz	line
		ret

; Hilfetext anzeigen
hilfe:		ld	hl, aFrequenzmessun	; "\xFF  Frequenzmessung am TB-Eing. \xFF"
		ld	de, 0EE00h	; bws(16,0)
		ld	bc, 140h
		ldir
hilfe1:		rst	20h
		db    1			; INCH
		cp	0Dh		; ENTER ?
		jr	nz, hilfe1
		ret

; clear	screen
cls:		ld	hl, 0EC00h	; bws(0,0)	
cls1:		ld	(hl), ' '
		inc	hl
		bit	4, h
		jp	z, cls1
		ret

; Rahmen zeichnen

; "                                "
; "                                "
; "                                "
; "                                "
; "¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦"
; "¦                              ¦"
; "¦                              ¦"
; "¦                              ¦"
; "¦ Z 1013 - SOFT - ZAEHLERMODUL ¦"
; "¦                              ¦"
; "¦                              ¦"
; "¦                              ¦"
; "¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦"
; "¦                              ¦"
; "¦                              ¦"
; "¦                              ¦"
; "¦                              ¦"
; "¦                              ¦"
; "¦                              ¦"
; "¦                              ¦"
; "¦       FREQUENZ: 12822 Hz     ¦"
; "¦                              ¦"
; "¦                              ¦"
; "¦                              ¦"
; "¦                              ¦"
; "¦                              ¦"
; "¦                              ¦"
; "¦                              ¦"
; "¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦"
; "                                "
; "                                "
; "                                "

rahmen:		ld	hl, 0EC80h	; bws(4,0)
		ld	de, 1		; linie nach rechts
		ld	b, 20h
		call	line
		ld	hl, 0EF80h	; bws(28,0)
		ld	b, 20h		; linie nach rechts
		call	line
		ld	hl, 0ED80h	; bws(12,0)
		ld	b, 20h		; linie nach rechts
		call	line
		ld	de, 20h		; linie nach unten
		ld	b, 18h
		ld	hl, 0EC80h	; bws(4,0)
		call	line
		ld	hl, 0EC9Fh	; bws(4,31)
		ld	b, 18h
		call	line		; linie nach unten
		ld	hl, aZ1013SoftZaehl ; "Z 1013 -	SOFT - ZAEHLERMODUL"
		ld	de, 0ED02h	; bws(8,2)
		ld	bc, 1Ch
		ldir			; Ausgabe Titel
		ret

; wait (ungenutzt)
; in DE
loc_3D00:	dec	de
		ld	a, e
		or	d
		jp	nz, loc_3D00
		ret

; Port-Initialisierung
iotab:		db 0CFh
		db 0FFh
		db    7

aZ1013SoftZaehl:db "Z 1013 - SOFT - ZAEHLERMODUL"
aFrequenzHz:	db "FREQUENZ:       Hz"
aBedienungsanle:db "Bedienungsanleitung ?"
aFrequenzmessun:db 0FFh,"  Frequenzmessung am TB-Eing. ",0FFh
		db 0FFh,"    Ue   minimal    100 mV    ",0FFh
		db 0FFh,"    Ue   maximal      5  V    ",0FFh
		db 0FFh,"    fe   maximal     12 kHz   ",0FFh
		db 0FFh,"                              ",0FFh
		db 0FFh,"   CPU-Takt   ZK=(3C35H/36H)  ",0FFh
		db 0FFh,"     1 MHz        190CH       ",0FFh
		db 0FFh,"     2 MHz        3218H       ",0FFh
		db 0FFh,"   Vorzaehler VZ=(3C3DH/3EH)  ",0FFh
		db 0FFh," bei TAKT=1 MHz: fe max 6 kHz ",0FFh
		db 0FFh
		db 0FFh
		db 0FFh

;ENDE

		db 0FEh	; þ
		db  27h	; '
		db 0DAh	; Ú
		db 0B8h	; ¸
		db  3Dh	; =
		db 0FEh	; þ
		db  30h	; 0
		db 0DAh	; Ú
		db 0BDh	; ½
		db  3Dh	; =
		db 0CDh	; Í
		db 0BFh	; ¿
		db  3Ch	; <
		db  18h
		db 0B4h	; ´
		db  21h	; !

		end
