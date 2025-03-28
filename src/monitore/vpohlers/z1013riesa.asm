	page	0
	CPU	z80

;Z1013-MONITOR 2.02, A.2
;reass: 1988-1990 Volker Pohlers, Lomonossowallee 41/81, Greifswald, 2200
;basierend auf GENS3M-Listing des 2.02-Monitors von C.Fischer/Ilmenau
;Fassung für den Arnold-Assembler und vielfach erweiterte Kommentare
;Volker Pohlers, Sanitz, 23.04.2004
;letzte Änderung 15.12.2011

;
;gewünschten Monitortyp auskommentieren
;
MONTYP	EQU	"Z1013_202"
;MONTYP	EQU	"Z1013_A2"

;die wichtigsten Unterschiede A2 <-> 2.02
;- kein H- und A- und F-Kommandos
;- andere Adressen Windows-Speicher
;- andere INKEY-Routine und auch INCH-Routine!
;- KDO mit RST-Aufrufen programmiert, damit Verschiebung aller Routinen des Monitors!

; Makros
hi              function x, (x>>8) & 0ffh	; High-Byte
lo              function x, x & 0ffh		; Low-Byte

;
;RAM-Zellen
;
R20BT:	EQU	00003H			;Nummer des RST20-Calls
LAKEY:	EQU	00004H			;letztes Zeichen von Tastatur
BPADR:	EQU	0000BH			;Breakpointadresse
BPOPC:	EQU	0000DH			;Operandenfolge bei Breakpoint
DATA:	EQU	00013H			;Adresse bei INHEX; intern f. INKEY b. A2
;SHILO:	EQU	00015H			;
SOIL:	EQU	00016H			;Beginn Eingabezeile
ARG1:	EQU	0001BH			;1. Argument
ARG2:	EQU	0001DH			;2. Argument
BUFFA:	EQU	0001FH			;vom Cursor verdecktes Zeichen
RST20:	EQU	00020H			;RST 20H
ARG3:	EQU	00023H			;3. Argument
SOIL2:	EQU	00025H			;Rest Eingabezeile
CUPOS:	EQU	0002BH			;aktuelle Cursorposition
LSYNC:	EQU	00033H			;Kenntonlaenge
RST38:	EQU	00038H			;RST 38H
	IF MONTYP == "Z1013_A2"
WINDL:	EQU	00035H			;Windowlaenge
KYBTS:	equ	00037h			;Tastaturroutinenzelle (Bit 4=Repeat)
WINDA:	EQU	0003BH			;Windowanfang
WINDE:	EQU	0003DH			;Windowende+1
	ELSE
KYBTS:	EQU	00027H			;Tastaturroutinenzelle (0=ASCII,80h=Grafik)
WINDL:	EQU	00047H			;Windowlaenge
WINDA:	EQU	00049H			;Windowanfang
WINDE:	EQU	0004BH			;Windowende+1
	ENDIF
REGBR:	EQU	0004DH			;Registerrettebereich
REGAF:	EQU	0005BH			;Register AF
REGPC:	EQU	00061H			;Register PC
REGSP:	EQU	00063H			;Userstack
NMI:	EQU	00066H
NBYTE:	EQU	00069H			;Operand bei NEXT
SPADR:	EQU	0006AH			;SP-Zwischenspeicher
FBANZ:	EQU	0006CH			;Zwsp. Anz. Suchbytes bei FIND
USRSK:	EQU	00090H			;Userstack
SYSSK:	EQU	000B0H			;Systemstack
USRKD:	EQU	SYSSK
;Bildschirm
BWS:	EQU	0EC00H			;Beginn BWS
BWSROW	EQU	32			;Anzahl Zeilen
BWSCOL	EQU	32			;Anzahl Zeichen/Zeile
BWSSZ	EQU	BWSROW*BWSCOL
;
;Markenvereinbarungen
;
CLS:	EQU	0CH
CR:	EQU	0DH
ESC:	EQU	27
NL:	EQU	1EH
LF:	EQU	0AH
;
;PIO
PIOAD	equ	00h 			; PIO A User
PIOAC	equ	01h
PIOBD	equ	02h			; PIO B, Bit0..4 Tastaturzeile
PIOBC	equ	03h			; Bit5->AB0 in, Bit6->TB in, Bit7->TB out
KEYP	equ	08h			; Port Ausgabe Tastaturspalte
;
; Makros für Systemaufrufe über RST 20h
;
ROUTC:	MACRO
	RST	20H
	DB	0			; OUTCH
	ENDM
RINCH:	MACRO
	RST	20H
	DB	01h			; INCH
	ENDM
RPRST:	MACRO
	RST	20H
	DB	02h			; PRST
	ENDM
RINHX:	MACRO
	RST	20H
	DB	03h			; INHEX
	ENDM
RINKY:	MACRO
	RST	20H
	DB	04h			; INKEY
	ENDM
RINLN:	MACRO
	RST	20H
	DB	05h			; INLIN
	ENDM
ROTHX:	MACRO
	RST	20H
	DB	06h			; OUTHX
	ENDM
ROTHL:	MACRO
	RST	20H
	DB	07h			; OUTHL
	ENDM
ROTHS:	MACRO
	RST	20H
	DB	0Ch			; OTHLS
	ENDM
ROTDP:	MACRO
	RST	20H
	DB	0Dh			; OUTDP
	ENDM
ROTSP:	MACRO
	RST	20H
	DB	0Eh			; OUTSP
	ENDM
;
;
;
	ORG	0F000H
;
;-------------------------------------------------------------------------------
; Start
;-------------------------------------------------------------------------------

INIT:	JR	INIT2
;Initialisierung
INIT1:	LD	HL,REGBR		;Registerrette-
	LD	DE,REGBR+1		;bereich loeschen
	LD	(HL),0
	LD	BC,0015H
	LDIR
INIT2:	LD	SP,SYSSK		;System-Stack
	IF MONTYP == "Z1013_202"
	xor	a			;Tastaturschalter
	ld	(KYBTS), a		;auf ASCII
	ENDIF
	LD	A,0C3H			;JMP ...
	LD	(RST20),A
	LD	HL,RST1			;RST20 eintragen
	LD	(RST20+1),HL
	LD	A,11001111b		;PIO Port B init.
	OUT	PIOBC, A		;BIT-Mode 3
	IF	MONTYP <> "Z1013_A2"
	LD	A,01111111b		;BIT7-Ausgang
	ELSE
	LD	A,01101111b		;Bit7 und Bit4 Ausg.
	ENDIF
	OUT	PIOBC, A
	LD	HL,MONTB		;System-RAM init.
	LD	DE,LSYNC
	LD	BC,INCH-MONTB		;Laenge Tabelle
	LDIR
;Systemmeldung
	RPRST
	DB	CLS
	DB	CR
	DB	CR
	IF MONTYP == "Z1013_202"
	DB	"robotron Z 1013/2.02"
	ELSEIF MONTYP == "Z1013_A2"
	DB	"robotron Z 1013/A.2"
	ENDIF
	DB	CR+80H
;
	LD	HL,USRSK		;User-Stack
	LD	(REGSP),HL
	IM	2
	JR	KDO2
;
;-------------------------------------------------------------------------------
;Eingang Kommandomodus
;-------------------------------------------------------------------------------
;
KDO1:	LD	SP,SYSSK		;System-Stack
	IF MONTYP == "Z1013_A2"
	RPRST
	ELSE
	CALL	PRST7
	ENDIF
	DB	'?'+80H
KDO2:
	IF MONTYP == "Z1013_A2"
	RINLN
	ELSE
	CALL	INLIN			;Zeile eingeben
	ENDIF
	LD	DE,(SOIL)
	CALL	SPACE			;Leerzeichen uebergehen
	LD	B,A			;B=1. Zeichen
	INC	DE
	LD	A,(DE)
	LD	C,A			;C=2. Zeichen
	PUSH	BC
	INC	DE
	IF MONTYP == "Z1013_A2"
	RINHX
	ELSE
	CALL	INHEX
	ENDIF
	JR	NZ, KDO3
	LD	A,(DE)
	CP	A, ':'			;die alten Werte nehmen ?
	JR	Z, KDO4
