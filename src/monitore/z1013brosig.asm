	CPU	z80

;Z1013-MONITOR Brosig (2.028 K7659)
;reass: 1988-1990 Volker Pohlers, Lomonossowallee 41/81, Greifswald, 2200
;basierend auf GENS3M-Listing des 2.02-Monitors von C.Fischer/Ilmenau
;und teilweise (Tastaturkommentare) auf dem CP/M-BIOS 4.8-Listing
;Fassung für den Arnold-Assembler 
;Volker Pohlers, Sanitz, 23.04.2004

; Makros
;hi              function x, (x>>8) & 0ffh	; High-Byte
;lo              function x, x & 0ffh		; Low-Byte

;
;RAM-Zellen
;
R20BT:	EQU	00003H			;Nummer des RST20-Calls
LAKEY:	EQU	00004H			;letztes Zeichen von Tastatur
BPADR:	EQU	0000BH			;Breakpointadresse
BPOPC:	EQU	0000DH			;Operandenfolge bei Breakpoint
DATA:	EQU	00013H			;Adresse bei INHEX
SHILO:	EQU	00015H			;
SOIL:	EQU	00016H			;Beginn Eingabezeile
ARG1:	EQU	0001BH			;1. Argument
ARG2:	EQU	0001DH			;2. Argument
BUFFA:	EQU	0001FH			;vom Cursor verdecktes Zeichen
RST20:	EQU	00020H			;RST 20H
ARG3:	EQU	00023H			;3. Argument
SOIL2:	EQU	00025H			;Rest Eingabezeile
KYBTS:	EQU	00027H			;Tastaturroutinenzelle
CUPOS:	EQU	0002BH			;aktuelle Cursorposition
LSYNC:	EQU	00033H			;Kenntonlaenge
DRZSP:	EQU	00035H			;3 Byte fuer Druckertreiber
RST38:	EQU	00038H			;RST 38H
PTKEY:	EQU	0003BH			;Tastenbelegungsfeldpointer
PTSTG:	EQU	0003DH			;Stringfeldpointer
PTNXZ:	EQU	0003FH			;Pointer nae. auszg. $Zeichen
PLFKY:	EQU	00041H			;Laenge Funktionstastenfeld
PTFKY:	EQU	00043H			;Pointer Funktionstastenfeld
PTFKA:	EQU	00045H			;Pointer Fkt.tastenadressfeld
WINDL:	EQU	00047H			;Windowlaenge
WINDA:	EQU	00049H			;Windowanfang
WINDE:	EQU	0004BH			;Windowende+1
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
;Kopfpuffer fuer Headersave/load
AADR:	EQU	000E0H			;Anfangsadresse
EADR:	EQU	000E2H			;Endadresse
SADR:	EQU	000E4H			;Startadresse
TYP:	EQU	000ECH			;Typ
SIGNS:	EQU	000EDH			;Kopfkennzeichnung
NAME:	EQU	000F0H			;Name
;Druckertreiber

DRINI:	EQU	0E800H			;Initialisierung log. Treiber
DRZEL:	EQU	0E803H			;druckt (ARG1) log.
DRAKK:	EQU	0E806H			;druckt Register A log.
ZEIDR:	EQU	0E809H			;druckt A phys.
BSDRK:	EQU	0E80CH			;Bildschirmdruck
HARDC:	EQU	0E80FH			;druckt A log., wenn Flag on
;Bildschirm
BWS:	EQU	0EC00H
;
;Markenvereinbarungen
;
CLS:	EQU	0CH
CR:	EQU	0DH
ESC:	EQU	27
NL:	EQU	1EH
LF:	EQU	0AH
;
ROUTC:	EQU	000E7H
RINCH:	EQU	001E7H
RPRST:	EQU	002E7H
RINHX:	EQU	003E7H
RINKY:	EQU	004E7H
ROTHX:	EQU	006E7H
ROTHL:	EQU	007E7H
ROTHS:	EQU	00CE7H
ROTDP:	EQU	00DE7H
ROTSP:	EQU	00EE7H
;
;
;
	ORG	0F000H
;
INIT:	JR	INIT2
;Initialisierung
INIT1:	LD	HL,REGBR		;Registerrette-
	LD	DE,REGBR+1		;bereich loeschen
	LD	(HL),0
	LD	BC,0015H
	LDIR
INIT2:	LD	SP,SYSSK		;System-Stack
	NOP
	CALL	INIT3			;Initialisierung
	LD	A,0C3H			;JMP ...
	LD	(RST20),A
	LD	HL,RST1			;RST20 eintragen
	LD	(RST20+1),HL
	LD	A,0CFH			;PIO Port B init.
	OUT	3, A			;BIT-Mode
	LD	A,7FH			;BIT7-Ausgang
	OUT	3, A
	LD	HL,MONTB		;System-RAM init.
	LD	DE,LSYNC
	LD	BC,INCH-MONTB		;Laenge Tabelle
	LDIR
;Systemmeldung
	DW	RPRST
	DB	CLS
	DB	CR
	DB	CR
	DB	"Z1013+K7659/2.028 RB"
	DB	CR+80H
;
	LD	HL,USRSK		;User-Stack
	LD	(REGSP),HL
	IM	2
	JR	KDO2
;
;Eingang Kommandomodus
;
KDO1:	LD	SP,SYSSK		;System-Stack
	CALL	PRST7
	DB	0BFH			;"?"
KDO2:
	CALL	INLIN			;Zeile eingeben
	LD	DE,(SOIL)
	CALL	SPACE			;Leerzeichen uebergehen
	LD	B,A			;B=1. Zeichen
	INC	DE
	LD	A,(DE)
	LD	C,A			;C=2. Zeichen
	PUSH	BC
	INC	DE
	CALL	INHEX
	JR	NZ, KDO3
	LD	A,(DE)
	CP	A, ':'			;die alten Werte nehmen ?
	JR	Z, KDO4
KDO3:	LD	(ARG1),HL		;neue Argumente holen
	CALL	INHEX
	LD	(ARG2),HL
	CALL	INHEX
	LD	(ARG3),HL
KDO4:	POP	BC
	EX	AF, AF'			;'
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
	JR	NZ, KDO5			;nein
	LD	A,B
	CP	A, '@'			;"@"-Kommando?
	JR	NZ, KDO1			;nein -> Eingabefehler
	LD	HL,USRKD		;Suchen in "@"-Kdo.tab.
	LD	B,C
	JR	KDO5
;
KDO6:	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	EX	DE,HL			;HL=UP-Adresse
	EX	AF, AF'			;'
	LD	BC,KDO2			;Returnadresse
	PUSH	BC
	JP	(HL)			;Sprung zur Routine
;
KDOTB:
	DB	"Z"
	DW	Z_KDO
	DB	"B"
	DW	B_KDO
	DB	"C"
	DW	C_KDO
	DB	"D"
	DW	D_KDO
	DB	"E"
	DW	E_KDO
	DB	"F"
	DW	F_KDO
	DB	"G"
	DW	G_KDO
	DB	"O"
	DW	O_KDO
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
;Eingang bei RST 20H
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
	DW	H_KDO			;DB 18
	DW	A_KDO			;DB 19

;
;Eingabe ein Zeichen von der Tastatur in A
;
INKEY:	PUSH	BC
	PUSH	DE
	PUSH	HL
	CALL	INKY
	POP	HL
	POP	DE
	POP	BC
	RET
;
;uebergibt aktuell gedrueckte Taste
;
POLL:	XOR	A
	LD	(LAKEY),A		;Puffer loeschen
	CALL	INKEY
	PUSH	AF
	XOR	A
	LD	(LAKEY),A		;Puffer wieder
	POP	AF			;reinigen
	RET
