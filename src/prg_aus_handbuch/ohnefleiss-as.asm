; File Name   :	d:\hobby3\z1013_hb_programme\C.Ohne Fleiss k.Pr.z80
; Format      :	Binary file
; Base Address:	0000h Range: 00E0h - 0380h Loaded length: 02A0h

		cpu	z80undoc


CUPOS:	EQU	0002BH			;aktuelle Cursorposition
BWS:	EQU	0EC00H			;Beginn BWS
RST38:	EQU	00038H			;RST 38H

; bws(zeile 0..31, spalte 0..31) analog print_at
bws		function z,s,z*32+s+0EC00h

		org 100h


; "                                "
; "   OHNE FLEISS-KEIN PREIS       "
; "                                "
; "                                "
; "                                "
; "                                "
; "                                "
; "        ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦         "
; "        ¦             ¦         "
; "        ¦    15 14 13 ¦         "
; "        ¦             ¦         "
; "        ¦ 12 11 10 09 ¦         "
; "        ¦             ¦         "
; "        ¦ 08 07 06 05 ¦         "
; "        ¦             ¦         "
; "        ¦ 04 03 02 01 ¦         "
; "        ¦             ¦         "
; "        ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦         "
; "                                "
; "          ZUG-NR: 0000          "
; "                                "
; "                                "
; "S=START, N=ZAEHLER NULL         "
; "CTRL-C=ABBRUCH                  "
; "     _                          "
; "     ?                          "
; "     U                          "
; " <-  -  ->                      "
; "     ?                          "
; "     _                          "
; "                                "
; 

start:		; Ueberschrift
		rst	20h
		db	2		; RPRST
		db 0Ch,0Dh,0Dh,"   OHNE FLEISS-KEIN PREIS",0A0h
		ld	hl, (CUPOS)
		ld	(hl), ' '
		; Spielfeldumrandung zeichnen
		; obere Linie links->rechts
		ld	hl, bws(8,8)
		ld	b, 15
start1:		ld	(hl), 0FFh
		inc	hl
		djnz	start1
		; rechte Linie oben->unten
		ld	hl, bws(9,22)
		ld	de, 20h
		ld	b, 10
start2:		ld	(hl), 0FFh
		add	hl, de
		djnz	start2
		; untere Linie rechts->links
		ld	hl,bws(18,21)
		ld	b, 14
start3:		ld	(hl), 0FFh
		dec	hl
		djnz	start3
		; linke Linie unten->oben
		ld	hl, bws(17,8)
		ld	b, 10
		xor	a		; Cy=0 f. sbc
start4:		ld	(hl), 0FFh
		sbc	hl, de
		djnz	start4
		;		
		ld	hl,bws(10,9)
		ld	(CUPOS), hl
; Spielfeld init 		
start5:		ld	a, 16h		; Zahlen von 16..01 abwaerts
		ld	c, 4		; 4 Zeilen
		ld	b, 4		; 4 Werte nebeneinander
start6:		push	af
		rst	20h
		db    2			; RPRST
		db ' '+80h
		pop	af
		rst	20h
		db    6			; ROTHX
		sub	1
		daa
		djnz	start6
		;
		dec	c
		jr	z, start7	; 16 Zahlen geschrieben
		;
		ld	hl, (CUPOS)
		ld	(hl), ' '
		ld	de, 34h
		add	hl, de
		ld	(hl), ' '
		ld	(CUPOS), hl
		ld	b, 4		; 4 Werte nebeneinander
		jr	start6		; nächste Zeile
; Freifeld leeren (noch steht dort 16)
start7:		ld	hl, (CUPOS)
		ld	(hl), ' '
		ld	hl, bws(10,10)
		ld	(CUPOS), hl
		ld	(hl), ' '
		inc	hl
		ld	(hl), ' '