KDO3:	LD	(ARG1),HL		;neue Argumente holen
	IF MONTYP == "Z1013_A2"
	RINHX
	ELSE
	CALL	INHEX
	ENDIF
	LD	(ARG2),HL
	IF MONTYP == "Z1013_A2"
	RINHX
	ELSE
	CALL	INHEX
	ENDIF
	LD	(ARG3),HL
KDO4:	POP	BC
	EX	AF, AF'
	LD	(SOIL2),DE		;Anfang 4. Argument
;Kommando (in Reg B) suchen
	LD	HL,KDOTB		;in Kommandotabelle
KDO5:	LD	A,(HL)
	CP	A, B
	JR	Z, KDO6			;wenn gefunden
	INC	HL
	INC	HL
	INC	HL
	OR	A			;Tabellenende?
	JR	NZ, KDO5		;nein
	LD	A,B
	CP	A, '@'			;"@"-Kommando?
	JR	NZ, KDO1		;nein -> Eingabefehler
	LD	HL,USRKD		;Suchen in "@"-Kdo.tab.
	LD	B,C
	JR	KDO5
;
KDO6:	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	EX	DE,HL			;HL=UP-Adresse
	EX	AF, AF'
	LD	BC,KDO2			;Returnadresse
	PUSH	BC
	JP	(HL)			;Sprung zur Routine
;
KDOTB:
	IF MONTYP == "Z1013_202"
	DB	"A"
	DW	A_KDO
	ENDIF
	DB	"B"
	DW	B_KDO
	DB	"C"
	DW	C_KDO
	DB	"D"
	DW	D_KDO
	DB	"E"
	DW	E_KDO
	IF MONTYP <> "Z1013_A2"
	DB	"F"
	DW	F_KDO
	ENDIF
	DB	"G"
	DW	G_KDO
	IF MONTYP == "Z1013_202"
	DB	"H"
	DW	H_KDO
	ENDIF
	DB	"I"
	DW	INIT1
	DB	"J"
	DW	J_KDO
	DB	"K"
	DW	K_KDO
	DB	"L"
	DW	CLOAD
	DB	"M"
	DW	MEM
	DB	"N"
	DW	N_KDO
	DB	"R"
	DW	R_KDO
	DB	"S"
	DW	CSAVE
	DB	"T"
	DW	T_KDO
	DB	"W"
	DW	W_KDO
	DB	0
;
;-------------------------------------------------------------------------------
;Eingang bei RST 20H
;-------------------------------------------------------------------------------
;
RST1:	EX	(SP),HL
	PUSH	AF
	LD	A,(HL)			;Datenbyte hinter Ruf holen
	LD	(R20BT),A		;und ablegen
	INC	HL			;Returnadresse erhoehen
	POP	AF
	EX	(SP),HL
;
	PUSH	HL
	PUSH	BC
	PUSH	AF
	LD	HL,RSTTB
	LD	A,(R20BT)
	SLA	A
	LD	C,A
	LD	B,0
	ADD	HL,BC			;HL=Adresse in Tab.
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A			;HL=UP-Adresse
	POP	AF
	POP	BC
	EX	(SP),HL			;Ansprung der
	RET				;Routine
;
RSTTB:	DW	OUTCH			;DB 0
	DW	INCH			;DB 1
	DW	PRST7			;DB 2
	DW	INHEX			;DB 3
	DW	INKEY			;DB 4
	DW	INLIN			;DB 5
	DW	OUTHX			;DB 6
	DW	OUTHL			;DB 7
	DW	CSAVE			;DB 8
	DW	CLOAD			;DB 9
	DW	MEM			;DB 10
	DW	W_KDO			;DB 11
	DW	OTHLS			;DB 12
	DW	OUTDP			;DB 13
	DW	OUTSP			;DB 14
	DW	T_KDO			;DB 15
	DW	INSTR			;DB 16
	DW	K_KDO			;DB 17
	IF MONTYP <> "Z1013_A2"
	DW	H_KDO			;DB 18
	DW	A_KDO			;DB 19
	ENDIF

;
;-------------------------------------------------------------------------------
;Eingabe ein Zeichen von der Tastatur in A
;-------------------------------------------------------------------------------
;
	IF MONTYP == "Z1013_202"