;
;Anzeige Zusatzmonitorkommandos
;
Z_KDO:	LD	DE,USRKD		;Adr. Tabelle
ZKO1:	LD	A,(DE)
	AND	A, 0E0H
	RET	Z			;wenn Steuerzeichen
	BIT	7,A
	RET	NZ			;wenn Grafikzeichen
	DW	RPRST
	DB	0C0H			;"@"
	LD	A,(DE)
	DW	ROUTC			;Buchstabe ausgeben
	DW	RPRST
	DB	0BEH			;">"
	INC	DE
	LD	A,(DE)
	LD	L,A
	INC	DE
	LD	A,(DE)
	LD	H,A
	DW	ROTHL			;Adresse anzeigen
	DW	RPRST
	DB	CR+80H
	INC	DE
	JR	ZKO1			;naechstes Kommando
;
;Portausgabe
;
O_KDO:	LD	A,(ARG1)		;Portadresse
	LD	C,A
	LD	A,(ARG2)		;Wert
	OUT	(C),A
	RET
;
;Registeranzeige / NMI-Routine
;
REGAN:	CALL	REGA			;Register retten
	POP	HL
	LD	(BPADR),HL
	LD	(REGPC),HL
	LD	(REGSP),SP
;
	LD	SP,SYSSK
	LD	DE,BPOPC
	LD	BC,3
	LDIR				;BREAK-Bytes kopieren
;
	CALL	REGDA			;Registeranzeige
;
	LD	SP,SYSSK		;Grundzustand herstellen
	LD	HL,KDO2
	PUSH	HL
	RETN				;zum Monitor
;
;Initialisierung der Zusatzfunktionen
;
INIT3:	LD	A,(NMI)
	CP	A, 0C3H			;schon init. ?
	JR	Z, INIT4		;dann zurueck
;
	LD	A,0C3H
	LD	(NMI),A
	LD	HL,REGAN		;NMI-Funktion:
	LD	(NMI+1),HL		;Registeranzeige
;
	CALL	RZMIN			;Init. Zusatzmonitor
;
	XOR	A
	LD	(KYBTS),A
;Signalton
	LD	BC,0A040H
	CALL	RBEEP
	LD	BC,0500H
	CALL	RBEEP
	LD	BC,0A040H
	CALL	RBEEP
;
	LD	HL,MONTB
	LD	DE,LSYNC
	LD	BC,001AH		;Monitorzellen
	LDIR				;initialisieren
INIT4:	RET
;
;Hardcopy
;
COPY:	PUSH	HL
	PUSH	AF
	LD	HL,KYBTS
	BIT	3,(HL)
	JR	Z, COPY2		;kein Copy an
;
	CP	A, CR			;Konvertierung CR
	JR	NZ, COPY1
	LD	A,1EH			;in NL
COPY1:	CALL	RDRAK			;Druckerausgabe
COPY2:	POP	AF
	POP	HL
;
	PUSH	AF
	PUSH	BC
	PUSH	DE
	JP	OUT1			;weiter zu OUTCH
;
;
;
	DB	0FFH
	DB	0FFH
	DB	0FFH
	DB	0FFH
	DB	0FFH
	DB	0FFH
	DB	0FFH
	DB	0FFH
	DB	0FFH

;
;Monitorinit., wird nach 33H umgeladen
;
MONTB:
	phase	0033h

	DW	07D0H			;Kenntonlaenge	LSYNC
	DB	0
	DB	0
	DB	0
	JP	KDO1			;RST38-Sprung	RST38
	DW	K7KEY			;Tastaturbelegungsfeld
	DW	K7STG			;Stringfeld
	DW	0
	DW	K7FKA-K7FKY		;Laenge Funktionstastenfeld
	DW	K7FKY			;Fkt.tastenpositionsfeld
	DW	K7FKA			;Funktionstastenadressfeld
	DW	03E0H			;WINDOW-Laenge	WINDL
	DW	BWS			;WINDOW-Anfang	WINDA
	DW	BWS+400H		;WINDOW-Ende	WINDE

	dephase
;
;Zeichen von Tastatur holen, warten bis Taste gedrueckt
;

INCH:	NOP
	NOP
	NOP
INC1:	CALL	INKEY
	OR	A
	JR	Z, INC1			;keine Taste gedrueckt
	NOP
	NOP
	NOP
	RET
;
;Ausgabe Zeichen auf Bildschirm
;
OUT0:	AND	A, 7FH
;
OUTCH:
	JP	COPY			;einschleifen Hardcopy
;
OUT1:	PUSH	HL
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
	JR	NZ, OUT6			;nein
;
	LD	DE,(WINDA)		;scrollen um
	LD	HL,0020H		;eine Zeile im Window
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
	LD	BC,001FH
	LDIR
;
	LD	HL,(SOIL)		;SOIL um eine Zeile
	LD	DE,0020H		;erhoehen
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
;
OUT7:	DEC	HL			;Cursor links
	JR	OUT3
;
OUT8:	LD	A,0E0H			;neue Zeile
	AND	A, L
	ADD	A, 20H			;A=NWB der Position
	LD	C,A			;eine Zeile tiefer
OUT9:	LD	(HL),' '		;Rest der Zeile ab
	INC	HL			;ENTER loeschen
	LD	A,L
	CP	A, C
	JR	NZ, OUT9
	JR	OUT3
;
OUT10:	LD	HL,(WINDL)		;Window loeschen
	LD	BC,001FH
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
;Ausgabe String, bis Bit7=1
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
;Eingabe einer Zeile mit Promtsymbol
;
INLIN:	CALL	PRST7
	DB	" #"
	DB	0A0H			;" "
;
;Eingabe einer Zeichenkette
;
INSTR:	PUSH	HL
	LD	HL,(CUPOS)
	LD	(SOIL),HL		;SOIL=1.Position
INS1:	DW	RINCH			;Zeichen von Tastatur
	DW	ROUTC			;anzeigen
	CP	A, CR			;>ENTER<?
	JR	NZ, INS1		;nein --> weiter eingeben
	POP	HL
	RET
;
;fuehrende Leerzeichen ueberlesen
;
SPACE:	LD	A,(DE)
	CP	A, ' '
	RET	NZ
	INC	DE
	JR	SPACE
;
;letzen vier Zeichen als Hexzahl konvertieren
;und in DATA ablegen
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
;Konvertierung ASCII-Hex ab (DE) --> (HL)
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
;Ausgabe (A) hexadezimal
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
;Ausgabe HL hexadezimal
;
OUTHL:	PUSH	AF
	LD	A,H
	CALL	OUTHX
	LD	A,L
	CALL	OUTHX
	POP	AF
	RET
;
;Speicherinhalt modifizieren
;
MEM:	LD	HL,(ARG1)
MEM1:	DW	ROTHL			;Ausgabe Adresse
	PUSH	HL
	DW	ROTSP			;Leerzeichen
	LD	A,(HL)
	DW	ROTHX			;Ausgabe Byte
	CALL	INLIN
	LD	DE,(SOIL)
	LD	A,(DE)
	EX	AF, AF'			;'
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
	DW	RPRST
	DB	"ER"
	DB	0A0H			;" "
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
	EX	AF, AF'			;'
	CP	A, ' '
	JR	Z, MEM1			;Z=1 keine Eingabe
	DEC	HL
	CP	A, 'R'			;"R" gegeben?
	JR	NZ, MEM1		;nein
	DEC	HL			;sonst eine Adresse
	JR	MEM1			;zurueck
;
;Abspeichern auf Kassette
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
SAV3:	LD	DE,000EH		;kurzer Vorton

SAV4:	PUSH	HL
	POP	IX
;HL=Adresse, IX=Kopfinhalt, DE=Laenge Vorton
BSMK:	LD	B,70H			;Vorton ausgeben
SAV5:	DJNZ	SAV5
	CALL	SAV21			;Flanke ausgeben
	DEC	DE
	LD	A,E
	OR	D
	JR	NZ, BSMK
;
	LD	C,2			;Trennzeichen schreiben
SAV6:	LD	B,36H
SAV7:	DJNZ	SAV7
	CALL	SAV21			;Flanke ausgeben
	DEC	C
	JR	NZ, SAV6
	PUSH	IX
	POP	DE

;
	LD	B,12H			;Kopfinhalt ausgeben
SAV8:	DJNZ	SAV8
	CALL	SAV14			;Ausgabe DE
	LD	B,0FH
SAV9:	DJNZ	SAV9
;
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
	LD	B,0EH
