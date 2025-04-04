;Volker Pohlers, Lomonossowallee 41/81, Greifswald, 2200
;letzte Aenderung: 21.10.90
;
;RAM-Zellen
;
R20BT:	EQU	00003H		;Nummer des RST20-Calls
LAKEY:	EQU	00004H		;letztes Zeichen von Tastatur
BPADR:	EQU	0000BH		;Breakpointadresse
BPOPC:	EQU	0000DH		;Operandenfolge bei Breakpoint
DATA:	EQU	00013H		;Adresse bei INHEX
SHILO:	EQU	00015H		;
SOIL:	EQU	00016H		;Beginn Eingabezeile
ARG1:	EQU	0001BH		;1. Argument
ARG2:	EQU	0001DH		;2. Argument
BUFFA:	EQU	0001FH		;vom Cursor verdecktes Zeichen
RST20:	EQU	00020H		;RST 20H
ARG3:	EQU	00023H		;3. Argument
SOIL2:	EQU	00025H		;Rest Eingabezeile
KYBTS:	EQU	00027H		;Tastaturroutinenzelle
CUPOS:	EQU	0002BH		;aktuelle Cursorposition
LSYNC:	EQU	00033H		;Kenntonlaenge
DRZSP:	EQU	00035H		;3 Byte fuer Druckertreiber
RST38:	EQU	00038H		;RST 38H
PTKEY:	EQU	0003BH		;Tastenbelegungsfeldpointer
PTSTG:	EQU	0003DH		;Stringfeldpointer
PTNXZ:	EQU	0003FH		;Pointer nae. auszg. $Zeichen
PLFKY:	EQU	00041H		;Laenge Funktionstastenfeld
PTFKY:	EQU	00043H		;Pointer Funktionstastenfeld
PTFKA:	EQU	00045H		;Pointer Fkt.tastenadressfeld
WINDL:	EQU	00047H		;Windowlaenge
WINDA:	EQU	00049H		;Windowanfang
WINDE:	EQU	0004BH		;Windowende+1
REGBR:	EQU	0004DH		;Registerrettebereich
REGAF:	EQU	0005BH		;Register AF
REGPC:	EQU	00061H		;Register PC
REGSP:	EQU	00063H		;Userstack
NMI:	EQU	00066H
NBYTE:	EQU	00069H		;Operand bei NEXT
SPADR:	EQU	0006AH		;SP-Zwischenspeicher
FBANZ:	EQU	0006CH		;Zwsp. Anz. Suchbytes bei FIND
USRSK:	EQU	00090H		;Userstack
SYSSK:	EQU	000B0H		;Systemstack
USRKD:	EQU	SYSSK
;Kopfpuffer fuer Headersave/load
AADR:	EQU	000E0H		;Anfangsadresse
EADR:	EQU	000E2H		;Endadresse
SADR:	EQU	000E4H		;Startadresse
TYP:	EQU	000ECH		;Typ
SIGNS:	EQU	000EDH		;Kopfkennzeichnung
NAME:	EQU	000F0H		;Name
;
HARDC:	EQU	0E80FH
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
INIT:	JR	INIT2-#
;Initialisierung
INIT1:	LD	HL,REGBR	;Registerrette-
	LD	DE,REGBR+1	;bereich loeschen
	LD	M,0
	LD	BC,0015H
	LDIR
INIT2:	LD	SP,SYSSK	;System-Stack
	NOP
	CALL	INIT3		;Initialisierung
	LD	A,0C3H		;JMP ...
	LD	(RST20),A
	LD	HL,RST1		;RST20 eintragen
	LD	(RST20+1),HL
	LD	A,0CFH		;PIO Port B init.
	OUT	3		;BIT-Mode
	LD	A,7FH		;BIT7-Ausgang
	OUT	3
	LD	HL,MONTB	;System-RAM init.
	LD	DE,LSYNC
	LD	BC,001AH
	LDIR
;Systemmeldung
	DA	RPRST
	DB	CLS
	DB	CR
	DB	CR
	DB	'Z1013+K7659/2.02C VP'
	DB	CR+80H
;
	LD	HL,USRSK	;User-Stack
	LD	(REGSP),HL
	IM2
	JR	KDO2-#
;
;Eingang Kommandomodus
;
KDO1:	LD	SP,SYSSK	;System-Stack
	CALL	PRST7
	DB	0BFH		;"?"
KDO2:	CALL	INLIN		;Zeile eingeben
	LD	DE,(SOIL)
	CALL	SPACE		;Leerzeichen uebergehen
	LD	B,A		;B=1. Zeichen
	INC	DE
	LD	A,(DE)
	LD	C,A		;C=2. Zeichen
	PUSH	BC
	INC	DE
	CALL	INHEX
	JRNZ	KDO3-#
	LD	A,(DE)
	CMP	':'		;die alten Werte nehmen ?
	JRZ	KDO4-#
KDO3:	LD	(ARG1),HL	;neue Argumente holen
	CALL	INHEX
	LD	(ARG2),HL
	CALL	INHEX
	LD	(ARG3),HL
KDO4:	POP	BC
	EXAF
	LD	(SOIL2),DE	;Anfang 4. Argument
;Kommando (in Reg B) suchen
	LD	HL,KDOTB	;in Kommandotabelle
KDO5:	LD	A,M
	CMP	B
	JRZ	KDO6-#		;wenn gefunden
	INC	HL
	INC	HL
	INC	HL
	OR 	A		;Tabellenende?
	JRNZ	KDO5-#		;nein
	LD	A,B
	CMP	'@'		;"@"-Kommando?
	JRNZ	KDO1-#		;nein -> Eingabefehler
	LD	HL,USRKD	;Suchen in "@"-Kdo.tab.
	LD	B,C
	JR	KDO5-#
;
KDO6:	INC	HL
	LD	E,M
	INC	HL
	LD	D,M
	EX	DE,HL		;HL=UP-Adresse
	EXAF
	LD	BC,KDO2		;Returnadresse
	PUSH	BC
	JMP	M		;Sprung zur Routine
;
KDOTB:	DB	'Z'
	DA	ZKDO
	DB	'B'
	DA	BKDO
	DB	'C'
	DA	CKDO
	DB	'D'
	DA	DKDO
	DB	'E'
	DA	EKDO
	DB	'F'
	DA	FKDO
	DB	'G'
	DA	GKDO
	DB	'O'
	DA	OKDO
	DB	'I'
	DA	INIT1
	DB	'J'
	DA	JKDO
	DB	'K'
	DA	KKDO
	DB	'L'
	DA	CLOAD
	DB	'M'
	DA	MEM
	DB	'N'
	DA	NKDO
	DB	'R'
	DA	RKDO
	DB	'S'
	DA	CSAVE
	DB	'T'
	DA	TKDO
	DB	'W'
	DA	WKDO
	DB	0
;
;Eingang bei RST 20H 
;
RST1:	EX	(SP),HL
	PUSH	AF
	LD	A,M		;Datenbyte hinter Ruf holen
	LD	(R20BT),A	;und ablegen
	INC	HL		;Returnadresse erhoehen
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
	ADD	HL,BC		;HL=Adresse in Tab.
	LD	A,M
	INC	HL
	LD	H,M
	LD	L,A		;HL=UP-Adresse
	POP	AF
	POP	BC
	EX	(SP),HL		;Ansprung der
	RET			;Routine
;
RSTTB:	DA	OUTCH	;DB 0
	DA	INCH	;DB 1
	DA	PRST7	;DB 2
	DA	INHEX	;DB 3
	DA	INKEY	;DB 4
	DA	INLIN	;DB 5
	DA	OUTHX	;DB 6
	DA	OUTHL	;DB 7
	DA	CSAVE	;DB 8
	DA	CLOAD	;DB 9
	DA	MEM	;DB 10
	DA	WKDO	;DB 11
	DA	OTHLS	;DB 12
	DA	OUTDP	;DB 13
	DA	OUTSP	;DB 14
	DA	TKDO	;DB 15
	DA	INSTR	;DB 16
	DA	KKDO	;DB 17
	DA	HKDO	;DB 18
	DA	AKDO	;DB 19
;
;Eingabe ein Zeichen von der Tastatur in A
;
INKEY:	PUSH	BC
	PUSH	DE
	PUSH	HL
	CALL	JOYIN
	POP	HL
	POP	DE
	POP	BC
	RET
;
;uebergibt aktuell gedrueckte Taste
;
POLL:	XOR	A
	LD	(LAKEY),A	;Puffer loeschen
	CALL	INKEY
	PUSH	AF
	XOR	A
	LD	(LAKEY),A	;Puffer wieder
	POP	AF		;reinigen
	RET
;
;Anzeige Zusatzmonitorkommandos
;
ZKDO:	LD	DE,USRKD	;Adr. Tabelle
ZKO1:	LD	A,(DE)
	AND	0E0H
	RZ			;wenn Steuerzeichen
	BIT	7,A
	RNZ			;wenn Grafikzeichen
	DA	RPRST
	DB	0C0H		;"@"
	LD	A,(DE)
	DA	ROUTC		;Buchstabe ausgeben 
	DA	RPRST
	DB	0BEH		;">"
	INC	DE
	LD	A,(DE)
	LD	L,A
	INC	DE
	LD	A,(DE)
	LD	H,A
	DA	ROTHL		;Adresse anzeigen
	DA	RPRST
	DB	CR+80H
	INC	DE
	JR	ZKO1-#		;naechstes Kommando
;
;Portausgabe
;
OKDO:	LD	A,(ARG1)	;Portadresse
	LD	C,A
	LD	A,(ARG2)	;Wert
	OUT	A
	RET
;
;Registeranzeige / NMI-Routine
;
REGAN:	CALL	REGA		;Register retten
	POP	HL
	LD	(BPADR),HL
	LD	(REGPC),HL
	LD	(REGSP),SP