; Tastatur
; --------
;
;      -------------------------------------------------        I-------I
;      I X   I Y   I Z   I [ { I \ | I ] } I ^ ~ I _   I        I S1 S2 I
;  RZ0-I     I     I     I     I     I     I     I     I        I       I
;      I @ ` I A   I B   I C   I D   I E   I F   I G   I        I S0    I
;      I-----+-----+-----+-----+-----+-----+-----+-----I        I-------I
;      I 0   I 1 ! I 2 " I 3 # I 4 $ I 5 % I 6 & I 7 ' I
;  RZ1-I     I     I     I     I     I     I     I     I        S0 = normal, Großbuchstaben
;      I H   I I   I J   I K   I L   I M   I N   I O   I        S1 = Ziffern etc.
;      I-----+-----+-----+-----+-----+-----+-----+-----I        S2 = Sonderzeichen etc.
;      I 8 ( I 9 ) I : * I ; + I < , I = - I > . I ? / I        S3 = Kleinbuchstaben
;  RZ2-I     I     I     I     I     I     I     I     I        S4 = Ctrl.
;      I P   I Q   I R   I S   I T   I U   I V   I W   I
;      I-----+-----+-----+-----+-----+-----+-----+-----I
;      I     I     I     I     I     I     I     I     I
;  RZ3-I     I     I     I     I     I     I     I     I
;      I S1  I S2  I S3  I S4  I <-  I SP  I ->  I ENT I
;      -------------------------------------------------
;         !     !     !     !     !     !     !     !
;        RS0   RS1   RS2   RS3   RS4   RS5   RS6   RS7
;
; IN 2 |                     OUT 8


inkey:					;bei Ret A=ASCII
	xor	a
	ld	h, a
	ld	l, a
	call	ink9			;Tastenabfrage
	jr	nc, ink8		;Cy=0 keine Taste
	add	hl, de
	call	ink12			;restl. Spalten
	ld	c, 44h			;Tastaturcodetabelle 0044H Shift-Ebene 0 40h,48h,50h
	jr	c, ink1			;Cy=1 2.Taste gedr.
	ex	de, hl
	bit	3, d			;Abfrage Zeile 3
	jr	z, ink2			;Z=1 Taste gedr.
	jr	ink3
ink1:	bit	3, d			;2. Taste ? Zeile 3
	jr	z, ink2			;Z=1 Taste gedr.
	ex	de, hl
	bit	3, d			;1. Taste ? Zeile 3
	jr	nz, ink3		;Z=1 Taste gedr.
ink2:	call	ink13			;Welche Taste in Z3
	push	bc
	call	ink22			;Summand holen
	pop	bc
	jr	z, ink4			;Z=0 kein Summ.
	ex	de, hl
ink3:	call	ink22			;Summand holen
	jr	nz, ink8		;Z=0 kein Summ.
ink4:	add	a, e
	ld	hl, KYBTS
	add	a, (hl)
;Berechnung Ascii-Wert abgeschlossen
ink5:	ld	hl, LAKEY		;Softwareentprel-
	cp	(hl)			;lung, verhindert
	jr	z, inkey		;Repeat-Funktion
	ld	b, a
	ld	a, (hl)
	or	a
	ld	a, b
	jr	nz, inkey		;Z=1 vorher keine
	ld	(LAKEY), a		;Taste gedrueckt
	cp	91h			;(S4/A)
	jr	z, ink6			;Z=1- ASCII
	cp	17h			;(S4/G)
	ret	nz			;Z=0 Ruecksprung
	ld	a, 80h
	jr	ink7
ink6:	xor	a
ink7:	ld	(KYBTS), a
ink8:	xor	a			;Ruecksprung wenn
	ld	(LAKEY), a		;keine Taste gedr.
	ret				;mit A=0
;UP Tastenabfrage
ink9:	ld	e, a			;E=Spaltennummer
	out	(KEYP), a		;Ausgabe Spalte
	ld	b, 20h
ink10:	in	a, (PIOBD)
	and	0Fh
	ld	d, a			;D=Zeilennummer
	in	a, (PIOBD)
	and	0Fh
	cp	d
	jr	nz, ink11		;Z=0 Taste prellt
	cp	0Fh
	ret	nz			;Z=0 Taste gedr.
ink11:	djnz	ink10
ink12:	ld	a, e			;Erhoeh. Spalten-
	inc	a			;zahl
	cp	8
	jr	nz, ink9		;Z=1 alle Tasten
	ret				;abgefragt
;Taste in Z3
ink13:	ld	a, 1			;Untersuchung
	cp	e			;welche Taste in
	jr	z, ink19		;Zeile 3 gedr. ist
	jr	nc, ink18		;E=Spaltenzahl
	add	a, 2			;E=0 - C=41H
	cp	e			;E=1 - C=3EH
	jr	z, ink21		;E=2 - C=3BH
	jr	nc, ink20		;E=3 - C=35H
	add	a, 2			;E=4 - A=08H
	cp	e			;E=5 - A=20H
	jr	z, ink15		;E=6 - A=09H
	jr	nc, ink16		;E=7 - A=0DH
	add	a, 2
	cp	e
	jr	z, ink14
	ld	a, 9			; ->
	jr	ink17
ink14:	ld	a, 0Dh			; ENT
	jr	ink17
ink15:	ld	a, 20h			; SPACE
	jr	ink17
ink16:	ld	a, 8			; <-
ink17:	pop	bc
	jr	ink5
ink18:	ld	c, 41h			;Tastaturcodetabelle 0041H Shift-Ebene 1 58h,30h,38h
	ret
ink19:	ld	c, 3Eh			;Tastaturcodetabelle 003EH Shift-Ebene 2 78h,20h,28h
	ret
ink20:	ld	c, 3Bh			;Tastaturcodetabelle 003BH Shift-Ebene 3 60h,68h,70h
	ret
ink21:	ld	c, 35h			;Tastaturcodetabelle 0035H Shift-Ebene 4 10h,00h,08h
	ret

;Summand holen
ink22:	bit	0, d			;Abfrage Zeile 0
	jr	nz, ink24		;Z=0 keine Taste
ink23:	ld	l, c
	ld	h, 0
	ld	a, (hl)
	ret
ink24:	inc	c
	bit	1, d			;Abfrage Zeile 1
	jr	nz, ink25		;Z=0 keine Taste
	jr	ink23
ink25:	inc	c
	bit	2, d			;Abfrage Zeile 2
	ret	nz			;Z=0 keine Taste
	jr	ink23

	ELSEIF MONTYP == "Z1013_A2"

; Tastatur
; --------
;
;      -------------------------------------------------
;      I   ! I   # I   % I   ' I   ) I   = I     I     I
;  RZ0-I     I     I     I     I     I     I     I     I
;      I 1   I 3   I 5   I 7   I 9   I -   I GRA I     I
;      I-----+-----+-----+-----+-----+-----+-----+-----I
;      I     I     I     I     I     I   ` I     I     I
;  RZ1-I     I     I     I     I     I     I     I     I
;      I Q   I E   I T   I U   I O   I @   I ENT I     I
;      I-----+-----+-----+-----+-----+-----+-----+-----I
;      I     I     I     I     I     I   : I     I     I
;  RZ2-I     I     I     I     I     I     I Cu  I     I
;      I A   I D   I G   I J   I L   I *   I leftI     I
;      I-----+-----+-----+-----+-----+-----+-----+-----I
;      I     I     I     I     I   > I   ~ I     I     I
;  RZ3-I     I     I     I     I     I     I Cu  I     I
;      I Y   I C   I B   I M   I     I ^   I rghtI     I
;      I-----+-----+-----+-----+-----+-----+-----+-----I
;      I   " I   $ I   & I   ( I     I   { I     I     I
;  RZ4-I     I     I     I     I     I     I     I     I
;  RZ0 I 2   I 4   I 6   I 8   I 0   I [   I Spc I     I
;      I-----+-----+-----+-----+-----+-----+-----+-----I
;      I     I     I     I     I     I         } I     I
;  RZ5-I     I     I     I     I     I     I     I     I
;  RZ1 I W   I R   I Z   I I   I P   I ]   I CTRLI     I
;      I-----+-----+-----+-----+-----+-----+-----+-----I
;      I     I     I     I     I   ; I   | I     I     I
;  RZ6-I     I     I     I     I     I     I Cu  I     I
;  RZ2 I S   I F   I H   I K   I +   I \\  I up  I ShftI
;      I-----+-----+-----+-----+-----+-----+-----+-----I
;      I     I     I     I   < I   ? I    I     I     I
;  RZ7-I     I     I     I     I     I     I Cu  I ShftI
;  RZ3 I X   I V   I N   I ,   I /   I _   I downI LockI
;      -------------------------------------------------
;         !     !     !     !     !     !     !     !
;        RS0   RS1   RS2   RS3   RS4   RS5   RS6   RS7
;
; IN 2 |                     OUT 8
;
; Zeile 4..7 werden auf Zeile 0..3 gemuxt, wenn Pio B4=1

inkey:	ld	hl, KYBTS		; Merkzelle
	ld	a, 01011011b
	and	(hl)
	ld	(hl), a
	ld	ix, keytab		; Tastaturcodetabelle
	call	ink16			; normale Taste gedrückt?
	jr	nc, ink1		; nein, dann evtl. Fkt.taste?
	push	de			;
	set	7, (hl)
	call	ink20			; ASCII-Code aus Tabelle ermitteln
	ld	(DATA), a		; ASCII-Code
	pop	de			;
	call	ink18			;
; Funktionstasten (Spalte 6)
ink1:	ld	ix, tab2		; Tastaturcodetabelle
	ld	e, 6			; Spalte 6
	call	ink19			; Spalte abfragen
	jr	z, ink9			; wenn keine Taste gedrückt
	bit	0, c			; GRA ?
	jr	z, ink2
	bit	5, c			; CTRL ?
	jr	z, ink5
	call	ink20			; ASCII-Code aus Tabelle ermitteln
	ret				; A = ASCII-Code
; GRA
ink2:	ld	a, 2
	res	3, (hl)
ink3:	bit	6, (hl)
	jr	nz, ink4
	set	6, (hl)			; Statusbit Grafikmode setzen
	xor	(hl)
	ld	(hl), a
ink4:	xor	a
	ret
; CTRL
ink5:	set	5, (hl)			; Statusbit CTRL setzen
	bit	7, (hl)
	jr	z, ink9
	ld	a, (DATA)
	bit	6, a
	jr	nz, ink6
	set	4, a
ink6:	and	1Fh
ink7:	bit	1, (hl)
	ret	z
	set	7, a			; Bit 7 := 1 (Grafikzeichen)
	ret
; Shift
ink8:	res	6, (hl)
	bit	7, (hl)
	ret	z
	ld	a, (DATA)
	jr	ink7
;
ink9:	ld	e, 7			; Spalte 7 (Shift)
	call	ink19			; Taste gedrückt?
	jr	z, ink10		; nein
	bit	7, c			; Shift Lock
	jr	z, ink15
	bit	6, c			; Shift
	jr	nz, ink8
	bit	5, (hl)
	jr	nz, ink15
ink10:	bit	7, (hl)			;
	ret	z			; nein
; Repeat
	ld	a, (DATA)
	bit	6, c
	jr	z, ink11
	bit	3, (hl)
	jr	z, ink7
	jr	ink12
ink11:	bit	3, (hl)
	jr	nz, ink7
ink12:	ld	b, a
	and	30h
	ld	a, b
	jp	po, ink13
	res	4, a
	jr	ink14
ink13:	set	4, a
ink14:	set	5, a
	jr	ink7
; Shift Lock
ink15:	ld	a, 8
	jp	ink3
; normale Taste gedrückt?
; IN: IX: Tastaturcodetabelle
; OUT: Z-Flag=1: Taste gedrückt
;      E = Spalte
;      Cy=0: keine Taste gedrückt
;	IX: Tastaturcodetabelle aktuelle Zeile
ink16:	ld	e, 0			; e = Spalte (0..5)
ink17:	call	ink19			; Taste in Spalte gedrückt?
	scf
	ret	nz			; wenn gedrueckt
ink18:	inc	e			; sonst naechste Spalte
	ld	bc, 8			; und Pointer auf Tastaturcode-
	add	ix, bc			; tabelle erhöhen
	ld	a, e
	cp	6			; Spalte RS6 erreicht?
	jr	nz, ink17		; bis alle 7 Spalten
	scf
	ccf				; Cy=0
	ret