SAV11:	DJNZ	SAV11
	JR	SAV10
;
SAV12:	PUSH	IX
	POP	DE			;Pruefsumme
	LD	B,10H
SAV13:	DJNZ	SAV13
	CALL	SAV14			;ausgeben
	RET
;
SAV14:	LD	C,10H			;Ausgabe DE
SAV15:	SRL	D
	RR	E
	JR	NC, SAV17		;C=1 Bit=1
	LD	B,3
SAV16:	DJNZ	SAV16
	NOP
	JR	SAV18
SAV17:	CALL	SAV21			;Flanke ausgeben
SAV18:	LD	B,19H
SAV19:	DJNZ	SAV19
	CALL	SAV21			;Flanke ausgeben
	DEC	C
	RET	Z			;wenn fertig
	LD	B,15H
SAV20:	DJNZ	SAV20
	JR	SAV15
;
SAV21:	IN	A, 2			;Flanke ausgeben
	XOR	80H			;durch Bit-Negierung
	OUT	2, A
	RET
;
;Laden von Kassette
;
CLOAD:	LD	HL,(ARG1)
LOA1:	CALL	LOA3			;laden 20H Bytes
	JR	Z, LOA2			;wenn kein Ladefehler
	CALL	PRST7
	DB	"CS"
	DB	0BCH			;"<"
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
LOA5:	LD	DE,0910H
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
	CALL	LOA19			;Pruefsumme lesen
	EX	DE,HL
	PUSH	IX
	POP	BC
	XOR	A
	SBC	HL,BC
	EX	DE,HL			;Z=0 Ladefehler
	RET
;Laden 2 Byte nach DE
LOA19:	PUSH	HL
	LD	L,10H			;2 Trenn- und 8 Datenbits
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
LOA24:	IN	A, 2
	XOR	B
	BIT	6,A
	PUSH	AF
	XOR	B
	LD	B,A
	POP	AF			;Z=0 --> Flanke
	RET
;Warten auf Flankenwechsel
LOA25:	IN	A, 2
	XOR	B
	BIT	6,A
	JR	Z, LOA25
	RET
;
;Speicherinhalt mit Checksumme anzeigen
;
D_KDO:	LD	HL,(ARG1)
DKO1:	LD	DE,(ARG2)
	SCF
	PUSH	HL
	SBC	HL,DE
	POP	HL
	RET	NC	;wenn EADR<AADR
	DW	ROTHL
	LD	BC,0800H		;B=8
	LD	E,0			;EC=0 - Checksumme
DKO2:	DW	RPRST
	DB	0A0H			;" "
	LD	A,(HL)
	DW	ROTHX
	ADD	A, C			;Checksumme bilden
	LD	C,A
	JR	NC, DKO3
	LD	A,0
	ADC	A, E
	LD	E,A
DKO3:	INC	HL
	DJNZ	DKO2
	DW	RPRST
	DB	0A0H			;" "
	LD	A,E
	CALL	OUX1			;Checksumme ausgeben
	LD	A,C
	DW	ROTHX
	JR	DKO1
;
;Argumente uebergeben
;
PARA:	LD	HL,(ARG1)
	LD	DE,(ARG2)
	LD	BC,(ARG3)
	RET
;
;Speicherbereich mit Byte beschreiben
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
;Speicherbereich verschieben
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
;Breakpoint-Adresse setzen
;
B_KDO:	LD	HL,(ARG1)
	LD	(BPADR),HL
	LD	DE,BPOPC		;3 Byte Operanden
	LD	BC,3			;retten
	LDIR
	CALL	REGDA			;Register anzeigen
	RET
;
;Programm starten mit Breakpoint
;
E_KDO:	LD	HL,(BPADR)
	LD	(HL),0CDH		;CALL ...
	INC	HL
	LD	DE,BREAK		;an Breakpoint Unter-
	LD	(HL),E			;Brechung zu BREAK eintragen
	INC	HL
	LD	(HL),D
;
;Programm starten
;
J_KDO:	LD	HL,(ARG1)		;Startadresse
	LD	(REGPC),HL		;zwischenspeichern
	LD	SP,(REGSP)		;Stack generieren
	PUSH	HL			;Startadresse in Stack
	JP	REGH			;Register holen
					;und Pgm. durch RET starten
;
;Programm nach Break fortsetzen
;
G_KDO:	LD	HL,(REGPC)
	LD	(ARG1),HL
	LD	DE,(BPADR)
	XOR	A			;Cy=0
	SBC	HL,DE
	JR	NZ, E_KDO		;wenn nicht Breakpoint
	JR	J_KDO			;starten
;
;Ausgabe eines Doppelpunktes
;
OUTDP:	DW	RPRST
	DB	0BAH			;":"
;
;Ausgabe hex 2 Byte Speicher (HL) und (HL-1)
;und ein Leerzeichen
;
OTHLS:	LD	A,(HL)			;hoeherwertiges Byte
	DW	ROTHX			;ausgeben
	DEC	HL
	LD	A,(HL)			;niederwertiges Byte
	DW	ROTHX			;ausgeben
	DEC	HL			;naechsten Aufruf vorbereiten
;
;Ausgabe ein Leerzeichen
;
OUTSP:	DW	RPRST
	DB	0A0H			;":"
	RET
;
;Z-Flag-Anzeige
;
AUS1:	DW	RPRST			;Ausg. "1 "
	DB	"1"
	DB	0A0H
	RET
AUSX:	JR	NZ, AUS1
	DW	RPRST			;Ausg. "0 "
	DB	"0"
	DB	0A0H
	RET
;
;Registermodifizerung und -anzeige
;
R_KDO:	CP	A, ':'
	JP	NZ, RKO3		;wenn Modifizierung
;
REGDA:	DW	RPRST			;Anzeige Breakpointadresse
	DB	CR
	DB	"B"
	DB	0D0H			;"BP "
	LD	HL,BPADR+1
	DW	ROTDP
	DW	RPRST			;Ausgabe Operandenfolge
	DB	"BS"			;am Breakpoint
	DB	0BAH			;"BS:"
	LD	B,3			;3 Byte
	LD	HL,BPOPC
RKO1:	LD	A,(HL)
	DW	ROTHX
	INC	HL
	DJNZ	RKO1
;
	DW	RPRST			;Flaganzeige
	DB	"   S Z C"
	DB	0A0H
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
	DW	RPRST
RKO2:	DB	"S"
	DB	0D0H			;"SP"
	DW	ROTDP
	DW	RPRST
	DB	"P"
	DB	0C3H			;"PC"
	DW	ROTDP
	DW	RPRST
	DB	"I"
	DB	0D8H			;"IX"
	DW	ROTDP
	DW	RPRST
	DB	"I"
	DB	0D9H			;"IY"
	DW	ROTDP
;
RKO4:	DW	RPRST			;Registersatz anzeigen
	DB	"A"
	DB	0C6H			;"AF"
	DW	ROTDP
	DW	RPRST
	DB	"B"
	DB	0C3H			;"BC"
	DW	ROTDP
	DW	RPRST
	DB	"D"
	DB	0C5H			;"DE"
	DW	ROTDP
	DW	RPRST
	DB	"H"
	DB	0CCH			;"HL"
	DW	ROTDP
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
	DW	ROTHS			;Ausgabe Wert
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

;
;Hex-Umschaltung (nicht implementiert)
;
H_KDO:	RET
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	RET
;
;ASCII-Umschaltung (nicht implementiert)
;
A_KDO:	RET
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	RET

;
;Window definieren
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
	CP	A, 0ECH			;innerhalb BWS ?
	RET	C	;nein
	LD	A,(ARG1)		;WINDOW-Anfang
	AND	A, 0E0H			;auf Zeilenanfang stellen
	LD	(ARG1),A
	LD	A,(ARG2)		;ebenso WINDOW-Ende
	AND	A, 0E0H
	LD	(ARG2),A
	LD	HL,(ARG2)
	LD	BC,(ARG1)
	SBC	HL,BC
	RET	C			;Endadresse zu klein
	JR	Z, WKO2			;kein Window --> Fehler
	DEC	HL
	LD	A,3			;WINDOW zu gross ?
	CP	A, H
	RET	C	;ja
	INC	HL
	LD	DE,0040H
	SBC	HL,DE
	RET	C			;wenn WINDOW zu klein
	LD	DE,0020H
	ADD	HL,DE
	RET
