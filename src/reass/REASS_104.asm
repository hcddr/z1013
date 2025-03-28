; File Name   :	d:\hobby3\z1013-reass\reass 1.02.z13
; Format      :	Binary file
; Base Address:	0000h Range: 3600h - 3FFFh Loaded length: 0A00h

; robotron Z 1013 REASS 1.02
; MRB Z 1013 Dokumentation, Anlagenteil. Anlage 11
; reassembled V. Pohlers 21.09.2020

		cpu	z80undoc

; 1.03 vp 22.09.2020
; korr
; 1. neg. Offs. bei IX (outICpd)
; 2. (undoc) Bit-Befehle bei IX/IY (codeicb)
; 3. (undoc) IX-Ladebfehle codei407F komplett neu

; 1.04 vp 23.09.2020  kleine Optimierungen (call ocomma, coderet)

; Z1013-System
SOIL	equ 0016h
CURSR	equ 002Bh
xxxx	equ 0073h

OUTCH		macro
		rst	20h
		db    0			; OUTCH
		endm

INCH		macro
		rst	20h
		db    1			; INCH
		endm

PRST7		macro
		rst	20h
		db    2			; PRST7
		endm

INHEX		macro
		rst	20h
		db    3			; INHEX
		endm

OUTHX		macro
		rst	20h
		db    6			; OUTHX
		endm

OUTHL		macro
		rst	20h
		db    7			; OUTHL
		endm

OUTSP		macro
		rst	20h
		db  0Eh			; OUTSP
		endm

INSTR		macro
		rst	20h
		db  10h			; INSTR
		endm

;------------------------------------------------------------------------------
; Hauptschleife
;------------------------------------------------------------------------------

		org 3600h

reas:		;;ld	hl, 0073h	; ???
		;;ld	(hl), 0
		PRST7
		db 0Ch,0Dh,0Dh,"robotron Z 1013 REASS 1.04",8Dh
reas0:		PRST7
		db 0Dh,0Dh,"AB   BIS  ORG-ADRESSE:",0Dh,8Dh
		INSTR
		ld	de, (SOIL)	; Eingabe-Pointer
		INHEX
		ld	(adr), hl	; ab
		ld	(oadr),	hl	; Offset-Adr.
		INHEX
		ld	(eadr),	hl	; bis
		INHEX
		ld	a, h
		or	l
		jr	z, reas1
		ld	(oadr),	hl	; org-adr
reas1:		ld	hl, (adr)
		call	codlen		; Befehlslaenge bestimmen
		ld	a, b
		ld	(laen),	a
		ld	d, a		; Anz. Bytes
		ld	hl, (CURSR)	; Cursor-Adresse
reas2:		ld	(cupos), hl	; sichern (wird aber nicht weiter genutzt)
		ld	hl, (oadr)	; Offset-Adr.
		OUTHL
		OUTSP
		ld	e, 13		; Tab-Position
		ld	hl, (adr)
reas3:		ld	a, (hl)		; D Bytes hex. ausgeben
		OUTHX
		OUTSP
		inc	hl
		dec	e
		dec	e
		dec	e
		dec	d
		jr	nz, reas3
reas4:		dec	e		; mit Leerzeichen auffuellen
		jr	z, reas5
		OUTSP
		jr	reas4
reas5:		call	code		; Ausgabe Mnemonik
		ld	hl, (adr)	; oadr neu berechnen
		ld	d, 0
		ld	a, (laen)
		ld	e, a
		add	hl, de
		ld	(adr), hl
		ld	hl, (oadr)	; Offset-Adr.
		add	hl, de
		ld	(oadr),	hl	; Offset-Adr.
		ld	hl, (adr)
		ld	de, (eadr)	; Ende erreicht?
		scf
		sbc	hl, de
		jp	nc, reas0	; ja ->	Neustart
reas6:		INCH
		cp	3
		jp	z, 0038h	; STOP -> Ende
		cp	0Dh		; Enter?
		jr	nz, reas6	; nein -> neue Abfrage
		OUTCH			; Ausgabe neue Zeile
		jr	reas1		; naechster Befehl

;------------------------------------------------------------------------------
; Befehlslaenge bestimmen
;s. Kieder/Meder U880, Anhang Programmierunterlagen zum U880
;------------------------------------------------------------------------------

codlen:		ld	a, (hl)		; 1. Byte
		cp	0DDh
		jr	z, codlen_xy
		cp	0EDh
		jp	z, codlen_ed
		cp	0FDh
		jr	z, codlen_xy
		and	0F0h	      	; ?? wozu ??
		cp	40h
		jr	c, codelen_xx	; 00..3F
		cp	0C0h       	; 40..BF
		jr	c, len_1	; 1-Byte-Befehl
		ld	a, (hl)		; 1. Byte
		cp	0E7h 	    	; E7 (RST20H) -> Z1013 spezifisch 2 Byte
		jr	z, len_2	; 2-Byte-Befehl
		and	3Fh		; C0..FF
		cp	0Dh		; CD
		jr	z, len_3	; 3-Byte-Befehl
		cp	3		; C3
		jr	z, len_3	; 3-Byte-Befehl
		cp	0Bh		; CB
		jr	z, len_2	; 2-Byte-Befehl
		and	37h
		cp	13h		; D3,DB
		jr	z, len_2	; 2-Byte-Befehl
		and	0Fh
		cp	2		; C2,CA,D2,DA,E2,EA,F2,FA (JP)
		jr	z, len_3	; 3-Byte-Befehl
		cp	4		; C4,CC,D4,DC,E4,EC,F4,FC (CALL)
		jr	z, len_3	; 3-Byte-Befehl
		cp	6		; C6,CE;D6,DE,E6,EE,F6,FE (ADD n..CP n)
		jr	z, len_2	; 2-Byte-Befehl
		jr	len_1		; 1-Byte-Befehl