; Abfrage einer Spalte
; IN E: Spalte
; OUT: C: Zeile
;      A = 0
;      Z-Flag=1: Taste gedrückt
ink19:	ld	a, e			; e = Spalte
	out	(KEYP), a		; Spalte aktivieren
	out	(PIOBD), a		; Pio B4 = 0 (Zeile 0..3)
	in	a, (PIOBD)		; Zeilen 0..3 einlesen
	and	0Fh
	ld	c, a
	set	4, a			; PIO B4 = 1 (Zeile 4..7)
	out	(PIOBD), a
	in	a, (PIOBD)		; Zeilen 4..7 einlesen
	sla	a			; in obere 4 Bits verschieben
	sla	a
	sla	a
	sla	a
	ld	d, a			; d = Zeile 4..7
	add	a, c
	ld	c, a			; c = Zeile 0..7
; Entprellen ...
	xor	a			; a = 0
	out	(PIOBD), a		; Pio B4 = 0 (Zeile 0..3)
	in	a, (PIOBD)		; Zeilen 0..3 einlesen
	and	0Fh
	add	a, d
	cp	c			; noch gleicher Wert?
	jr	nz, ink19		; nein
	cpl
	or	a
	ld	a, 0
	ret
; ASCII-Code aus Tabelle ermitteln
; IN: C = Zeile = Bit 0..7
;     IX = Tastaturcodetabelle
ink20:	ld	de, 0
	ld	b, 8			; max 8 Zeilen
ink21:	sra	c			; nächste Zeile
	jr	nc, ink22
	inc	e
	djnz	ink21
ink22:	add	ix, de
	ld	a, (ix+0)		; A = ASCII-Code
	res	6, (hl)			;
	ret

	ENDIF
;
;-------------------------------------------------------------------------------
;Monitorinit., wird nach 0033H (LSYNC) umgeladen
;-------------------------------------------------------------------------------
;
MONTB:
	phase	0033H

	IF MONTYP == "Z1013_202"

	DW	2000			;Kenntonlaenge LSYNC
	DB	10h,00h,08h		;Tastaturcodetabelle 0035H Shift-Ebene 4
	JP	KDO1			;RST38-Sprung	RST38
	db	60h,68h,70h		;Tastaturcodetabelle 003BH Shift-Ebene 3
	db	78h,20h,28h		;Tastaturcodetabelle 003EH Shift-Ebene 2
	db	58h,30h,38h		;Tastaturcodetabelle 0041H Shift-Ebene 1
	db	40h,48h,50h		;Tastaturcodetabelle 0044H Shift-Ebene 0
	DW	03E0H			;WINDOW-Laenge	WINDL
	DW	BWS			;WINDOW-Anfang	WINDA
	DW	BWS+BWSSZ		;WINDOW-Ende	WINDE

	ELSEIF MONTYP == "Z1013_A2"

	dw	2000			;Kenntonlaenge 	LSYNC
	DW	BWSSZ-BWSCOL		;WINDOW-Laenge 	WINDL
	db	0			;Status-Merkzelle f. INKEY KYBTS
	jp	KDO1			;RST38-Sprung	RST38
	DW	BWS			;WINDOW-Anfang	WINDA
	DW	BWS+BWSSZ		;WINDOW-Ende	WINDE

	ENDIF

	dephase
;
;-------------------------------------------------------------------------------
;Zeichen von Tastatur holen, warten bis Taste gedrueckt
;-------------------------------------------------------------------------------
;
	IF MONTYP == "Z1013_202"

INCH:	push	bc
	push	de
	push	hl
INC1:	CALL	INKEY
	OR	A
	JR	Z, INC1			;keine Taste gedrueckt
	pop	hl
	pop	de
	pop	bc
	RET

	ELSEIF MONTYP == "Z1013_A2"

INCH:	push	ix
	push	bc
	push	de
	push	hl
	ld	bc, 1000h		; B := 16; C := 0 (256)
INC1:	PUSH	BC
	CALL	INKEY			; ret: hl=KYBTS
	POP	BC
	LD	IX, LAKEY
	CP	(IX+0)
	JR	NZ, INC6		; wenn anderes Zeichen
	OR	A			; A = 0?
	JR	Z, INC5			; wenn keine Taste gedückt
INC2:	DEC	C
	JR	NZ, INC2		; kurz warten
	BIT	4, (HL)			; Repeat?
	JR	NZ, INC4		; ja -> gleich weiter
	LD	DE, 800H		; sonst längeres Warten
INC3:	DEC	DE
	LD	A, E
	OR	D
	JR	NZ, INC3
INC4:	DJNZ	INC1			; 16x
	SET	4, (HL)			; Repeat ein
	XOR	A			; A := 0, kein Zeichen
	JR	INC6
INC5:	RES	4, (HL)			; kein Repeat mehr
INC6:	LD	(IX+0),	A		; LAKEY füllen
	OR	A			; A = 0?
	JR	Z, INC1			; nochmal, bis Taste gedrückt
	POP	HL
	POP	DE
	POP	BC
	POP	IX
	RET

	ENDIF
;
;-------------------------------------------------------------------------------
;Ausgabe Zeichen auf Bildschirm
;-------------------------------------------------------------------------------
;
; Zeichenausgabe f. PRST7: Reset Bit 7
OUT0:	AND	A, 7FH
; Zeichenausgabe
OUTCH:	push	af
	push	bc
	push	de
	PUSH	HL
	LD	HL,(CUPOS)
	PUSH	AF
	LD	A,(BUFFA)		;Zeichen unter Cursor
	LD	(HL),A			;zurueckschreiben
	POP	AF
	CP	A, CR			;neue Zeile?
	JR	Z, OUT8
	CP	A, CLS			;Bildschirm loeschen?
	JR	Z, OUT10
	CP	A, 8			;Cursor links?
	JR	Z, OUT7
	CP	A, 9			;Cursor rechts?
	JR	Z, OUT2
	LD	(HL),A			;sonst Zeichen in BWS
OUT2:	INC	HL
;
OUT3:	EX	DE,HL
	LD	HL,(WINDE)
	XOR	A			;Test, ob neue Cursor-
	SBC	HL,DE			;position schon
	EX	DE,HL			;ausserhalb Window
	JR	NZ, OUT6		;nein
;
	LD	DE,(WINDA)		;scrollen um
	LD	HL,BWSCOL		;eine Zeile im Window
	ADD	HL,DE
	LD	BC,(WINDL)		;Windowlaenge
	LD	A,B
	OR	C			;=0?
	JR	Z, OUT5			;ja --> kein Scrollen
	LDIR
OUT5:	PUSH	DE			;letzte Zeile loeschen
	POP	HL
	PUSH	HL
	INC	DE
	LD	(HL),' '
	LD	BC,BWSCOL-1
	LDIR
;
	LD	HL,(SOIL)		;SOIL um eine Zeile
	LD	DE,BWSCOL		;erhoehen
	XOR	A
	SBC	HL,DE
	LD	(SOIL),HL
	POP	HL
;
OUT6:	LD	A,(HL)			;Zeichen unter Cursor
	LD	(BUFFA),A		;sichern
	LD	(HL),0FFH		;Cursor setzen
	LD	(CUPOS),HL
	POP	HL
	POP	DE
	POP	BC
	POP	AF
	RET
;Cursor links
OUT7:	DEC	HL
	JR	OUT3
;neue Zeile
OUT8:	LD	A, 0E0H			;auf Zeilenanfang stellen
	AND	A, L			;A=Anfang akt. Zeile
	ADD	A, BWSCOL		;A=NWB der Position
	LD	C,A			;eine Zeile tiefer
OUT9:	LD	(HL),' '		;Rest der Zeile ab
	INC	HL			;ENTER loeschen
	LD	A,L
	CP	A, C
	JR	NZ, OUT9
	JR	OUT3
;
;Window loeschen
OUT10:	LD	HL,(WINDL)
	LD	BC,BWSCOL-1
	ADD	HL,BC
	PUSH	HL
	POP	BC
	LD	HL,(WINDA)
	PUSH	HL
	LD	(HL),' '
	PUSH	HL
	POP	DE
	INC	DE
	LDIR
	POP	HL
	JR	OUT6
;
;-------------------------------------------------------------------------------
;Ausgabe String, bis Bit7=1
;-------------------------------------------------------------------------------
;
PRST7:	EX	(SP),HL			;Adresse hinter CALL
PRS1:	LD	A,(HL)
	INC	HL
	PUSH	AF
	CALL	OUT0
	POP	AF
	BIT	7,A			;Bit7 gesetzt?
	JR	Z, PRS1			;nein
	EX	(SP),HL			;neue Returnadresse
	RET