;
	LD	SP,SYSSK
	LD	DE,BPOPC
	LD	BC,3
	LDIR			;BREAK-Bytes kopieren 
;
	CALL	REGDA		;Registeranzeige
;
	LD	SP,SYSSK	;Grundzustand herstellen 
	LD	HL,KDO2
	PUSH	HL
	RETN			;zum Monitor
;
;Initialisierung der Zusatzfunktionen
;
INIT3:	LD	A,(NMI)
	CMP	0C3H		;schon init. ?
	JRZ	INIT4-#		;dann zurueck
;
	LD	A,0C3H
	LD	(NMI),A
	LD	HL,REGAN	;NMI-Funktion:
	LD	(NMI+1),HL	;Registeranzeige
;
	CALL	RZMIN		;Init. Zusatzmonitor
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
	LD	BC,001AH	;Monitorzellen
	LDIR			;initialisieren
INIT4:	RET
;
;Hardcopy
;
COPY:	PUSH	HL
	PUSH	AF
	LD	HL,KYBTS
	BIT	3,M
	JRZ	COPY2-#		;kein Copy an
;
	CMP	CR		;Konvertierung CR
	JRNZ	COPY1-#
	LD	A,1EH		;in NL
COPY1:	CALL	RDRAK		;Druckerausgabe
COPY2:	POP	AF
	POP	HL
;
	PUSH	AF
	PUSH	BC
	PUSH	DE
	JMP	OUT1		;weiter zu OUTCH
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
MONTB:	DA	07D0H		;Kenntonlaenge
	DB	0
	DB	0
	DB	0
	JMP     KDO1		;RST38-Sprung
	DA	K7KEY		;Tastaturbelegungsfeld
	DA	K7STG		;Stringfeld
	DA	0		
	DA	K7FKA-K7FKY	;Laenge Funktionstastenfeld
	DA	K7FKY		;Fkt.tastenpositionsfeld
	DA	K7FKA		;Funktionstastenadressfeld
	DA	03E0H		;WINDOW-Laenge
	DA	BWS		;WINDOW-Anfang
	DA	BWS+400H	;WINDOW-Ende
;
;Zeichen von Tastatur holen, warten bis Taste gedrueckt
;
INCH:	NOP
	NOP
	NOP
INC1:	CALL	INKEY
	OR 	A
	JRZ	INC1-#		;keine Taste gedrueckt
	NOP
	NOP
	NOP
	RET
;
;Ausgabe Zeichen auf Bildschirm
;
OUT0:	AND	7FH
;
OUTCH:	JMP	COPY		;einschleifen Hardcopy
;
OUT1:	PUSH	HL
	LD	HL,(CUPOS)
	PUSH	AF
	LD	A,(BUFFA)	;Zeichen unter Cursor
	LD	M,A		;zurueckschreiben
	POP	AF
	CMP	CR		;neue Zeile?
	JRZ	OUT8-#
	CMP	CLS		;Bildschirm loeschen?
	JRZ	OUT10-#
	CMP	8		;Cursor links?
	JRZ	OUT7-#
	CMP	9		;Cursor rechts?
	JRZ	OUT2-#
	LD	M,A		;sonst Zeichen in BWS
OUT2:	INC	HL
;
OUT3:	EX	DE,HL
	LD	HL,(WINDE)
	XOR	A		;Test, ob neue Cursor-
	SBC	HL,DE		;position schon
	EX	DE,HL		;ausserhalb Window
	JRNZ	OUT6-#		;nein
;
	LD	DE,(WINDA)	;scrollen um
	LD	HL,0020H	;eine Zeile im Window
	ADD	HL,DE
	LD	BC,(WINDL)	;Windowlaenge
	LD	A,B
	OR 	C		;=0?
	JRZ	OUT5-#		;ja --> kein Scrollen
	LDIR
OUT5:	PUSH	DE		;letzte Zeile loeschen
	POP	HL
	PUSH	HL
	INC	DE
	LD	M,' '
	LD	BC,001FH
	LDIR
;
	LD	HL,(SOIL)	;SOIL um eine Zeile
	LD	DE,0020H	;erhoehen
	XOR	A
	SBC	HL,DE
	LD	(SOIL),HL
	POP	HL
;
OUT6:	LD	A,M		;Zeichen unter Cursor
	LD	(BUFFA),A	;sichern
	LD	M,0FFH		;Cursor setzen
	LD	(CUPOS),HL
	POP	HL
	POP	DE
	POP	BC
	POP	AF
	RET
;
OUT7:	DEC	HL		;Cursor links
	JR	OUT3-#
;
OUT8:	LD	A,0E0H		;neue Zeile
	AND	L
	ADD	20H		;A=NWB der Position 
	LD	C,A		;eine Zeile tiefer
OUT9:	LD	M,' '		;Rest der Zeile ab
	INC	HL		;ENTER loeschen
	LD	A,L
	CMP	C
	JRNZ	OUT9-#
	JR	OUT3-#
;
OUT10:	LD	HL,(WINDL)	;Window loeschen
	LD	BC,001FH
	ADD	HL,BC
	PUSH	HL
	POP	BC
	LD	HL,(WINDA)
	PUSH	HL
	LD	M,' '
	PUSH	HL
	POP	DE
	INC	DE
	LDIR
	POP	HL
	JR	OUT6-#
;
;Ausgabe String, bis Bit7=1
;
PRST7:	EX	(SP),HL		;Adresse hinter CALL
PRS1:	LD	A,M
	INC	HL
	PUSH	AF
	CALL	OUT0
	POP	AF
	BIT	7,A		;Bit7 gesetzt?
	JRZ	PRS1-#		;nein
	EX	(SP),HL		;neue Returnadresse
	RET
;
;Eingabe einer Zeile mit Promtsymbol
;
INLIN:	CALL	PRST7
	DB	' #'
	DB	0A0H		;" "
;
;Eingabe einer Zeichenkette
;
INSTR:	PUSH	HL
	LD	HL,(CUPOS)
	LD	(SOIL),HL	;SOIL=1.Position
INS1:	DA	RINCH		;Zeichen von Tastatur
	DA	ROUTC		;anzeigen
	CMP	CR		;>ENTER<?
	JRNZ	INS1-#		;nein --> weiter eingeben
	POP	HL
	RET
;
;fuehrende Leerzeichen ueberlesen
;
SPACE:	LD	A,(DE)
	CMP	' '
	RNZ
	INC	DE
	JR	SPACE-#
;
;letzen vier Zeichen als Hexzahl konvertieren
;und in DATA ablegen
;
KONVX:	CALL	SPACE
	XOR	A
	LD	HL,DATA
	LD	M,A		;DATA=0
	INC	HL
	LD	M,A
KON1:	LD	A,(DE)
	DEC	HL
	SUB	30H		;Zeichen<"0"?
	RM
	CMP	0AH		;Zeichen<="9"?
	JRC	KON2-#
	SUB	7
	CMP	0AH		;Zeichen<"A"?
	RM
	CMP	10H		;Zeichen>"F"?
	RP
KON2:	INC	DE		;Hexziffer eintragen
	RLD
	INC	HL
	RLD
	JR	KON1-#		;naechste Ziffer
;
;Konvertierung ASCII-Hex ab (DE) --> (HL)
;
INHEX:	PUSH	BC
	CALL	KONVX		;Konvertierung
	LD	B,H		;BC=HL=DATA+1
	LD	C,L
	LD	L,M		;unteres Byte 
	INC	BC
	LD	A,(BC)
	LD	H,A		;oberes Byte
	OR 	L		;Z-Flag setzen
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
	CALL	OUX1		;obere Tetrade ausgeben
	POP	AF		;und die untere
OUX1:	PUSH	AF
	AND	0FH
	ADD	30H		;Konvertierung --> ASCII
	CMP	':'		;Ziffer "A" ... "F"?
	JRC	OUX2-#		;nein
	ADD	7		;sonst Korrektur
OUX2:	CALL	OUTCH		;und Ausgabe
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
MEM1:	DA	ROTHL		;Ausgabe Adresse
	PUSH	HL
	DA	ROTSP		;Leerzeichen
	LD	A,M
	DA	ROTHX		;Ausgabe Byte
	CALL	INLIN
	LD	DE,(SOIL)
	LD	A,(DE)
	EXAF
	POP	HL
	DEC	HL
MEM2:	INC	HL
	PUSH	HL
	CALL	INHEX
	JRZ	MEM4-#		;Trennzeichen
MEM3:	LD	A,L
	POP	HL
	LD	M,A
	CMP	M		;RAM-Test
	JRZ	MEM2-#		;i.O.
	DA	RPRST
	DB	'ER'
	DB	0A0H		;" "
	JR	MEM1-#
;
MEM4:	LD	A,(DE)		;Test Datenbyte=0
	CMP	' '		;wenn ja --> Z=1
	JRZ	MEM3-#
	POP	HL
	INC	HL
	LD	(ARG2),HL	;1. nichtbearb. Adr.
	CMP	';'
	RZ			;Return, wenn ";" gegeben
	EXAF
	CMP	' '
	JRZ	MEM1-#		;Z=1 keine Eingabe
	DEC	HL
	CMP	'R'		;"R" gegeben?
	JRNZ	MEM1-#		;nein
	DEC	HL		;sonst eine Adresse
	JR	MEM1-#		;zurueck
;
;Abspeichern auf Kassette
;
CSAVE:	LD	HL,(ARG1)
	CALL	SAV2		;Ausgabe 20H Bytes
SAV1:	EX	DE,HL
	LD	HL,(ARG2)
	AND	A
	SBC	HL,DE
	EX	DE,HL
	RC			;wenn File zu Ende
	CALL	SAV3		;Ausgabe 20H Byte
	JR	SAV1-#