;00..3F
codelen_xx:	ld	a, (hl)
		and	0Fh
		cp	1		; 01,11,21,31
		jr	z, len_3	; 3-Byte-Befehl
		ld	a, (hl)
		and	37h		; 00,08
		jr	z, len_1	; 1-Byte-Befehl
		and	2Fh
		cp	22h		; 22,2A,32,3A
		jr	z, len_3	; 3-Byte-Befehl
		and	0Fh		; 10,18,20,28,30,38
		jr	z, len_2	; 2-Byte-Befehl
		cp	6		; 06,0E,16,1E,26,2E,36,3E
		jr	z, len_2	; 2-Byte-Befehl
		jr	len_1		; 1-Byte-Befehl
;
len_4:		ld	a, 4		; 4-Byte-Befehl
		jr	len0
;
len_3:		ld	a, 3		; 3-Byte-Befehl
		jr	len0
;
len_2:		ld	a, 2		; 2-Byte-Befehl
		jr	len0
;
len_1:		ld	a, 1		; 1-Byte-Befehl
len0:		ld	b, a
		ret

;DD xx, FD xx
codlen_xy:	inc	hl
		ld	a, (hl)		; 2.Byte
		cp	21h
		jr	z, len_4	; 4-Byte-Befehl
		cp	22h
		jr	z, len_4	; 4-Byte-Befehl
		cp	36h
		jr	z, len_4	; 4-Byte-Befehl
		cp	2Ah
		jr	z, len_4	; 4-Byte-Befehl
		cp	2Bh
		jr	z, len_2	; 2-Byte-Befehl
		cp	34h
		jr	z, len_3	; 3-Byte-Befehl
		cp	35h
		jr	z, len_3	; 3-Byte-Befehl
		cp	0CBh
		jr	z, len_4	; 4-Byte-Befehl
		cp	7Ch
		jr	z, len_2	; 2-Byte-Befehl
		cp	23h
		jr	z, len_2	; 2-Byte-Befehl
		cp	7Dh
		jr	z, len_2	; 2-Byte-Befehl
		and	0F0h
		cp	70h		; 70..7F 3 Byte
		jr	z, len_3	; 3-Byte-Befehl
		ld	a, (hl)		; 2.Byte
		and	7
		cp	6		; 46,4E,56,5E,66..BE  3	Byte
		jr	z, len_3	; 3-Byte-Befehl
		jr	len_2		; 2-Byte-Befehl

;ED xx
codlen_ed:	inc	hl
		ld	a, (hl)		; 2. Byte
		cp	80h		; >=80h, dann immer 2 Byte
		jr	nc, len_2	; 2-Byte-Befehl
		and	7
		cp	3		; 0011 o. 1011 ->  x3 oder xB
					; ED43,ED4B,ED53,ED5B,ED73,ED7B	-> 4 Byte
		jr	z, len_4	; 4-Byte-Befehl
		jr	len_2		; 2-Byte-Befehl

;------------------------------------------------------------------------------
; UP
;------------------------------------------------------------------------------

; Ausgabe 4 Zeichen + Leerzeichen
out4:		ld	a, (hl)
		OUTCH
		inc	hl
		ld	a, (hl)
		OUTCH
		inc	hl
		ld	a, (hl)
		OUTCH
		inc	hl
		ld	a, (hl)
		OUTCH
		OUTSP
		ret

;------------------------------------------------------------------------------
; Texte
; Reihenfolge ist oftmals wichtig!
;------------------------------------------------------------------------------

aHalt:		db "HALT"
aLd:		db "LD  "
;Liste Arithmetikbefehle. Reihenfolge ist wichtig!
aAdd:		db "ADD "		; 80..87, C6
aAdc:		db "ADC "		; 88..8F, CE
aSub:		db "SUB "               ; 90..97, D6
aSbc:		db "SBC "		; 98..9F, DE
		db "AND "               ; A0..A7, E6
		db "XOR "               ; A8..AF, EE
		db "OR  "               ; B0..B7, F6
		db "CMP "               ; B8..BF, FE
;
aPush:		db "PUSH"
aPop:		db "POP "
aRst:		db "RST "
;Befehle C3,D3,DB,..F3,FB
aJmp:		db "JMP "
aExx:		db "EXX "
aOut:		db "OUT "
aIn:		db "IN  "
aEx:		db "EX  "
aEx_0:		db "EX  "
aDi:		db "DI  "
aEi:		db "EI  "
;
aSpHl:		db "(SP),HL",0
aDeHl:		db "DE,HL",0
aSpHl_0:	db "SP,HL",0
aInc:		db "INC "
aDec:		db "DEC "
aRlca:		db "RLCA"		; 07
aRrca:		db "RRCA"               ; 0F
aRla:		db "RLA "               ; 17
aRra:		db "RRA "               ; 1F
aDaa:		db "DAA "               ; 27
aCpl:		db "CPL "               ; 2F
aScf:		db "SCF "               ; 37
aCcf:		db "CCF "               ; 3F
;cJR, Reihenfolge ist wichtig!
aNop:		db "NOP "
		db "EXAF"
		db "DJNZ"
		db "JR  "
		db "JRNZ"
		db "JRZ "
		db "JRNC"
		db "JRC "
;
aBc:		db "(BC)"
aDe:		db "(DE)"
;
aRlc:		db "RLC "
		db "RRC "
		db "RL  "
		db "RR  "
		db "SLA "
		db "SRA "
		db "SLL "
		db "SRL "
aBit:		db "BIT "
aRes:		db "RES "
aSet:		db "SET "
aSp:		db "(SP)"
; ED44..ED5E Reihenfolge wichtig!
asc_3872:	db "    "
aNeg:		db "NEG "               ; ED44
		db "RETN"               ; ED45
		db "IM 0"               ; ED46
		db "RETI"               ; ED4D
		db "IM 1"               ; ED56
		db "    "
		db "IM 2"               ; ED5E