;
;-------------------------------------------------------------------------------
;Eingabe einer Zeile mit Promptsymbol
;-------------------------------------------------------------------------------
;
INLIN:	CALL	PRST7
	DB	" #"
	DB	' '+80H
;
;-------------------------------------------------------------------------------
;Eingabe einer Zeichenkette
;-------------------------------------------------------------------------------
;
INSTR:	PUSH	HL
	LD	HL,(CUPOS)
	LD	(SOIL),HL		;SOIL=1.Position
INS1:	RINCH				;Zeichen von Tastatur
	ROUTC				;anzeigen
	CP	A, CR			;>ENTER<?
	JR	NZ, INS1		;nein --> weiter eingeben
	POP	HL
	RET
;
;-------------------------------------------------------------------------------
;fuehrende Leerzeichen ueberlesen
;-------------------------------------------------------------------------------
;
SPACE:	LD	A,(DE)
	CP	A, ' '
	RET	NZ
	INC	DE
	JR	SPACE
;
;-------------------------------------------------------------------------------
;letzen vier Zeichen als Hexzahl konvertieren
;und in DATA ablegen
;-------------------------------------------------------------------------------
;
KONVX:	CALL	SPACE
	XOR	A
	LD	HL,DATA
	LD	(HL),A			;DATA=0
	INC	HL
	LD	(HL),A
KON1:	LD	A,(DE)
	DEC	HL
	SUB	30H			;Zeichen<"0"?
	RET	M
	CP	A, 0AH			;Zeichen<="9"?
	JR	C, KON2
	SUB	7
	CP	A, 0AH			;Zeichen<"A"?
	RET	M
	CP	A, 10H			;Zeichen>"F"?
	RET	P
KON2:	INC	DE			;Hexziffer eintragen
	RLD
	INC	HL
	RLD
	JR	KON1			;naechste Ziffer
;
;-------------------------------------------------------------------------------
;Konvertierung ASCII-Hex ab (DE) --> (HL)
;-------------------------------------------------------------------------------
;
INHEX:	PUSH	BC
	CALL	KONVX			;Konvertierung
	LD	B,H			;BC=HL=DATA+1
	LD	C,L
	LD	L,(HL)			;unteres Byte
	INC	BC
	LD	A,(BC)
	LD	H,A			;oberes Byte
	OR	L			;Z-Flag setzen
	POP	BC
	RET
;
;-------------------------------------------------------------------------------
;Ausgabe (A) hexadezimal
;-------------------------------------------------------------------------------
;
OUTHX:	PUSH	AF
	RRA
	RRA
	RRA
	RRA
	CALL	OUX1			;obere Tetrade ausgeben
	POP	AF			;und die untere
OUX1:	PUSH	AF
	AND	A, 0FH
	ADD	A, 30H			;Konvertierung --> ASCII
	CP	A, ':'			;Ziffer "A" ... "F"?
	JR	C, OUX2			;nein
	ADD	A, 7			;sonst Korrektur
OUX2:	CALL	OUTCH			;und Ausgabe
	POP	AF
	RET
;
;-------------------------------------------------------------------------------
;Ausgabe HL hexadezimal
;-------------------------------------------------------------------------------
;
OUTHL:	PUSH	AF
	LD	A,H
	CALL	OUTHX
	LD	A,L
	CALL	OUTHX
	POP	AF
	RET
;
;-------------------------------------------------------------------------------
;Speicherinhalt modifizieren
;-------------------------------------------------------------------------------
;
MEM:	LD	HL,(ARG1)
MEM1:	ROTHL				;Ausgabe Adresse
	PUSH	HL
	ROTSP				;Leerzeichen
	LD	A,(HL)
	ROTHX				;Ausgabe Byte
	CALL	INLIN
	LD	DE,(SOIL)
	LD	A,(DE)
	EX	AF, AF'
	POP	HL
	DEC	HL
MEM2:	INC	HL
	PUSH	HL
	CALL	INHEX
	JR	Z, MEM4			;Trennzeichen
MEM3:	LD	A,L
	POP	HL
	LD	(HL),A
	CP	A, (HL)			;RAM-Test
	JR	Z, MEM2			;i.O.
	RPRST
	DB	"ER"
	DB	' '+80H
	JR	MEM1
;
MEM4:	LD	A,(DE)			;Test Datenbyte=0
	CP	A, ' '			;wenn ja --> Z=1
	JR	Z, MEM3
	POP	HL
	INC	HL
	LD	(ARG2),HL		;1. nichtbearb. Adr.
	CP	A, ';'
	RET	Z			;Return, wenn ";" gegeben
	EX	AF, AF'
	CP	A, ' '
	JR	Z, MEM1			;Z=1 keine Eingabe
	DEC	HL
	CP	A, 'R'			;"R" gegeben?
	JR	NZ, MEM1		;nein
	DEC	HL			;sonst eine Adresse
	JR	MEM1			;zurueck
;
;-------------------------------------------------------------------------------
;Speichern auf Kassette
;-------------------------------------------------------------------------------
;
CSAVE:	LD	HL,(ARG1)
	CALL	SAV2			;Ausgabe 20H Bytes
SAV1:	EX	DE,HL
	LD	HL,(ARG2)
	AND	A, A
	SBC	HL,DE
	EX	DE,HL
	RET	C			;wenn File zu Ende
	CALL	SAV3			;Ausgabe 20H Byte
	JR	SAV1
;
SAV2:	LD	DE,(LSYNC)		;langer Vorton
	JR	SAV4
;Ausgabe ein Block = 20H Bytes
SAV3:	LD	DE,14			;kurzer Vorton
;Vorton: DE Halbschwingungen a 640 Hz
SAV4:	LD	B,70H			;Ausg. Vorton
SAV5:	DJNZ	SAV5
	CALL	SAV21			;Flanke wechseln
	DEC	DE
	LD	A,E
	OR	D
	JR	NZ,SAV4
;Trennschwingung: 1 Vollschwingung a 1280 Hz	
	LD	C,02H			;Ausgabe Synchron-
SAV6:	LD	B,35H			;impulse
SAV7:	DJNZ	SAV7
	CALL	SAV21			;Flanke wechseln
	DEC	C
	LD	DE,0
	JR	NZ,SAV6
;
	PUSH	DE			;DE=IX=0000
	POP	IX
;Kopfinhalt ausgeben
	LD	B,12H			;kurze Pause
SAV8:	DJNZ	SAV8
	CALL	SAV14			;Ausgabe DE
	LD	B,0FH			;kurze Pause
SAV9:	DJNZ	SAV9
;20H Bytes ausgeben
	LD	C,10H			;10H*2 Bytes
SAV10:	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	ADD	IX,DE			;Pruefsumme bilden
	INC	HL
	PUSH	BC
	CALL	SAV14			;Ausgabe DE
	POP	BC
	DEC	C
	JR	Z, SAV12		;Block fertig geschrieben
	LD	B,0EH			;kurze Pause
SAV11:	DJNZ	SAV11
	JR	SAV10
;Pruefsumme ausgeben
SAV12:	PUSH	IX
	POP	DE			;DE = Pruefsumme
	LD	B,10H			;kurze Pause
SAV13:	DJNZ	SAV13			
	CALL	SAV14			;DE ausgeben
	RET
;Ausgabe 16 Bit DE
SAV14:	LD	C,16			;16 Bit
SAV15:	SRL	D			;Hi-Bit in Cy schieben
	RR	E
	JR	NC, SAV17		;Cy=1, wenn Bit=1
;1-Bit 1 Halbschwingung mit 1280 Hz 
	LD	B,3
SAV16:	DJNZ	SAV16
	NOP
	JR	SAV18
;0-Bit 1 Vollschwingung mit 2560 Hz 
SAV17:	CALL	SAV21			;Flanke ausgeben
SAV18:	LD	B,19H
SAV19:	DJNZ	SAV19
	CALL	SAV21			;Flanke ausgeben
	DEC	C
	RET	Z			;wenn fertig
	LD	B,15H
SAV20:	DJNZ	SAV20
	JR	SAV15