;
SAV2:	LD	DE,(LSYNC)	;langer Vorton
	JR	SAV4-#
;Ausgabe ein Block = 20H Bytes
SAV3:	LD	DE,000EH	;kurzer Vorton
SAV4:	PUSH	HL
	POP	IX
;HL=Adresse, IX=Kopfinhalt, DE=Laenge Vorton
BSMK:	LD	B,70H		;Vorton ausgeben
SAV5:	DJNZ	SAV5-#
	CALL	SAV21		;Flanke ausgeben
	DEC	DE
	LD	A,E
	OR 	D
	JRNZ	BSMK-#
;
	LD	C,2		;Trennzeichen schreiben
SAV6:	LD	B,36H
SAV7:	DJNZ	SAV7-#
	CALL	SAV21		;Flanke ausgeben
	DEC	C
	JRNZ	SAV6-#
	PUSH	IX
	POP	DE
;
	LD	B,12H		;Kopfinhalt ausgeben
SAV8:	DJNZ	SAV8-#
	CALL	SAV14		;Ausgabe DE
	LD	B,0FH
SAV9:	DJNZ	SAV9-#
;
	LD	C,10H		;10H*2 Bytes
SAV10:	LD	E,M
	INC	HL
	LD	D,M
	ADD	IX,DE		;Pruefsumme bilden
	INC	HL
	PUSH	BC
	CALL	SAV14		;Ausgabe DE
	POP	BC
	DEC	C
	JRZ	SAV12-#		;Block fertig geschrieben
	LD	B,0EH
SAV11:	DJNZ	SAV11-#
	JR	SAV10-#
;
SAV12:	PUSH	IX
	POP	DE		;Pruefsumme
	LD	B,10H
SAV13:	DJNZ	SAV13-#
	CALL	SAV14		;ausgeben
	RET
;
SAV14:	LD	C,10H		;Ausgabe DE
SAV15:	SRL	D
	RR	E
	JRNC	SAV17-#		;C=1 Bit=1
	LD	B,3
SAV16:	DJNZ	SAV16-#
	NOP
	JR	SAV18-#
SAV17:	CALL	SAV21		;Flanke ausgeben
SAV18:	LD	B,19H
SAV19:	DJNZ	SAV19-#
	CALL	SAV21		;Flanke ausgeben
	DEC	C
	RZ			;wenn fertig
	LD	B,15H
SAV20:	DJNZ	SAV20-#
	JR	SAV15-#
;
SAV21:	IN	2		;Flanke ausgeben
	XOR	80H		;durch Bit-Negierung
	OUT	2
	RET
;
;Laden von Kassette
;
CLOAD:	LD	HL,(ARG1)
LOA1:	CALL	LOA3		;laden 20H Bytes
	JRZ	LOA2-#		;wenn kein Ladefehler
	CALL	PRST7
	DB	'CS'
	DB	0BCH		;"<"
	CALL	OUTHL		;Adresse ausgeben
	CALL	OUTSP
LOA2:	EX	DE,HL
	LD	HL,(ARG2)
	AND	A
	SBC	HL,DE		;Endadresse erreicht?
	EX	DE,HL
	RC			;ja --> fertig
	JR	LOA1-#		;sonst weiterlesen
;20H Bytes laden nach (HL)
LOA3:	CALL	LOA24		;synchronisieren
	CALL	LOA25		;Flanke abwarten
	LD	C,7
LOA5:	LD	DE,0910H
	LD	A,7
LOA6:	DEC	A
	JRNZ	LOA6-#
	CALL	LOA24		;synchronisieren
LOA7:	CALL	LOA24		;Flanke ?
	JRNZ	LOA3-#		;wenn nicht Vorton
	DEC	D
	JRNZ	LOA7-#
	DEC	C
	JRZ	LOA9-#
LOA8:	IN	2
	XOR	B
	BIT	6,A
	JRNZ	LOA5-#
	DEC	E
	JRNZ	LOA8-#
	JR	LOA3-#
;Synchronisierimpulse lesen
LOA9:	CALL	LOA25		;Flanke abwarten
	LD	A,44H
LOA10:	DEC	A
	JRNZ	LOA10-#
	CALL	LOA24		;Flanke ?
	JRNZ	LOA9-#		;wenn nicht
	CALL	LOA25		;Flanke abwarten
	LD	A,1EH
LOA11:	DEC	A
	JRNZ	LOA11-#
;2 Bytes Kopf lesen
	CALL	LOA19		;lesen DE
;20H Byte Daten lesen 
	LD	C,10H		;10H x 2 Bytes
	PUSH	DE
	POP	IX		;IX-Pruefsummenzaehler=
	LD	A,1AH
LOA12:	DEC	A
	JRNZ	LOA12-#
LOA13:	CALL	LOA19		;laden DE
	ADD	IX,DE		;Pruefsumme bilden
	PUSH	BC
	LD	C,L
	LD	B,H
	LD	HL,(ARG2)
	XOR	A
	SBC	HL,BC		;Endadresse erreicht?
	LD	L,C
	LD	H,B
	POP	BC
	JRC	LOA14-#		;ja --> Leseende
	LD	M,E
	INC	HL
	LD	M,D
	JR	LOA16-#
LOA14:	LD	A,1
LOA15:	DEC	A
	JRNZ	LOA15-#
	INC	HL
LOA16:	INC	HL
	DEC	C
	JRZ	LOA18-#		;wenn Blockende
	LD	A,12H
LOA17:	DEC	A
	JRNZ	LOA17-#
	JR	LOA13-#		;naechte 2 Byte
LOA18:	LD	A,12H
LOA27:	DEC	A
	JRNZ	LOA27-#
	CALL	LOA19		;Pruefsumme lesen
	EX	DE,HL
	PUSH	IX
	POP	BC
	XOR	A
	SBC	HL,BC
	EX	DE,HL		;Z=0 Ladefehler
	RET
;Laden 2 Byte nach DE
LOA19:	PUSH	HL
	LD	L,10H		;2 Trenn- und 8 Datenbits
LOA20:	CALL	LOA24		;Flanke ?
	JRNZ	LOA21-#
	XOR	A		;Cy=0
	JR	LOA22-#
LOA21:	SCF
LOA22:	RR	D
	RR	E
	CALL	LOA25		;Flanke abwarten
	DEC	L
	JRZ	LOA23-#		;wenn fertig
	LD	A,1EH
LOA26:	DEC	A
	JRNZ	LOA26-#
	JR	LOA20-#
LOA23:	POP	HL
	RET
;Portabfrage
LOA24:	IN	2
	XOR	B
	BIT	6,A
	PUSH	AF
	XOR	B
	LD	B,A
	POP	AF		;Z=0 --> Flanke
	RET
;Warten auf Flankenwechsel
LOA25:	IN	2
	XOR	B
	BIT	6,A
	JRZ	LOA25-#
	RET
;
;Speicherinhalt mit Checksumme anzeigen
;
DKDO:	LD	HL,(ARG1)
DKO1:	LD	DE,(ARG2)
	SCF
	PUSH	HL
	SBC	HL,DE
	POP	HL
	RNC			;wenn EADR<AADR
	DA	ROTHL
	LD	BC,0800H	;B=8
	LD	E,0		;EC=0 - Checksumme
DKO2:	DA	RPRST
	DB	0A0H		;" "
	LD	A,M
	DA	ROTHX
	ADD	C		;Checksumme bilden
	LD	C,A
	JRNC	DKO3-#
	LD	A,0
	ADC	E
	LD	E,A
DKO3:	INC	HL
	DJNZ	DKO2-#
	DA	RPRST
	DB	0A0H		;" "
	LD	A,E
	CALL	OUX1		;Checksumme ausgeben
	LD	A,C
	DA	ROTHX
	JR	DKO1-#
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
KKDO:	CALL	PARA
	LD	M,C		;C=Fuellbyte
	PUSH	HL
	XOR	A
	EX	DE,HL
	SBC	HL,DE
	LD	B,H
	LD	C,L		;BC=Laenge
	POP	HL
	LD	D,H
	LD	E,L
	INC	DE
	LDIR
	RET
;
;Speicherbereich verschieben
;
TKDO:	CALL	PARA
	XOR	A
	PUSH	HL
	SBC	HL,DE
	POP	HL
	JRC	TKO1-#		;wenn Zieladr. groesser
	LDIR			;Vorwaertstransfer
	RET
TKO1:	ADD	HL,BC
	EX	DE,HL
	ADD	HL,BC
	EX	DE,HL
	DEC	HL
	DEC	DE
	LDDR			;Rueckwaertstransfer
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
	EXAF
	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
	JR	REG1-#
;Register aus Registerrettebereich holen
REGH:	LD	(DATA),SP
	LD	SP,REGBR
	POP	HL
	POP	DE
	POP	BC
	POP	AF
	EXX
	EXAF
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
BREAK:	CALL	REGA		;Register ablegen
	POP	HL		;HL=Breakadr.+3
	LD	(REGSP),SP	;SP sichern
	LD	SP,SYSSK	;Systemstack nutzen
	DEC	HL
	DEC	HL
	DEC	HL
	LD	(REGPC),HL	;Breakadresse
	LD	DE,(BPADR)	;die originalen 3 Byte
	LD	HL,BPOPC	;Operanden zurueckbringen
	LD	BC,3
	LDIR
	CALL	REGDA
	JMP	KDO2
;
;Breakpoint-Adresse setzen
;
BKDO:	LD	HL,(ARG1)
	LD	(BPADR),HL
	LD	DE,BPOPC	;3 Byte Operanden
	LD	BC,3		;retten
	LDIR
	CALL	REGDA		;Register anzeigen
	RET
;
;Programm starten mit Breakpoint
;
EKDO:	LD	HL,(BPADR)
	LD	M,0CDH		;CALL ...
	INC	HL
	LD	DE,BREAK	;an Breakpoint Unter-
	LD	M,E		;Brechung zu BREAK eintragen
	INC	HL
	LD	M,D