;
aRrd:		db "RRD "		; ED67
		db "RLD "               ; ED6F
;
aIA:		db "I,A "		; ED47
		db "R,A "               ; ED4F
		db "A,I "               ; ED57
		db "A,R "               ; ED5F
;EDA0..EDBB
aLdi:		db "LDI "
		db "CPI "
		db "INI "
		db "OUTI"
		db "LDIR"
		db "CPIR"
		db "INIR"
		db "OTIR"
		db "LDD "
		db "CPD "
		db "IND "
		db "OUTD"
		db "LDDR"
		db "CPDR"
		db "INDR"
		db "OTDR"
;??
;;		db  20h
;;		db  4Fh	; O
;;		db  55h	; U
;;		db  54h	; T
;;		db  43h	; C
;;		db  48h	; H
;;		db  43h	; C
;;		db  41h	; A
;;		db  52h	; R
;;		db  20h
;;		db  4Ch	; L
;;		db  52h	; R
;;		db  20h
;;		db  20h

;------------------------------------------------------------------------------
; UPs
;------------------------------------------------------------------------------

; Lookup in Tabelle HL,	Offset 2*A
out2c:		sla	a		; 2*A
		add	a, l
		ld	l, a
		ld	a, h
		adc	a, 0
		ld	h, a		; HL+2*A
		ld	a, (hl)		; 1. Zeichen ausgeben
		OUTCH
		inc	hl
		ld	a, (hl)		; 2. Zeichen
		or	a		; 0 -> Ende
		ret	z
		OUTCH			; sonst ausgeben
		ret

; Ausgabe Einzelregister, Offs.	A
out_r:		ld	hl, aReg	; "B"
		jr	out2c		; Lookup in Tabelle HL,	Offset 2*A, Ausgabe

; Ausgabe Doppelregister, Offs.	A
out_rr:		ld	hl, aRReg	; "BC"
		jr	out2c		; Lookup in Tabelle HL,	Offset 2*A, Ausgabe

; Ausgabe Sprungbedingung, Offs. A
out_jpbed:	ld	hl, aJPBed
		jr	out2c		; Lookup in Tabelle HL,	Offset 2*A, Ausgabe

; Ausgabe diverse Texte, 2 Zeichen, Offs. A
out_divers:	ld	hl, aRet	; " R"
		jr	out2c		; Lookup in Tabelle HL,	Offset 2*A, Ausgabe

out_rr2:	ld	hl, aRReg2	; "BC"
		jr	out2c		; Lookup in Tabelle HL,	Offset 2*A, Ausgabe

;------------------------------------------------------------------------------
; 2 Zeichen-Texte (Register etc.)
; Reihenfolge ist wichtig!
;------------------------------------------------------------------------------

;s.a. Kieser/Meder 3.1.5.3 ff (S. 38ff)
;Liste Einzelregister r. Reihenfolge ist wichtig!
aReg:		db 'B',0
		db 'C',0
		db 'D',0
		db 'E',0
		db 'H',0
		db 'L',0
		db 'M',0
		db 'A',0
;Liste Doppelregister qq. Reihenfolge ist wichtig!
aRReg:		db "BC"
		db "DE"
		db "HL"
		db "AF"
;Liste Sprungbedingungen. Reihenfolge ist wichtig!
aJPBed:		db "NZ"
		db "Z "
		db "NC"
		db "C "
		db "PO"
		db "PE"
		db "P "
		db "M "
;Liste diverse Texte
aRet:		db " R"	; RET + bedingte RETs
		db "ET"
		db "JP"
		db "JR"
aCall:		db "CA"	; CALL + bedingte CALLs
		db "LL"
		db "-#"
		db "A,"
		db ",A"
;Liste Doppelregister dd. Reihenfolge ist wichtig!
aRReg2:		db "BC"
		db "DE"
		db "HL"
		db "SP"

;------------------------------------------------------------------------------
; UPs
;------------------------------------------------------------------------------

; Bits 5..3
bits543:	ld	a, (iy+0)	; Codebyte
		and	38h
		rrca
		rrca
		rrca
		and	7
		ret

; Bits 6..4
bits654:	call	bits543		; Bits 5..3
		rrca
		and	3
		ret

; BC hexa ausgeben
obchx:		ld	a, b
		OUTHX
		ld	a, c
		OUTHX
		ret

; Ausgabe Komma
ocomma:		ld	a, ','
		OUTCH
		ret

;------------------------------------------------------------------------------
; Befehls-Decoder
; in: aadr aktuelle Adr.
;------------------------------------------------------------------------------

code:		exx
		ld	iy, (adr)	; IY=Pointer auf Befehl
		ld	a, (iy+0)	; 1.Byte
		cp	40h
		jp	c, code003F	; 00.3F
		cp	80h
		jr	c, code407F	; Ladebebefehle
		cp	0C0h
		jr	c, code80BF	; Arithmetik-Befehle
		jr	codec0FF

; Ladebebefehle
;40..7F
code407F:	cp	76h
		jr	z, cHalt
		ld	hl, aLd		; "LD  "
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		call	bits543		; Bits 5..3
		call	out_r		; Ausgabe Einzelregister, Offs.	A
		call	ocomma
		ld	a, (iy+0)	; Codebyte
		and	7		; Register aus Bit 2..0
		call	out_r		; Ausgabe Einzelregister, Offs.	A
		exx
		ret		; Ende Code

; HALT
cHalt:		ld	hl, aHalt	; "HALT"
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		exx
		ret		; Ende Code