;Flanke ausgeben
SAV21:	IN	A, PIOBD		;Flanke ausgeben
	XOR	80H			;durch Bit-Negierung Bit7
	OUT	PIOBD, A
	RET
;
;-------------------------------------------------------------------------------
;Laden von Kassette
;-------------------------------------------------------------------------------
;
CLOAD:	LD	HL,(ARG1)
LOA1:	CALL	LOA3			;laden 20H Bytes
	JR	Z, LOA2			;wenn kein Ladefehler
	CALL	PRST7			;sonst Fehler
	DB	"CS"
	DB	'<'+80h
	CALL	OUTHL			;Adresse ausgeben
	CALL	OUTSP
LOA2:	EX	DE,HL
	LD	HL,(ARG2)
	AND	A, A
	SBC	HL,DE			;Endadresse erreicht?
	EX	DE,HL
	RET	C			;ja --> fertig
	JR	LOA1			;sonst weiterlesen
;20H Bytes laden nach (HL)
LOA3:	CALL	LOA24			;synchronisieren
	CALL	LOA25			;Flanke abwarten
	LD	C,7
LOA5:	LD	DE,0910H		;D=9, E=10h
	LD	A,7
LOA6:	DEC	A
	JR	NZ, LOA6
	CALL	LOA24			;synchronisieren
LOA7:	CALL	LOA24			;Flanke ?
	JR	NZ, LOA3		;wenn nicht Vorton
	DEC	D
	JR	NZ, LOA7
	DEC	C
	JR	Z, LOA9
LOA8:	IN	A, 2
	XOR	B
	BIT	6,A
	JR	NZ, LOA5
	DEC	E
	JR	NZ, LOA8
	JR	LOA3
;Synchronisierimpulse lesen
LOA9:	CALL	LOA25			;Flanke abwarten
	LD	A,44H
LOA10:	DEC	A
	JR	NZ, LOA10
	CALL	LOA24			;Flanke ?
	JR	NZ, LOA9		;wenn nicht
	CALL	LOA25			;Flanke abwarten
	LD	A,1EH
LOA11:	DEC	A
	JR	NZ, LOA11
;2 Bytes Kopf lesen
	CALL	LOA19			;lesen DE
;20H Byte Daten lesen
	LD	C,10H			;10H x 2 Bytes
	PUSH	DE
	POP	IX			;IX-Pruefsummenzaehler=
	LD	A,1AH
LOA12:	DEC	A
	JR	NZ, LOA12
LOA13:	CALL	LOA19			;laden DE
	ADD	IX,DE			;Pruefsumme bilden
	PUSH	BC
	LD	C,L
	LD	B,H
	LD	HL,(ARG2)
	XOR	A
	SBC	HL,BC			;Endadresse erreicht?
	LD	L,C
	LD	H,B
	POP	BC
	JR	C, LOA14		;ja --> Leseende
	LD	(HL),E
	INC	HL
	LD	(HL),D
	JR	LOA16
LOA14:	LD	A,1
LOA15:	DEC	A
	JR	NZ, LOA15
	INC	HL
LOA16:	INC	HL
	DEC	C
	JR	Z, LOA18		;wenn Blockende
	LD	A,12H
LOA17:	DEC	A
	JR	NZ, LOA17
	JR	LOA13			;naechte 2 Byte
LOA18:	LD	A,12H
LOA27:	DEC	A
	JR	NZ, LOA27
;Pruefsumme lesen	
	CALL	LOA19			;laden DE
	EX	DE,HL
	PUSH	IX
	POP	BC
	XOR	A
	SBC	HL,BC			;Prüfsumme gleich?
	EX	DE,HL			;Z=0 Ladefehler
	RET
;Laden 2 Byte nach DE
LOA19:	PUSH	HL
	LD	L,10H			;16 Datenbits
LOA20:	CALL	LOA24			;Flanke ?
	JR	NZ, LOA21
	XOR	A			;Cy=0
	JR	LOA22
LOA21:	SCF
LOA22:	RR	D
	RR	E
	CALL	LOA25			;Flanke abwarten
	DEC	L
	JR	Z, LOA23		;wenn fertig
	LD	A,1EH
LOA26:	DEC	A
	JR	NZ, LOA26
	JR	LOA20
LOA23:	POP	HL
	RET
;Portabfrage
LOA24:	IN	A, PIOBD
	XOR	B
	BIT	6,A			;Bit6->TB in
	PUSH	AF
	XOR	B
	LD	B,A
	POP	AF			;Z=0 --> Flanke
	RET
;Warten auf Flankenwechsel
LOA25:	IN	A, PIOBD
	XOR	B
	BIT	6,A			;Bit6->TB in
	JR	Z, LOA25
	RET
;
;-------------------------------------------------------------------------------
;Speicherinhalt mit Checksumme anzeigen
;-------------------------------------------------------------------------------
;
D_KDO:	LD	HL,(ARG1)
DKO1:	LD	DE,(ARG2)
	SCF
	PUSH	HL
	SBC	HL,DE
	POP	HL
	RET	NC			;wenn EADR<AADR
	ROTHL
	LD	BC,0800H		;B=8
	LD	E,0			;EC=0 - Checksumme
DKO2:	RPRST
	DB	' '+80H
	LD	A,(HL)
	ROTHX
	ADD	A, C			;Checksumme bilden
	LD	C,A
	JR	NC, DKO3
	LD	A,0
	ADC	A, E
	LD	E,A
DKO3:	INC	HL
	DJNZ	DKO2
	RPRST
	DB	' '+80H
	LD	A,E
	CALL	OUX1			;Checksumme ausgeben
	LD	A,C
	ROTHX
	JR	DKO1
;
;-------------------------------------------------------------------------------
;Argumente uebergeben
;-------------------------------------------------------------------------------
;
PARA:	LD	HL,(ARG1)
	LD	DE,(ARG2)
	LD	BC,(ARG3)
	RET
;
;-------------------------------------------------------------------------------
;Speicherbereich mit Byte beschreiben
;-------------------------------------------------------------------------------
;
K_KDO:	CALL	PARA
	LD	(HL),C			;C=Fuellbyte
	PUSH	HL
	XOR	A
	EX	DE,HL
	SBC	HL,DE
	LD	B,H
	LD	C,L			;BC=Laenge
	POP	HL
	LD	D,H
	LD	E,L
	INC	DE
	LDIR
	RET
;
;-------------------------------------------------------------------------------
;Speicherbereich verschieben
;-------------------------------------------------------------------------------
;
T_KDO:	CALL	PARA
	XOR	A
	PUSH	HL
	SBC	HL,DE
	POP	HL
	JR	C, TKO1			;wenn Zieladr. groesser
	LDIR				;Vorwaertstransfer
	RET
TKO1:	ADD	HL,BC
	EX	DE,HL
	ADD	HL,BC
	EX	DE,HL
	DEC	HL
	DEC	DE
	LDDR				;Rueckwaertstransfer
	RET
;
;-------------------------------------------------------------------------------
;Debugging-Funktionen
;-------------------------------------------------------------------------------
;
;Register im Registerrettebereich ablegen
;
REGA:	LD	(DATA),SP
	LD	SP,REGPC
	PUSH	IX
	PUSH	IY
	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
	EXX
	EX	AF, AF'
	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
	JR	REG1
;Register aus Registerrettebereich holen
REGH:	LD	(DATA),SP
	LD	SP,REGBR
	POP	HL
	POP	DE
	POP	BC
	POP	AF
	EXX
	EX	AF, AF'
	POP	HL
	POP	DE
	POP	BC
	POP	AF
	POP	IY
	POP	IX
REG1:	LD	SP,(DATA)
	RET
;
;Einsprung bei Breakpoint
;
BREAK:	CALL	REGA			;Register ablegen
	POP	HL			;HL=Breakadr.+3
	LD	(REGSP),SP		;SP sichern
	LD	SP,SYSSK		;Systemstack nutzen
	DEC	HL
	DEC	HL
	DEC	HL
	LD	(REGPC),HL		;Breakadresse
	LD	DE,(BPADR)		;die originalen 3 Byte
	LD	HL,BPOPC		;Operanden zurueckbringen
	LD	BC,3
	LDIR
	CALL	REGDA
	JP	KDO2
;
;-------------------------------------------------------------------------------
;Breakpoint-Adresse setzen
;-------------------------------------------------------------------------------
;
B_KDO:	LD	HL,(ARG1)
	LD	(BPADR),HL
	LD	DE,BPOPC		;3 Byte Operanden
	LD	BC,3			;retten
	LDIR
	CALL	REGDA			;Register anzeigen
	RET