;
WKO2:	SCF
	RET
;
WKO3:	POP	AF
	RST	38H
;
;Initialisierungstabelle fuer PIO bei NEXT
;
NKTA:	DB	0FEH			;L(NINTA)
	DB	97H
	DB	0DFH
;
;NEXT-Kommando, Step-Betrieb
;
N_KDO:	LD	A,0F7H			;H(NINTA)
	LD	I,A			;Interruptvektor
	DI
	LD	HL,NKTA 		;Initialisieren PIO Port B
	LD	BC,0303H		;3 Bytes
	OTIR				;loest selbstaendig INT aus
	LD	HL,(BPADR)		;erstes Byte von Breakadr.
	DEC	HL			;wird EI
	LD	A,(HL)
	LD	(NBYTE),A		;Byte retten
	LD	(HL),0FBH		;EI einschreiben
	LD	(SPADR),SP
	LD	SP,(REGSP)
	PUSH	HL
	JP	REGH			;Register holen und Start
;Eingang bei Interrupt
NINTR:	DI
	CALL	REGA			;Register retten
	LD	A,7			;Interrupt von PIO
	OUT	3, A			;verbieten
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
;Speicherbereiche vergleichen
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
CKO3:	DW	ROTHL			;1. Adresse
	DW	ROTSP
	LD	A,(HL)
	DW	ROTHX			;1. Byte
	DW	ROTSP
	EX	DE,HL
	DW	ROTHL			;2. Adresse
	DW	ROTSP
	EX	DE,HL
	LD	A,(DE)
	DW	ROTHX			;2. Byte
	DW	RPRST
	DB	CR+80H
	DW	RINCH			;warten auf Tastendruck
	CP	A, CR
	RET	NZ			;Abbruch wenn <> >ENTER<
	JR	CKO2			;sonst weitertesten

;
;Bytefolge suchen
;
F_KDO:	LD	DE,(SOIL2)
	DEC	DE
	DEC	DE
	LD	(ARG3),DE		;DE = Beginn Bytefolge
	LD	BC,(ARG1)		;Suchadresse
FKO1:	LD	DE,(ARG3)
	DW	RINHX			;L = 1. Suchbyte
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
	DW	RINHX			;naechstes Suchbyte holen
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
FKO7:	DW	RPRST
	DB	"NOT FOUND"
	DB	CR+80H
	RET
;
;Interrupttabelle fuer Break
;
NINTA:	DW	NINTR

	; org f800h

;*****************************************************************************
;* Erweiterung Brosig-Monitor F800-FFFF                                      *
;*****************************************************************************
;
;neue INKEY-Routine
;
INKY:	LD	A,0FH			;Statusabfrage
	OUT	8, A
	LD	HL,KYBTS
	BIT	1,(HL)
	JP	NZ, INY24		;wenn noch Stringausgabemodus
	LD	B,0
	BIT	6,(HL)
	JR	Z, INY2			;kein SLOW-Modus
;sonst SLOW-Verzoegerung
INY1:	EX	(SP),IX
	EX	(SP),IX
	DJNZ	INY1
;
INY2:	IN	A, 2
	CPL
	AND	A, 0FH
	JR	NZ, INY3		;wenn Taste gedrueckt
	RES	0,(HL)			;sonst Repeatbit auf 0
	RES	7,(HL)			;keine Taste gedrueckt
	LD	(LAKEY),A		;A=0
	OUT	8, A			;Status ruecksetzen
	RET
;
INY3:	LD	A,(LAKEY)
	OR	A			;vorher Taste gedrueckt ?
	JR	Z, INY12		;nein --> gleich weiter
	BIT	0,(HL)
	JR	Z, INY6			;kein langes Repeat noetig
;kurze Repeatwartezeit
	LD	B,26H
INY4:	LD	C,0
INY5:	DEC	C
	JR	NZ, INY5
	DJNZ	INY4
	JR	INY12
;grosses Repeat + negative Entprellung
INY6:	LD	B,80H
INY7:	LD	C,0
INY8:	IN	A, 2
	CPL
	AND	A, 0FH
	JR	Z, INY9
	DEC	C
	JR	NZ, INY8
	DJNZ	INY7
	SET	0,(HL)			;langes Repeat durchlaufen
	JR	INY12
;
INY9:	LD	B,4
INY10:	LD	C,0
INY11:	IN	A, 2
	CPL
	AND	A, 0FH
	JR	NZ, INY6
	DEC	C
	JR	NZ, INY11
	DJNZ	INY10
;Spaltenabtastung
INY12:	BIT	7,(HL)			;Entprellung?
	JR	NZ, INY15		;eine Taste war betaetigt
	LD	B,3			;pos. Entprellung
INY13:	LD	C,0
INY14:	IN	A, 2
	CPL
	AND	A, 0FH
	RET	Z			;Taste gedrueckt
	DEC	C
	JR	NZ, INY14
	DJNZ	INY13
;
INY15:	XOR	A
INY16:	CP	A, 7
	JR	NZ, INY17
	ADD	A, 1			;SHIFT/CTRL uebergehen
INY17:	OUT	8, A
	LD	D,A
	IN	A, 2
	CPL
	AND	A, 0FH
	JR	NZ, INY19		;aktive Spalte
	LD	A,D
	ADD	A, 1
	CP	A, 12
	JR	NZ, INY16		;alle Spalten durch
	RES	0,(HL)			;kein langes Repeat
INY18:	XOR	A			;keine Taste betaetigt
	RET
;Ermittlung Tastenposition
INY19:	LD	BC,0708H		;Spalte 7 aktiv
	OUT	(C), B
	SLA	D
	SLA	D
	SLA	D			;Spalte*8
	SUB	1
	ADD	A, D
	LD	E,A			;E=A=Controlcode
	LD	(LAKEY),A
;Auswertung SHIFT
	IN	A, 2
	AND	A, 0FH
	XOR	8
	LD	A,E
	JR	NZ, INY20
	ADD	A, 60H			;sonst Korrektur fuer SHIFT
	LD	E,A
;Funktionstasten
INY20:	LD	HL,(PTFKY)
	LD	BC,(PLFKY)
	CPIR
	JR	NZ, INY21		;wenn Code keine Fkt-Taste
;
	DEC	HL
	LD	BC,(PTFKY)
	SBC	HL,BC
	SLA	L
	LD	BC,(PTFKA)
	ADD	HL,BC
	LD	C,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,C			;HL:=Adr. aus Adressfeld
	LD	BC,KYBTS
	LD	A,(BC)
	RES	0,A			;keine Taste gedrueckt
	BIT	7,A			;war schon langes Repeat?
	JP	NZ, INY18		;kein Repeat von Fkt.tasten
	SET	7,A			;sonst Repeat setzen
	LD	(BC),A
	JP	(HL)			;Ausfuehren Funktion
;Funktionen
JP100:	LD	SP,SYSSK
	JP	100H
JP200:	LD	SP,SYSSK
	JP	200H
JP300:	LD	SP,SYSSK
	JP	300H
;
SGRAF:	LD	L,4			;Graphikschalter
	JR	SCHLT
SPRNT:	LD	L,8			;Druckerschalter
	JR	SCHLT
SSLOW:	LD	L,40H			;SLOW-Schalter
	JR	SCHLT
SBEEP:	LD	L,20H			;Tastaturbeepschalter
	JR	SCHLT
SCAPS:	LD	L,10H			;CAPS-Schalter
SCHLT:	LD	A,(BC)			;setzt entsprechendes Bit
	XOR	L
	LD	(BC),A
SCHL2:	XOR	A
	LD	E,A
	JP	BEEP5
JP038:	CALL	ZMINI
	RST	38H

;Stringtasten
INY21:	LD	HL,(PTKEY)
	LD	D,0
	ADD	HL,DE			;E:=Tastencode
	LD	A,(HL)
	LD	E,A