; Arithmetik-Befehle
; 80..BF add a,b..cp a
code80BF:	and	38h
		rrca			; Befehle in 8er Bloecken. durch 2 (RR) macht 4 Zeichen
		ld	hl, aAdd	; "ADD "
		add	a, l		; HL+A berechnen
		ld	l, a
		ld	a, h
		adc	a, 0
		ld	h, a
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		ld	a, (iy+0)
		and	7
		call	out_r		; Ausgabe Einzelregister, Offs.	A
		exx
		ret		; Ende Code

; C0..FF
codec0FF:	cp	0CBh
		jp	z, code_cb
		cp	0DDh
		jp	z, code_ix
		cp	0EDh
		jp	z, code_ed
		cp	0FDh
		jp	z, code_iy
		cp	0CDh
		jp	z, cCALL
		and	7
		jp	z, cRETBed	; Offs.	f. " R"
		cp	6
		jr	z, cADDRR	; Codebyte
		cp	7
		jr	z, cRST
		cp	4
		jp	z, cCALLBed	; Offs.	f. "CA"
		cp	2
		jp	z, cJPBed	; Offs.	f. "JP"
		ld	a, (iy+0)	; Codebyte
		and	0Fh
		cp	1
		jr	z, cPOP
		cp	5
		jr	z, cPUSH
		jp	cSonst1

; PUSH rr
cPUSH:		ld	hl, aPush	; "PUSH"
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
cPUSH1:		call	bits654		; Bits 6..4
		call	out_rr		; Ausgabe Doppelregister, Offs.	A
		exx
		ret		; Ende Code

; POP rr
cPOP:		ld	hl, aPop	; "POP "
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		jr	cPUSH1

; ADD rr,rr
cADDRR:		ld	a, (iy+0)	; Codebyte
		and	38h
		rrca			; Befehle in 8er Bloecken. durch 2 (RR) macht 4 Zeichen
		ld	hl, aAdd	; "ADD "
		add	a, l		; HL+A berechnen
		ld	l, a
		ld	a, h
		adc	a, 0
		ld	h, a
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		ld	a, (iy+1)	; 2. Codebyte
		OUTHX
		exx
		ret		; Ende Code

; RST n
cRST:		ld	hl, aRst	; "RST "
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		call	bits654		; RST codiert in Bit 5..3, hier	Bit (6)+5+4 schieben
		add	a, '0'          ; "0".."3'
		OUTCH
		ld	a, (iy+0)	; Codebyte
		and	8		; Bit 3
		add	a, '0'          ; "0" oder "8'
		OUTCH
		exx
		ret		; Ende Code

; CALL nn
cCALL:		ld	hl, aCall	; "CALL"
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		jr	outAdr		; Adresse ausgeben

; bedingter CALL
cCALLBed:	ld	a, 4		; Offs.	f. "CA"
cALLBed1:	call	out_divers	; Ausgabe diverse Texte, 2 Zeichen, Offs. A
		call	bits543		; Bits 5..3
		call	out_jpbed	; Ausgabe Sprungbedingung, Offs. A
		OUTSP
		jr	outAdr		; Adresse ausgeben

; bedingtes RET
cRETBed:	ld	a, 0		; Offs.	f. " R"
		call	out_divers	; Ausgabe diverse Texte, 2 Zeichen, Offs. A
		call	bits543		; Bits 5..3
		call	out_jpbed	; Ausgabe Sprungbedingung, Offs. A
		exx
		ret		; Ende Code

; bedingter JP
cJPBed:		ld	a, 2		; Offs.	f. "JP"
		jr	cALLBed1

;
outAdr:		ld	c, (iy+1)	; Adresse ausgeben
		ld	b, (iy+2)
		ld	(vadr),	bc	; tmp. Speicher	f. Adresse
		call	obchx		; BC hexa ausgeben
		exx
		ret		; Ende Code

;sonstige Befehle C0..FF
cSonst1:	ld	de, 0
		and	7
		cp	3
		jr	nz, cSonst11

;C3,D3,DB,..,F3,FB
		call	bits543		; Bits 5..3
		push	af
		ld	hl, aJmp	; "JMP "
		call	out4c1
		exx			; undo coderet EXX
		pop	af
		cp	0		; C3 = jmp
		jr	z, outAdr	; Adresse ausgeben
		cp	4
		jr	c, cINOUTn	; D3..DB out/in
		jr	z, cEXSPHL	; E3 = ex (sp),hl
		cp	5
		jr	z, cEXDEHL	; EB = ex de,hl
		exx
		ret		; Ende Code

;
cINOUTn:	ld	a, (iy+1)	;  2. Codebyte
		OUTHX
		exx
		ret		; Ende Code

; EX (SP),HL
cEXSPHL:	ld	hl, aSpHl	; "(SP),HL"
cEXSPHL1:	call	oStrng0		; Ausgabe nullterminierten String
		exx
		ret		; Ende Code

; EX DE,HL
cEXDEHL:	ld	hl, aDeHl	; "DE,HL"
		jr	cEXSPHL1

;
cSonst11:	call	bits654		; Bits 6..4
		jr	z, cRET		; C9=ret
		cp	2
		jr	c, cEXX		; D9 = exx
		jr	z, cJMPM	; E9 = jmp m

; F9 ld sp.hl
		ld	hl, aLd		; "LD  "
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		ld	hl, aSpHl_0	; "SP,HL"
		jr	cEXSPHL1

; RET
cRET:		ld	hl, aRet	; " R"
cRET1:		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		exx
		ret		; Ende Code

; EXX
cEXX:		ld	hl, aExx	; "EXX "
		jr	cRET1

; JMP M
cJMPM:		ld	hl, aJmp	; "JMP "
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		ld	a, 'M'
		OUTCH
		exx
		ret		; Ende Code

