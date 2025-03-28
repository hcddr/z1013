; File Name   :	D:\hobby3\z1013_hb_programme\musikmodul.bin
; Format      :	Binary file
; Base Address:	0000h Range: 0100h - 0260h Loaded length: 0160h


		cpu	z80
		
		org 100h
; 1Mhz
start1:		xor	a		; 0
musik0:		ld	(sysclk), a
		jr	musik1
; 2MHz
start2:		ld	a, 1
		jr	musik0
;
musik1:		ld	hl, melodie
musik2:		ld	a, (hl)		; nächster Ton
		or	a
		jp	z, 0038h	; Pgm.Ende bei 00
		ld	c, (hl)
		inc	hl
		push	hl
		ld	a, (hl)
		ld	e, (hl)
		ld	d, 0
		cp	0FFh
		jr	z, musik4
		call	ton
musik3:		pop	hl
		inc	hl
		jr	musik2
musik4:		ld	b, 80h
		djnz	$
		ld	b, 80h
		djnz	$
		ld	a, (sysclk)
		or	a
		jr	z, musik9
		ld	b, 80h
		djnz	$
		ld	b, 80h
		djnz	$
musik9:		dec	c
		jr	nz, musik4
		jr	musik3

; Ausgabe Ton
ton:		ld	hl, hilftab
		add	hl, de
		ld	d, (hl)
		inc	hl
		ld	a, (hl)
		add	a, c
		ld	c, a
ton1:		set	7, a
		out	(2), a
		ld	b, d
		djnz	$
		ld	a, (sysclk)
		or	a
		jr	z, ton3
		ld	b, d
		djnz	$
ton3:		res	7, a
		out	(2), a
		ld	b, d
		djnz	$
		ld	a, (sysclk)
		or	a
		jr	z, ton6
		ld	b, d
		djnz	$
ton6:		dec	c
		jr	nz, ton1
		ret

;
sysclk:		db 0			; 0=1MHz, 1=2MHz
		db  0Ah
		db    0
		db    0


;Hilfstabelle (Tonhöhe+Anz.Schwingungen)
hilftab:	db 0A0h,   0		; C
		db  98h,   7            ; CIS
		db  90h, 0Fh            ; D
		db  87h, 17h            ; DIS
		db  80h, 1Fh            ; E
		db  78h, 27h            ; F
		db  70h, 2Fh            ; FIS
		db  6Ah, 34h            ; G
		db  65h, 3Ah            ; GIS
		db  60h, 3Fh            ; A
		db  5Bh, 43h            ; AIS
		db  56h, 49h            ; H
		db  4Fh, 50h            ; C'
;
		db  44h,   0            ; ??
		db    0,   0
		db    0,   0

;Melodie	(Kein schoener Land)
;jeweils Tonlänge - Tonhöhe - Pausenlänge - Pausenzeichen (FFH)
; Tonlänge: Länge der Note 1 -> 60,  1/2 -> 30,  1/4 -> 18,  1/8 ->  0B, 1/16 -> 06
; Die Bildung der Pausenlänge ist analog.
; Tonhöhe	C - 00, CIS - 02, D - 04, DIS - 06, E - 08, F - 0A
;		FIS - 0C, G - 0E, GIS - 10, A - 12, AIS - 14, H - 16, C' - 18
; Melodieende durch ein Nullbyte (00H)


melodie:	
		db  30h,   0,  18h, 0FFh 
		db  30h,   0,  18h, 0FFh 
		db  30h,   0,  18h, 0FFh 
		db  60h, 0Ah,  18h, 0FFh 
		db  60h, 12h,  18h, 0FFh 
		db  30h, 0Eh,  0Bh, 0FFh 
		db  30h, 0Ah,  0Bh, 0FFh 
		db  60h, 0Eh, 0B0h, 0FFh 
		db  30h,   0,  18h, 0FFh 
		db  30h,   0,  18h, 0FFh 
		db  30h,   0,  18h, 0FFh 
		db  60h, 0Ah,  18h, 0FFh 
		db  60h, 12h,  18h, 0FFh 
		db  30h, 0Eh,  0Bh, 0FFh 
		db  30h, 0Ah,  0Bh, 0FFh 
		db  60h, 0Eh, 0B0h, 0FFh 
		db  30h, 12h,  0Bh, 0FFh 
		db  30h, 0Ah,  0Bh, 0FFh 
		db  30h, 0Eh,  0Bh, 0FFh 
		db  30h, 12h,  0Bh, 0FFh 
		db  30h, 18h,  0Bh, 0FFh 
		db  30h, 14h,  0Bh, 0FFh 
		db  30h, 12h,  0Bh, 0FFh 
		db  30h, 0Eh,  0Bh, 0FFh 
		db  30h, 0Ah,  0Bh, 0FFh 
		db  30h, 0Eh,  0Bh, 0FFh 
		db  30h, 14h,  0Bh, 0FFh 
		db  30h, 12h,  0Bh, 0FFh 
		db  30h, 0Eh,  0Bh, 0FFh 
		db  30h, 0Ah,  0Bh, 0FFh 
		db  30h, 0Eh,  0Bh, 0FFh 
		db  60h, 12h, 0B0h, 0FFh 
		db  30h, 12h,  0Bh, 0FFh 
		db  30h, 0Ah,  0Bh, 0FFh 
		db  30h, 0Eh,  0Bh, 0FFh 
		db  30h, 12h,  0Bh, 0FFh 
		db  30h, 18h,  0Bh, 0FFh 
		db  30h, 14h,  0Bh, 0FFh 
		db  30h, 12h,  0Bh, 0FFh 
		db  30h, 0Eh,  0Bh, 0FFh 
		db  30h, 0Ah,  0Bh, 0FFh 
		db  30h, 0Eh,  0Bh, 0FFh 
		db  30h, 14h,  0Bh, 0FFh 
		db  30h, 12h,  0Bh, 0FFh 
		db  30h, 0Eh,  0Bh, 0FFh 
		db  30h, 0Ah,  0Bh, 0FFh 
		db  30h,   8,  0Bh, 0FFh 
		db  60h, 0Ah, 0B0h, 0FFh 
		db    0				; Melodieende
; ENDE	
		db    0
		db    0
		db    0
		db    0
		db    0
		db  30h	; 0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0

		end