;
;Programm starten
;
JKDO:	LD	HL,(ARG1)	;Startadresse
	LD	(REGPC),HL	;zwischenspeichern
	LD	SP,(REGSP)	;Stack generieren
	PUSH	HL		;Startadresse in Stack
	JMP	REGH		;Register holen
				;und Pgm. durch RET starten
;
;Programm nach Break fortsetzen
;
GKDO:	LD	HL,(REGPC)
	LD	(ARG1),HL
	LD	DE,(BPADR)
	XOR	A		;Cy=0
	SBC	HL,DE
	JRNZ	EKDO-#		;wenn nicht Breakpoint
	JR	JKDO-#		;starten
;
;Ausgabe eines Doppelpunktes
;
OUTDP:	DA	RPRST
	DB	0BAH		;":"
;
;Ausgabe hex 2 Byte Speicher (HL) und (HL-1)
;und ein Leerzeichen
;
OTHLS:	LD	A,M		;hoeherwertiges Byte
	DA	ROTHX		;ausgeben
	DEC	HL
	LD	A,M		;niederwertiges Byte
	DA	ROTHX		;ausgeben
	DEC	HL		;naechsten Aufruf vorbereiten
;
;Ausgabe ein Leerzeichen
;
OUTSP:	DA	RPRST
	DB	0A0H		;":"
	RET
;
;Z-Flag-Anzeige
;
AUS1:	DA	RPRST		;Ausg. "1 "
	DB	'1'
	DB	0A0H
	RET
AUSX:	JRNZ	AUS1-#
	DA	RPRST		;Ausg. "0 "
	DB	'0'
	DB	0A0H
	RET
;
;Registermodifizerung und -anzeige
;
RKDO:	CMP	':'
	JPNZ	RKO3		;wenn Modifizierung
;
REGDA:	DA	RPRST		;Anzeige Breakpointadresse
	DB	CR
	DB	'B'
	DB	0D0H		;"BP "
	LD	HL,BPADR+1
	DA	ROTDP
	DA	RPRST		;Ausgabe Operandenfolge
	DB	'BS'		;am Breakpoint
	DB	0BAH		;"BS:"
	LD	B,3		;3 Byte 
	LD	HL,BPOPC
RKO1:	LD	A,M
	DA	ROTHX
	INC	HL
	DJNZ	RKO1-#
;
	DA	RPRST		;Flaganzeige
	DB	'   S Z C'
	DB	0A0H
	LD	A,(REGAF)	;A-Flagregister
	LD	L,A
	BIT	7,L		;S-Flag
	CALL	AUSX
	BIT	6,L		;Z-Flag
	CALL	AUSX
	BIT	0,L		;Cy-Flag
	CALL	AUSX
;
	LD	HL,REGSP+1	;Sonderregister-anzeige
	LD	B,2		;2 Registersaetze
	DA	RPRST
RKO2:	DB	'S'
	DB	0D0H		;"SP"
	DA	ROTDP
	DA	RPRST
	DB	'P'
	DB	0C3H		;"PC"
	DA	ROTDP
	DA	RPRST
	DB	'I'
	DB	0D8H		;"IX"
	DA	ROTDP
	DA	RPRST
	DB	'I'
	DB	0D9H		;"IY"
	DA	ROTDP
;
RKO4:	DA	RPRST		;Registersatz anzeigen
	DB	'A'
	DB	0C6H		;"AF"
	DA	ROTDP
	DA	RPRST
	DB	'B'
	DB	0C3H		;"BC"
	DA	ROTDP
	DA	RPRST
	DB	'D'
	DB	0C5H		;"DE"
	DA	ROTDP
	DA	RPRST
	DB	'H'
	DB	0CCH		;"HL"
	DA	ROTDP
	DJNZ	RKO4-#
;
	LD	HL,(CUPOS)	;2. Satz als Schatten-
	DEC	HL		;register markieren:
	LD	M,27H		;"'"
	RET
;
RKO3:	LD	BC,0400H	;B=4, C-Registernummer
	LD	HL,(SOIL)
	INC	HL
	INC	HL
	LD	DE,RKO2
RKO5:	LD	A,(DE)		;Vergleich Registereingabe
	CMP	M		;mit allen Registern
	JRZ	RKO8-#		;wenn gefunden
	INC	DE
RKO6:	PUSH	HL
	LD	HL,5
	ADD	HL,DE
	EX	DE,HL		;naechster Reg.name
	POP	HL
	INC	C		;C-Registernummer
	DJNZ	RKO5-#
	LD	B,4
	LD	A,C
	CMP	8
	JRNZ	RKO5-#		;weitersuchen
	POP	AF		;sonst falsche Eingabe
	RST	38H		;--> zum KDO-Monitor
;
RKO7:	DEC	HL		;weitersuchen
	JR	RKO6-#
;
RKO8:	INC	DE		;Ueberpruefen zweiter
	INC	HL		;Buchstabe
	LD	A,(DE)
	AND	7FH
	CMP	M
	JRNZ	RKO7-#		;wenn ungleich
	INC	HL
	LD	A,M		;Schattenregister ?
	CMP	27H		;"'"
	LD	A,C
	JRNZ	RKO9-#		;wenn nicht
	ADD	4
RKO9:	SLA	A
	LD	C,A
	LD	B,0
	LD	HL,REGSP+1
	SBC	HL,BC
	LD	B,H		;HL=Adresse im
	LD	C,L		;Registerrettebereich
	DA	ROTHS		;Ausgabe Wert
	CALL	INLIN		;Eingabe neuer Wert
	LD	DE,(SOIL)
	CALL	INHEX		;HL=neuer Wert
	JRNZ	RKO10-#		;wenn alles ok
	LD	A,(DE)		;keine Zahl, vielleicht
	CMP	';'		;Abbruch ?
	RZ
;
RKO10:	EX	DE,HL
	PUSH	BC
	POP	HL		;Adr. im Reg.rettebereich
	LD	M,D		;neuen Wert eintragen
	DEC	HL
	LD	M,E
	JMP	REGDA		;Registeranzeige
;
;Hex-Umschaltung (nicht implementiert)
;
HKDO:	RET
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
AKDO:	RET
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
WKDO:	CALL	WKO1		;Kontrolle Parameter
	JRC	WKO3-#		;wenn Fehleingabe
	LD	(WINDL),HL	;neue Werte eintragen
	LD	(WINDA),BC
	LD	HL,(ARG2)
	LD	(WINDE),HL
	LD	HL,(CUPOS)	;Cursor loeschen
	LD	M,' '
	LD	(CUPOS),BC	;Cursor home
	RET
;
WKO1:	LD	A,(ARG1+1)
	CMP	0ECH		;innerhalb BWS ?
	RC			;nein
	LD	A,(ARG1)	;WINDOW-Anfang
	AND	0E0H		;auf Zeilenanfang stellen
	LD	(ARG1),A
	LD	A,(ARG2)	;ebenso WINDOW-Ende
	AND	0E0H
	LD	(ARG2),A
	LD	HL,(ARG2)
	LD	BC,(ARG1)
	SBC	HL,BC
	RC			;Endadresse zu klein
	JRZ	WKO2-#		;kein Window --> Fehler
	DEC	HL
	LD	A,3		;WINDOW zu gross ?
	CMP	H
	RC			;ja
	INC	HL
	LD	DE,0040H
	SBC	HL,DE
	RC			;wenn WINDOW zu klein
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
NKTA:	DB	0FEH		;L(NINTA)
	DB	97H
	DB	0DFH
;
;NEXT-Kommando, Step-Betrieb
;
NKDO:	LD	A,0F7H		;H(NINTA)
	LD	I,A		;Interruptvektor
	DI 
	LD	HL,NKTA 	;Initialisieren PIO Port B
    	LD	BC,0303H	;3 Bytes
	OTIR			;loest selbstaendig INT aus
	LD	HL,(BPADR)	;erstes Byte von Breakadr.
	DEC	HL		;wird EI
	LD	A,M
	LD	(NBYTE),A	;Byte retten
	LD	M,0FBH		;EI einschreiben
	LD	(SPADR),SP
	LD	SP,(REGSP)
	PUSH	HL
	JMP	REGH		;Register holen und Start
;Eingang bei Interrupt
NINTR:	DI 
	CALL	REGA		;Register retten
	LD	A,7		;Interrupt von PIO
	OUT	3		;verbieten
	LD	HL,(BPADR)	;EI-Befehl durch Original-
	DEC	HL		;Byte ersetzen
	LD	A,(NBYTE)
	LD	M,A
	POP	HL
	LD	(BPADR),HL	;neue Breakadresse
	LD	(REGPC),HL
	LD	(REGSP),SP
	LD	SP,(SPADR)	;neue Operandenfolge
	LD	DE,BPOPC	;umladen
	LD	BC,3
	LDIR
	LD	HL,REGDA
	PUSH	HL
	RETI			;Sprung zur Registeranzeige
;
;Speicherbereiche vergleichen
;
CKDO:	CALL	PARA		;Parameter holen
CKO1:	LD	A,(DE)
	CMP	M		;Vergleich
	JRNZ	CKO3-#		;wenn ungleich
CKO2:	DEC	BC
	INC	HL
	INC	DE
	LD	A,B
	OR 	C
	RZ			;wenn alles geprueft
	JR	CKO1-#		;sonst weitertesten
;
CKO3:	DA	ROTHL		;1. Adresse
	DA	ROTSP
	LD	A,M
	DA	ROTHX		;1. Byte
	DA	ROTSP
	EX	DE,HL
	DA	ROTHL		;2. Adresse
	DA	ROTSP
	EX	DE,HL
	LD	A,(DE)
	DA	ROTHX		;2. Byte
	DA	RPRST
	DB	CR+80H
	DA	RINCH		;warten auf Tastendruck
	CMP	CR
	RNZ			;Abbruch wenn <> >ENTER<
	JR	CKO2-#		;sonst weitertesten