;00..3F
code003F:	and	0Fh
		cp	3
		jr	z, cinc_rr	; 03,13,23,33
		cp	0Bh
		jr	z, cdec_rr	; 0B,1B,2B,3B
		and	7
		jr	z, cJR		; 00,08,10,18,20,28,30,38
		cp	2
		jp	c, c_ld_add_rr	; 01,09,11,19,21,29,31,39
		jp	z, cld_a_irr	; 02,0A,12,1A,22,2A,32,3A
		cp	5
		jr	c, cINCr	; 04,0C,14,1C,24,2C,34,3C
		jr	z, cDECr	; 05,0D,15,1D,25,2D,35,3D
		cp	7
		jr	c, cLDrn	; 06,0E,16,1E,26,2E,36,3E
;07..3F
		ld	hl, aRlca	; "RLCA"
; Ausgabe Befehl via Bits543
out4c_0:	call	bits543		; Bits 5..3
		jp	out4c1

; 03,13,23,33 INC rr
cinc_rr:	ld	hl, aInc	; "INC "
cinc_rr1:	call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		call	bits654		; Bits 6..4
		call	out_rr2
		exx
		ret		; Ende Code

; 0B,1B,2B,3B DEC rr
cdec_rr:	ld	hl, aDec	; 0B,1B,2B,3B
		jr	cinc_rr1

; 04,0C,14,1C,24,2C,34,3C INC r
cINCr:		ld	hl, aInc	; "INC "
cINCr1:		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		call	bits543		; Bits 5..3
		call	out_r		; Ausgabe Einzelregister, Offs.	A
		exx
		ret		; Ende Code

; 05,0D,15,1D,25,2D,35,3D DEC r
cDECr:		ld	hl, aDec	; "DEC "
		jr	cINCr1

; 06,0E,16,1E,26,2E,36,3E LD r,n
cLDrn:		ld	hl, aLd		; "LD  "
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		call	bits543		; Bits 5..3
		call	out_r		; Ausgabe Einzelregister, Offs.	A
		call	ocomma
		ld	a, (iy+1)	; 2. Codebyte
		OUTHX
		exx
		ret		; Ende Code

; 00,08,10,18,20,28,30,38 JR + bedingte JR
cJR:		ld	hl, aNop
		call	out4c_0		; Ausgabe Befehl via Bits543
		exx
		call	bits543		; Bits 5..3
		cp	2
		jr	c, coderet	; Ende Code
		xor	a
		ld	b, a
		ld	c, (iy+1)
		bit	7, c
		jr	z, cJR1
		dec	b
cJR1:		ld	hl, (oadr)	; Offset-Adr.
		add	hl, bc
		push	hl
		pop	bc
		inc	bc
		inc	bc
		ld	(vadr),	bc	; tmp. Speicher	f. Adresse
		call	obchx		; BC hexa ausgeben
		ld	a, 6
		call	out_divers	; Ausgabe diverse Texte, 2 Zeichen, Offs. A
coderet:	exx
		ret		; Ende Code

;01,09,11,19,21,29,31,39
c_ld_add_rr:	call	bits543		; Bits 5..3
		bit	0, a
		jr	z, c_ld_rr
		rrca
		and	3
		push	af
		ld	hl, aAdd	; "ADD "
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		ld	a, 2
		call	out_rr		; Ausgabe Doppelregister, Offs.	A
		call	ocomma
		pop	af
		call	out_rr2
		exx
		ret		; Ende Code

; LD rr,nn
c_ld_rr:	rrca
		and	3
		push	af
		ld	hl, aLd		; "LD  "
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		pop	af
		call	out_rr2
		call	ocomma
		ld	c, (iy+1)
		ld	b, (iy+2)
		call	obchx		; BC hexa ausgeben
		exx
		ret		; Ende Code

;02,0A,12,1A,22,2A,32,3A
cld_a_irr:	ld	hl, aLd		; "LD  "
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		call	bits543		; Bits 5..3
		cp	4
		jr	nc, cLDnn	; 22,2A,32,3A
		and	a
		jr	z, cld_bc_a	; 02
		cp	2
		jr	z, cld_de_a	; 12
		jr	c, ld_a_bc	; 0A
; 1A ld a,(de)
		ld	a, 7		; "A,"
		call	out_divers	; Ausgabe diverse Texte, 2 Zeichen, Offs. A
		ld	hl, aDe		; "(DE)"
ld_a_de1:	call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		exx
		ret		; Ende Code

; LD A,(BC)
ld_a_bc:	ld	a, 7		; "A,"
		call	out_divers	; Ausgabe diverse Texte, 2 Zeichen, Offs. A
		ld	hl, aBc		; "(BC)"
		jr	ld_a_de1

; LD A,(DE)
cld_de_a:	ld	hl, aDe		; "(DE)"
		jr	cld_bc1

; LD (BC),A
cld_bc_a:	ld	hl, aBc		; "(BC)"
cld_bc1:	call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		ld	a, 8		; ",A"
		call	out_divers	; Ausgabe diverse Texte, 2 Zeichen, Offs. A
		exx
		ret		; Ende Code

; 22,2A,32,3A LD (nn),rr
cLDnn:		ld	b, (iy+2)	; Adr. aus Codebyte 2+3
		ld	c, (iy+1)
		call	bits543		; Bits 5..3
		sub	4
		jr	z, cld_nn_hl	; 22 ld	(nn),hl
		ld	d, a
		cp	2
		jr	z, cld_nn_a	; 32 ld	(nn),a
		jr	nc, cld_a_nn	; 3A ld	a,(nn)

;2A LD HL,(nn)
		ld	a, 2		; "HL"
		call	out_rr		; Ausgabe Doppelregister, Offs.	A
cld_hl_nn1:	call	ocomma		; Ausgabe Komma


; BC hexa in Klammern ausgeben
outIBC:		ld	a, '('
		OUTCH
		call	obchx		; BC hexa ausgeben
		ld	a, ')'
		OUTCH
		exx
		ret		; Ende Code

; 3A LD A,(nn)
cld_a_nn:	ld	a, 7		; "A"
		call	out_r		; Ausgabe Einzelregister, Offs.	A
		jr	cld_hl_nn1