;CONTROL-Funktion
	IN	A, 2
	BIT	3,A
	JR	NZ, INY22
	LD	A,E
	AND	A, 9FH
	LD	E,A
	IN	A, 2
	AND	A, 0FH
	JR	NZ, INY22
	LD	A,80H
	ADD	A, E
	LD	E,A
;Stringfunktion
INY22:	BIT	7,E
	JR	Z, INY26		;wenn keine Stringausgabe
	LD	(LAKEY),A
	LD	HL,(PTSTG)
INY23:	LD	A,(HL)
	OR	A
	JR	Z, INY26		;wenn Stringtabellenende
	INC	HL
	CP	A, E
	JR	NZ, INY23
	LD	(PTNXZ),HL
;naechstes Stringzeichen
INY24:	LD	HL,(PTNXZ)
	LD	A,(HL)
	INC	HL
	LD	(PTNXZ),HL
	LD	HL,KYBTS
	SET	1,(HL)			;Stringmode an
	BIT	7,A
	JR	NZ, INY25		;wenn letzter Buchstabe war
	OR	A
	RET	NZ
INY25:	RES	1,(HL)			;Stringmode aus
	XOR	A
	RET
;Graphik-Mode?
INY26:	LD	HL,KYBTS
	LD	A,E
	BIT	2,(HL)			;Grafikmode an?
	JR	Z, INY27		;nein
	CP	A, 8
	JR	Z, INY27
	CP	A, 9
	JR	Z, INY27		;wenn CULEFT o. CURIGHT
	ADD	A, 80H			;--> Grafikzeichen
	LD	E,A
;CAPS-Umschaltung
INY27:	BIT	4,(HL)			;CAPS an ?
	JR	Z, INY29		;nein
	LD	A,E			;sonst Gross-Klein-wandlung
	CP	A, 'A'
	JR	C, INY29
	CP	A, '^'
	JR	NC, INY28
	ADD	A, 20H
	LD	E,A
	JR	INY29
INY28:	CP	A, 'a'
	JR	C, INY29
	CP	A, '~'
	JR	NC, INY29
	SUB	20H
	LD	E,A
;Tastaturbeepimpuls
INY29:	LD	A,E
	LD	(LAKEY),A
	SET	7,(HL)
	BIT	5,(HL)
	JR	Z, BEEP7
;
;Tonausgabe
;  C=Tonhoehe, B=Tondauer
;
	LD	BC,2039H
BEEP:	PUSH	BC
BEEP1:	PUSH	BC
	LD	A,C
	OR	A
	LD	A,0FH
	JR	Z, BEEP2		;C=0 --> kein Ton
	LD	A,0EH			;Beep an
BEEP2:	OUT	8, A
	POP	BC
	PUSH	BC
BEEP3:	DEC	C
	JR	NZ, BEEP3		;Flanke abwarten
	LD	A,0FH
	OUT	8, A			;Beep aus
	POP	BC
	PUSH	BC
BEEP4:	DEC	C
	JR	NZ, BEEP4		;Flanke abwarten
	POP	BC
	DJNZ	BEEP1			;Tondauer
	POP	BC
;Rekonstruktion der Flags
BEEP5:	PUSH	HL
	LD	HL,KYBTS
	LD	A,0EH			;Flags ruecksetzen
	OUT	8, A
	BIT	3,(HL)			;Drucker parallel?
	JR	Z, BEEP6		;nein
	LD	A,0CH
	OUT	8, A
BEEP6:	BIT	4,(HL)			;CAPS an?
	POP	HL
	JR	Z, BEEP7		;nein
	LD	A,0DH
	OUT	8, A
BEEP7:	LD	A,7
	OUT	8, A
;
	LD	A,E			;Tastencode uebergeben
	OR	A			;evtl. Z-Flag
	RET
;
;Tastaturfelder
;
;Funktionstastenpositionsfeld
K7FKY:	DB	82
	DB	53
	DB	84
	DB	85
	DB	67
	DB	71
	DB	72
	DB	73
	DB	83
	DB	74
;Funktionstastenadressfeld
K7FKA:	DW	SGRAF
	DW	SCAPS
	DW	SSLOW
	DW	SBEEP
	DW	JP038
	DW	JP100
	DW	JP200
	DW	JP300
	DW	SPRNT
	DW	BSDR
;Tastenbelegungsfeld
K7KEY:	DB	"1QAY2WSX"		;Spalte 0
	DB	"3EDC4RFV"		;Spalte 1
	DB	"5TGB6ZHN"		;Spalte 2
	DB	"7UJM8IK,"		;Spalte 3
	DB	"9OL.0P\\-"		;Spalte 4	(\\ nötig wg. Assembler, bedeutet \)
	DB	"~][<+#^@"		;Spalte 5
	DB	">"			;Spalte 6
	DB	CR
	DB	0BH			;CUUP
	DB	8			;CULEFT
	DB	" "
	DB	0			;--> CAPS
	DB	0AH			;CUDOWN
	DB	9			;CURIGHT
					;Spalte 7
	DB	0
	DB	0
	DB	0
	DB	0
	DB	0
	DB	0
	DB	0			;SHIFT
	DB	0			;CTRL
					;Spalte 8
	DB	0
	DB	7FH			;DEL
	DB	14H			;^T
	DB	0			;--> RST38
	DB	1BH			;ESC
	DB	'{'
	DB	'}'
	DB	0			;--> JP100
					;Spalte 9
	DB	0			;--> JP200
	DB	0			;--> JP300
	DB	0			;--> HCOPY
	DB	15H			;^U
	DB	19H			;^Y
	DB	12H			;^R
	DB	10H			;^P
	DB	3			;^C
					;Spalte 10
	DB	6			;^F
	DB	0
	DB	0			;--> GRAPHIK
	DB	0			;--> DRUCKER
	DB	0			;--> SLOW
	DB	0			;--> BEEP
	DB	0
	DB	1CH			;^\
					;Spalte 11
	DB	1DH			;^]
	DB	0
	DB	0
	DB	0
	DB	5			;^E
	DB	0
	DB	1			;^A
	DB	0
;Tastenbelegung unter SHIFT
	DB	"!qay",'"',"wsx"	;Spalte 0
	DB	"@edc$rfv"		;Spalte 1
	DB	"%tgb&zhn"		;Spalte 2
	DB	"/ujm(ik;"		;Spalte 3
	DB	")ol:=p|_"		;Spalte 4
	DB	"?}{[*"			;Spalte 5
	DB	27H			;'
	DB	"|\\"			;		(\\ nötig wg. Assembler, bedeutet \)
					;Spalte 6
	DB	"]"
	DB	CR
	DB	0BH			;CUUP
	DB	8			;CULEFT
	DB	" "
	DB	0			;--> CAPS
	DB	0AH			;CUDOWN
	DB	9			;CURIGHT
					;Spalte 7
	DB	0
	DB	0
	DB	0
	DB	0
	DB	0
	DB	0
	DB	0			;SHIFT
	DB	0			;CTRL
					;Spalte 8
	DB	0
	DB	2			;^B
	DB	13H			;^S
	DB	0			;--> RST38
	DB	1BH			;^[
	DB	'`'
	DB	'~'
	DB	0			;--> JP100
					;Spalte 9
	DB	0			;--> JP200
	DB	0			;--> JP300
	DB	0			;--> HCOPY
	DB	0FH			;^O
	DB	18H			;^X
	DB	11H			;^Q
	DB	1FH			;^_
	DB	3			;^C
					;Spalte 10
	DB	1EH			;^^
	DB	0
	DB	0			;--> GRAPHIK
	DB	0			;--> DRUCKER
	DB	0			;--> SLOW
	DB	0			;--> BEEP
	DB	0
	DB	1CH			;^\
					;Spalte 11
	DB	1DH			;^]
	DB	0
	DB	0
	DB	0
	DB	19H			;^Y
	DB	0
	DB	18H			;^X
	DB	0