;
;Bytefolge suchen
;
FKDO:	LD	DE,(SOIL2)
	DEC	DE
	DEC	DE
	LD	(ARG3),DE	;DE = Beginn Bytefolge
	LD	BC,(ARG1)	;Suchadresse
FKO1:	LD	DE,(ARG3)
	DA	RINHX		;L = 1. Suchbyte 
FKO2:	LD	A,(BC)
	CMP	L		;L = Suchbyte
	JRZ	FKO3-#		;wenn Bytes gleich
	INC	BC		;sonst naechste Suchadresse
	LD	A,B
	OR 	C
	JRZ	FKO7-#		;wenn Speicherende erreicht
	JR	FKO2-#		;weitersuchen
;
FKO3:	PUSH	BC
	PUSH	DE
	LD	DE,(ARG2)	;Suchbyteanzahl
	DEC	DE
	LD	(FBANZ),DE	;Zwischenspeicher fuer Anzahl
	INC	BC
FKO4:	LD	A,D
	OR 	E		;alle Suchbytes verglichen?
	POP	DE
	JRZ	FKO5-#		;wenn Bytefolge gefunden
	DA	RINHX		;naechstes Suchbyte holen
	LD	A,(BC)
	CMP	L
	JRNZ	FKO6-#		;wenn Folge nicht gefunden
	PUSH	DE
	LD	DE,(FBANZ)	;1 Byte weniger zu vergleichen
	DEC	DE
	LD	(FBANZ),DE
	INC	BC
	JR	FKO4-#		;weitervergleichen
;Bytefolge gefunden
FKO5:	POP	BC
	LD	(ARG1),BC
	JMP	MEM		;Speicher modifizieren
;
FKO6:	POP	BC
	INC	BC
	JR	FKO1-#
;Bytefolge nirgends gefunden
FKO7:	DA	RPRST
	DB	'NOT FOUND'
	DB	CR+80H
	RET
;
;Interrupttabelle fuer Break
;
NINTA:	DA	NINTR
;
;neue INKEY-Routine
;
INKY:	LD	A,0FH		;Statusabfrage
	OUT	8
	LD	HL,KYBTS
	BIT	1,M
	JPNZ	INY24		;wenn noch Stringausgabemodus
	LD	B,0
	BIT	6,M
	JRZ	INY2-#		;kein SLOW-Modus
;sonst SLOW-Verzoegerung
INY1:	EX 	(SP),IX
	EX 	(SP),IX
	DJNZ	INY1-#
;
INY2:	IN	2
	CPL
	AND	0FH
	JRNZ	INY3-#		;wenn Taste gedrueckt
	RES	0,M		;sonst Repeatbit auf 0 
	RES	7,M		;keine Taste gedrueckt
	LD	(LAKEY),A	;A=0
	OUT	8		;Status ruecksetzen
	RET
;
INY3:	LD	A,(LAKEY)
	OR 	A		;vorher Taste gedrueckt ?
	JRZ	INY12-#		;nein --> gleich weiter
	BIT	0,M
	JRZ	INY6-#		;kein langes Repeat noetig
;lange Repeatwartezeit
	LD	B,26H
INY4:	LD	C,0
INY5:	DEC	C
	JRNZ	INY5-#
	DJNZ	INY4-#
	JR	INY12-#
;
INY6:	LD	B,80H
INY7:	LD	C,0
INY8:	IN	2
	CPL
	AND	0FH
	JRZ	INY9-#
	DEC	C
	JRNZ	INY8-#
	DJNZ	INY7-#
	SET	0,M		;langes Repeat durchlaufen
	JR	INY12-#
;
INY9:	LD	B,4
INY10:	LD	C,0
INY11:	IN	2
	CPL
	AND	0FH
	JRNZ	INY6-#
	DEC	C
	JRNZ	INY11-#
	DJNZ	INY10-#
;
INY12:	BIT	7,M
	JRNZ	INY15-#		;eine Taste war betaetigt
	LD	B,3
INY13:	LD	C,0
INY14:	IN	2
	CPL
	AND	0FH
	RZ			;Taste gedrueckt
	DEC	C
	JRNZ	INY14-#
	DJNZ	INY13-#
;Spaltenabfrage
INY15:	XOR	A
INY16:	CMP	7
	JRNZ	INY17-#
	ADD	1		;SHIFT/CTRL uebergehen
INY17:	OUT	8
	LD	D,A
	IN	2
	CPL
	AND	0FH
	JRNZ	INY19-#		;aktive Spalte
	LD	A,D
	ADD	1
	CMP	12
	JRNZ	INY16-#		;alle Spalten durch
	RES	0,M		;kein langes Repeat
INY18:	XOR	A		;keine Taste betaetigt
	RET
;Abfrage SHIFT/CTRL
INY19:	LD	BC,0708H
	OUT	B
	SLA	D
	SLA	D
	SLA	D		;Spalte*8
	SUB	1
	ADD	D
	LD	E,A		;E=A=Controlcode
	LD	(LAKEY),A
	IN	2
	AND	0FH
	XOR	8
	LD	A,E
	JRNZ	INY20-#		;wenn CONTR gedrueckt
	ADD	60H		;sonst Korrektur fuer SHIFT
	LD	E,A
;Funktionstasten
INY20:	LD	HL,(PTFKY)
	LD	BC,(PLFKY)
	CPIR
	JRNZ	INY21-#		;wenn Code keine Fkt-Taste
;
	DEC	HL
 	LD	BC,(PTFKY)
	SBC	HL,BC
	SLA	L
	LD	BC,(PTFKA)
	ADD	HL,BC
	LD	C,M
	INC	HL
	LD	H,M
	LD	L,C		;HL:=Adr. aus Adressfeld
	LD	BC,KYBTS
	LD	A,(BC)
	RES	0,A		;keine Taste gedrueckt
	BIT	7,A		;war schon langes Repeat?
	JPNZ	INY18		;kein Repeat von Fkt.tasten
	SET	7,A		;sonst Repeat setzen
	LD	(BC),A
	JMP	M		;Ausfuehren Funktion
;Funktionen
JP100:	LD	HL,100H
	JR	JPX-#
JP200:	LD	HL,200H
	JR	JPX-#
JP300:	LD	HL,300H
JPX:	LD	SP,SYSSK
	LD	DE,KDO1
	PUSH	DE
	JMP	M
;
SGRAF:	LD	L,4		;Graphikschalter
	JR	SCHLT-#
SPRNT:	LD	L,8		;Druckerschalter
	JR	SCHLT-#
SSLOW:	LD	L,40H		;SLOW-Schalter
	JR	SCHLT-#
SBEEP:	LD	L,20H		;Tastaturbeepschalter
	JR	SCHLT-#
SCAPS:	LD	L,10H		;CAPS-Schalter
SCHLT:	LD	A,(BC)		;setzt entsprechendes Bit
	XOR	L
	LD	(BC),A
SCHL2:	XOR	A
	LD	E,A
	JMP	BEEP5
JP038:	CALL	ZMINI
	RST	38H
;
O4SLT:	DA	RINCH		;Tastatureingabe
	SUB	'1'
	JRC	SCHL2-#	
	CMP	6
	JRNC	SCHL2-#
	LD	HL,O4TAB
	LD	D,0
	LD	E,A
	ADD	HL,DE
	IN	4
	AND	0F0H		;Schreibschutz an
	BIT	0,E		;gerade Ziffer (=Setzen)?
	JRNZ	O4SL1-#
	AND	M
	JR	O4SL2-#
O4SL1:	OR	M
O4SL2:	OUT	4
	JR	SCHL2-#		
;
O4TAB:	DB	01110000B	;"1" 64x16 Zeichen
	DB	10000000B	;"2"
	DB	10110000B	;"3" 4 Mhz
	DB	01000000B	;"4"
	DB	11010000B	;"5" 2.ter Zeichensatz
	DB	00100000B	;"6"
;
;Stringtasten
INY21:	LD	HL,(PTKEY)
	LD	D,0
	ADD	HL,DE		;E:=Tastencode
	LD	A,M
	LD	E,A
	IN	2
	BIT	3,A
	JRNZ	INY22-#
	LD	A,E
	AND	9FH
	LD	E,A
	IN	2
	AND	0FH
	JRNZ	INY22-#
	LD	A,80H
	ADD	E
	LD	E,A
INY22:	BIT	7,E
	JRZ	INY26-#		;wenn keine Stringausgabe
 	LD	(LAKEY),A
	LD	HL,(PTSTG)
INY23:	LD	A,M
	OR 	A
	JRZ	INY26-#		;wenn Stringtabellenende 
	INC	HL
	CMP	E
	JRNZ	INY23-#
	LD	(PTNXZ),HL
;Stringausgabe
INY24:	LD	HL,(PTNXZ)
	LD	A,M
	INC	HL
	LD	(PTNXZ),HL
	LD	HL,KYBTS
	SET	1,M		;Stringmode an
	BIT	7,A
	JRNZ	INY25-#		;wenn letzter Buchstabe war
 	OR 	A
 	RNZ
 INY25:	RES	1,M		;Stringmode aus
	XOR	A
	RET
;
INY26:	LD	HL,KYBTS
	LD	A,E
	BIT	2,M		;Grafikmode an?
	JRZ	INY27-#		;nein
	CMP	8
	JRZ	INY27-#
	CMP	9
	JRZ	INY27-#		;wenn CULEFT o. CURIGHT
	ADD	80H		;--> Grafikzeichen
	LD	E,A
