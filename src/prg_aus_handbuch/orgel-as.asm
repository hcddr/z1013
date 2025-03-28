; File Name   :	d:\hobby3\z1013_hb_programme\C.ORGEL(8).z80
; Format      :	Binary file
; Base Address:	0000h Range: 02E0h - 0360h Loaded length: 0080h

		cpu	z80

		org 300h

; Tastatur abfragen
orgel:		ld	b, 8		; 8 Tastaturspalten
		ld	de, tab2	; Tastaturspalte
		ld	hl, tab1	; Tonhoehentabelle
o1:		ld	a, (de)
		out	(8), a		; Spalte aktivieren
		in	a, (2)		; Tastatur abfragen
		and	0Fh		; Bit0..3
		cp	7		; 
		jr	z, o2		; Taste	in unterer Tastenzeile gedrueckt
		cp	5		; S4+K
		jp	z, 0038h	; dann Ende
		inc	hl		; naechste Tonhoehe
		inc	de		; naechste Spalte
		djnz	o1		; bis alle Spalten durch
		jr	orgel		; zureck auf Anfang

; Ton ausgeben
o2:		ld	c, 50h		; 50=Tonlaenge
o3:		set	7, a		; Tonsignal an
		out	(2), a
		ld	b, (hl)		; warteschleife
o4:		djnz	$
		res	7, a		; Tonsignal aus
		out	(2), a
		ld	b, (hl)		; Warteschleife
o5:		djnz	$
		dec	c		; das ganze Tonlaengen mal
		jr	nz, o3
		jr	orgel


; Tonhoehentabelle 2 MHz
tab1:		db  40h
		db  39h
		db  33h
		db  30h
		db  2Bh
		db  26h
		db  22h
		db  1Fh

; Tastaturspalte
tab2:		db    0
		db    1
		db    2
		db    3
		db    4
		db    5
		db    6
		db    7
;ENDE
		db  30h
		db 0FAh
		db  19h
		db  22h
		db  96h
		db    7
		db  21h
		db 0F9h
		db  0Bh
		db  3Eh

		end