; Tasten-Beschreibung
; Ausgabe via RPRST geht nicht, da Grafikzeichen enthalten sind
		ld	hl, bws(23,0)
		ld	(CUPOS), hl
		ld	hl, aSStartNZaehler ; "S=START,	N=ZAEHLER NULL\rCTRL-C=ABBRUCH\r"...
start8:		ld	a, (hl)
		rst	20h
		db 0			; ROUTC
		inc	hl
		cp	9Ah 		; Ende
		jr	nz, start8
;		
		ld	hl, (CUPOS)
		ld	(hl), ' '
		jr	start9		; Startposition	0,0

aSStartNZaehler:db "S=START, N=ZAEHLER NULL",0Dh
		db "CTRL-C=ABBRUCH",0Dh
		db "     ",9Dh, 0Dh
		db "     ",0A1h,0Dh
		db "     U",0Dh
		db " <-  -  ->",0Dh
		db "     ",0A1h, 0Dh
		db "     ",9Ah
		
start9:		xor	a		; Startposition	0,0
		ld	(spalte), a	; Spalte Freifeld
		ld	(zeile), a	; Zeile	Freifeld
;
null:		xor	a		; Zaehler auf 0
		ld	(zugnr), a
		ld	(zugnr+1), a
		call	outzug		; ZugNr. anzeigen
		jr	loop1

; Tastaturschleife
loop:		call	inczug		; Zg.Nr	erhoehen und anzeigen
loop1:		rst	20h
		db    1			; INCH
		cp	'S'
		jp	z, start
		cp	'U'
		jp	z, hoch
		cp	8
		jp	z, links
		cp	'N'
		jp	z, null		; Zaehler null
		cp	9
		jp	z, rechts
		cp	' '
		jp	z, runter
		cp	3		; Ctrl-C Abbruch
		jp	z, RST38
		jr	loop1

; Schieben nach links
links:		ld	a, (spalte)	; Spalte Freifeld
		cp	3		; pos ist ganz rechts?
		jp	z, loop1	; dann kein verschieben	moeglich
		inc	a		; Freifeld eins nach rechts setzen
		ld	(spalte), a	; Spalte Freifeld
		dec	a		; orig. Spalte Freifeld
		call	roffs		; BC=A*3
		ld	a, (zeile)	; Zeile	Freifeld
		call	toffs		; DE=A*2
		ld	hl, ztab	; Tabelle der Zeilenpos.
		call	zugbws
		ld	bc, 3		; 3 Zeichen nach rechts
		
; Spielzug ausfuehren
zug0:		add	hl, bc
zug1:		; 3 Zeichen in Zwischenpuffer
		ld	b, 3		; 3 Zeichen
		ld	(savpos), hl	; Speicher aktuelle Position
		push	de		; DE sichern
		ld	de, zugbuf
zug2:		ld	a, (hl)
		ld	(de), a
		inc	hl
		inc	de
		djnz	zug2
		; die 3 Zeichen nach DE kopieren
		pop	de		; DE restaurieren
		ld	hl, zugbuf
		ld	b, 3
zug3:		ld	a, (hl)
		ld	(de), a
		inc	hl
		inc	de
		djnz	zug3
		;Freifeld zeichnen (3 Leerzeichen)
		ld	hl, (savpos)	; Speicher aktuelle Position
		ld	b, 3
zug4:		ld	(hl), ' '
		inc	hl
		djnz	zug4
		jp	loop

;  Schieben nach unten
runter:		ld	a, (zeile)	; Zeile	Freifeld
		or	0		; pos ist ganz oben?
		jp	z, loop1	; dann kein verschieben	moeglich
		dec	a
		ld	(zeile), a	; Zeile	Freifeld
		inc	a
		call	doffs		; BC=A*40h
		ld	a, (spalte)	; Spalte Freifeld
		call	toffs		; DE=A*2
		ld	hl, stab	; Tabelle der Spaltenpos.
		call	zugbws		; Berechne naechste BWS-Pos.
		ld	bc, 40h		; 2 Bildzeilen nach unten