;
;-------------------------------------------------------------------------------
;Programm starten mit Breakpoint
;-------------------------------------------------------------------------------
;
E_KDO:	LD	HL,(BPADR)
	LD	(HL),0CDH		;CALL ...
	INC	HL
	LD	DE,BREAK		;an Breakpoint Unter-
	LD	(HL),E			;Brechung zu BREAK eintragen
	INC	HL
	LD	(HL),D
;
;-------------------------------------------------------------------------------
;Programm starten
;-------------------------------------------------------------------------------
;
J_KDO:	LD	HL,(ARG1)		;Startadresse
	LD	(REGPC),HL		;zwischenspeichern
	LD	SP,(REGSP)		;Stack generieren
	PUSH	HL			;Startadresse in Stack
	JP	REGH			;Register holen
					;und Pgm. durch RET starten
;
;-------------------------------------------------------------------------------
;Programm nach Break fortsetzen
;-------------------------------------------------------------------------------
;
G_KDO:	LD	HL,(REGPC)
	LD	(ARG1),HL
	LD	DE,(BPADR)
	XOR	A			;Cy=0
	SBC	HL,DE
	JR	NZ, E_KDO		;wenn nicht Breakpoint
	JR	J_KDO			;starten
;
;-------------------------------------------------------------------------------
;Ausgabe eines Doppelpunktes und (HL) und Leerzeichen
;-------------------------------------------------------------------------------
;
OUTDP:	RPRST
	DB	':'+80H
;
;-------------------------------------------------------------------------------
;Ausgabe hex 2 Byte Speicher (HL) und (HL-1)
;und ein Leerzeichen
;-------------------------------------------------------------------------------
;
OTHLS:	LD	A,(HL)			;hoeherwertiges Byte
	ROTHX				;ausgeben
	DEC	HL
	LD	A,(HL)			;niederwertiges Byte
	ROTHX				;ausgeben
	DEC	HL			;naechsten Aufruf vorbereiten
;
;-------------------------------------------------------------------------------
;Ausgabe ein Leerzeichen
;-------------------------------------------------------------------------------
;
OUTSP:	RPRST
	DB	' '+80H
	RET
;
;-------------------------------------------------------------------------------
;Registermodifizerung und -anzeige
;-------------------------------------------------------------------------------
;
;Z-Flag-Anzeige
;
AUS1:	RPRST				;Ausg. "1 "
	DB	"1"
	DB	' '+80H
	RET
AUSX:	JR	NZ, AUS1
	RPRST				;Ausg. "0 "
	DB	"0"
	DB	' '+80H
	RET
;
; R-Kommando
;
R_KDO:	CP	A, ':'
	JP	NZ, RKO3		;wenn Modifizierung
;
REGDA:	RPRST				;Anzeige Breakpointadresse
	DB	CR
	DB	"B"			;"BP"
	DB	'P'+80H
	LD	HL,BPADR+1
	ROTDP
	RPRST				;Ausgabe Operandenfolge
	DB	"BS"			;am Breakpoint
	DB	':'+80H
	LD	B,3			;3 Byte
	LD	HL,BPOPC
RKO1:	LD	A,(HL)
	ROTHX
	INC	HL
	DJNZ	RKO1
;
	RPRST				;Flaganzeige
	DB	"   S Z C"
	DB	' '+80H
	LD	A,(REGAF)		;A-Flagregister
	LD	L,A
	BIT	7,L			;S-Flag
	CALL	AUSX
	BIT	6,L			;Z-Flag
	CALL	AUSX
	BIT	0,L			;Cy-Flag
	CALL	AUSX
;
	LD	HL,REGSP+1		;Sonderregister-anzeige
	LD	B,2			;2 Registersaetze
	RPRST
RKO2:	DB	"S"
	DB	'P'+80H
	ROTDP
	RPRST
	DB	"P"
	DB	'C'+80H
	ROTDP
	RPRST
	DB	"I"
	DB	'X'+80H
	ROTDP
	RPRST
	DB	"I"
	DB	'Y'+80H
	ROTDP
;
RKO4:	RPRST				;Registersatz anzeigen
	DB	"A"
	DB	'F'+80H
	ROTDP
	RPRST
	DB	"B"
	DB	'C'+80H
	ROTDP
	RPRST
	DB	"D"
	DB	'E'+80H
	ROTDP
	RPRST
	DB	"H"
	DB	'L'+80H
	ROTDP
	DJNZ	RKO4
;
	LD	HL,(CUPOS)		;2. Satz als Schatten-
	DEC	HL			;register markieren:
	LD	(HL),27H		;"'"
	RET
;
RKO3:	LD	BC,0400H		;B=4, C-Registernummer
	LD	HL,(SOIL)
	INC	HL
	INC	HL
	LD	DE,RKO2
RKO5:	LD	A,(DE)			;Vergleich Registereingabe
	CP	A, (HL)			;mit allen Registern
	JR	Z, RKO8			;wenn gefunden
	INC	DE
RKO6:	PUSH	HL
	LD	HL,5
	ADD	HL,DE
	EX	DE,HL			;naechster Reg.name
	POP	HL
	INC	C			;C-Registernummer
	DJNZ	RKO5
	LD	B,4
	LD	A,C
	CP	A, 8
	JR	NZ, RKO5		;weitersuchen
	POP	AF			;sonst falsche Eingabe
	RST	38H			;--> zum KDO-Monitor
;
RKO7:	DEC	HL			;weitersuchen
	JR	RKO6
;
RKO8:	INC	DE			;Ueberpruefen zweiter
	INC	HL			;Buchstabe
	LD	A,(DE)
	AND	A, 7FH
	CP	A, (HL)
	JR	NZ, RKO7		;wenn ungleich
	INC	HL
	LD	A,(HL)			;Schattenregister ?
	CP	A, 27H			;"'"
	LD	A,C
	JR	NZ, RKO9		;wenn nicht
	ADD	A, 4
RKO9:	SLA	A
	LD	C,A
	LD	B,0
	LD	HL,REGSP+1
	SBC	HL,BC
	LD	B,H			;HL=Adresse im
	LD	C,L			;Registerrettebereich
	ROTHS				;Ausgabe Wert
	CALL	INLIN			;Eingabe neuer Wert
	LD	DE,(SOIL)
	CALL	INHEX			;HL=neuer Wert
	JR	NZ, RKO10		;wenn alles ok
	LD	A,(DE)			;keine Zahl, vielleicht
	CP	A, ';'			;Abbruch ?
	RET	Z
;
RKO10:	EX	DE,HL
	PUSH	BC
	POP	HL			;Adr. im Reg.rettebereich
	LD	(HL),D			;neuen Wert eintragen
	DEC	HL
	LD	(HL),E
	JP	REGDA			;Registeranzeige

	IF MONTYP == "Z1013_202"
;
;-------------------------------------------------------------------------------
;Hex-Umschaltung
;-------------------------------------------------------------------------------
;
H_KDO:	ld	hl,5048h		;Aenderung der Tastaturcodetab.
	ld	(LSYNC+15),hl		;Shift-Ebene 1, Zeile 2 und 3
	ld	hl,3830h		;vertauschen mit
	ld	(LSYNC+18),hl		;Shift-Ebene 0, Zeile 2 und 3
	RET
;
;-------------------------------------------------------------------------------
;ASCII-Umschaltung
;-------------------------------------------------------------------------------
;
A_KDO:	ld	hl,MONTB+2		;Laden der alten
	ld	de,LSYNC+2		;Tastaturcodetab.
	ld	bc,12h
	ldir
	RET

	ENDIF
;
;-------------------------------------------------------------------------------
;Window definieren
;-------------------------------------------------------------------------------
;
W_KDO:	CALL	WKO1			;Kontrolle Parameter
	JR	C, WKO3			;wenn Fehleingabe
	LD	(WINDL),HL		;neue Werte eintragen
	LD	(WINDA),BC
	LD	HL,(ARG2)
	LD	(WINDE),HL
	LD	HL,(CUPOS)		;Cursor loeschen
	LD	(HL),' '
	LD	(CUPOS),BC		;Cursor home
	RET