;
;Tastaturstatus ermitteln
;
STAT:	LD	A,0FH			;Statusabfrage
	OUT	8, A
	XOR	A
	LD	(LAKEY),A		;hinterlaesst Null, d.h.
	IN	A, 2			;keine Taste gedrueckt
	AND	A, 0FH
	SUB	0FH
	RET	Z			;keine Taste gedrueckt
	LD	A,0FFH			;sonst Uebergabe 0FFH
	RET
;
;HeaderSave
;
SAR0:	DB	0FDH			;LD HY,0
	LD	H,0			;d.h. Typabfrage
;
SARUF:	
	CP	A, ':'			;alte Parameter nutzen?
	CALL	NZ, AKP0		;nein --> neue Eingabe
	DW	RPRST
	DB	CR+80H
	CALL	HADR			;Adressen holen
	LDIR				;und kopieren
	LD	HL,AADR
	CALL	HSAV1			;Ausgabe Kopfblock
	LD	HL,(AADR)
	CALL	OADR1			;Anzeige der Adressen
	CALL	HSAV1			;Ausg. 1.Block m. langem Ton
	CALL	HSAV0			;Abspeichern File
	CALL	VERIF			;Verify-Funktion
	RET
;
;Abspeichern ein Block mit langem Vorton
;
HSAV1:	LD	DE,1000H
	JP	SAV4
;
;Aufbereitung Kopfpuffer
;
AKP0:	CALL	HADR			;Adressen holen und
	EX	DE,HL			;nach ARGx transportieren
	LDIR
	LD	HL,(ARG3)
	LD	(SADR),HL
;
	LD	HL,SIGNS		;Block als Kopfblock
	LD	A,0D3H			;markieren
	LD	B,3
AKP1:	LD	(HL),A
	INC	HL
	DJNZ	AKP1
;
	CALL	INKPF			;Eingabe Typ und Name
	DB	0FDH
	LD	A,H			;LD	A,HY
	LD	(TYP),A			;Typ eintragen
	LD	HL,(SOIL)		;Name eintragen
	LD	BC,0010H
	LD	DE,NAME
	LDIR
	DW	RPRST
	DB	CR+80H
	RET
;
;Abspeichern File
;
HSAV0:	EX	DE,HL			;Test, ob Fileende erreicht
	LD	HL,(EADR)
	AND	A, A
	SBC	HL,DE
	EX	DE,HL
	RET	C			;wenn ja
	LD	(SOIL2),HL		;sonst weiter mit
	CALL	SAV3			;Blockausgabe
	CALL	OADR1			;Adressen anzeigen
	JR	HSAV0
;
;Aufzeichnung ueberpruefen
;
VERIF:	DW	RPRST
	DB	"verify? (Y)"
	DB	0BAH			;":"
	DW	RINCH			;Tastatureingabe
	CP	A, 'Y'
	RET	NZ			;wenn kein Verify
;
	DW	RPRST
	DB	" rewind "
	DB	0BCH
	DW	RINCH			;warten auf Tastendruck
	DW	RPRST
	DB	CR
	DB	CR+80H
;
VER1:	CALL	INKY
	CP	A, 3			;>STOP< ?
	JP	Z, RST38		;ja --> Abbruch
	CALL	VER3			;Block lesen
	JR	NZ, VER1		;wenn kein Fehler
	LD	A,0E0H			;L(AADR)
	CP	A, E
	JR	NZ, VER1		;kein Kopfblock
	XOR	A
	CP	A, D
	JR	NZ, VER1		;kein Kopfblock
;
VER2:	CALL	VER3			;Block lesen
	CALL	NZ, ERBAD		;evtl. Fehlermeldung
	PUSH	AF
	LD	BC,0039H
	CALL	NZ, BEEP		;wenn Fehler
	POP	AF
	RET	NZ			;wenn Fehler
	LD	H,D
	LD	L,E
	CALL	OADR1			;Anzeige Ladeadresse
	LD	A,(SOIL2)
	CP	A, E			;Endadresse erreicht?
	JR	NZ, VER2		;nein --> weiterlesen
	LD	A,(SOIL2+1)
	CP	A, D
	JR	NZ, VER2		;nein --> weiterlesen
	CALL	OADR3			;Cursorpos. korrigieren
	RET
;
VER3:	LD	A,0FFH			;vollen Block
	LD	(ARG2+1),A
	LD	HL,BWS			;auf den Bildschirm
	CALL	HLBLK			;Block lesen
	RET
;
;HeaderLoad
;
LOR0:	LD	HL,(SOIL)		;Beginn Eingabezeile
	INC	HL
	INC	HL
	INC	HL
	LD	A,(HL)			;(HL)=3. Buchstabe
	DB	0FDH			;hinter "@"
	LD	L,A			;LD	LY,A
	DEC	HL
	DB	0FDH
	LD	H,0			;LD	HY,0
	LD	A,(HL)			;(HL)=2. Buchstabe
;
LORUF:	
	LD	HL,SHILO		;SHILO dient als
	LD	(HL),0			;Namenslaengenpuffer
	LD	HL,BPADR		;BPADR ist Moduspuffer
	LD	(HL),0
;
	CP	A, 'N'			;Namenseingabe?
	PUSH	HL
	CALL	Z, INKPF		;wenn ja --> Eingabe
	POP	HL
;
	LD	HL,(ARG1)		;neue Ladedresse
	LD	(ARG3),HL		;in ARG3 merken
	EX	AF, AF'			;'
LOR1:	DW	RINKY			;Tastaturabfrage
	CP	A, 3			;>STOP< ?
	JR	NZ, LOR2
	DW	RPRST			;ja --> Abbruch
	DB	CR+80H
	RET
;
LOR2:	LD	A,0FFH			;stets vollen Block lesen
	LD	(ARG2),A
	LD	HL,AADR
	CALL	HLBLK			;Block lesen
	EX	AF, AF'
	CP	A, 'A'			;war zweiter Buchstabe "A"?
	JR	Z, LOR4			;ja --> als Kopfblock werten
	EX	AF, AF'
	JR	NZ, LOR1		;sonst bei Fehler neu lesen
;
	LD	D,A			;A=0	-- das ist Fehler von R.Brosig, hier müsste LD A,D stehen! (vp)
	OR	E
	LD	(BPADR),A
;Test, ob Kopfblock gelesen
	LD	B,3			;3 Kopfkennzeichen
	LD	HL,SIGNS
LOR3:	LD	A,(HL)
	CP	A, 0D3H			;Kopfkennzeichen
	INC	HL
	JR	NZ, LOR1		;wenn kein Kopf
	DJNZ	LOR3			;sonst weitertesten
;
LOR4:	DW	RPRST
	DB	CR+80H
;Anzeige von AADR, EADR, SADR
	LD	B,3
	LD	HL,(AADR)
	LD	(SOIL2),HL
	LD	HL,AADR+1
LOR5:	DW	ROTHS			;Adresse anzeigen
	INC	HL
	INC	HL
	INC	HL
	INC	HL
	DJNZ	LOR5
	DW	RPRST
	DB	CR
	DB	CR+80H
;Anzeige gelesener Typ und Name
	LD	HL,TYP
	LD	DE,(CUPOS)
	LD	BC,0014H
	LDIR
	INC	DE
	LD	(CUPOS),DE
;
	DB	0FDH
	LD	A,H			;LD	A,HY
	CP	A, 21H			;ist Typ Steuerzeichen?
	JR	C, LOR6			;ja --> kein Vergleich
	LD	HL,TYP
	CP	A, (HL)
	CALL	NZ, ERNF		;Typ stimmt nicht
	JR	NZ, LOR1		;neuen Kopf suchen
;
LOR6:	LD	A,(SHILO)		;Namenslaenge
	LD	B,A
	OR	A
	JR	Z, LOR8			;kein Vergleich
;
	LD	HL,NAME			;Namensvergleich
	LD	DE,(SOIL)
LOR7:	LD	A,(DE)
	CP	A, (HL)
	INC	HL
	INC	DE
	CALL	NZ, ERNF		;wenn Name nicht stimmt
	JP	NZ, LOR1		;dann neuen Kopf lesen
	DJNZ	LOR7
;Anzeige der Zieladressen
LOR8:	LD	HL,(ARG3)		;neue Ladeadresse
	XOR	A
	OR	H
	JR	Z, LOR9			;wenn nicht eingegeben