INY27:	BIT	4,M		;CAPS an ?
	JRZ	INY29-#		;nein
	LD	A,E		;sonst Gross-Klein-wandlung
	CMP	'A'
	JRC	INY29-#
	CMP	'^'
	JRNC	INY28-#
	ADD	20H
	LD	E,A
	JR	INY29-#
INY28:	CMP	'a'
	JRC	INY29-#
	CMP	'�'
	JRNC	INY29-#
	SUB	20H
	LD	E,A
INY29:	LD	A,E
	LD	(LAKEY),A
	SET	7,M
	BIT	5,M
	JRZ	BEEP7-#
;
;Tonausgabe
;  C=Tonhoehe, B=Tondauer
;
	LD	BC,2039H
BEEP:	PUSH	BC
BEEP1:	PUSH	BC
	LD	A,C
	OR 	A
	LD	A,0FH
	JRZ	BEEP2-#		;C=0 --> kein Ton
	LD	A,0EH		;Beep an
BEEP2:	OUT	8
	POP	BC
	PUSH	BC
BEEP3:	DEC	C
	JRNZ	BEEP3-#		;Flanke abwarten
	LD	A,0FH
	OUT	8		;Beep aus
	POP	BC
	PUSH	BC
BEEP4:	DEC	C
	JRNZ	BEEP4-#		;Flanke abwarten
	POP	BC
	DJNZ	BEEP1-#		;Tondauer
	POP	BC
;Rekonstruktion der Flags
BEEP5:	PUSH	HL
	LD	HL,KYBTS
	LD	A,0EH		;Flags ruecksetzen
	OUT	8
	BIT	3,M		;Drucker parallel?
	JRZ	BEEP6-#		;nein
	LD	A,0CH
	OUT	8
BEEP6:	BIT	4,M		;CAPS an?
	POP	HL
	JRZ	BEEP7-#		;nein
	LD	A,0DH
	OUT	8
BEEP7:	LD	A,7
	OUT	8
;
	LD	A,E		;Tastencode uebergeben
	OR 	A		;evtl. Z-Flag
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
	DB	69		;O4LST
;
;Funktionstastenadressfeld
K7FKA:	DA	SGRAF
	DA	SCAPS
	DA	SSLOW
	DA	SBEEP
	DA	JP038
	DA	JP100
	DA	JP200
	DA	JP300
	DA	SPRNT
	DA	RBSDR
	DA	O4SLT
;Tastenbelegungsfeld
K7KEY:	DB	'1QAY2WSX'	;Spalte 0
	DB	'3EDC4RFV'	;Spalte 1
	DB	'5TGB6ZHN'	;Spalte 2
	DB	'7UJM8IK,'	;Spalte 3
	DB	'9OL.0P�-'	;Spalte 4
	DB	'ᚎ<+#^@'	;Spalte 5
	DB	'>'		;Spalte 6
	DB	CR
	DB	0BH		;CUUP
	DB	8		;CULEFT
	DB	' '
	DB	0		;--> CAPS
	DB	0AH		;CUDOWN
	DB	9		;CURIGHT
				;Spalte 7
	DB	0
	DB	0
	DB	0
	DB	0
	DB	0
	DB	0
	DB	0		;SHIFT
	DB	0		;CTRL
				;Spalte 8
	DB	0
	DB	7FH		;DEL
	DB	14H		;^T
	DB	0		;--> RST38
	DB	ESC
	DB	0		;--> O4SLT
	DB	'�'
	DB	0		;--> JP100
				;Spalte 9
	DB	0		;--> JP200
	DB	0		;--> JP300
	DB	0		;--> HCOPY
	DB	15H		;^U
	DB	19H		;^Y
	DB	12H		;^R
	DB	10H		;^P
	DB	3		;^C
				;Spalte 10
	DB	6		;^F
	DB	0
	DB	0		;--> GRAPHIK
	DB	0		;--> DRUCKER
	DB	0		;--> SLOW
	DB	0		;--> BEEP
	DB	0
	DB	1CH		;^�
				;Spalte 11
	DB	1DH		;^�
	DB	0
	DB	0
	DB	0
	DB	5		;^E
	DB	0
	DB	1		;^A
	DB	0
;Tastenbelegung unter SHIFT
	DB	'!qay"wsx'	;Spalte 0
	DB	'@edc$rfv'	;Spalte 1
	DB	'%tgb&zhn'	;Spalte 2
	DB	'/ujm(ik;'	;Spalte 3
	DB	')ol:=p�_'	;Spalte 4
	DB	'?��`*'		;Spalte 5
	DB	27H		;'
	DB	'�@'
				;Spalte 6
	DB	27H
	DB	CR
	DB	0BH		;CUUP
	DB	8		;CULEFT
	DB	' '
	DB	0		;--> CAPS
	DB	0AH		;CUDOWN
	DB	9		;CURIGHT
				;Spalte 7
	DB	0
	DB	0
	DB	0
	DB	0
	DB	0
	DB	0
	DB	0		;SHIFT
	DB	0		;CTRL
				;Spalte 8
	DB	0
	DB	2		;^B
	DB	13H		;^S
	DB	0		;--> RST38
	DB	1BH		;^�
	DB	0		;--> O4SLT
	DB	'�'
	DB	0		;--> JP100
				;Spalte 9
	DB	0		;--> JP200
	DB	0		;--> JP300
	DB	0		;--> HCOPY
	DB	0FH		;^O
	DB	18H		;^X
	DB	11H		;^Q
	DB	1FH		;^_
	DB	3		;^C
				;Spalte 10
	DB	1EH		;^^
	DB	0
	DB	0		;--> GRAPHIK
	DB	0		;--> DRUCKER
	DB	0		;--> SLOW
	DB	0		;--> BEEP
	DB	0
	DB	1CH		;^�
				;Spalte 11
	DB	1DH		;^�
	DB	0
	DB	0
	DB	0
	DB	19H		;^Y
	DB	0
	DB	18H		;^X
	DB	0
;
;Tastaturstatus ermitteln
;
STAT:	LD	A,0FH		;Statusabfrage
	OUT	8
	XOR	A
	LD	(LAKEY),A	;hinterlaesst Null, d.h.
	IN	2		;keine Taste gedrueckt
	AND	0FH
	SUB	0FH
	RZ			;keine Taste gedrueckt
	LD	A,0FFH		;sonst Uebergabe 0FFH
	RET
;
;HeaderSave
;
SAR0:	DB	0FDH		;LD HY,0
	LD	H,0		;d.h. Typabfrage
;
SARUF:	CALL	HDKAS
	JPC	0D803H		;HEADERDISK
	CMP	':'		;alte Parameter nutzen?
	CANZ	AKP0		;nein --> neue Eingabe
	DA	RPRST
	DB	CR+80H
	CALL	HADR		;Adressen holen
	LDIR			;und kopieren
	LD	HL,AADR
	CALL	HSAV1		;Ausgabe Kopfblock
	LD	HL,(AADR)
	CALL	OADR1		;Anzeige der Adressen
	CALL	HSAV1		;Ausg. 1.Block m. langem Ton
	CALL	HSAV0		;Abspeichern File
	CALL	VERIF		;Verify-Funktion
	RET
;
;Abspeichern ein Block mit langem Vorton 
;
HSAV1:	LD	DE,1000H
	JMP	SAV4
;
;Aufbereitung Kopfpuffer
;
AKP0:	CALL	HADR		;Adressen holen und
	EX	DE,HL		;nach ARGx transportieren 
	LDIR
	LD	HL,(ARG3)
	LD	(SADR),HL
;
	LD	HL,SIGNS	;Block als Kopfblock
	LD	A,0D3H		;markieren
	LD	B,3
AKP1:	LD	M,A
	INC	HL
	DJNZ	AKP1-#
;
	CALL	INKPF		;Eingabe Typ und Name
	DB	0FDH
	LD	A,H		;LD	A,HY
	LD	(TYP),A		;Typ eintragen
	LD	HL,(SOIL)	;Name eintragen
	LD	BC,0010H
	LD	DE,NAME
	LDIR
	DA	RPRST
	DB	CR+80H
	RET
;
;Abspeichern File
;
HSAV0:	EX	DE,HL		;Test, ob Fileende erreicht
	LD	HL,(EADR)
	AND	A
	SBC	HL,DE
	EX	DE,HL
	RC			;wenn ja
	LD	(SOIL2),HL	;sonst weiter mit
	CALL	SAV3		;Blockausgabe
	CALL	OADR1		;Adressen anzeigen
	JR	HSAV0-#
;
;Aufzeichnung ueberpruefen
;
VERIF:	DA	RPRST
	DB	'verify? (Y)'
	DB	0BAH		;":"
	DA	RINCH		;Tastatureingabe
	CMP	'Y'
	RNZ			;wenn kein Verify
;
	DA	RPRST
	DB	' rewind '
	DB	0BCH
	DA	RINCH		;warten auf Tastendruck
	DA	RPRST
	DB	CR
	DB	CR+80H
;
VER1:	CALL	INKY
	CMP	3		;>STOP< ?
	JPZ	RST38		;ja --> Abbruch
	CALL	VER3		;Block lesen
	JRNZ	VER1-#		;wenn kein Fehler
	LD	A,0E0H		;L(AADR)
	CMP	E
	JRNZ	VER1-#		;kein Kopfblock
	XOR	A
	CMP	D
	JRNZ	VER1-#		;kein Kopfblock
;
VER2:	CALL	VER3		;Block lesen
	CANZ	ERBAD		;evtl. Fehlermeldung
	PUSH	AF
	LD	BC,0039H
	CANZ	BEEP		;wenn Fehler
	POP	AF
	RNZ			;wenn Fehler
	LD	H,D
	LD	L,E
	CALL	OADR1		;Anzeige Ladeadresse
	LD	A,(SOIL2)
	CMP	E		;Endadresse erreicht?
	JRNZ	VER2-#		;nein --> weiterlesen
	LD	A,(SOIL2+1)
	CMP	D
	JRNZ	VER2-#		;nein --> weiterlesen
	CALL	OADR3		;Cursorpos. korrigieren
	RET
