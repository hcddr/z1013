; File Name   :	d:\hobby3\z1013_hb_programme\sirene.bin
; Format      :	Binary file
; Base Address:	0000h Range: 0380h - 03D0h Loaded length: 0050h

		cpu	z80

		org 380h

sirene:		ld	l, 30h		; l=Anzahl Schritte
		ld	d, 60h		; d=tonhoehe/pulsbreite
		ld	e, 1
; Tastatur abfragen S4+K->Ende
		ld	a, 3
		out	(8), a		; Spalte aktivieren
		in	a, (2)		; Tastatur abfragen
		and	0Fh		; Bit0..3
		cp	5		; S4+K
		jp	z, 0038h	; dann Ende
;anschwellen
s1:		ld	c, e
;
s2:		xor	80h		; Toggle Tonsignal
		out	(2), a
		ld	b, d
s3:		djnz	$
;
		xor	80h		; Toggle Tonsignal
		out	(2), a
		ld	b, d
s4:		djnz	$
;
		dec	c
		jr	nz, s2
;
		dec	d
		inc	e
		dec	l
		jr	nz, s1
;		
;abschwellen
		ld	l, 30h
s5:		ld	c, e
s6:		xor	80h		; Toggle Tonsignal
		out	(2), a
		ld	b, d
s7:		djnz	$
;
		xor	80h		; Toggle Tonsignal
		out	(2), a
		ld	b, d
s8:		djnz	$
;
		dec	c
		jr	nz, s6
		inc	d
		dec	e
		dec	l
		jr	nz, s5
		jr	sirene

;ENDE
		db 0C3h
		db 0C3h
		db    1
		db 0DDh
		db  36h
		db    8
		db    0
		db 0CDh
		db 0D5h
		db    4
		db  16h
;
		end