;
	LD	BC,(AADR)
	LD	(AADR),HL		;neue AADR eintragen
	DW	ROTHL			;und anzeigen
	DW	ROTSP
	SBC	HL,BC
	LD	BC,(EADR)
	ADD	HL,BC			;neue EADR berechnen
	LD	(EADR),HL		;eintragen
	DW	ROTHL			;und anzeigen
LOR9:	DW	RPRST
	DB	CR
	DB	CR+80H
;
	CALL	HADR			;Adressen kopieren
	LDIR
;
	LD	HL,(AADR)
LOR10:	LD	A,(KYBTS)		;KYBTS merken
	LD	(ARG3),A
	RES	6,A			;SLOW-Mode aus
	LD	(KYBTS),A
	CALL	INKEY			;Tastaturabfrage
	EX	AF, AF'
	LD	A,(ARG3)
	LD	(KYBTS),A		;KYBTS rueckspeichern
	EX	AF, AF'
	CP	A, 3			;<STOP>?
	RET	Z			;ja --> Abbruch
;
	CALL	OADR1			;Anzeige Blockadresse
	LD	A,(BPADR)		;wenn Mode 0, so lesen
	OR	A			;ohne Fehlerbehandlung
	PUSH	AF
	CALL	Z, BLMKF
	POP	AF
	CALL	NZ, BLMK		;sonst mit
;
	EX	DE,HL			;Test, ob Ende erreicht
	LD	HL,(EADR)
	AND	A, A
	SBC	HL,DE
	EX	DE,HL
	JR	NC, LOR10		;nein --> weiterlesen
;
	LD	HL,(EADR)		;Anzeige der EADR
	CALL	OADR1
	CALL	OADR3			;Cursorpos. korrigieren
;
	LD	HL,(SADR)
	LD	(ARG3),HL
	LD	A,(TYP)
	CP	A, 'C'			;ist Typ="C"?
	RET	NZ			;nein --> Abbruch
	DB	0FDH
	LD	A,L			;LD	A,LY
	CP	A, ' '			;ist Selbstart freigeg.?
	RET	NZ			;nein --> Abbruch
	JP	(HL)			;sonst Programmstart
;
;Block lesen mit Header
;
BLMK:	CALL	HLBLK
	JR	Z, BLMK3		;wenn ohne Fehler
;
	CALL	ERBAD			;Ausgabe "bad record"
	LD	BC,0039H
	CALL	BEEP
BLMK1:	DW	RINCH			;Tastaturabfrage
	CP	A, 3			;>STOP< ?
	JR	Z, BLMK5		;ja --> zurueck
	DW	RPRST
	DB	CR
	DB	CR+80H
BLMK2:	LD	BC,0020H
	AND	A, A
	SBC	HL,BC			;Adresse Fehlerblock
	CALL	HLBLK			;Block neu lesen
	JR	NZ, BLMK2		;wenn Fehler
;
BLMK3:	LD	A,D
	AND	A, E
	INC	A
	JR	Z, BLMK5		;wenn FFFF-Block gelesen
	PUSH	HL
	EX	DE,HL
	AND	A, A
	LD	DE,(SOIL2)
	SBC	HL,DE
	POP	HL
	JR	Z, BLMK4		;wenn richtigen Block gelesen
	JR	C, BLMK2		;wenn
	CALL	ERREC			;Ausgabe "record"
	CALL	ERNF			;"not found"
	LD	BC,0040H
	CALL	BEEP
	JR	BLMK1			;erneut lesen
;
BLMK4:	PUSH	HL
	LD	HL,0020H		;neue Adresse
	ADD	HL,DE
	LD	(SOIL2),HL		;uebergeben
BLMK5:	POP	HL
	RET

;
;Block lesen ohne Fehlerbehandlung
;
BLMKF:	CALL	HLBLK			;Block lesen
	RET	Z			;wenn kein Fehler
	DB	0FDH			;Selbstart verbieten (A=0)
	LD	L,A			;LD	LY,A
	CALL	ERBAD			;Fehlermeldung
	RET
;
;Uebergibt Adressen fuer Kopfblockaufbereitung
;
HADR:	LD	HL,AADR
	LD	DE,ARG1
	LD	BC,4
	RET
;
;Abfrage Typ und Namen
;
INKPF:	DB	0FDH
	LD	A,H			;LD	A,HY
	OR	A
	JR	NZ, INKP2		;wenn Typ vorgeben
;Abfrage Typ
	DW	RPRST
	DB	CR
	DB	"typ"
	DB	0BAH			;":"
	DW	RINCH
	CP	A, ' '
	JR	NC, INKP1		;Steuerzeichen werden zu
	LD	A,' '			;Space gewandelt
INKP1:	DW	ROUTC
	DB	0FDH			;LD HY,A
	LD	H,A			;Typ merken
;Abfrage Filename
INKP2:	DW	RPRST
	DB	" filename"
	DB	0BAH			;":"
	LD	HL,(CUPOS)
	LD	(SOIL),HL
	LD	C,0FFH			;C:=Zeichenzaehler
INKP3:	INC	C
	DW	RINCH			;Zeichen eingeben
	CP	A, 3			;>STOP< ?
	JP	Z, OADR2		;ja --> Abbruch
	CP	A, 8			;Cursor links
	JR	NZ, INKP5		;nein
	DEC	C			;ein Zeichen zurueck
	JP	M, INKP3		;wenn linker Rand
INKP4:	DEC	C			;auf vorhergehendes Zeichen
INKP5:	DW	ROUTC			;Zeichen anzeigen
	CP	A, CR			;>ENTER< ?
	LD	A,C
	LD	(SHILO),A		;Zeichenanzahl uebergeben
	RET	Z			;ja --> zurueck
	LD	A,16
	CP	A, C			;max. Namenlaenge erreicht?
	LD	A,8
	JR	NZ, INKP3
	JR	INKP4			;ja --> ein Zeichen zurueck
;
;Fehlermeldungen
;
ERBAD:	CALL	OADR3			;Cursorpos. korrigieren
	DW	RPRST
	DB	"bad"
	DB	0A0H
;
ERREC:	DW	RPRST
	DB	"record"
	DB	0A0H
	RET
;
ERNF:	DW	RPRST
	DB	"not found"
	DB	CR+80H
	RET
;
;Ausgabe HL, Cursor loeschen und Cursor zurueck
;
OADR1:	PUSH	DE
	PUSH	HL
	LD	DE,(CUPOS)
	DW	ROTHL
	LD	HL,(CUPOS)
	LD	(HL),' '
	LD	(CUPOS),DE
OADR2:	POP	HL
	POP	DE
	RET
;
;Cursor 5 Zeichen vorruecken
;
OADR3:	PUSH	HL
	PUSH	BC
	LD	HL,(CUPOS)
	LD	BC,0005H
	ADD	HL,BC
	LD	(CUPOS),HL
	POP	BC
	POP	HL
	RET
;
;Block lesen mit Headerkopf
;
HLBLK:	CALL	LOA24			;synchronisieren
	CALL	LOA25			;Flanke abwarten
	LD	C,7
HLB1:	LD	DE,0910H
	LD	A,7
HLB2:	DEC	A
	JR	NZ, HLB2
	CALL	LOA24			;synchronisieren
HLB3:	CALL	LOA24			;Flanke?
	JR	NZ, HLBLK		;nein --> kein Vorton
	DEC	D
	JR	NZ, HLB3
	DEC	C
	JR	Z, HLB5
HLB4:	IN	A, 2
	XOR	B
	BIT	6,A
	JR	NZ, HLB1
	DEC	E
	JR	NZ, HLB4
	JR	HLBLK
;Synchronisierimpulse lesen
HLB5:	CALL	LOA25			;Flanke abwarten
	LD	A,44H
HLB6:	DEC	A
	JR	NZ, HLB6
	CALL	LOA24			;Flanke?
	JR	NZ, HLB5		;wenn nicht
	CALL	LOA25			;Flanke abwarten
	LD	A,1EH
HLB7:	DEC	A
	JR	NZ, HLB7