;
VER3:	LD	A,0FFH		;vollen Block
	LD	(ARG2+1),A
	LD	HL,BWS		;auf den Bildschirm
	CALL	HLBLK		;Block lesen
	RET
;
;HeaderLoad
;
LOR0:	LD	HL,(SOIL)	;Beginn Eingabezeile
	INC	HL
	INC	HL
	INC	HL
	LD	A,M		;(HL)=3. Buchstabe
	DB	0FDH		;hinter "@"
	LD	L,A		;LD	LY,A
	DEC	HL
	DB	0FDH
	LD	H,0		;LD	HY,0
	LD	A,M		;(HL)=2. Buchstabe
;
LORUF:	CALL	HDKAS
	JPC	0D800H		;HEADERDISK
	LD	HL,SHILO	;SHILO dient als
	LD	M,0		;Namenslaengenpuffer
;
	CMP	'N'		;Namenseingabe?
	PUSH	HL
	CAZ	INKPF		;wenn ja --> Eingabe
	POP	HL
;
	LD	HL,(ARG1)	;neue Ladedresse
	LD	(ARG3),HL	;in ARG3 merken
	EXAF
LOR1:	DA	RINKY		;Tastaturabfrage
	CMP	3		;>STOP< ?
	JRNZ	LOR2-#
	DA	RPRST		;ja --> Abbruch
	DB	CR+80H
	RET
;
LOR2:	LD	A,0FFH		;stets vollen Block lesen 
	LD	(ARG2),A
	LD	HL,AADR
	CALL	HLBLK		;Block lesen
	JRNZ	LOR1-#		;sonst bei Fehler neu lesen
;
;Test, ob Kopfblock gelesen
	LD	B,3		;3 Kopfkennzeichen
	LD	HL,SIGNS
LOR3:	LD	A,M
	CMP	0D3H		;Kopfkennzeichen
	INC	HL
	JRNZ	LOR1-#		;wenn kein Kopf
	DJNZ	LOR3-#		;sonst weitertesten
;
LOR4:	DA	RPRST
	DB	CR+80H
;Anzeige von AADR, EADR, SADR
	LD	B,3
	LD	HL,(AADR)
	LD	(SOIL2),HL
	LD	HL,AADR+1
LOR5:	DA	ROTHS		;Adresse anzeigen
	INC	HL
	INC	HL
	INC	HL
	INC	HL
	DJNZ	LOR5-#
	DA	RPRST
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
	LD	A,H		;LD	A,HY
	CMP	21H		;ist Typ Steuerzeichen?
	JRC	LOR6-#		;ja --> kein Vergleich
	LD	HL,TYP
	CMP	M
	CANZ	ERNF		;Typ stimmt nicht
	JRNZ	LOR1-#		;neuen Kopf suchen
;
LOR6:	LD	A,(SHILO)	;Namenslaenge
	LD	B,A
	OR 	A
	JRZ	LOR8-#		;kein Vergleich
;
	LD	HL,NAME		;Namensvergleich
	LD	DE,(SOIL)
LOR7:	LD	A,(DE)
	CMP	M
	INC	HL
	INC	DE
	CANZ	ERNF		;wenn Name nicht stimmt
	JPNZ	LOR1		;dann neuen Kopf lesen
	DJNZ	LOR7-#
;Anzeige der Zieladressen
LOR8:	LD	HL,(ARG3)	;neue Ladeadresse
	XOR	A
	OR 	H
	JRZ	LOR9-#		;wenn nicht eingegeben
;
	LD	BC,(AADR)
	LD	(AADR),HL	;neue AADR eintragen
	DA	ROTHL		;und anzeigen
	DA	ROTSP
	SBC	HL,BC
	LD	BC,(EADR)
	ADD	HL,BC		;neue EADR berechnen
	LD	(EADR),HL	;eintragen
	DA	ROTHL		;und anzeigen
LOR9:	DA	RPRST
	DB	CR
	DB	CR+80H
;
	CALL	HADR		;Adressen kopieren
	LDIR
;
	LD	HL,(AADR)
LOR10:	LD	A,(KYBTS)	;KYBTS merken
	LD	(ARG3),A
	RES	6,A		;SLOW-Mode aus
	LD	(KYBTS),A
	CALL	INKEY		;Tastaturabfrage
	EXAF
	LD	A,(ARG3)
	LD	(KYBTS),A	;KYBTS rueckspeichern
	EXAF
	CMP	3		;<STOP>?
	RZ			;ja --> Abbruch
;
	CALL	OADR1		;Anzeige Blockadresse
	CALL	BLMK		;Block lesen
;
	EX	DE,HL		;Test, ob Ende erreicht
	LD	HL,(EADR)
	AND	A
	SBC	HL,DE
	EX	DE,HL
	JRNC	LOR10-#		;nein --> weiterlesen
;
	LD	HL,(EADR)	;Anzeige der EADR
	CALL	OADR1
	CALL	OADR3		;Cursorpos. korrigieren
;
	LD	HL,(SADR)
	LD	(ARG3),HL
	LD	A,(TYP)
	CMP	'C'		;ist Typ="C"?
	RNZ			;nein --> Abbruch
	DB	0FDH
	LD	A,L		;LD	A,LY
	CMP	' '		;ist Selbstart freigeg.?
	RNZ			;nein --> Abbruch
	JMP	M		;sonst Programmstart
;
;Block lesen mit Header
;
BLMK:	CALL	HLBLK
	JRZ	BLMK3-#		;wenn ohne Fehler
;
	CALL	ERBAD		;Ausgabe "bad record"
	LD	BC,0039H
	CALL	BEEP
BLMK1:	DA	RINCH		;Tastaturabfrage
	CMP	3		;>STOP< ?
	JRZ	BLMK5-#		;ja --> zurueck
	DA	RPRST
	DB	CR
	DB	CR+80H
BLMK2:	LD	BC,0020H
	AND	A
	SBC	HL,BC		;Adresse Fehlerblock
	CALL	HLBLK		;Block neu lesen
	JRNZ	BLMK2-#		;wenn Fehler
;
BLMK3:	LD	A,D
	AND	E
	INC	A
	JRZ	BLMK5-#		;wenn FFFF-Block gelesen
	PUSH	HL
	EX	DE,HL
	AND	A
	LD	DE,(SOIL2)
	SBC	HL,DE
	POP	HL
	JRZ	BLMK4-#		;wenn richtigen Block gelesen
 	JRC	BLMK2-#		;wenn
	CALL	ERREC		;Ausgabe "record"
	CALL	ERNF		;"not found"
	LD	BC,0040H
	CALL	BEEP
	JR	BLMK1-#		;erneut lesen
;
BLMK4:	PUSH	HL
	LD	HL,0020H	;neue Adresse
	ADD	HL,DE
	LD	(SOIL2),HL	;uebergeben
BLMK5:	POP	HL
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
	LD	A,H		;LD	A,HY
	OR 	A
	JRNZ	INKP2-#		;wenn Typ vorgeben
;Abfrage Typ
	DA	RPRST
	DB	CR
	DB	'typ'
	DB	0BAH		;":"
	DA	RINCH
	CMP	' '
	JRNC	INKP1-#		;Steuerzeichen werden zu
	LD	A,' '		;Space gewandelt
INKP1:	DA	ROUTC
	DB	0FDH		;LD	HY,A
	LD	H,A		;Typ merken
;Abfrage Filename
INKP2:	DA	RPRST
	DB	' filename'
	DB	0BAH		;":"
	LD	HL,(CUPOS)
	LD	(SOIL),HL
	LD	C,0FFH		;C:=Zeichenzaehler
INKP3:	INC	C
	DA	RINCH		;Zeichen eingeben
	CMP	3		;>STOP< ?
	JPZ	OADR2		;ja --> Abbruch
	CMP	8		;Cursor links
	JRNZ	INKP5-#		;nein
	DEC	C		;ein Zeichen zurueck
	JPM	INKP3		;wenn linker Rand
INKP4:	DEC	C		;auf vorhergehendes Zeichen
INKP5:	DA	ROUTC		;Zeichen anzeigen
	CMP	CR		;>ENTER< ?
	LD	A,C
	LD	(SHILO),A	;Zeichenanzahl uebergeben
	RZ			;ja --> zurueck
	LD	A,16
	CMP	C		;max. Namenlaenge erreicht?
	LD	A,8
	JRNZ	INKP3-#
	JR	INKP4-#		;ja --> ein Zeichen zurueck
;
;Fehlermeldungen
;
ERBAD:	CALL	OADR3		;Cursorpos. korrigieren
	DA	RPRST
	DB	'bad'
	DB	0A0H
;
ERREC:	DA	RPRST
	DB	'record'
	DB	0A0H
	RET
;
ERNF:	DA	RPRST
	DB	'not found'
	DB	CR+80H
	RET
;
;Ausgabe HL, Cursor loeschen und Cursor zurueck
;
OADR1:	PUSH	DE
	PUSH	HL
	LD	DE,(CUPOS)
	DA	ROTHL
	LD	HL,(CUPOS)
	LD	M,' '
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
HLBLK:	CALL	LOA24		;synchronisieren
	CALL	LOA25		;Flanke abwarten
	LD	C,7
HLB1:	LD	DE,0910H
	LD	A,7
HLB2:	DEC	A
	JRNZ	HLB2-#
	CALL	LOA24		;synchronisieren
HLB3:	CALL	LOA24		;Flanke?
	JRNZ	HLBLK-#		;nein --> kein Vorton
	DEC	D
	JRNZ	HLB3-#
	DEC	C
	JRZ	HLB5-#