; LD (nn),HL
cld_nn_hl:	call	outIBC		; BC hexa in Klammern ausgeben
		exx
		call	ocomma		; Ausgabe Komma
		ld	a, 2		; "HL"
		call	out_rr		; Ausgabe Doppelregister, Offs.	A
		exx
		ret		; Ende Code

; 32 LD	(nn),A
cld_nn_a:	call	outIBC		; BC hexa in Klammern ausgeben
		exx
		call	ocomma		; Ausgabe Komma
		ld	a, 7		; "A"
		call	out_r		; Ausgabe Einzelregister, Offs.	A
		exx
		ret		; Ende Code

;------------------------------------------------------------------------------
; CB-Befehle (Bit-Operationen)
;------------------------------------------------------------------------------
;
code_cb:	inc	iy		; CB übergehen
		ld	a, (iy+0)
		cp	40h
		jr	nc, code_cb1
; CB00.CB3F RLC..SRL r
		ld	hl, aRlc	; "RLC "
		call	out4c_0		; Ausgabe Befehl via Bits543
		exx
		ld	a, (iy+0)
		and	7
		call	out_r		; Ausgabe Einzelregister, Offs.	A
		exx
		ret		; Ende Code

;
code_cb1:	call	code_cb2
		ld	a, (iy+0)
		and	7		; Register
		call	out_r		; Ausgabe Einzelregister, Offs.	A
		exx
		ret		; Ende Code

code_cb2:	cp	80h
		jr	c, cBIT		; CB40..CB7F
		cp	0C0h
		jr	c, cRES		; CB80..CBBF

; CBC0..CBFF SET n,r
		ld	hl, aSet	; "SET "
		jr	cBIT1

; CB80..CBBF RES n,r
cRES:		ld	hl, aRes	; CB80..CBBF
		jr	cBIT1

; CB40..CB7F BIT n,r
cBIT:		ld	hl, aBit	; CB40..CB7F
cBIT1:		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		call	bits543		; Bits 5..3
		add	a, '0'          ; Bitnummer "0".."7"
		OUTCH
		call	ocomma
		ret

;------------------------------------------------------------------------------
; UPs IX+IY-Befehle
;------------------------------------------------------------------------------

;Fehler:negativer Offset falsch
;FF ->  IX-00 muss sein IX-01
; Ausgabe "(IC+d)"
outICpd:	ld	a, '('
		OUTCH
		ld	a, 'I'
		OUTCH
		ld	a, c
		OUTCH
		ld	a, '+'
		bit	7, b
		jr	z, outICpd1
		inc	a
		inc	a		; A = "-"
		OUTCH
		ld	a, b
		;cpl			; neg. Offs
		neg			; Korr vp
		jr	outICpd2
outICpd1:	OUTCH
		ld	a, b		; d
outICpd2:	OUTHX
		ld	a, ')'
		OUTCH
		ret
;;		db  7Ah			; ???

;Ausgabe 2 Zeichen A und C
outAC:		OUTCH			; Ausgabe 2 Zeichen A und C
		ld	a, c
		OUTCH
		ret

; Ausgabe IX,IY
outIC:	; FUNCTION CHUNK AT 3CE3 SIZE 00000006 BYTES
		ld	a, 'I'
		jr	outAC

; Ausgabe HX, HY
outHC:		ld	a, 'H'
		jr	outAC
; Ausgabe LX, LY
outLC:		ld	a, 'L'
		jr	outAC

; Ausgabe " ,"
outSPC:		OUTSP
		call	ocomma
		ret

;------------------------------------------------------------------------------
; IX+IY-Befehle
;------------------------------------------------------------------------------

code_ix:	ld	c, 'X'
		jr	code_iy1
;
code_iy:	ld	c, 'Y'
code_iy1:	inc	iy		; Vorbyte uebergehen
		ld	a, (iy+0)
		ld	b, (iy+1)
		cp	76h
		jr	z, codret2	; Ende Code
		cp	40h
		jp	c, codei003F
		cp	80h
		jp	c, codei407F
		cp	0C0h
		jp	c, codei80BF
		cp	0CBh
		jr	z, codeiCB
		cp	0E1h
		jr	z, codeiPOP
		cp	0E3h
		jr	z, codeiEX
		cp	0E5h
		jr	z, codeiPUSH
		cp	0E9h
		jr	z, codeiJP
		cp	0F9h
		jr	z, codeiLDSP
codret2:	exx
		ret		; Ende Code

; e1 POP IX
codeiPOP:	ld	hl, aPop	; "POP "
		jr	codeiPUSH1

; e5 PUSH IX
codeiPUSH:	ld	hl, aPush	; "PUSH"
codeiPUSH1:	call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		call	outIC		; Ausgabe IX,IY
		jr	codret2

; e3 EX (SP),IX
codeiEX:	ld	hl, aEx		; "EX  "
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		ld	hl, aSp		; "(SP)"
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		call	outSPC		; Ausgabe " ,"
		call	outIC		; Ausgabe IX,IY
		jr	codret2

; e9 JMP (IX)
codeiJP:	ld	hl, aJmp	; "JMP "
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		ld	a, '('
		OUTCH
		call	outIC		; Ausgabe IX,IY
		ld	a, ')'
		OUTCH
		jr	codret2

; f9 LD SP,IX
codeiLDSP:	ld	hl, aLd		; "LD  "
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		ld	a, 3		; "SP"
		call	out_rr2
		call	ocomma
		call	outIC		; Ausgabe IX,IY
		jr	codret2

; IX-Bitfehle

;fehler: Es wird erst das allg. Register M angezeigt, dann ",(IX+d)"
;korr:
code_cb3:	inc     iy
		ld      a, (iy+0)
		cp      40h
		jp      nc, code_cb2
		ld      hl, aRlc        ; "RLC "
		call    out4c_0
		exx
		ret