;2 Byte Kopf lesen
	CALL	LOA19			;2 Byte lesen nach DE
	LD	(DATA),DE		;und merken
;20H Datenbyte lesen
	PUSH	DE
	POP	IX
	LD	A,1AH
	LD	C,10H			;10Hx 2 Byte
HLB8:	DEC	A
	JR	NZ, HLB8
HLB9:	CALL	LOA19			;lesen nach DE
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
	JR	C, HLB10		;ja --> Leseende
	LD	(HL),E
	INC	HL
	LD	(HL),D
	JR	HLB12
;
HLB10:	LD	A,1
HLB11:	DEC	A
	JR	NZ, HLB11
	INC	HL
;
HLB12:	INC	HL
	DEC	C
	JR	Z, HLB14		;wenn Blockende
	LD	A,12H
HLB13:	DEC	A
	JR	NZ, HLB13
	JR	HLB9			;sonst weiterlesen
;
HLB14:	LD	A,12H
HLB15:	DEC	A
	JR	NZ, HLB15
	CALL	LOA19			;Pruefsumme lesen
	EX	DE,HL
	PUSH	IX
	POP	BC
	XOR	A
	SBC	HL,BC			;Z<>0 Ladefehler
	EX	DE,HL
	LD	DE,(DATA)		;Kopf uebergeben
	RET
;
;Suchen Kopfblock
;
SUCHK:	PUSH	HL
	PUSH	DE
	PUSH	BC
SUCH1:	DW	RINKY			;Tastaturabfrage
	CP	A, 3			;>STOP< ?
	JR	Z, SUCH3		;ja --> Abbruch
	LD	A,0FFH			;vollen Block
	LD	(ARG2),A
	LD	HL,AADR			;nach AADR
	CALL	HLBLK			;Block lesen
;
	LD	B,3			;Test ob Kopfblock
	LD	HL,SIGNS
SUCH2:	LD	A,(HL)
	CP	A, 0D3H
	INC	HL
	JR	NZ, SUCH1		;kein Kopfblock
	DJNZ	SUCH2			;weitertesten
SUCH3:	POP	BC
	POP	DE
	POP	HL
	RET
;
;Aufbereitung Kopfpuffer
;
AKP:	PUSH	HL
	PUSH	DE
	PUSH	BC
	CALL	AKP0			;Aufbereitung unter HSAVE
	POP	BC
	POP	DE
	POP	HL
	RET

;
;logischen Druckertreiber ruecksetzen
;
DRDEL:	PUSH	HL
	LD	HL,DRZSP
	LD	(HL),0
	INC	HL
	LD	(HL),0
	INC	HL
	LD	(HL),0
	POP	HL
	RET
;
;Bildschirmkopie drucken
;
BSDR:	CALL	DRDEL			;Drucker ruecksetzen
	PUSH	DE
	PUSH	HL
	LD	HL,BWS			;erste Adresse
	LD	DE,0
	LD	A,CR
	CALL	RDRAK			;Wagenruecklauf
BSDR1:	LD	A,(HL)
	CP	A, 0FFH			;Cursor erreicht?
	JR	Z, BSDR2		;ja
	CALL	RDRAK			;Druckerausgabe
	INC	HL			;naechstes Zeichen
	INC	E
	LD	A,E
	CP	A, 20H
	JR	NZ, BSDR1		;kein Zeileende
	LD	E,0
	LD	A,CR
	CALL	RDRAK			;Wagenruecklauf
	LD	A,0AH
	CALL	RDRAK			;Zeilenvorschub
	INC	D
	LD	A,D
	CP	A, 20H
	JR	NZ, BSDR1		;kein BWS-Ende
BSDR2:	POP	HL
	POP	DE
	XOR	A
	RET
;
;Ausgabe Ton, in C steht die Tonlaenge
;
SOUND:	PUSH	BC
	LD	A,80H
	OUT	0, A			;Ausgabe Userport
	OUT	2, A			;Ausgabe Tonbandbuchse
	LD	B,C
SOUN1:	BIT	0,(IX+0)		;warten erste Halbperiode
	DJNZ	SOUN1
	XOR	A
	LD	B,C
	OUT	0, A
	OUT	2, A
SOUN2:	BIT	0,(IX+0)		;warten zweite Halbperiode
	DJNZ	SOUN2
	POP	BC
	RET
;
;Joystickabfrage, Joystickmodul nach 'practic'
;
GETST:	LD	A,0CFH			;PIO Mode 2
	LD	C,1FH
	OUT	1, A
	LD	A,C
	OUT	1, A
	LD	A,20H			;linker Joystick
	OUT	0, A
	IN	A, 0
	AND	A, C
	SCF
	RET	Z			;Cy=1 --> kein Modul
	CPL
	AND	A, C
	LD	B,A
	LD	A,40H			;rechter Joystick
	OUT	0, A
	IN	A, 0
	CPL
	AND	A, C
	LD	C,A
	OR	B			;Z=0 --> keine Taste gedrueckt
	RET


;
;Initialisieren Zsatzmonitor
;
ZMINI:	LD	HL,ZMTAB
	LD	DE,USRKD
	LD	BC,K7STG-ZMTAB		;Laenge
	LDIR
	RET
;
;
;
ZMTAB:	DB	"L"			;Header-Load
	DW	LOR0
	DB	"S"			;Header-Save
	DW	SAR0
	DB	"D"			;Druckertreiber ruecksetzen
	DW	RDDEL
	DB	"I"			;Druckertreiber initialisieren
	DW	RDINI
;
;Stringtabelle fuer Inkey-Routine
;

K7STG:	DB	81H
	DB	CR
	DB	"(C) Rainer Brosig,Florinstr.2c,"
	DB	"COSWIG,8270, V.5.4 FR 8.11.87"
	DB	82H
	DB	"GOSUB"
	DB	83H
	DB	"CALL"
	DB	84H
	DB	"DATA"
	DB	85H
	DB	"EDIT"
	DB	88H
	DB	"FOR"
	DB	87H
	DB	"GOTO"
	DB	89H
	DB	"INPUT"
	DB	8AH
	DB	"CHR$("
	DB	9CH
	DB	"POKE"
	DB	8CH
	DB	"CLOAD",'"'
	DB	8BH
	DB	"NEXT"
	DB	8FH
	DB	"OUT"
	DB	8DH
	DB	"PRINTAT("
	DB	90H
	DB	"PRINT"
	DB	92H
	DB	"RUN"
	DB	95H
	DB	"RETURN"
	DB	86H
	DB	"CSAVE",'"'
	DB	94H
	DB	"LIST"
	DB	97H
	DB	"WINDOW"
	DB	99H
	DB	"INKEY$"
	DB	0

	db	26h,0h,0h,60h,44h,24h,66h	; Füllbytes im Brosig-Monitor?
;
;Sprungverteiler
;
	ORG	0FFB7H
;
RRET:	RET
	JP	SOUND			;Tonausgabe, eine Periode
	JP	GETST			;Joystikabfrage
	JP	AKP			;Aufbereitung Kopfpuffer
	JP	SUCHK			;Kopfblock suchen
	JP	BSMK			;Block schreiben
	JP	BLMK			;Block lesen
RZEID:	JP	ZEIDR			;phys. Druckertreiber
RDINI:	JP	DRINI			;Druckertreiber initialisieren
	JP	RRET			;BIN
	JP	RRET			;AIN
	JP	RRET			;BSTA
	JP	RRET			;ASTA
RBEEP:	JP	BEEP			;Tonausgabe
	JP	DRZEL			;log. Druckertreiber
	JP	HARDC			;BWS+Druck
	JP	BSDR			;Bildschirmkopie
RDRAK:	JP	DRAKK			;log. Druckertreiber
RDDEL:	JP	DRDEL			;log. Treiber ruecksetzen
RZMIN:	JP	ZMINI			;Zusatzmonitor installieren
	JP	LORUF			;Headerload
	JP	SARUF			;Headersave
	JP	STAT			;Tastaturstatus
	JP	POLL			;Tastaturpolling
	JP	INKY			;Tastaturabfrage
;
	END