HLB4:	IN	2
	XOR	B
	BIT	6,A
	JRNZ	HLB1-#
	DEC	E
	JRNZ	HLB4-#
	JR	HLBLK-#
;Synchronisierimpulse lesen
HLB5:	CALL	LOA25		;Flanke abwarten
	LD	A,44H
HLB6:	DEC	A
	JRNZ	HLB6-#
	CALL	LOA24		;Flanke?
	JRNZ	HLB5-#		;wenn nicht
	CALL	LOA25		;Flanke abwarten
	LD	A,1EH
HLB7:	DEC	A
	JRNZ	HLB7-#
;2 Byte Kopf lesen
	CALL	LOA19		;2 Byte lesen nach DE
	LD	(DATA),DE	;und merken
;20H Datenbyte lesen
	PUSH	DE
	POP	IX
	LD	A,1AH
	LD	C,10H		;10Hx 2 Byte
HLB8:	DEC	A
	JRNZ	HLB8-#
HLB9:	CALL	LOA19		;lesen nach DE
	ADD	IX,DE		;Pruefsumme bilden
	PUSH	BC
	LD	C,L
	LD	B,H
	LD	HL,(ARG2)
	XOR	A
	SBC	HL,BC		;Endadresse erreicht?
	LD	L,C
	LD	H,B
	POP	BC
	JRC	HLB10-#		;ja --> Leseende
	LD	M,E
	INC	HL
	LD	M,D
	JR	HLB12-#
;
HLB10:	LD	A,1
HLB11:	DEC	A
	JRNZ	HLB11-#
	INC	HL
;
HLB12:	INC	HL
	DEC	C
	JRZ	HLB14-#		;wenn Blockende
	LD	A,12H
HLB13:	DEC	A
	JRNZ	HLB13-#
	JR	HLB9-#		;sonst weiterlesen
;
HLB14:	LD	A,12H
HLB15:	DEC	A
	JRNZ	HLB15-#
	CALL	LOA19		;Pruefsumme lesen
	EX	DE,HL
	PUSH	IX
	POP	BC
	XOR	A
	SBC	HL,BC		;Z<>0 Ladefehler
	EX	DE,HL
	LD	DE,(DATA)	;Kopf uebergeben
	RET
;
;Suchen Kopfblock
;
SUCHK:	PUSH	HL
	PUSH	DE
	PUSH	BC
SUCH1:	DA	RINKY		;Tastaturabfrage
	CMP	3		;>STOP< ?
	JRZ	SUCH3-#		;ja --> Abbruch
	LD	A,0FFH		;vollen Block
	LD	(ARG2),A
	LD	HL,AADR		;nach AADR
	CALL	HLBLK		;Block lesen
;
	LD	B,3		;Test ob Kopfblock
	LD	HL,SIGNS
SUCH2:	LD	A,M
	CMP	0D3H
	INC	HL
	JRNZ	SUCH1-#		;kein Kopfblock
	DJNZ	SUCH2-#		;weitertesten
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
	CALL	AKP0		;Aufbereitung unter HSAVE
	POP	BC
	POP	DE
	POP	HL
	RET
;
;******************************************************
; Druckertreiber           CENTONICS
;******************************************************
;
DRINI:	LD	A,(ARG1)
	LD	(DRZSP),A	;fuer Joystickeinbindung
	OR	A
	RNZ
	LD	HL,INLST
	CALL	LSTOT
	RET
;
INLST:	DB	7		;Anzahl
	DB	ESC
	DB	'@'
	DB	ESC
	DB	'8'		;PE aus
	DB	ESC
	DB	'l'
	DB	8		;linker Rand
;
DRZEL:	PUSH	AF
	LD	A,(ARG1)
	CALL	DRAKK
	POP	AF
	RET
;
DRAKK:	PUSH	AF
	CMP	NL		;NL-->CRLF
	JRNZ	DRAK1-#
	LD	A,CR
	CALL	ZEIDR
	LD	A,LF
DRAK1:	CALL	ZEIDR
	POP	AF
	RET
;
LSTOT:	LD	B,M		;<HL>-Liste
LST1:	INC	HL
	LD	A,M
	CALL	ZEIDR
	DJNZ	LST1-#	;<B> mal
	RET
;
ZEIDR:	PUSH	AF
	DI
	LD	A,I
	LD	(BPADR),A	;retten I-Register
	LD	A,0FH		;PIO - Mode 0
	OUT	1
	LD	A,0B4H		;L(INTAB)
	OUT	1
	LD	A,083H		;INT ein
	OUT	1
	LD	A,0FFH		;H(INTAB+1)
	LD	I,A
;
	POP	AF
	OUT	0		;ausgeben
	SCF
	EI
ZEID1:	JRC	ZEID1-#
	LD	A,(BPADR)
	LD	I,A
	RET
;
INTS:	DI
	OR	A	;Cy=0
	RETI
;
;Ausgabe Ton, in C steht die Tonlaenge
;
SOUND:	PUSH	BC
	LD	A,80H
	OUT	0		;Ausgabe Userport
	OUT	2		;Ausgabe Tonbandbuchse
	LD	B,C
SOUN1:	BIT	0,(IX+0)	;Warten erste Halbperiode
	DJNZ	SOUN1-#
	XOR	A
	OUT	0
	OUT	2
	LD	B,C
SOUN2:	BIT	0,(IX+0)	;Warten zweite Halbperiode
	DJNZ	SOUN2-#
	POP	BC
	RET
;
;Joystickabfrage, Joystickmodul nach 'practic' 
;
GETST:	LD	A,0CFH		;PIO Mode 2
	LD	C,1FH
	OUT	1
	LD	A,C
	OUT	1
	LD	A,20H		;linker Joystick
	OUT	0
	IN	0
	AND	C
	SCF
	RZ			;Cy=1 --> kein Modul
	CPL
	AND	C
	LD	B,A
	LD	A,40H		;rechter Joystick
	OUT	0
	IN	0
	CPL
	AND	C
	LD	C,A
	OR 	B		;Z=0 --> keine Taste gedrueckt
	RET
;
;Joystickeinbindung
;
JOYIN:	CALL	INKY		;Tastatureingabe
	RNZ			;wenn Taste gedrueckt
	LD	A,(DRZSP)
	OR	A
	RZ			;kein Joy-Modus
;
	PUSH	BC
	CALL	GETST
	LD	A,20H	
	BIT	4,B
	JRNZ	JOYI1-#
	LD	A,20H	
	BIT	4,B
	JRNZ	JOYI1-#
	LD	A,0BH	
	BIT	3,B
	JRNZ	JOYI1-#
	DEC	A
	BIT	2,B
	JRNZ	JOYI1-#
	DEC	A
	BIT	1,B
	JRNZ	JOYI1-#
	DEC	A
	BIT	0,B
	JRNZ	JOYI1-#
	XOR	A
JOYI1:	LD	(LAKEY),A
	POP	BC
	RET
;
;Initialisieren Zsatzmonitor
;
ZMINI:	LD	HL,ZMTAB
	LD	DE,USRKD
	LD	BC,9
	LDIR
	RET
;
;Zusatzmonitorkommando-Tabelle
;
ZMTAB:	DB	'L'		;Header-Load
	DA	LOR0
	DB	'S'		;Header-Save
	DA	SAR0
	DB	'I'		;Druckertreiber initialisieren
	DA	RDINI
;
;Stringtabelle fuer Inkey-Routine
;
K7STG:	DB	8CH		;L
	DB	'HLOAD'
	DB	86H		;S
	DB	'HSAVE'
	DB	97H		;W
	DB	'WINDOW:CLS'
	DB	85H		;E
	DB	ESC		;1 Zoll Vorschub
	DB	'N'
	DB	6
	DB	ESC		;ELITE-Schrift
	DB	'M'
	DB	1
	DB	0
;
;Umleitung RAM-Disk -- Kassette
;
HDKAS:	LD	(BPADR),A
	DA	RPRST
	DB	CR
	DB	'Cassette or Disk'
	DB	0BAH		;":"
;
HDKA1:	DA	RINCH
	CMP	'C'
	JRZ	HDKA2-#		;Cy=0
	CMP	'D'
	JRNZ	HDKA1-#
	SCF
;
HDKA2:	PUSH	AF
	DA	ROUTC
	DA	RPRST
	DB	CR+80H
	POP	AF
;
	LD	A,(BPADR)	
	RET			;Cy=1 RAM-Disk
;
P1END:	EQU	#
;
;Sprungverteiler
;
	ORG	0FFB4H
;
INTAB:	DA	INTS		;INT-Tabelle
	NOP
;
RRET:	RET
	JMP	SOUND		;Tonausgabe, eine Periode
	JMP	GETST		;Joystikabfrage
	JMP	AKP		;Aufbereitung Kopfpuffer
	JMP	SUCHK		;Kopfblock suchen
	JMP	BSMK		;Block schreiben
	JMP	BLMK		;Block lesen
RZEID:	JMP	ZEIDR		;phys. Druckertreiber
RDINI:	JMP	DRINI		;Druckertreiber initialisieren
	JMP	RRET		;BIN
	JMP	RRET		;AIN
	JMP	RRET		;BSTA
	JMP	RRET		;ASTA
RBEEP:	JMP	BEEP		;Tonausgabe
	JMP	DRZEL		;log. Druckertreiber
	JMP	HARDC		;BWS+Druck
RBSDR:	JMP	RRET		;Bildschirmkopie
RDRAK:	JMP	DRAKK		;log. Druckertreiber
	JMP	RRET		;log. Treiber ruecksetzen
RZMIN:	JMP	ZMINI		;Zusatzmonitor installieren
	JMP	LORUF		;Headerload
	JMP	SARUF		;Headersave
	JMP	STAT		;Tastaturstatus
	JMP	POLL		;Tastaturpolling
	JMP	JOYIN		;Tastaturabfrage

END