codeiCB:	inc	iy		; CB uebergehen
		ld	a, (iy+1)
		and	7
		cp	6		; nur gueltig f. (HL)
		jp	nz, coderet	; Ende Code
		;call	code_cb
		;call	ocomma		; Ausgabe Komma
		call	code_cb3
		call	outICpd		; Ausgabe "(IC+d)"
		exx
		ret		; Ende Code

; IX-Arithmetikbefehle
codei80BF:	ld	hl, aAdd	; "ADD "
		call	out4c_0		; Ausgabe Befehl via Bits543
		exx
		ld	a, (iy+0)
		and	7
		cp	4		; ",H"
		jr	z, outHCr
		cp	5		; ",L"
		jr	z, outLCr
		cp	6		; ",M"
		call	z, outICpd	; Ausgabe "(IC+d)"
		exx
		ret		; Ende Code

;
outHCr:		call	outHC		; Ausgabe HX, HY
		exx
		ret

;
outLCr:		call	outLC		; Ausgabe LX, LY
		exx
		ret

; IX-Ladebfehle
;;codei407F:	ld	hl, aLd		; "LD  "
;;		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
;;		call	bits543		; Bits 5..3
;;		cp	6		; "H," o. "L,"
;;		jr	z, codei407Fx
;;;fehler: bei ld r,HX etc. fehlt das Komma, und das 2. Register wird nicht als HX, LX geschrieben
;;;47D8 DD	5C	 LD   EH  -> ld	e,hx
;;;47DA DD	5D	 LD   EL  --> ld e,lx
;;		call	out_r		; Ausgabe Einzelregister, Offs.	A
;;		call	bits543		; Bits 5..3
;;		jr	codei407Fs
;;codei407Fx:	call	outICpd		; Ausgabe "(IC+d)"
;;		call	ocomma		; Ausgabe Komma
;;codei407Fs:	ld	a, (iy+0)
;;		and	7
;;		cp	6		; ",M"?
;;		jr	z, codei407Fm	;  dann (ix+d)
;;		call	out_r		; Ausgabe Einzelregister, Offs.	A
;;		exx
		ret		; Ende Code
;;codei407Fm:	call	ocomma		; Ausgabe Komma
;;		call	outICpd		; Ausgabe "(IC+d)"
;;		exx
		ret		; Ende Code


codei407F:	ld	hl, aLd		; "LD  "
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		call	bits543		; Bits 5..3
		call	ciLDreg
		call	ocomma		; Ausgabe Komma
codei407Fs:	ld	a, (iy+0)
		and	7
		call	ciLDreg
		exx
		ret		; Ende Code
;
ciLDreg:	cp	4		; ",H"
		jp	z, outHC
		cp	5		; ",L"
		jp	z, outLC
		cp	6		; ",M"
		jp	z, outICpd	; Ausgabe "(IC+d)"
		jp	out_r		; Ausgabe Einzelregister, Offs.	A


;IX sonstige
codei003F:	and	0Fh
		cp	9		; 09,19,29,39 add ix,rr
		jp	z, codeiADDrr
		ld	a, (iy+0)
		cp	21h
		jp	c, coderet	; Ende Code
		jp	z, codei21	; 21 ld	ix,nn
		and	0Fh
		cp	3		; 23 inc ix
		jp	z, codei23
		cp	0Bh
		jp	z, codei2B	; 2b dec ix
		and	7
		cp	4		; 24 inc hx, 2C	inc lx
		jr	z, codeincx
		cp	5		; 25 dec hx, 2d	dec lx
		jr	z, codeidecx
		ld	hl, aLd		; "LD  "
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		ld	a, (iy+0)
		cp	22h		; 22 ld (ix),nn
		jr	z, codei22
		cp	26h		; 26 ld hx,n
		jr	z, codei26
		cp	2Ah		; 2a ld ix,(nn)
		jr	z, codei2A
		cp	2Eh		; 2e ld lx,n
		jr	z, codei2E
		cp	36h		; 2e ld (ix),n
		jr	nz, coderet3
		call	outICpd		; Ausgabe "(IC+d)"
		call	ocomma		; Ausgabe Komma
		ld	a, (iy+2)
		OUTHX
		jr	coderet3

;2e LD (IX),n
codei2E:	call	outLC		; Ausgabe LX, LY
OUTcn:		ld	a, ','          ; Ausgabe ",n"
		OUTCH
		ld	a, (iy+1)
		OUTHX
coderet3:	exx
		ret		; Ende Code

;26 LD HX,n
codei26:	call	outHC		; Ausgabe HX, HY
		jr	OUTcn		; Ausgabe ",n"

;2a LD IX,(nn)
codei2A:	call	outIC		; Ausgabe IX,IY
		call	ocomma		; Ausgabe Komma
; Ausgabe "(nn)"
outcnn:		ld	a, '('
		OUTCH
		ld	c, (iy+1)
		ld	b, (iy+2)
		call	obchx		; BC hexa ausgeben
		ld	a, ')'
		OUTCH
		jr	coderet3

; 22 LD	(IX),nn
codei22:	push	bc
		call	outcnn		; Ausgabe "(nn)"
		exx
		pop	bc
		call	ocomma		; Ausgabe Komma
		call	outIC		; Ausgabe IX,IY
		jr	coderet3

; 25 DEC HX, 2d	DEC LX
codeidecx:	ld	hl, aDec	; "DEC "
		jr	codeinx2

; 24 INC HX, 2C	INC LX
codeincx:	ld	hl, aInc	; "INC "
codeinx2:	call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		ld	a, (iy+0)
		cp	27h		; ??
		jp	c, outHCr
		cp	30h		; ??
		jp	c, outLCr
		call	outICpd		; Ausgabe "(IC+d)"
		jr	coderet3