runter1:	and	a
		sbc	hl, bc
		jp	zug1

;  Schieben nach oben
hoch:		ld	a, (zeile)	; Zeile	Freifeld
		cp	3		; pos ist ganz unten?
		jp	z, loop1	; dann kein verschieben	moeglich
		inc	a
		ld	(zeile), a	; Zeile	Freifeld
		dec	a
		call	doffs		; BC=A*40h
		ld	a, (spalte)	; Spalte Freifeld
		call	toffs		; DE=A*2
		ld	hl, stab	; Tabelle der Spaltenpos.
		call	zugbws		; Berechne naechste BWS-Pos.
		ld	bc, 40h		; 2 Bildzeilen nach oben
		jp	zug0

;  Schieben nach rechts
rechts:		ld	a, (spalte)	; Spalte Freifeld
		or	0		; pos ist ganz links?
		jp	z, loop1	; dann kein verschieben	moeglich
		dec	a
		ld	(spalte), a	; Spalte Freifeld
		inc	a
		call	roffs		; BC=A*3
		ld	a, (zeile)	; Zeile	Freifeld
		call	toffs		; DE=A*2
		ld	hl, ztab	; Tabelle der Zeilenpos.
		call	zugbws		; Berechne naechste BWS-Pos.
		ld	bc, 3		; 3 Spalten nach rechts
		jp	runter1

; Offset nächste Spalte berechnen
; BC=A*3
roffs:		ld	b, a		; a = alte Spalte Leerfeld
		sla	a
		add	a, b		; *3
		ld	b, 0
		ld	c, a		; BC=offs. nächste Spalte
		ret

; Offset nächste Zeile berechnen
; BC=A*40h
doffs:		ld	b, a
		or	a
		jr	z, doffs2
		ld	c, 40h		; Länge 2 BWS-Zeilen
		xor	a
doffs1:		add	a, c
		djnz	doffs1
doffs2:		ld	b, 0
		ld	c, a
		ret

; Offset fuer ztab oder stab berechnen
; DE=A*2
toffs:		sla	a
		ld	d, 0
		ld	e, a
		ret

; Berechne naechste BWS-Pos.
zugbws:		add	hl, de		; HL=ztab oder stab
					; DE=offs zur Zeile/Spalte
		ld	e, (hl)
		inc	hl
		ld	d, (hl)
		ex	de, hl		; HL=BWS-Pos finale Zeile/Spalte
		add	hl, bc		; add. Offs nächste Pos
		push	hl
		pop	de		; HL=DE
		ret


; Zg.Nr	erhoehen und anzeigen
inczug:		and	a
		ld	a, (zugnr)
		add	a, 1
		daa
		ld	(zugnr), a
		ld	a, (zugnr+1)
		adc	a, 0
		daa
		ld	(zugnr+1), a
		call	outzug		; ZugNr. anzeigen
		ret

; ZugNr. anzeigen
outzug:		ld	hl, (CUPOS)
		ld	(hl), ' '
		ld	hl, bws(20,10)
		ld	(CUPOS), hl
		rst	20h
		db    2			; RPRST
		db "ZUG-NR:",0A0h
		ld	hl, (zugnr)
		rst	20h
		db    7			; ROTHL
		ld	hl, (CUPOS)
		ld	(hl), ' '
		ret

; Startpositionen BWS Zeilen und Spalten
ztab:		dw bws(10,9)
		dw bws(12,9)
		dw bws(14,9)
		dw bws(16,9)

stab:		dw bws(10,9)
		dw bws(10,12)
		dw bws(10,15)
		dw bws(10,18)

spalte:		db 0			; Spalte Freifeld
zeile:		db 0			; Zeile	Freifeld
zugnr:		dw 1			; Anzahl der Züge
savpos:		dw 0			; Speicher aktuelle Position
		db 0			; ?? frei
zugbuf:		ds 3			; 3 Zeichen Puffer f. Zug
		
; ENDE		
		db 0
		db 0

		end