;
WKO1:	LD	A,(ARG1+1)
	CP	A, hi(BWS)		;innerhalb BWS ?
	RET	C			;nein
	LD	A,(ARG1)		;WINDOW-Anfang
	AND	A, 0E0H			;auf Zeilenanfang stellen
	LD	(ARG1),A
	LD	A,(ARG2)		;ebenso WINDOW-Ende
	AND	A, 0E0H			;auf Zeilenanfang stellen
	LD	(ARG2),A
	LD	HL,(ARG2)
	LD	BC,(ARG1)
	SBC	HL,BC
	RET	C			;Endadresse zu klein
	JR	Z, WKO2			;kein Window --> Fehler
	DEC	HL
	LD	A,3			;WINDOW zu gross ?
	CP	A, H
	RET	C			;ja
	INC	HL
	LD	DE,2*BWSCOL
	SBC	HL,DE
	RET	C			;wenn WINDOW zu klein
	LD	DE,BWSCOL
	ADD	HL,DE
	RET
;
WKO2:	SCF
	RET
;
WKO3:	POP	AF
	RST	38H
;
;-------------------------------------------------------------------------------
;NEXT-Kommando, Step-Betrieb
;-------------------------------------------------------------------------------
;
;Initialisierungstabelle fuer PIO bei NEXT
;PIO B5 => AB0 in
;
NKTA:	DB	Lo(NINTA)		;Interruptvektor Low Byte
	DB	10010111b		;Interruptsteuerwort, EI, Low-aktiv, Mask folgt
	DB	11011111b		;Interruptmaske Bit5 aktiv
;
;NEXT-Kommando
;
N_KDO:	LD	A,Hi(NINTA)
	LD	I,A			;Interruptvektor
	DI
	LD	HL,NKTA 		;Initialisieren PIO Port B
	LD	BC,0303H		;3 Bytes, Port PIOBC
	OTIR				;loest selbstaendig INT aus
	LD	HL,(BPADR)		;Byte vor Breakadr.(!)
	DEC	HL			;wird EI
	LD	A,(HL)
	LD	(NBYTE),A		;Byte retten
	LD	(HL),0FBH		;Code EI einschreiben
	LD	(SPADR),SP
	LD	SP,(REGSP)
	PUSH	HL			;Adr. mit EI-Befehl
	JP	REGH			;Register holen und Start
;Die PIO generiert bereits beim OTIR eine Interruptanforderung, da dabei AB0 => 0.
;Sobald EI und nachfolgender Befehl ausgeführt wird, wird der Interrupt angenommen
;und nachfolgende Routine über Inhalt der Adr. NINTA angesprungen (da IM 2)
;
;Eingang bei Interrupt
NINTR:	DI
	CALL	REGA			;Register retten
	LD	A,00000111b		;Interrupt von PIO
	OUT	PIOBC, A		;verbieten
	LD	HL,(BPADR)		;EI-Befehl durch Original-
	DEC	HL			;Byte ersetzen
	LD	A,(NBYTE)
	LD	(HL),A
	POP	HL
	LD	(BPADR),HL		;neue Breakadresse
	LD	(REGPC),HL
	LD	(REGSP),SP
	LD	SP,(SPADR)		;neue Operandenfolge
	LD	DE,BPOPC		;umladen
	LD	BC,3
	LDIR
	LD	HL,REGDA
	PUSH	HL
	RETI				;Sprung zur Registeranzeige
;
;-------------------------------------------------------------------------------
;Speicherbereiche vergleichen
;-------------------------------------------------------------------------------
;
C_KDO:	CALL	PARA			;Parameter holen
CKO1:	LD	A,(DE)
	CP	A, (HL)			;Vergleich
	JR	NZ, CKO3		;wenn ungleich
CKO2:	DEC	BC
	INC	HL
	INC	DE
	LD	A,B
	OR	C
	RET	Z			;wenn alles geprueft
	JR	CKO1			;sonst weitertesten
;
CKO3:	ROTHL				;1. Adresse
	ROTSP
	LD	A,(HL)
	ROTHX				;1. Byte
	ROTSP
	EX	DE,HL
	ROTHL				;2. Adresse
	ROTSP
	EX	DE,HL
	LD	A,(DE)
	ROTHX				;2. Byte
	RPRST
	DB	CR+80H
	RINCH				;warten auf Tastendruck
	CP	A, CR
	RET	NZ			;Abbruch wenn <> >ENTER<
	JR	CKO2			;sonst weitertesten

	IF	MONTYP <> "Z1013_A2"
;
;-------------------------------------------------------------------------------
;Bytefolge suchen
;-------------------------------------------------------------------------------
;
F_KDO:	LD	DE,(SOIL2)
	DEC	DE
	DEC	DE
	LD	(ARG3),DE		;DE = Beginn Bytefolge
	LD	BC,(ARG1)		;Suchadresse
FKO1:	LD	DE,(ARG3)
	RINHX				;L = 1. Suchbyte
FKO2:	LD	A,(BC)
	CP	A, L			;L = Suchbyte
	JR	Z, FKO3			;wenn Bytes gleich
	INC	BC			;sonst naechste Suchadresse
	LD	A,B
	OR	C
	JR	Z, FKO7			;wenn Speicherende erreicht
	JR	FKO2			;weitersuchen
;
FKO3:	PUSH	BC
	PUSH	DE
	LD	DE,(ARG2)		;Suchbyteanzahl
	DEC	DE
	LD	(FBANZ),DE		;Zwischenspeicher fuer Anzahl
	INC	BC
FKO4:	LD	A,D
	OR	E			;alle Suchbytes verglichen?
	POP	DE
	JR	Z, FKO5			;wenn Bytefolge gefunden
	RINHX				;naechstes Suchbyte holen
	LD	A,(BC)
	CP	A, L
	JR	NZ, FKO6		;wenn Folge nicht gefunden
	PUSH	DE
	LD	DE,(FBANZ)		;1 Byte weniger zu vergleichen
	DEC	DE
	LD	(FBANZ),DE
	INC	BC
	JR	FKO4			;weitervergleichen
;Bytefolge gefunden
FKO5:	POP	BC
	LD	(ARG1),BC
	JP	MEM			;Speicher modifizieren
;
FKO6:	POP	BC
	INC	BC
	JR	FKO1
;Bytefolge nirgends gefunden
FKO7:	RPRST
	DB	"NOT FOUND"
	DB	CR+80H
	RET

	ENDIF

	IF MONTYP == "Z1013_A2"
;
;-------------------------------------------------------------------------------
; Tastaturcodetabelle
;-------------------------------------------------------------------------------
;
keytab:
; spalte 0
	db  31h ; 1
	db  51h ; Q
	db  41h ; A
	db  59h ; Y
	db  32h ; 2
	db  57h ; W
	db  53h ; S
	db  58h ; X
; Spalte 1
	db  33h ; 3
	db  45h ; E
	db  44h ; D
	db  43h ; C
	db  34h ; 4
	db  52h ; R
	db  46h ; F
	db  56h ; V
; Spalte 2
	db  35h ; 5
	db  54h ; T
	db  47h ; G
	db  42h ; B
	db  36h ; 6
	db  5Ah ; Z
	db  48h ; H
	db  4Eh ; N
; Spalte 3
	db  37h ; 7
	db  55h ; U
	db  4Ah ; J
	db  4Dh ; M
	db  38h ; 8
	db  49h ; I
	db  4Bh ; K
	db  2Ch ; ,
; Spalte 4
	db  39h ; 9
	db  4Fh ; O
	db  4Ch ; L
	db  2Eh ; .
	db  30h ; 0
	db  50h ; P
	db  2Bh ; +
	db  2Fh ; /
; Spalte 5
	db  2Dh ; -
	db  40h ; @
	db  2Ah ; *
	db  5Eh ; ^
	db  5Bh ; [
	db  5Dh ; ]
	db  5Ch ;
	db  5Fh ; _
; Spalte 6
tab2:	db    0 ; Graph E/A
	db  0Dh ; ENT
	db    8 ; Cu. links
	db    9 ; Cu. rechts
	db  20h ; Leerz.
	db    0 ; CTRL
	db  0Bh ; Cu. hoch
	db  0Ah ; Cu. runter

	ENDIF

;
;-------------------------------------------------------------------------------
;Interrupttabelle fuer Break
;-------------------------------------------------------------------------------
;

	align	2
NINTA:	DW	NINTR

	END