; 2b DEC IX
codei2B:	ld	hl, aDec	; "DEC "
		jr	codei232

; 23 INC IX
codei23:	ld	hl, aInc	; "INC "
codei232:	call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		call	outIC		; Ausgabe IX,IY
		exx
		ret		; Ende Code

; 21 LD	IX,nn
codei21:	ld	hl, aLd		; "LD  "
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		call	outIC		; Ausgabe IX,IY
		call	ocomma
		ld	c, (iy+1)
		ld	b, (iy+2)
		call	obchx		; BC hexa ausgeben
		jr	coderet3

;
codeiADDrr:	ld	hl, aAdd	; "ADD "
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		call	outIC		; Ausgabe IX,IY
		call	ocomma
		call	bits654		; Bits 6..4
		cp	2
		jr	z, codeiADDrr2
		call	out_rr2
		exx
		ret		; Ende Code
;
codeiADDrr2:	call	outIC		; Ausgabe IX,IY
		exx
		ret		; Ende Code


;------------------------------------------------------------------------------
; EB-Befehlsgruppe
;------------------------------------------------------------------------------

code_ed:	inc	iy		; ED uebergehen
		ld	a, (iy+0)
		cp	80h
		jp	nc, cblock	; EDA0..EDBB
		cp	40h		; <40 kein gueltiger Code
		jp	c, coderet	; Ende Code
		and	7		; 40,48,..,78 IN
		jr	z, cin
		cp	1		; 41,49,..,79 OUT
		jr	z, cout
		ld	a, (iy+0)
		and	0Fh
		cp	3		; 43,53,..,73 ld (nn),rr
		jp	z, cldcnnrr
		jp	c, csbchl	; 42,52,..,72 sbc hl,rr
		cp	0Ah
		jr	z, cadchl	; 4A,5A,..,7A adc hl,rr
		cp	0Bh
		jp	z, cldrrcnn	; 4B,5B,..,7B ld rr,(nn)
		ld	a, (iy+0)
		cp	60h
		jr	nc, crrd	; 67 rrd
;40..5F Rest
		and	7
		cp	7
		jr	z, ldspez	; 57 ld	a,i; 5F	ld a,r
		call	bits543		; Bits 5..3
		ld	b, a
		and	1
		ld	c, a
		inc	b
		ld	a, (iy+0)
		and	3
		add	a, b
		add	a, c
		ld	hl, asc_3872	; "    "
; Lookup in Tabelle HL,	Offset 2*A, Ausg. 4 Zeichen
out4c1:		rlca
		rlca
out4c:		ld	d, 0
		ld	e, a
		add	hl, de
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
coderet1:	exx
		ret		; Ende Code

; 67 RRD
crrd:		and	8
		rrca
		ld	hl, aRrd	; "RRD "
		jr	out4c

; 57 ld	a,i; 5F	ld a,r
ldspez:		ld	hl, aLd		; "LD  "
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		call	bits543		; Bits 5..3
		ld	hl, aIA		; "I,A "
		jr	out4c1

; 40,48,..,78 IN
cin:		ld	hl, aIn		; "IN  "
cin1:		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		call	bits543		; Bits 5..3
		cp	6
		jr	z, cin2		; ED70 -> in f
		call	out_r		; Ausgabe Einzelregister, Offs.	A
		exx
		ret
cin2:		ld	a, 'F'
		OUTCH
		exx
		ret

; 41,49,..,79 OUT
cout:		ld	hl, aOut	; "OUT "
		jr	cin1

; 42,52,..,72 SBC HL,rr
csbchl:		ld	hl, aSbc	; "SBC "
		jr	cadchl1


; 4A,5A,..,7A ADC HL,rr
cadchl:		ld	hl, aAdc	; "ADC "
cadchl1:	call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		ld	a, 2		; "HL"
		call	out_rr		; Ausgabe Doppelregister, Offs.	A
		call	ocomma
cadchl2:	call	bits654		; Bits 6..4
		call	out_rr2
		exx
		ret

; 43,53,..,73 LD (nn),rr
cldcnnrr:	ld	hl, aLd		; "LD  "
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		call	outcnn		; Ausgabe "(nn)"
		exx			; wg coderet
		call	ocomma		; Ausgabe Komma
		jr	cadchl2

; 4B,5B,..,7B LD rr,(nn)
cldrrcnn:	ld	hl, aLd		; "LD  "
		call	out4		; Ausgabe 4 Zeichen + Leerzeichen
		call	cadchl2
		exx			; wg coderet
		call	ocomma		; Ausgabe Komma
		jp	outcnn		; Ausgabe "(nn)"

;EDA0..EDBB Blockbefehle LDI..OTDR
cblock:		cp	0A0h
		jp	c, coderet	; Ende Code
		cp	0BCh
		jp	nc, coderet	; Ende Code
		and	7
		cp	4
		jp	nc, coderet	; Ende Code
		ld	a, (iy+0)
		cp	0B0h
		jr	c, cblock1
		add	a, 4		; AC..AF gibt es nicht
cblock1:	and	0Fh
		ld	hl, aLdi	; "LDI "
		jp	out4c1

;------------------------------------------------------------------------------
; UP
;------------------------------------------------------------------------------

; Ausgabe nullterminierten String
oStrng0:	ld	a, (hl)
		or	a
		ret	z
		OUTCH
		inc	hl
		jr	oStrng0		; Ausgabe nullterminierten String

;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------

adr:		dw 0FFFFh
vadr:		dw 0FFFFh		; tmp. Speicher	f. Adresse
					; (wird nur bweschrieben, nicht genutzt)
laen:		dw 0FFFFh
eadr:		dw 0FFFFh		; End-Adresse
oadr:		dw 0			; Offset-Adr., wird bei JR beachtet
cupos:		dw 0			; Cursor-Adresse
					; (wird nur bweschrieben, nicht genutzt)

		end

