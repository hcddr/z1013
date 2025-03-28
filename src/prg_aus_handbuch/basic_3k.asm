;PN	TINY-BASIC Version 3.01, Original aus Handbuch IIb bzw. Kassette M0111

;reass: Volker Pohlers, Lomonossowallee 41/81, O-2200 Greifswald
;letzte Aenderung: 9.6.1991
;vp070819 Einbau weiterer handschriftl. Kommentare lt. Ausdruck, vermutlich auch noch 1991
;vp070819 Anpassung Arnold-Assembler
;03.12.2012 Anpassung an Palo-Alto-Labels etc.

;das Basic 

	cpu	z80

;Monitoradressen
ARG1:	EQU	0001BH			;1. Argument
ARG2:	EQU	0001DH			;2. Argument
CUPOS:	EQU	0002BH			;akt. Cursorposition
SYSSK:	EQU	000B0H			;Systemstack

;Kopfpuffer bei CLOAD/CSAVE
FAADR:	EQU	000E0H			;Anfangsadresse
FEADR:	EQU	000E2H			;Endadresse
FNAME:	EQU	000F0H			;Filename


ARBRM:	EQU	01000H			;Beginn Arbeitsspeicher
LENZK:	EQU	ARBRM			;Laenge akt. Zeichenkette
LSTZL:	EQU	ARBRM+002H		;Anz. zu listender Zeilen
;????					;LSTZL+1 ist ungenutzt
RANPNT:	EQU	ARBRM+004H		;Zufallswert
INOT:	EQU	ARBRM+006H		;3 byte fuer IN/OUT
CURRNT:	EQU	ARBRM+00BH		;Zeiger auf aktuelle Zeile
STKGOS:	EQU	ARBRM+00DH		;UP-Starter, bei Aufenthalt in UP-Routine 00
VARNXT:	EQU	ARBRM+00FH		;Adresse akt. NEXT-Variable
STKINP:	EQU	ARBRM+011H		;INPUT
LOPVAR:	EQU	ARBRM+013H		;Laufvariablenadresse
LOPINC:	EQU	ARBRM+015H		;Schrittweite Schleife
LOPLMT:	EQU	ARBRM+017H		;Endwert Schleife
LOPLN:	EQU	ARBRM+019H		;Anfangszeile Schleife
LOPPT:	EQU	ARBRM+01BH
M101D:	EQU	ARBRM+01DH
TXTUNF:	EQU	ARBRM+01FH		;BASIC-Pgm.-Ende
STMAX:	EQU	ARBRM+049H		;max. Stacktiefe
STACK:	EQU	ARBRM+113H		;BASIC-Stack
VARBGN:	EQU	ARBRM+115H		;Variablenspeicher A..Z
TXTEND:	EQU	ARBRM+14CH		;memory end
BUFFER:	EQU	ARBRM+14EH		;Pointer Eingabepuffer
INPND:	EQU	ARBRM+150H		;Pointer Eing.pufferende
TXTBGN:	EQU	ARBRM+152H		;Beginn BASIC-Programm

STEND:	EQU	03094H			;Standardwert memory end


CR:	EQU	0DH


;allgemeine Registerverwendung:
;
;   DE - zeigt auf Adresse im Input
;   HL - enthaelt Funktionswert, 2 Byte mit Vorzeichen
;


	ORG	100H

	JP	COLD
	JP	RSTART
OUTCH:	RST	20H			;Zeichenausgabe
	DB	0			;von A
	RET
INCH:	RST	20H			;Zeicheneingabe
	DB	1			;nach A
	RET
SAVE:	RST	20H			;Kassettenspeichern
	DB	8			;von (ARG1) bis (ARG2)
	RET
LOAD:	RST	20H			;Kassettenladen
	DB	9			;von (ARG1) bis (ARG2)
	RET
HEXUM:	RST	20H			;Tastatur auf
	DB	12H			;Zahleneingabe
	RET
ALFA:	RST	20H			;Tastatur auf
	DB	13H			;Buchstabeneingabe
	RET
;
;++++++++++++++++++++++++++++++++++++++
;Vergleich HL und DE
;++++++++++++++++++++++++++++++++++++++
;
COMP:	LD	A,H
	CP	A, D
	RET	NZ
	LD	A,L
	CP	A, E
	RET
;
;++++++++++++++++++++++++++++++++++++++
;Uebergehen von Leerzeichen
;++++++++++++++++++++++++++++++++++++++
;
IGNBLK:	LD	A,(DE)
	CP	A, ' '
	RET	NZ
	INC	DE
	JR	IGNBLK
;
;++++++++++++++++++++++++++++++++++++++
;naechsten Befehl bearbeiten
;++++++++++++++++++++++++++++++++++++++
;
FINISH:	POP	AF
;folgt	noch ein Befehl o. ist Zeilenende?
	CALL	FIN			;dann diesen interpretieren
;nein, also Fehler
	JP	QWHAT
;
;++++++++++++++++++++++++++++++++++++++
;Variablenadresse holen
;++++++++++++++++++++++++++++++++++++++
;
VARAD:	CALL	IGNBLK			;Leerzeichen uebergehen
	SUB	40H			;Buchstabe ?
	RET	C			;nein
	JR	NZ, TV1		;wenn Variable
;
;Feldvariable @(.)
;Ablage des Feldes ab (TXTEND) abwaerts
;
	INC	DE
	CALL	PARN			;Index holen
	ADD	HL,HL			;*2
	JP	C, QHOW		;wenn Index negativ
	PUSH	DE
	EX	DE,HL			;DE=rel. Adresse Variable
	CALL	SIZE			;HL=freier Speicher
	CALL	COMP
	JP	C, QSORRY		;wenn HL<DE -> 'sorry'
;
	LD	HL,(TXTEND)
	CALL	SUBDE			;HL=Adresse Variable
	POP	DE
	RET
;
;Buchstabenvariable
;Ablage im Variablenspeicher
;
TV1:	CP	A, 1BH			;Gro~buchstabe ?
	CCF
	RET	C			;nein
	INC	DE
	LD	HL,VARBGN		;Beginn Variablenspeicher
	RLCA				;A*2
	ADD	A, L
	LD	L,A
	LD	A,0
	ADC	A, H
	LD	H,A			;HL=Adresse
	RET
;
;++++++++++++++++++++++++++++++++++++++
;Zeichenvergleich und Verzweigung
;++++++++++++++++++++++++++++++++++++++
;
TSTC:	EX	(SP),HL
	CALL	IGNBLK			;Leerzeichen uebergehen
	CP	A, (HL)			;(DE)=Datenbyte nach Ruf?
	INC	HL
	JR	Z, TSTC1		;ja
;
;sonst Datenadresse holen und zu dieser+2 springen
;
	PUSH	DE
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	EX	DE,HL
	POP	DE
	JR	TSTC2
;
;wenn Zeichen gleich, so 3 Byte hinter Ruf weiter
;
TSTC1:	INC	DE
TSTC2:	INC	HL
	INC	HL
	EX	(SP),HL
	RET
;
;++++++++++++++++++++++++++++++++++++++
;ASCII->HEX-Konvertierung
;++++++++++++++++++++++++++++++++++++++
;
TSTNUM:	LD	HL,0			;Startwert
	LD	B,H			;B=Stellenanzahl
	CALL	IGNBLK			;Leerzeichen uebergehen
TN1:	CP	A, '0'			;Ziffer >0 ?
	RET	C			;nein
	CP	A, ':'			;Ziffer <=9 ?
	RET	NC			;nein
;reicht der Zahlenumfang fuer die naechste Ziffer?
	LD	A,0F0H			;SET A TO # OF DIGITS
	AND	A, H			;IF H>255, THERE IS NO ROOM FOR NEXT DIGIT
	JR	NZ, QHOW		;nein
;
	INC	B			;naechste Stelle
	PUSH	BC
;EXPR*10
	LD	B,H			;HL=10;*HL+(NEW DIGIT)
	LD	C,L
	ADD	HL,HL			;WHERE 10;* IS DONE BY
	ADD	HL,HL			;SHIFT AND ADD
	ADD	HL,BC
	ADD	HL,HL
;und neue Ziffer dazu
	LD	A,(DE)			;AND (DIGIT) IS FROM
	INC	DE			;STRIPPING THE ASCII
	AND	A, 0FH			;CODE
	ADD	A, L
	LD	L,A
	LD	A,0
	ADC	A, H
	LD	H,A
	POP	BC
;EXPR noch positiv? dann naechste Stelle
	LD	A,(DE)			;DO THIS DIGIT AFTER
	JP	P, TN1			;DIGIT. S SAYS OVERFLOW

;
;++++++++++++++++++++++++++++++++++++++
;Fehlermeldung 'HOW?'
;++++++++++++++++++++++++++++++++++++++
;
QHOW:	PUSH	DE			;*** ERROR: "HOW?" ***
AHOW:	LD	DE,HOW
	JP	ERROR
;
;++++++++++++++++++++++++++++++++++++++
;Meldungen
;++++++++++++++++++++++++++++++++++++++
;
HOW:	DB	"HOW?", CR
OK:	DB	"READY", CR
WHAT:	DB	"WHAT?", CR
SORRY:	DB	"SORRY", CR

;**************************************************************
;*
;* *** MAIN ***
;*
;* THIS IS THE MAIN LOOP THAT COLLECTS THE TINY BASIC PROGRAM
;* AND STORES IT IN THE MEMORY.
;*
;* AT START, IT PRINTS OUT "(CR)OK(CR)", AND INITIALIZES THE
;* STACK AND SOME OTHER INTERNAL VARIABLES.  THEN IT PROMPTS
;* ">" AND READS A LINE.  IF THE LINE STARTS WITH A NON-ZERO
;* NUMBER, THIS NUMBER IS THE LINE NUMBER.  THE LINE NUMBER
;* (IN 16 BIT BINARY) AND THE REST OF THE LINE (INCLUDING CR)
;* IS STORED IN THE MEMORY.  IF A LINE WITH THE SAME LINE
;* NUMBER IS ALREDY THERE, IT IS REPLACED BY THE NEW ONE.  IF
;* THE REST OF THE LINE CONSISTS OF A 0DHONLY, IT IS NOT STORED
;* AND ANY EXISTING LINE WITH THE SAME LINE NUMBER IS DELETED.
;*
;* AFTER A LINE ISs INSERTED, REPLACED, OR DELETED, THE PROGRAM
;* LOOPS BACK AND ASK FOR ANOTHER LINE.  THIS LOOP WILL BE
;* TERMINATED WHEN IT READS A LINE WITH ZERO OR NO LINE
;* NUMBER; AND CONTROL IS TRANSFERED TO "DIRCT".
;*
;* TINY BASIC PROGRAM SAVE AREA STARTS AT THE MEMORY LOCATION
;* LABELED "TXTBGN" AND ENDED AT "TXTEND".  WE ALWAYS FILL THIS
;* AREA STARTING AT "TXTBGN", THE UNFILLED PORTION IS POINTED
;* BY THE CONTENT OF A MEMORY LOCATION LABELED "TXTUNF".
;*
;* THE MEMORY LOCATION "CURRNT" POINTS TO THE LINE NUMBER
;* THAT IS CURRENTLY BEING INTERPRETED.  WHILE WE ARE IN
;* THIS LOOP OR WHILE WE ARE INTERPRETING A DIRECT COMMAND
;* (SEE NEXT SECTION), "CURRNT" SHOULD POINT TO A 0.
;*
;
;++++++++++++++++++++++++++++++++++++++
;Warmstart
;++++++++++++++++++++++++++++++++++++++
;
RSTART:	LD	SP,STACK		;Stack initialisieren
	CALL	ALFA			;Tastatur im Normalmode
	LD	DE,OK
	SUB	A			;A=0
	CALL	PRTSTG			;'Ready' ausgeben
;
	LD	HL,ST2+1		;LITERAL 0
	LD	(CURRNT),HL		;CURRNT->LINE # = 0
	LD	A,0FFH			;Anzahl zu listender
	LD	(LSTZL),A		;Zeilen
ST2:	LD	HL,0
	LD	(LOPVAR),HL
	LD	(STKGOS),HL
;
ST3:	LD	A,'>'			;Ausgabe Prompt
	CALL	GETLN			;und Zeileneingabe
;
	PUSH	DE			;DE->END OF LINE akt. Pufferende
	LD	DE,(BUFFER)		;DE->BEGINNING OF LINE
	CALL	TSTNUM			;evtl. Zeilennummer?
	CALL	IGNBLK			;Leerzeichen uebergehen
	LD	A,H			;HL=VALUE OF THE # OR
	OR	L			;0 IF NO # WAS FOUND
	POP	BC			;BC->END OF LINE
	JP	Z, DIRECT		;wenn keine Zeilenummer, so Befehl ausfuehren
;Zeilennummer hex. in Puffer schreiben
	DEC	DE			;BACKUP DE AND SAVE
	LD	A,H			;VALUE OF LINE # THERE
	LD	(DE),A
	DEC	DE
	LD	A,L
	LD	(DE),A
;
	PUSH	BC			;BC,DE->BEGIN, END
	PUSH	DE
	LD	A,C
	SUB	E
	PUSH	AF			;A=# OF BYTES IN LINE
	CALL	FNDLN			;FIND THIS LINE IN SAVE
	PUSH	DE			;AREA, DE->SAVE AREA
	JR	NZ, ST4			;NZ:NOT FOUND, INSERT
;
	PUSH	DE			;Z:FOUND, DELETE IT
	CALL	FNDNXT			;Zeilenende suchen DE->NEXT LINE
	POP	BC			;BC->LINE TO BE DELETED
	LD	HL,(TXTUNF)		;HL->UNFILLED SAVE AREA
	CALL	MVUP			;MOVE UP TO DELETE
	LD	H,B			;TXTUNF->UNFILLED AREA
	LD	L,C
	LD	(TXTUNF),HL		;UPDATE
;
ST4:	POP	BC			;GET READY TO INSERT
	LD	HL,(TXTUNF)		;BUT FIRT CHECK IF
	POP	AF			;THE LENGTH OF NEW LINE
	PUSH	HL			;IS 3 (LINE # AND CR)
	CP	A, 3			;THEN DO NOT INSERT
	JP	Z, RSTART		;MUST CLEAR THE STACK
	ADD	A, L			;COMPUTE NEW TXTUNF
	LD	L,A
	LD	A,0
	ADC	A, H
	LD	H,A			;HL->NEW UNFILLED AREA
	LD	DE,(TXTEND)		;CHECK TO SEE IF THERE
	CALL	COMP			;IS ENOUGH SPACE
	JP	NC, QSORRY		;SORRY, NO ROOM FOR IT
	LD	(TXTUNF),HL		;OK, UPDATE TXTUNF
	POP	DE			;DE->OLD UNFILLED AREA
	CALL	MVDOWN
	POP	DE			;DE->BEGIN, HL->END
	POP	HL
	CALL	MVUP			;MOVE NEW LINE TO SAVE
	JP	ST3			;AREA
;*
;**************************************************************
;*
;* WHAT FOLLOWS IS THE CODE TO EXECUTE DIRECT AND STATEMENT
;* COMMANDS.  CONTROL IS TRANSFERED TO THESE POINTS VIA THE
;* COMMAND TABLE LOOKUP CODE OF 'DIRECT' AND 'EXEC' IN LAST
;* SECTION.  AFTER THE COMMAND IS EXECUTED, CONTROL IS
;* TANSFERED TO OTHER SECTIONS AS FOLLOWS:
;*
;* FOR 'LIST', 'NEW', AND 'STOP': GO BACK TO 'RSTART'
;* FOR 'RUN': GO EXECUTE THE FIRST STORED LINE IFF ANY; ELSE
;* GO BACK TO 'RSTART'.
;* FOR 'GOTO' AND 'GOSUB': GO EXECUTE THE TARGET LINE.
;* FOR 'RETURN' AND 'NEXT': GO BACK TO SAVED RETURN LINE.
;* FOR ALL OTHERS: IFF 'CURRNT' -> 0, GO TO 'RSTART', ELSE
;* GO EXECUTE NEXT COMMAND.  (THIS IS DONE IN 'FINISH'.)
;*
;**************************************************************
;*
;* *** NEW *** STOP *** RUN (& FRIENDS) *** & GOTO ***
;*
;* 'NEW(CR)' SETS 'TXTUNF' TO POINT TO 'TXTBGN'
;*
;* 'STOP(CR)' GOES BACK TO 'RSTART'
;*
;* 'RUN(CR)' FINDS THE FIRST STORED LINE, STORE ITS ADDRESS (IN
;* 'CURRNT'), AND START EXECUTE IT.  NOTE THAT ONLY THOSE
;* COMMANDS IN TAB2 ARE LEGAL FOR STORED PROGRAM.
;*
;* THERE ARE 3 MORE ENTRIES IN 'RUN':
;* 'RUNNXL' FINDS NEXT LINE, STORES ITS ADDR. AND EXECUTES IT.
;* 'RUNTSL' STORES THE ADDRESS OF THIS LINE AND EXECUTES IT.
;* 'RUNSML' CONTINUES THE EXECUTION ON SAME LINE.
;*
;* 'GOTO EXPR(CR)' EVALUATES THE EXPRESSION, FIND THE TARGET
;* LINE, AND JUMP TO 'RUNTSL' TO DO IT.
;* 'DLOAD' LOADS A NAMED PROGRAM FROM DISK.
;* 'DSAVE' SAVES A NAMED PROGRAM ON DISK.
;* 'FCBSET' SETS UP THE FILE CONTROL BLOCK FOR SUBSEQUENT DISK I/O.
;*
;
;**************************************
;NEW - Programm loeschen
;**************************************
;
NEW:	CALL	ENDCHK			;folgt noch was?
	LD	HL,TXTBGN		;Pgm-ende-zeiger
	LD	(TXTUNF),HL		;ruecksetzen
;
;**************************************
;STOP - Programmabbruch
;**************************************
;
STOP:	CALL	ENDCHK			;folgt noch was?
	JP	RSTART
;
;**************************************
;RUN - Start eines Programms
;**************************************
;
RUN:	CALL	ENDCHK			;folgt noch was?
	LD	DE,TXTBGN		;Programmanfang
;
;neue Zeile abarbeiten
;
RUNNXL:	LD	HL,0
	CALL	FNDLNP			;naechste Zeile suchen
	JP	C, RSTART		;C:PASSED TXTUNF, QUIT
;
RUNTSL:	LD	(CURRNT),DE		;Zeilenanfangsadr.
	INC	DE			;BUMP PASS LINE #
	INC	DE
;
;naechsten Befehl bearbeiten
;
RUNSML:	CALL	CHKIO			;Tastaturinterrupt?
	LD	HL,TBPRC		;Prozedurentab. durchsuchen
	JP	EXEC			;Befehl interpretieren
;
;**************************************
;GOTO znr
;**************************************
;
GOTO:	CALL	EXPR			;znr holen
	PUSH	DE			;SAVE FOR ERROR ROUTINE
	CALL	ENDCHK			;folgt noch was?
	CALL	FNDLN			;Zeile znr suchen
	JP	NZ, AHOW		;wenn nicht ex.
;
	POP	AF			;CLEAR THE "PUSH DE"
	JP	RUNTSL			;Sprung zur Zeile
;*
;*************************************************************
;*
;* *** LIST *** & PRINT ***
;*
;* LIST HAS TWO FORMS:
;* 'LIST(CR)' LISTS ALL SAVED LINES
;* 'LIST #(CR)' START LIST AT THIS LINE #
;* YOU CAN STOP THE LISTING BY CONTROL C KEY
;*
;* PRINT COMMAND IS 'PRINT ....;' OR 'PRINT ....(CR)'
;* WHERE '....' IS A LIST OF EXPRESIONS, FORMATS, BACK-
;* ARROWS, AND STRINGS.  THESE ITEMS ARE SEPERATED BY COMMAS.
;*
;* A FORMAT IS A POUND SIGN FOLLOWED BY A NUMBER.  IT CONTROLSs
;* THE NUMBER OF SPACES THE VALUE OF A EXPRESION IS GOING TO
;* BE PRINTED.  IT STAYS EFFECTIVE FOR THE REST OF THE PRINT
;* COMMAND UNLESS CHANGED BY ANOTHER FORMAT.  IFF NO FORMAT IS
;* SPECIFIED, 6 POSITIONS WILL BE USED.
;*
;* A STRING IS QUOTED IN A PAIR OF SINGLE QUOTES OR A PAIR OF
;* DOUBLE QUOTES.
;*
;* A BACK-ARROW MEANS GENERATE A (CR) WITHOUT (LF)
;*
;* A (CRLF) IS GENERATED AFTER THE ENTIRE LIST HAS BEEN
;* PRINTED OR IFF THE LIST IS A NULL LIST.  HOWEVER IFF THE LIST
;* ENDED WITH A COMMA, NO (CRL) IS GENERATED.
;*
;
;**************************************
;LIST [znr]
;**************************************
;
LIST:	CALL	TSTNUM			;znr berechnen
	CALL	ENDCHK			;folgt noch was?
	LD	A,H
	OR	L
	JR	Z, LIST1
;
;wenn znr=0, so max. 255 Zeilen listen
;sonst Listen von 20 Zeilen ab znr
;
	LD	A,20
	LD	(LSTZL),A
LIST1:	CALL	FNDLN
LS1:	JP	C, RSTART
	CALL	PRTLN			;Anzeige Zeile
	CALL	CHKIO
	LD	A,(LSTZL)
	DEC	A
	LD	(LSTZL),A
	JP	Z, RSTART		;alle Zeilen durch
	CALL	FNDLNP			;zur naechsten Zeile
	JR	LS1
;
;**************************************
;PRINT
;**************************************
;
PRINT:	LD	C,6			;Ausgabeformat 6 Stellen
;
	CALL	TSTC			;folgt ein ';' ?
	DB	";"
	DW	PR2-2			;nein
	CALL	CRLF			;ja -> Ausgabe CR
	JP	RUNSML			;und zurueck
;
PR2:	CALL	TSTC			;folgt Zeilenende ?
	DB	CR
	DW	PR0-2
	CALL	CRLF			;dann CR und zurueck
	JP	RUNNXL
;
PR0:	CALL	TSTC			;folgt Formatanweisung ?
	DB	"#"
	DW	PR1-2
	CALL	EXPR			;dann Format holen
	LD	C,L			;und merken
	JR	PR3			;LOOK FOR MORE TO PRINT
;
PR1:	CALL	QTSTG			;OR IS IT A STRING?
	JR	PR8			;IFF NOT, MUST BE EXPR.
;
PR3:	CALL	TSTC			;folgt ',' ?
	DB	","
	DW	PR6-2
	CALL	FIN			;dann Zahlenwert berechnen
	JR	PR0			;LIST CONTINUES
;
PR6:	CALL	CRLF			;Ausgabe CR
	CALL	FINISH
;
PR8:	CALL	EXPR			;EVALUATE THE EXPR
	PUSH	BC
	CALL	PRTNUM			;EXPR anzeigen
	POP	BC
	JR	PR3			;MORE TO PRINT?
;*
;**************************************************************
;*
;* *** GOSUB *** & RETURN ***
;*
;* 'GOSUB EXPR;' OR 'GOSUB EXPR (CR)' IS LIKE THE 'GOTO'
;* COMMAND, EXCEPT THAT THE CURRENT TEXT POINTER, STACK POINTER
;* ETC. ARE SAVE SO THAT EXECUTION CAN BE CONTINUED AFTER THE
;* SUBROUTINE 'RETURN'.  IN ORDER THAT 'GOSUB' CAN BE NESTED
;* (AND EVEN RECURSIVE), THE SAVE AREA MUST BE STACKED.
;* THE STACK POINTER IS SAVED IN 'STKGOS'. THE OLD 'STKGOS' IS
;* SAVED IN THE STACK.  IFF WE ARE IN THE MAIN ROUTINE, 'STKGOS'
;* IS ZERO (THIS WAS DONE BY THE "MAIN" SECTION OF THE CODE),
;* BUT WE STILL SAVE IT AS A FLAG FORr NO FURTHER 'RETURN'S.
;*
;* 'RETURN(CR)' UNDOS EVERYHING THAT 'GOSUB' DID, AND THUS
;* RETURN THE EXCUTION TO THE COMMAND AFTER THE MOST RECENT
;* 'GOSUB'.  IFF 'STKGOS' IS ZERO, IT INDICATES THAT WE
;* NEVER HAD A 'GOSUB' AND IS THUS AN ERROR.
;*
;
;**************************************
;GOSUB znr
;**************************************
;
GOSUB:	CALL	PUSHA			;neue Verschachtelungsebene
	CALL	EXPR			;znr holen
	PUSH	DE			;akt. Position in Zeile merken
	CALL	FNDLN			;diese Zeile suchen
	JP	NZ, AHOW		;wenn nicht ex.
	LD	HL,(CURRNT)		;FOUND IT, SAVE OLD
	PUSH	HL			;'CURRNT' OLD 'STKGOS'
	LD	HL,(STKGOS)
	PUSH	HL
	LD	HL,0			;AND LOAD NEW ONES
	LD	(LOPVAR),HL
	ADD	HL,SP
	LD	(STKGOS),HL
	JP	RUNTSL			;THEN RUN THAT LINE
;
;**************************************
;RETURN
;**************************************
;
RETURN:	CALL	ENDCHK			;folgt noch was?
	LD	HL,(STKGOS)		;OLD STACK POINTER
	LD	A,H			;0 MEANS NOT EXIST
	OR	L
	JP	Z, QWHAT		;SO, WE SAY: "WHAT?"
	LD	SP,HL			;ELSE, RESTORE IT
	POP	HL
	LD	(STKGOS),HL		;AND THE OLD 'STKGOS'
	POP	HL
	LD	(CURRNT),HL		;AND THE OLD 'CURRNT'
	POP	DE			;OLD TEXT POINTER
	CALL	POPA			;OLD "FOR" PARAMETERS
	CALL	FINISH			;AND WE ARE BACK HOME
;*
;**************************************************************
;*
;* *** FOR *** & NEXT ***
;*
;* 'FOR' HAS TWO FORMS:
;* 'FOR VAR=EXP1 TO EXP2 STEP EXP1' AND 'FOR VAR=EXP1 TO EXP2'
;* THE SECOND FORM MEANS THE SAME THING AS THE FIRST FORM WITH
;* EXP1=1.  (I.E., WITH A STEP OF +1.)
;* TBI WILL FIND THE VARIABLE VAR. AND SET ITS VALUE TO THE
;* CURRENT VALUE OF EXP1.  IT ALSO EVALUATES EXPR2 AND EXP1
;* AND SAVE ALL THESE TOGETHER WITH THE TEXT POINTERr ETC. IN
;* THE 'FOR' SAVE AREA, WHICH CONSISTS OF 'LOPVAR', 'LOPINC',
;* 'LOPLMT', 'LOPLN', AND 'LOPPT'.  IFF THERE IS ALREADY SOME-
;* THING IN THE SAVE AREA (THIS IS INDICATED BY A NON-ZERO
;* 'LOPVAR'), THEN THE OLD SAVE AREA IS SAVED IN THE STACK
;* BEFORE THE NEW ONE OVERWRITES IT.
;* TBI WILL THEN DIG IN THE STACK AND FIND OUT IFF THIS SAME
;* VARIABLE WAS USED IN ANOTHER CURRENTLY ACTIVE 'FOR' LOOP.
;* IFF THAT IS THE CASE THEN THE OLD 'FOR' LOOP IS DEACTIVATED.
;* (PURGED FROM THE STACK..)
;*
;* 'NEXT VAR' SERVES AS THE LOGICAL (NOT NECESSARILLY PHYSICAL)
;* END OF THE 'FOR' LOOP.  THE CONTROL VARIABLE VAR. IS CHECKED
;* WITH THE 'LOPVAR'.  IFF THEY ARE NOT THE SAME, TBI DIGS IN
;* THE STACK TO FIND THE RIGHTt ONE AND PURGES ALL THOSE THAT
;* DID NOT MATCH.  EITHER WAY, TBI THEN ADDS THE 'STEP' TO
;* THAT VARIABLE AND CHECK THE RESULT WITH THE LIMIT.  IFF IT
;* IS WITHIN THE LIMIT, CONTROL LOOPS BACK TO THE COMMAND
;* FOLLOWING THE 'FOR'.  IFF OUTSIDE THE LIMIT, THE SAVE ARER
;* IS PURGED AND EXECUTION CONTINUES.
;*
;
;**************************************
;FOR var=anfang FR1 ende [FR2 weite]
;**************************************
;
FOR:	CALL	PUSHA			;SAVE THE OLD SAVE AREA
	CALL	SETVAL			;SET THE CONTROL VAR.
	DEC	HL			;HL IS ITS ADDRESS
	LD	(LOPVAR),HL		;SAVE THAT
	LD	HL,TBTO			;USE 'EXEC' TO LOOK
	JP	EXEC			;FOR THE WORD 'TO'
;
;**************************************
;TO
;**************************************
;
FR1:	CALL	EXPR			;EVALUATE THE LIMIT
	LD	(LOPLMT),HL		;SAVE THAT
	LD	HL,TBSTP		;USE 'EXEC' TO LOOK
	JP	EXEC			;FOR THE WORD 'STEP'
;
;**************************************
;STEP
;**************************************
;
FR2:	CALL	EXPR			;FOUND IT, GET STEP
	JR	FR4
;
;wenn nicht STEP, so Schrittweite 1
;
FR3:	LD	HL,1			;NOT FOUND, SET TO 1
FR4:	LD	(LOPINC),HL		;SAVE THAT TOO
	LD	HL,(CURRNT)		;SAVE CURRENT LINE #
	LD	(LOPLN),HL		;akt. Zeile merken
	EX	DE,HL			;AND TEXT POINTER
	LD	(LOPPT),HL		;akt. Pos. in Zeile
	LD	BC,10			;B=0, C=10, ;DIG INTO STACK TO
	LD	HL,(LOPVAR)		;FIND 'LOPVAR'
	EX	DE,HL			;DE=Laufvariablenadr.
	LD	H,B
	LD	L,B			;HL=0 NOW
	ADD	HL,SP			;HERE IS THE STACK
	DB	3EH			;LD A,...
FR7:	ADD	HL,BC			;EACH LEVEL IS 10 DEEP
	LD	A,(HL)			;GET THAT OLD 'LOPVAR'
	INC	HL
	OR	(HL)
	JR	Z, FR8			;0 SAYS NO MORE IN IT
	LD	A,(HL)
	DEC	HL
	CP	A, D			;SAME AS THIS ONE?
	JR	NZ, FR7
	LD	A,(HL)			;THE OTHER HALF?
	CP	A, E
	JR	NZ, FR7
	EX	DE,HL			;YES, FOUND ONE
	LD	HL,0
	ADD	HL,SP			;TRY TO MOVE SP
	LD	B,H
	LD	C,L
	LD	HL,10
	ADD	HL,DE
	CALL	MVDOWN			;AND PURGE 10 WORDS
	LD	SP,HL			;IN THE STACK
FR8:	LD	HL,(LOPPT)		;JOB DONE, RESTORE DE
	EX	DE,HL
	CALL	FINISH			;AND CONTINUE
;
;**************************************
;NEXT var
;**************************************
;
NEXT:	CALL	VARAD			;GET ADDRESS OF VAR.
	JP	C, QWHAT		;NO VARIABLE, "WHAT?"
	LD	(VARNXT),HL		;YES, SAVE IT
NX0:	PUSH	DE			;SAVE TEXT POINTER
	EX	DE,HL
	LD	HL,(LOPVAR)		;GET VAR. IN 'FOR'
	LD	A,H
	OR	L			;0 SAYS NEVER HAD ONE
	JP	Z, AWHAT		;SO WE ASK: "WHAT?"
	CALL	COMP			;ELSE WE CHECK THEM
	JR	Z, NX3			;OK, THEY AGREE
	POP	DE			;NO, LET'S SEE
	CALL	POPA			;PURGE CURRENT LOOP
	LD	HL,(VARNXT)		;AND POP ONE LEVEL
	JR	NX0			;GO CHECK AGAIN
;
NX3:	LD	E,(HL)			;COME HERE WHEN AGREED
	INC	HL
	LD	D,(HL)			;DE=VALUE OF VAR.
	LD	HL,(LOPINC)
	PUSH	HL
	LD	A,H
	XOR	D
	LD	A,D
	ADD	HL,DE			;ADD ONE STEP
	JP	M, NEXT3
	XOR	H
	JP	M, NEXT5
NEXT3:	EX	DE,HL
	LD	HL,(LOPVAR)		;PUT IT BACK
	LD	(HL),E
	INC	HL
	LD	(HL),D
	LD	HL,(LOPLMT)		;HL->LIMIT
	POP	AF
	OR	A
	JP	P, NX1			;STEP > 0
	EX	DE,HL
NX1:	CALL	CKHLDE			;COMPARE WITH LIMIT
	POP	DE			;RESTORE TEXT POINTER
	JR	C, NX2			;OUTSIDE LIMIT
	LD	HL,(LOPLN)		;WITHIN LIMIT, GO
	LD	(CURRNT),HL		;BACK TO THE SAVED
	LD	HL,(LOPPT)		;'CURRNT' AND TEXT
	EX	DE,HL			;POINTER
	CALL	FINISH
NEXT5:	POP	HL
	POP	DE
NX2:	CALL	POPA			;PURGE THIS LOOP
	CALL	FINISH
;*
;**************************************************************
;*
;* *** REM *** IFF *** INPUT *** & LET (& DEFLT) ***
;*
;* 'REM' CAN BE FOLLOWED BY ANYTHING AND IS IGNORED BY TBI.
;* TBI TREATS IT LIKE AN 'IF' WITH A FALSE CONDITION.
;*
;* 'IF' IS FOLLOWED BY AN EXPR. AS A CONDITION AND ONE OR MORE
;* COMMANDS (INCLUDING OUTHER 'IF'S) SEPERATED BY SEMI-COLONS.
;* NOTE THAT THE WORD 'THEN' IS NOT USED.  TBI EVALUATES THE
;* EXPR. IFF IT IS NON-ZERO, EXECUTION CONTINUES.  IFF THE
;* EXPR. IS ZERO, THE COMMANDS THAT FOLLOWS ARE IGNORED AND
;* EXECUTION CONTINUES AT THE NEXT LINE.
;*
;* 'INPUT' COMMAND IS LIKE THE 'PRINT' COMMAND, AND IS FOLLOWED
;* BY A LIST OF ITEMS.  IF THE ITEM IS A STRING IN SINGLE OR
;* DOUBLE QUOTES, OR IS A BACK-ARROW, IT HAS THE SAME EFFECT AS
;* IN 'PRINT'.  IF AN ITEM IS A VARIABLE, THIS VARIABLE NAME IS
;* PRINTED OUT FOLLOWED BY A COLON.  THEN TBI WAITS FOR AN
;* EXPR. TO BE TYPED IN.  THE VARIABLE ISs THEN SET TO THE
;* VALUE OF THIS EXPR.  IF THE VARIABLE IS PROCEDED BY A STRING
;* (AGAIN IN SINGLE OR DOUBLE QUOTES), THE STRING WILL BE
;* PRINTED FOLLOWED BY A COLON.  TBI THEN WAITS FOR INPUT EXPR.
;* AND SET THE VARIABLE TO THE VALUE OF THE EXPR.
;*
;* IF THE INPUT EXPR. IS INVALID, TBI WILL PRINT "WHAT?",
;* "HOW?" OR "SORRY" AND REPRINT THE PROMPT AND REDO THE INPUT.
;* THE EXECUTION WILL NOT TERMINATE UNLESS YOU TYPE CONTROL-C.
;* THIS IS HANDLED IN 'INPERR'.
;*
;* 'LET' IS FOLLOWED BY A LIST OF ITEMS SEPERATED BY COMMAS.
;* EACH ITEM CONSISTS OF A VARIABLE, AN EQUAL SIGN, AND AN EXPR.
;* TBI EVALUATES THE EXPR. AND SET THE VARIBLE TO THAT VALUE.
;* TB WILL ALSO HANDLE 'LET' COMMAND WITHOUT THE WORD 'LET'.
;* THIS IS DONE BY 'DEFLT'.
;*
;
;**************************************
;REM - Kommentarzeile
;**************************************
;
REM:	LD	HL,0			;=FALSE
	JR	IF1
;
;**************************************
;IF n vgl m
;**************************************
;
IFF:	CALL	EXPR			;log. Ausdruck auswerten
IF1:	LD	A,H			;IS THE EXPR.=0?
	OR	L
	JP	NZ, RUNSML		;NO, CONTINUE
	CALL	FNDSKP			;YES, SKIP REST OF LINE
	JP	NC, RUNTSL
	JP	RSTART
;
;++++++++++++++++++++++++++++++++++++++
;
;++++++++++++++++++++++++++++++++++++++
;
INPERR:	LD	HL,(STKINP)
	LD	SP,HL			;RESTORE OLD SP
	POP	HL			;AND OLD 'CURRNT'
	LD	(CURRNT),HL
	POP	DE			;AND OLD TEXT POINTER
	POP	DE			;REDO INPUT
;
;**************************************
;INPUT
;**************************************
;
INPUT:	PUSH	DE			;SAVE IN CASE OF ERROR
	CALL	QTSTG			;IS NEXT ITEM A STRING?
	JR	IP2			;NO
;
	CALL	VARAD			;YES. BUT FOLLOWED BY A
	JP	C, IP4			;VARIABLE?   NO.
	JR	IP3			;YES.  INPUT VARIABLE
;
IP2:	PUSH	DE			;SAVE FOR 'PRTSTG'
	CALL	VARAD			;MUST BE VARIABLE NOW
	JP	C, QWHAT		;"WHAT?" IT IS NOT?
	LD	A,(DE)			;GET READY FOR 'RTSTG'
	LD	C,A
	SUB	A
	LD	(DE),A
	POP	DE
	CALL	PRTSTG			;PRINT STRING AS PROMPT
	LD	A,C			;RESTORE TEXT
	DEC	DE
	LD	(DE),A
IP3:	PUSH	DE			;SAVE IN CASE OF ERROR
	EX	DE,HL
	LD	HL,(CURRNT)		;ALSO SAVE 'CURRNT'
	PUSH	HL
	LD	HL,INPUT		;A NEGATIVE NUMBER
	LD	(CURRNT),HL		;AS A FLAG
	LD	HL,0			;SAVE SP TOO
	ADD	HL,SP
	LD	(STKINP),HL
	PUSH	DE			;OLD HL
	CALL	HEXUM			;Tastatur auf Hexmode
	LD	A,':'			;PRINT THIS TOO
	CALL	GETLN			;AND GET A LINE
	CALL	ALFA			;Tastatur zurueckschalten
	LD	DE,(BUFFER)		;POINTS TO BUFFER
	CALL	EXPR			;EVALUATE INPUT
	POP	DE			;OK, GET OLD HL
	EX	DE,HL
	LD	(HL),E			;SAVE VALUE IN VAR.
	INC	HL
	LD	(HL),D
	POP	HL			;GET OLD 'CURRNT'
	LD	(CURRNT),HL
	POP	DE			;AND OLD TEXT POINTER
IP4:	POP	AF			;PURGE JUNK IN STACK
	CALL	TSTC			;IS NEXT CH. ','?
	DB	","
	DW	INPT4-2
	JP	INPUT			;YES, MORE ITEMS.

INPT4:	CALL	FINISH
;
;**************************************
;ohne Prozedurruf
;**************************************
;
DEFLT:	LD	A,(DE)
	CP	A, CR			;EMPTY LINE IS OK
	JR	Z, LT1			;ELSE IT IS 'LET'
;
;**************************************
;LET
;**************************************
;
LET:	CALL	SETVAL			;Zuweisung
	CALL	TSTC			;SET VALUE TO VAR.
	DB	","
	DW	LT1-2
	JR	LET			;ITEM BY ITEM
;
LT1:	CALL	FINISH			;UNTIL FINISH
;*
;**************************************************************
;*
;* *** EXPR ***
;*
;* 'EXPR' EVALUATES ARITHMETICAL OR LOGICAL EXPRESSIONS.
;* <EXPR>::=<EXPR2>
;*          <EXPR2><REL.OP.><EXPR2>
;* WHERE <REL.OP.> IS ONE OF THE OPERATORSs IN TAB8 AND THE
;* RESULT OF THESE OPERATIONS IS 1 IFF TRUE AND 0 IFF FALSE.
;* <EXPR2>::=(+ OR -)<EXPR3>(+ OR -<EXPR3>)(....)
;* WHERE () ARE OPTIONAL AND (....) ARE OPTIONAL REPEATS.
;* <EXPR3>::=<EXPR4>(<* OR /><EXPR4>)(....)
;* <EXPR4>::=<VARIABLE>
;*           <FUNCTION>
;*           (<EXPR>)
;* <EXPR> IS RECURSIVE SO THAT VARIABLE '@' CAN HAVE AN <EXPR>
;* AS INDEX, FNCTIONS CAN HAVE AN <EXPR> AS ARGUMENTS, AND
;* <EXPR4> CAN BE AN <EXPR> IN PARANTHESE.
;*
;*                 EXPR   CALL EXPR2     THIS IS AT LOC. 18
;*                        PUSH HL        SAVE <EXPR2> VALUE
;
;++++++++++++++++++++++++++++++++++++++
;EXPR berechnen
;++++++++++++++++++++++++++++++++++++++
;
EXPR:	CALL	EXPR2
	PUSH	HL			;SAVE <EXPR2> VALUE
;
	LD	HL,TBVGL		;LOOKUP REL.OP.
	JP	EXEC			;GO DO IT
;
;**************************************
;>=
;**************************************
;
XP11:	CALL	XP18			;REL.OP.">="
	RET	C			;NO, RETURN HL=0
	LD	L,A			;YES, RETURN HL=1
	RET
;
;**************************************
;#
;**************************************
;
XP12:	CALL	XP18			;REL.OP."#"
	RET	Z			;FALSE, RETURN HL=0
	LD	L,A			;TRUE, RETURN HL=1
	RET
;
;**************************************
;>
;**************************************
;
XP13:	CALL	XP18			;REL.OP.">"
	RET	Z			;FALSE
	RET	C			;ALSO FALSE, HL=0
	LD	L,A			;TRUE, HL=1
	RET
;
;**************************************
;<=
;**************************************
;
XP14:	CALL	XP18			;REL.OP."<="
	LD	L,A			;SET HL=1
	RET	Z			;REL. TRUE, RETURN
	RET	C
	LD	L,H			;ELSE SET HL=0
	RET
;
;**************************************
;=
;**************************************
;
XP15:	CALL	XP18			;REL.OP."="
	RET	NZ			;FALSE, RETRUN HL=0
	LD	L,A			;ELSE SET HL=1
	RET
;
;**************************************
;<
;**************************************
;
XP16:	CALL	XP18			;REL.OP."<"
	RET	NC			;FALSE, RETURN HL=0
	LD	L,A			;ELSE SET HL=1
	RET
;
;**************************************
;ohne Vergleichsoperation
;**************************************
;
XP17:	POP	HL			;NOT REL.OP.
	RET				;RETURN HL=<EXPR2>
;
;++++++++++++++++++++++++++++++++++++++
;
;++++++++++++++++++++++++++++++++++++++
;
XP18:	LD	A,C			;SUBROUTINE FOR ALL
	POP	HL			;REL.OP.'S
	POP	BC
	PUSH	HL			;REVERSE TOP OF STACK
	PUSH	BC
	LD	C,A
	CALL	EXPR2			;GET 2ND <EXPR2>
	EX	DE,HL			;VALUE IN DE NOW
	EX	(SP),HL			;1ST <EXPR2> IN HL
	CALL	CKHLDE			;COMPARE 1ST WITH 2ND
	POP	DE			;RESTORE TEXT POINTER
	LD	HL,0			;SET HL=0, A=1
	LD	A,1
	RET
;
;++++++++++++++++++++++++++++++++++++++
;math. Ausdruck berechnen
;++++++++++++++++++++++++++++++++++++++
;
;negatives Vorzeichen
;
EXPR2:	CALL	TSTC			;NEGATIVE SIGN?
	DB	"-"
	DW	XP21-2
	LD	HL,0			;YES, FAKE '0-'
	JR	XP26			;TREAT LIKE SUBTRACT
;
;positives Vorzeichen
;
XP21:	CALL	TSTC			;POSITIVE SIGN?  IGNORE
	DB	"+"
	DW	XP22-2
XP22:	CALL	EXPR3			;1ST <EXPR3>
;
;Addition
;
XP23:	CALL	TSTC			;ADD?
	DB	"+"
	DW	XP25-2
	PUSH	HL			;YES, SAVE VALUE
	CALL	EXPR3			;GET 2ND<EXPR3>
XP24:	EX	DE,HL			;2ND IN DE
	EX	(SP),HL			;1ST IN HL
	LD	A,H			;COMPARE SIGN
	XOR	D
	LD	A,D
	ADD	HL,DE
	POP	DE			;RESTORE TEXT POINTER
	JP	M, XP23			;1ST 2ND SIGN DIFFER
	XOR	H			;1ST 2ND SIGN EQUAL
	JP	P, XP23			;SO ISp RESULT
	JP	QHOW			;ELSE WE HAVE OVERFLOW
;
;Subtraktion
;
XP25:	CALL	TSTC			;SUBTRACT?
	DB	"-"
	DW	XP42-2
XP26:	PUSH	HL			;YES, SAVE 1ST <EXPR3>
	CALL	EXPR3			;GET 2ND <EXPR3>
	CALL	CHGSGN			;NEGATE
	JR	XP24			;AND ADD THEM
;
;Multiplikation
;
EXPR3:	CALL	EXPR4			;GET 1ST <EXPR4>
XP31:	CALL	TSTC			;MULTIPLY?
	DB	"*"
	DW	XP34-2
	PUSH	HL			;YES, SAVE 1ST
	CALL	EXPR4			;AND GET 2ND <EXPR4>
	LD	B,0			;CLEAR B FOR SIGN
	CALL	CHKSGN			;CHECK SIGN
	EX	(SP),HL
	CALL	CHKSGN			;CHECK SIGN OF 1ST
	EX	DE,HL			;2ND IN DE NOW
	EX	(SP),HL			;1ST IN HL
	LD	A,H			;IS HL > 255 ?
	OR	A
	JR	Z, XP32			;NO
	LD	A,D
	OR	D
	EX	DE,HL			;PUT SMALLER IN HL
	JP	NZ, AHOW		;ALSO >, WILL OVERFLOW
XP32:	LD	A,L			;THIS IS DUMB
	LD	HL,0			;CLEAR RESULT
	OR	A			;ADD AND COUNT
	JR	Z, XP35
XP33:	ADD	HL,DE
	JP	C, AHOW			;OVERFLOW
	DEC	A
	JR	NZ, XP33
	JR	XP35			;FINISHED
;
;Division
;
XP34:	CALL	TSTC			;DIVIDE?
	DB	"/"
	DW	XP42-2
	PUSH	HL			;YES, SAVE 1ST <EXPR4>
	CALL	EXPR4			;AND GET 2ND ONE
	LD	B,0			;CLEAR B FOR SIGN
	CALL	CHKSGN			;CHECK SIGN OF 2ND
	EX	(SP),HL
	CALL	CHKSGN			;CHECK SIGN OF 1ST
	EX	DE,HL
	EX	(SP),HL			;GET 1ST IN HL
	EX	DE,HL			;PUT 2ND IN DE
	LD	A,D			;DIVIDE BY 0?
	OR	E
	JP	Z, AHOW			;SAY "HOW?"
	PUSH	BC			;ELSE SAVE SIGN
	CALL	DIVIDE			;USE SUBROUTINE
	LD	H,B			;RESULT IN HL NOW
	LD	L,C
	POP	BC			;GET SIGN BACK
XP35:	POP	DE			;AND TEXT POINTER
	LD	A,H			;HL MUST BE +
	OR	A
	JP	M, QHOW			;ELSE IT IS OVERFLOW
	LD	A,B
	OR	A
	CALL	M, CHGSGN		;CHANGE SIGN IFF NEEDED
	JP	XP31			;LOOK OR MORE TERMS
;
EXPR4:	LD	HL,TBFKT		;FIND FUNCTION IN TBFKT
	JP	EXEC			;AND GO DO IT
;
;**************************************
;wenn kein Funktionsruf
;**************************************
;
XP40:	CALL	VARAD			;NO, NOT A FUNCTION
	JR	C, XP41			;NOR A VARIABLE
	LD	A,(HL)			;VARIABLE
	INC	HL
	LD	H,(HL)			;VALUE IN HL
	LD	L,A
	RET				;HL=Variableninhalt
;
XP41:	CALL	TSTNUM			;OR IS IT A NUMBER
	LD	A,B			;# OF DIGIT
	OR	A
	RET	NZ			;OK
;
;
;++++++++++++++++++++++++++++++++++++++
;EXPR in Klammern berechnen
;++++++++++++++++++++++++++++++++++++++
;
PARN:	CALL	TSTC			;NO DIGIT, MUST BE
	DB	"("
	DW	XP43-2
	CALL	EXPR			;"(EXPR)"
	CALL	TSTC
	DB	")"
	DW	XP43-2
XP42:	RET
;
XP43:	JP	QWHAT			;ELSE SAY: "WHAT?"
;
;**************************************
;RND (EXPR)
;**************************************
;
RND:	LD	HL,RANPNT		;Speicher fuer Zufallswert
	LD	A,R			;aendern
	RLD
	INC	HL
	RLD
	CALL	PARN			;EXPR holen
	LD	A,H			;EXPR MUST BE +
	OR	A
	JP	M, QHOW
	OR	L			;AND NON-ZERO
	JP	Z, QHOW
	PUSH	DE			;SAVE BOTH
	PUSH	BC
	EX	DE,HL			;in DE EXPR
	LD	HL,(RANPNT)
RA1:	SBC	HL,DE			;Zufallszahl um index er-
	JR	NC, RA1			;niedrigen, bis negativ
	ADD	HL,DE			;dann index addieren
	INC	HL
	POP	BC
	POP	DE
	RET
;
;**************************************
;ABS (EXPR)
;**************************************
;
ABS:	CALL	PARN			;EXPR holen
	DEC	DE
	CALL	CHKSGN			;und Betrag bilden
	INC	DE
	RET
;
;**************************************
;SIZE
;**************************************
;
SIZE:	LD	HL,(TXTUNF)		;aktuelles Pgm.ende
	PUSH	DE			;GET THE NUMBER OF FREE
	EX	DE,HL			;BYTES BETWEEN 'TXTUNF'
	LD	HL,(TXTEND)		;und Speicherende
	CALL	SUBDE			;Differenz bilden
	POP	DE
	RET
;*
;**************************************************************
;*
;* *** DIVIDE *** SUBDE *** CHKSGN *** CHGSGN *** & CKHLDE ***
;*
;* 'DIVIDE' DIVIDES HL BY DE, RESULT IN BC, REMAINDER IN HL
;*
;* 'SUBDE' SUBTRACTS DE FROM HL
;*
;* 'CHKSGN' CHECKS SIGN OF HL.  IFF +, NO CHANGE.  IFF -, CHANGE
;* SIGN AND FLIP SIGN OF B.
;*
;* 'CHGSGN' CHNGES SIGN OF HL AND B UNCONDITIONALLY.
;*
;* 'CKHLE' CHECKS SIGN OF HL AND DE.  IFF DIFFERENT, HL AND DE
;* ARE INTERCHANGED.  IFF SAME SIGN, NOT INTERCHANGED.  EITHER
;* CASE, HL DE ARE THEN COMPARED TO SET THE FLAGS.
;*
;
;++++++++++++++++++++++++++++++++++++++
;Division BC := HL / DE
;++++++++++++++++++++++++++++++++++++++
;
DIVIDE:	PUSH	HL
	LD	L,H			;DIVIDE H BY DE
	LD	H,0
	CALL	DHLD1
	LD	B,C			;SAVE RESULT IN B
	LD	A,L			;(REMAINDER+L)/DE
	POP	HL
	LD	H,A
DHLD1:	LD	C,0FFH			;RESULT IN C
DHLD2:	INC	C			;DUMB ROUTINE
	CALL	SUBDE			;DIVIDE BY SUBTRACT
	JR	NC, DHLD2		;AND COUNT
	ADD	HL,DE
	RET
;
;++++++++++++++++++++++++++++++++++++++
;Berechnung HL := HL - DE
;++++++++++++++++++++++++++++++++++++++
;
SUBDE:	LD	A,L
	SUB	E			;SUBTRACT DE FROM
	LD	L,A			;HL
	LD	A,H
	SBC	A,D
	LD	H,A
	RET
;
;++++++++++++++++++++++++++++++++++++++
;Absolutbetrag einer EXPR bilden
;++++++++++++++++++++++++++++++++++++++
;
CHKSGN:	LD	A,H
	OR	A			;CHECK SIGN OF HL
	RET	P			;IF -, CHANGE SIGN
;
;inverse EXPR bilden
;
CHGSGN:	LD	A,H			;EXPR=0?
	OR	L
	RET	Z			;ja
;
	LD	A,H			;sonst EXPR negieren...
	PUSH	AF
	CPL				;CHANGE SIGN OF HL
	LD	H,A
	LD	A,L
	CPL
	LD	L,A
	INC	HL
	POP	AF
	XOR	H
	JP	P, QHOW			;wenn Ueberlauf
	LD	A,B			;AND ALSO FLIP B
	XOR	80H
	LD	B,A
	RET
;
;++++++++++++++++++++++++++++++++++++++
;Vergleich HL - DE
;++++++++++++++++++++++++++++++++++++++
;
CKHLDE:	LD	A,H
	XOR	D			;SAME SIGN?
	JP	P, COMP1		;YES, COMPARE
	EX	DE,HL			;NO, XCH AND COMP
COMP1:	CALL	COMP
	RET
;*
;**************************************************************
;*
;* *** SETVAL *** FIN *** ENDCHK *** & ERROR (& FRIENDS) ***
;*
;* "SETVAL" EXPECTS A VARIABLE, FOLLOWED BY AN EQUAL SIGN AND
;* THEN AN EXPR.  IT EVALUATES THE EXPR. AND SET THE VARIABLE
;* TO THAT VALUE.
;*
;* "FIN" CHECKS THE END OF A COMMAND.  IFF IT ENDED WITH ";",
;* EXECUTION CONTINUES.  IFF IT ENDED WITH A CR, IT FINDS THE
;* NEXT LINE AND CONTINUE FROM THERE.
;*
;* "ENDCHK" CHECKS IFF A COMMAND IS ENDED WITH CR.  THIS IS
;* REQUIRED IN CERTAIN COMMANDS. (GOTO, RETURN, AND STOP ETC.)
;*
;* "ERROR" PRINTS THE STRING POINTED BY DE (AND ENDS WITH CR).
;* IT THEN PRINTS THE LINE POINTED BY 'CURRNT' WITH A "?"
;* INSERTED AT WHERE THE OLD TEXT POINTER (SHOULD BE ON TOP
;* O THE STACK) POINTS TO.  EXECUTION OF TB IS STOPPED
;* AND TBI IS RESTARTED.  HOWEVER, IFF 'CURRNT' -> ZERO
;* (INDICATING A DIRECT COMMAND), THE DIRECT COMMAND IS NOT
;*  PRINTED.  AND IFF 'CURRNT' -> NEGATIVE # (INDICATING 'INPUT'
;* COMMAND, THE INPUT LINE IS NOT PRINTED AND EXECUTION IS
;* NOT TERMINATED BUT CONTINUED AT 'INPERR'.
;*
;* RELATED TO 'ERROR' ARE THE FOLLOWING:
;* 'QWHAT' SAVES TEXT POINTER IN STACK AND GET MESSAGE "WHAT?"
;* 'AWHAT' JUST GET MESSAGE "WHAT?" AND JUMP TO 'ERROR'.
;* 'QSORRY' AND 'ASORRY' DO SAME KIND OF THING.
;* 'QHOW' AND 'AHOW' IN THE ZERO PAGE SECTION ALSO DO THIS
;*
;
;++++++++++++++++++++++++++++++++++++++
;LET-Zuweisung
;++++++++++++++++++++++++++++++++++++++
;
SETVAL:	CALL	VARAD			;Var.adr. holen
	JP	C, QWHAT		;"WHAT?" NO VARIABLE
;
	PUSH	HL			;SAVE ADDRESS OF VAR.
	CALL	TSTC			;PASS "=" SIGN
	DB	"="
	DW	SV1-2
;
	CALL	EXPR			;EVALUATE EXPR.
	LD	B,H			;VALUE IN BC NOW
	LD	C,L
	POP	HL			;GET ADDRESS
	LD	(HL),C			;SAVE VALUE
	INC	HL
	LD	(HL),B
	RET

SV1:	JP	QWHAT			;NO "=" SIGN
;
;++++++++++++++++++++++++++++++++++++++
;naechsten Befehl interpretieren
;++++++++++++++++++++++++++++++++++++++
;
FIN:	CALL	TSTC
	DB	";"
	DW	FI1-2
	POP	AF			;";", PURGE RET ADDR.
	JP	RUNSML			;CONTINUE SAME LINE
;
FI1:	CALL	TSTC			;NOT ";", IS IT CR?
	DB	CR
	DW	FI2-2
	POP	AF			;YES, PURGE RET ADDR.
	JP	RUNNXL			;RUN NEXT LINE
;
FI2:	RET				;ELSE RETURN TO CALLER
;
;++++++++++++++++++++++++++++++++++++++
;Test, ob Zeilenende erreicht
;++++++++++++++++++++++++++++++++++++++
;
ENDCHK:	CALL	IGNBLK			;Leerzeichen uebergehen
	CP	A, CR			;END WITH CR?
	RET	Z			;OK, ELSE SAY: "WHAT?"
;
;++++++++++++++++++++++++++++++++++++++
;Fehlermeldung 'WHAT'
;++++++++++++++++++++++++++++++++++++++
;
QWHAT:	PUSH	DE
AWHAT:	LD	DE,WHAT
;
;++++++++++++++++++++++++++++++++++++++
;Fehlerbehandlung
;++++++++++++++++++++++++++++++++++++++
;
ERROR:	SUB	A
	CALL	PRTSTG			;PRINT 'WHAT?', 'HOW?'
	POP	DE			;OR 'SORRY'
	LD	A,(DE)			;SAVE THE CHARACTER
	PUSH	AF			;AT WHERE OLD DE ->
	SUB	A			;AND PUT A 0 THERE
	LD	(DE),A
;
	LD	HL,(CURRNT)		;GET CURRENT LINE #
	PUSH	HL
	LD	A,(HL)			;CHECK THE VALUE
	INC	HL
	OR	(HL)
	POP	DE
	JP	Z, RSTART		;IF ZERO, JUST RERSTART
;
	LD	A,(HL)			;IF NEGATIVE,
	OR	A
	JP	M, INPERR		;REDO INPUT
;
	CALL	PRTLN			;ELSE PRINT THE LINE
	DEC	DE			;UPTO WHERE THE 0 IS
	POP	AF			;RESTORE THE CHARACTER
	LD	(DE),A
	LD	A,'?'			;PRINTt A "?"
	CALL	OTSTC
	SUB	A			;AND THE REST OF THE
	CALL	PRTSTG			;LINE
	JP	RSTART
;
;++++++++++++++++++++++++++++++++++++++
;Fehlermeldung 'SORRY'
;++++++++++++++++++++++++++++++++++++++
;
ERSOR:	PUSH	DE
QSORRY:	LD	DE,SORRY
	JP	ERROR
;*
;**************************************************************
;*
;* *** GETLN *** FNDLN (& FRIENDS) ***
;*
;* 'GETLN' READS A INPUT LINE INTO 'BUFFER'.  IT FIRST PROMPT
;* THE CHARACTER IN A (GIVEN BY THE CALLER), THEN IT FILLS THE
;* THE BUFFER AND ECHOS.  IT IGNORES LF'S AND NULLS, BUT STILL
;* ECHOS THEM BACK.  RUB-OUT IS USED TO CAUSE IT TO DELETE
;* THE LAST CHARATER (IFF THERE IS ONE), AND ALT-MOD IS USED TO
;* CAUSE IT TO DELETE THE WHOLE LINE AND START IT ALL OVER.
;* 0DHSIGNALS THE END OF A LINE, AND CAUE 'GETLN' TO RETURN.
;*
;* 'FNDLN' FINDS A LINE WITH A GIVEN LINE # (IN HL) IN THE
;* TEXT SAVE AREA.  DE IS USED AS THE TEXT POINTER.  IFF THE
;* LINE IS FOUND, DE WILL POINT TO THE BEGINNING OF THAT LINE
;* (I.E., THE LOW BYTE OF THE LINE #), AND FLAGS ARE NC & Z.
;* IFF THAT LINE IS NOT THERE AND A LINE WITH A HIGHER LINE #
;* IS FOUND, DE POINTS TO THERE AND FLAGS ARE NC & NZ.  IFF
;* WE REACHED THE END OF TEXT SAVE ARE AND CANNOT FIND THE
;* LINE, FLAGS ARE C & NZ.
;* 'FNDLN' WILL INITIALIZE DE TO THE BEGINNING OF THE TEXT SAVE
;* AREA TO START THE SEARCH.  SOME OTHER ENTRIES OF THIS
;* ROUTINE WILL NOT INITIALIZE DE AND DO THE SEARCH.
;* 'FNDLNP' WILL START WITH DE AND SEARCH FOR THE LINE #.
;* 'FNDNXT' WILL BUMP DE BY 2, FIND A 0DHAND THEN START SEARCH.
;* 'FNDSKP' USE DE TO FIND A CR, AND THEN STRART SEARCH.
;*
;
;++++++++++++++++++++++++++++++++++++++
;Eingaberoutine
;++++++++++++++++++++++++++++++++++++++
;
GETLN:	CALL	OTSTC			;Ausgabe (A)
	LD	DE,(BUFFER)		;Beginn Eingabepuffer
INLI1:	CALL	INCH			;Zeicheneingabe
	CP	A, 8			;Cursor links?
	JR	Z, INLI4		;ein Zeichen zurueck
	CP	A, 9			;Cursor rechts?
	JR	Z, INLI2		;dann ein Zeichen weiter
	CP	A, 3			;STOP?
	JP	Z, RSTART		;dann Abbruch
;
	LD	(DE),A			;sonst Zeichen in Puffer
;
INLI2:	INC	DE			;Pufferadr. erhoehen
INLI3:	CALL	OTSTC			;Zeichen anzeigen
;
	CP	A, CR			;bei ENTER
	RET	Z			;zurueck
;
	LD	A,E
	CALL	M0961			;Pufferende erreicht?
	JR	NZ, INLI1		;nein --> weiter
;sonst ein Zeichen zurueck
INLI4:	LD	A,E
	CALL	M0968			;Pufferanfang erreicht?
	JR	Z, INLI1		;weiter eingeben
;
	DEC	DE			;sonst im Puffer zurueck
	LD	A,8			;und Cursor zurueck
	JR	INLI3
;
;++++++++++++++++++++++++++++++++++++++
;suche naechste Zeile mit znr <= HL
;++++++++++++++++++++++++++++++++++++++
;
FNDLN:	LD	A,H
	OR	A			;CHECK SIGN OF HL
	JP	M, QHOW			;IT CANNT BE -
	LD	DE,TXTBGN		;INIT. TEXT POINTER
;naechstfolgende Zeile suchen
FNDLNP:	EQU	$
FL1:	PUSH	HL			;SAVE LINE #
	LD	HL,(TXTUNF)		;CHECK IFF WE PASSED END
	DEC	HL
	CALL	COMP			;Ende erreicht?
	POP	HL			;GET LINE # BACK
	RET	C			;C,NZ PASSED END
	LD	A,(DE)			;WE DID NOT, GET BYTE 1
	SUB	L			;IS THIS THE LINE?
	LD	B,A			;COMPARE LOW ORDER
	INC	DE
	LD	A,(DE)			;GET BYTE 2
	SBC	A, H			;COMPARE HIGH ORDER
	JR	C, FL2			;NO, NOT THERE YET
;weitersuchen bis Zeilennummer erreicht o. ueberschritten
	DEC	DE			;ELSE WE EITHER FOUND
	OR	B			;IT, OR IT IS NOT THERE
	RET				;NC,Z:FOUND; NC,NZ:NO
;Zeilenende suchen
FNDNXT:	INC	DE			;FIND NEXT LINE
FL2:	INC	DE			;JUST PASSED BYTE 1 & 2
FNDSKP:	LD	A,(DE)
	CP	A, CR			;TRY TO FIND 0DH
	JR	NZ, FL2			;KEEP LOOKING
	INC	DE			;FOUND CR, SKIP OVER
	JR	FL1			;CHECK IF END OF TEXT
;*
;*************************************************************
;*
;* *** PRTSTG *** QTSTG *** PRTNUM *** & PRTLN ***
;*
;* 'PRTSTG' PRINTS A STRING POINTED BY DE.  IT STOPS PRINTING
;* AND RETURNS TO CALLER WHEN EITHER A 0DH IS PRINTED OR WHEN
;* THE NEXT BYTE IS THE SAME AS WHAT WAS IN A (GIVEN BY THE
;* CALLER).  OLD A IS STORED IN B, OLD B IS LOST.
;*
;* 'QTSTG' LOOKS FOR A BACK-ARROW, SINGLE QUOTE, OR DOUBLE
;* QUOTE.  IFF NONE OF THESE, RETURN TO CALLER.  IFF BACK-ARROW,
;* OUTPUT A 0DH WITHOUT A LF.  IF SINGLE OR DOUBLE QUOTE, PRINT
;* THE STRING IN THE QUOTE AND DEMANDS A MATCHING UNQUOTE.
;* AFTER THE PRINTING THE NEXT 3 BYTES OF THE CALLER IS SKIPPED
;* OVER (USUALLY A JUMP INSTRUCTION).
;*
;* 'PRTNUM' PRINTS THE NUMBER IN HL.  LEADING BLANKS ARE ADDED
;* IF NEEDED TO PAD THE NUMBER OF SPACES TO THE NUMBER IN C.
;* HOWEVER, IF THE NUMBER OF DIGITS IS LARGER THAN THE # IN
;* C, ALL DIGITS ARE PRINTED ANYWAY.  NEGATIVE SIGN IS ALSO
;* PRINTED AND COUNTED IN, POSITIVE SIGN IS NOT.
;*
;* 'PRTLN' PRINSrA SAVED TEXT LINE WITH LINE # AND ALL.
;*
;
;++++++++++++++++++++++++++++++++++++++
;Stringausgabe
;++++++++++++++++++++++++++++++++++++++
;
PRTSTG:	LD	B,A			;A=Abschlu~byte
STRN1:	LD	A,(DE)			;DE-Stringadresse
	INC	DE
	CP	A, B
	RET	Z
	CALL	OTSTC
	CP	A, CR			;Abbruch auch bei
	JR	NZ, STRN1		;Zeilenende
	RET
;
;++++++++++++++++++++++++++++++++++++++
;Stringausgabe fuer PRINT und INPUT
;++++++++++++++++++++++++++++++++++++++
;
QTSTG:	CALL	TSTC			;Zeichenkette in ".."
	DB	'"'			;eingeschlossen?
	DW	TXOU3-2
	LD	A,'"'
TXOU1:	CALL	PRTSTG			;dann Stringausgabe
	CP	A, CR
	POP	HL			;Returnadr.
	JP	Z, RUNNXL			;wenn Zeilenende
TXOU2:	INC	HL			;2 Byte-Befehl hinter
	INC	HL			;Aufruf uebergehen, wenn
	JP	(HL)			;String ausgegeben
;
TXOU3:	CALL	TSTC			;Zeichenkette in '..'
	DB	27H			;eingeschlossen?
	DW	TXOU4-2
	LD	A,27H
	JR	TXOU1			;dann Stringausgabe
;
TXOU4:	CALL	TSTC			;steht ein _, so
	DB	"_"			;Ausgabe
	DW	TXOU5-2			;sonst zurueck
	LD	A,CR			;2x CR
	CALL	OTSTC
	CALL	OTSTC
	POP	HL
	JR	TXOU2
;
TXOU5:	RET
;
;++++++++++++++++++++++++++++++++++++++
;Ausgabe HL dezimal
;in:  C - Stellenanzahl
;++++++++++++++++++++++++++++++++++++++
;
PRTNUM:	LD	B,0
	CALL	CHKSGN			;Betrag bilden
	JP	P, HLOU1		;wenn positiv
	LD	B,'-'			;sonst Vorzeichen '-'
	DEC	C
HLOU1:	PUSH	DE
	LD	DE,10
	PUSH	DE
	DEC	C
	PUSH	BC
HLOU2:	CALL	DIVIDE			;Division HL/10
	LD	A,B
	OR	C
	JR	Z, HLOU3		;wenn Quotient = 0
	EX	(SP),HL
	DEC	L
	PUSH	HL
	LD	H,B
	LD	L,C
	JR	HLOU2
;
HLOU3:	POP	BC
HLOU4:	DEC	C
	LD	A,C
	OR	A
	JP	M, HLOU5
	LD	A,' '
	CALL	OTSTC
	JR	HLOU4
;
HLOU5:	LD	A,B
	OR	A
	CALL	NZ, OTSTC
	LD	E,L
HLOU6:	LD	A,E
	CP	A, 0AH
	POP	DE
	RET	Z
	ADD	A, '0'
	CALL	OTSTC
	JR	HLOU6
;
;++++++++++++++++++++++++++++++++++++++
;Ausgabe Zeile ab DE
;++++++++++++++++++++++++++++++++++++++
;
PRTLN:	LD	A,(DE)			;Zeilennummer
	LD	L,A
	INC	DE
	LD	A,(DE)
	LD	H,A
	INC	DE
	LD	C,4			;4 stellig
	CALL	PRTNUM			;ausgeben
	LD	A,' '
	CALL	OTSTC			;dann ein Leerzeichen
	SUB	A
	CALL	PRTSTG			;und die Zeile
	RET
;*
;**************************************************************
;*
;* *** MVUP *** MVDOWN *** POPA *** & PUSHA ***
;*
;* 'MVUP' MOVES A BLOCK UP FROM HERE DE-> TO WHERE BC-> UNTIL
;* DE = HL
;*
;* 'MVDOWN' MOVES A BLOCK DOWN FROM WHERE DE-> TO WHERE HL->
;* UNTIL DE = BC
;*
;* 'POPA' RESTORES THE 'FOR' LOOP VARIABLE SAVE AREA FROM THE
;* STACK
;*
;* 'PUSHA' STACKS THE 'FOR' LOOP VARIABLE SAVE AREA INTO THE
;* STACK
;*
;
;++++++++++++++++++++++++++++++++++++++
;
;++++++++++++++++++++++++++++++++++++++
;
MVUP:	CALL	COMP
	RET	Z
	LD	A,(DE)
	LD	(BC),A
	INC	DE
	INC	BC
	JR	MVUP
;
;++++++++++++++++++++++++++++++++++++++
;
;++++++++++++++++++++++++++++++++++++++
;
MVDOWN:	LD	A,B
	SUB	D
	JR	NZ, MD1
	LD	A,C
	SUB	E
	RET	Z
MD1:	DEC	DE
	DEC	HL
	LD	A,(DE)
	LD	(HL),A
	JR	MVDOWN
;
;++++++++++++++++++++++++++++++++++++++
;Verlassen der aktuellen Struktur
;++++++++++++++++++++++++++++++++++++++
;
POPA:	POP	BC
	POP	HL
	LD	(LOPVAR),HL		;ist UP ausgeführt worden?
	LD	A,H
	OR	L			;(dann LOPVAR = 00)
	JR	Z, PP1		;so zurueck
;
	POP	HL
	LD	(LOPINC),HL		;sonst aktuelle Werte
	POP	HL			;zurueckschreiben
	LD	(LOPLMT),HL
	POP	HL
	LD	(LOPLN),HL
	POP	HL
	LD	(LOPPT),HL
PP1:	PUSH	BC
	RET
;
;++++++++++++++++++++++++++++++++++++++
;Eroeffnen einer neuen Verschachtelungsebene
;++++++++++++++++++++++++++++++++++++++
;
PUSHA:	LD	HL,STMAX		;wird die max. moegliche
	CALL	CHGSGN			;Tiefe ueberschritten?
	POP	BC
	ADD	HL,SP
	JP	NC, ERSOR		;ja --> 'sorry'
;
	LD	HL,(LOPVAR)		;war 'GOSUB'?
	LD	A,H
	OR	L
	JR	Z, PU1			;dann ist nix zu tun
;
	LD	HL,(LOPPT)		;sonst aktuelle Werte
	PUSH	HL			;retten
	LD	HL,(LOPLN)
	PUSH	HL
	LD	HL,(LOPLMT)
	PUSH	HL
	LD	HL,(LOPINC)
	PUSH	HL
	LD	HL,(LOPVAR)
PU1:	PUSH	HL
	PUSH	BC
	RET
;
;++++++++++++++++++++++++++++++++++++++
;Systemkaltstart
;++++++++++++++++++++++++++++++++++++++
;
COLD:	LD	SP,STACK		;Stack init.
	LD	A,0CH
	CALL	OTSTC			;Bildschirm loeschen
	CALL	CRLF
	CALL	CRLF
	SUB	A
	LD	DE,TITEL		;Titelzeile ausgeben
	CALL	PRTSTG
	LD	HL,COLD
	LD	(M101D),HL
	LD	HL,TXTBGN		;kein Programm im
	LD	(TXTUNF),HL		;Speicher
	LD	HL,STEND		;Standartwerte fuer
	LD	(TXTEND),HL		;Speicherende,
	LD	HL,STEND+2
	LD	(BUFFER),HL		;Inputpuffer,
	LD	HL,STEND+66
	LD	(INPND),HL		;Inputpufferende
	JP	RSTART			;setzen
;
;++++++++++++++++++++++++++++++++++++++
;Ausgabe Zeilenvorschub
;++++++++++++++++++++++++++++++++++++++
;
CRLF:	LD	A,0DH
;
;++++++++++++++++++++++++++++++++++++++
;Ausgabe Zeichen in A
;++++++++++++++++++++++++++++++++++++++
;
OTSTC:	PUSH	BC
	PUSH	AF
	CALL	OUTCH
	POP	AF
	POP	BC
	RET
;
;++++++++++++++++++++++++++++++++++++++
;Titelzeile
;++++++++++++++++++++++++++++++++++++++
;
TITEL:	DB	"robotron Z1013 BASIC 3.01"
	DB	CR


;*
;**************************************************************
;*
;* *** TABLES *** DIRECT *** & EXEC ***
;*
;* THIS SECTION OF THE CODE TESTS A STRING AGAINST A TABLE.
;* WHEN A MATCH IS FOUND, CONTROL IS TRANSFERED TO THE SECTION
;* OF CODE ACCORDING TO THE TABLE.
;*
;* AT 'EXEC', DE SHOULD POINT TO THE STRING AD HL SHOULD POINT
;* TO THE TABLE-1.  AT 'DIRECT', DE SHOULD POINT TO THE STRING,
;* HL WILL BE SET UP TO POINT TO TAB1-1, WHICH IS THE TABLE OF
;* ALL DIRECT AND STATEMENT COMMANDS.
;*
;* A '.' IN THE STRING WILL TERMINATE THE TEST AND THE PARTIAL
;* MATCH WILL BE CONSIDERED AS A MATCH.  E.G., 'P.', 'PR.',
;* 'PRI.', 'PRIN.', OR 'PRINT' WILL ALL MATCH 'PRINT'.
;*
;* THE TABLE CONSISTS OF ANY NUMBER OF ITEMS.  EACH ITEM
;* IS A STRING OF CHARACTERS AND 0 BYTE.
;*
;* END OF TABLE IS AN ITEM WITH A JUMP ADDRESS ONLY.  IF THE
;* STRING DOES NOT MATCH ANY OF THE OTHER ITEMS, IT WILL
;* MATCH THIS NULL ITEM AS DEFAULT.
;*

;
;++++++++++++++++++++++++++++++++++++++
;direkt auszufuehrende Kommandos
;++++++++++++++++++++++++++++++++++++++
;
TBKDO:	EQU	$-1
	DB	"LIST",0
	DW	LIST
	DB	"RUN",0
	DW	RUN
	DB	"NEW",0
	DW	NEW
	DB	"BYE",0
	DW	BYE
	DB	"END",0
	DW	END
	DB	"CSAVE",0
	DW	CSAVE
	DB	"CLOAD",0
	DW	CLOAD
;
;++++++++++++++++++++++++++++++++++++++
;Prozeduren
;++++++++++++++++++++++++++++++++++++++
;
TBPRC:	EQU	$-1
	DB	"NEXT",0
	DW	NEXT
	DB	"LET",0
	DW	LET
	DB	"IF",0
	DW	IFF
	DB	"GOTO",0
	DW	GOTO
	DB	"GOSUB",0
	DW	GOSUB
	DB	"RETURN",0
	DW	RETURN
	DB	"REM",0
	DW	REM
	DB	"FOR",0
	DW	FOR
	DB	"INPUT",0
	DW	INPUT
	DB	"PRINT",0
	DW	PRINT
	DB	"STOP",0
	DW	STOP
	DB	"CALL",0
	DW	CALLP
	DB	"OUTCHAR",0
	DW	OUTCHAR
	DB	"OUT",0
	DW	OUTP
	DB	"O$",0
	DW	OUTSTR
	DB	"I$",0
	DW	INPSTR
	DB	"POKE",0
	DW	POKE
	DB	"TAB",0
	DW	TAB
	DB	"BYTE",0
	DW	BYTE
	DB	"WORD",0
	DW	WORD
	DB	0
	DW	DEFLT
;
;++++++++++++++++++++++++++++++++++++++
;Funktionen
;++++++++++++++++++++++++++++++++++++++
;
TBFKT:	EQU	$-1
	DB	"RND",0
	DW	RND
	DB	"ABS",0
	DW	ABS
	DB	"SIZE",0
	DW	SIZE
	DB	"PEEK",0
	DW	PEEK
	DB	"INCHAR",0
	DW	INCHAR
	DB	"HEX",0
	DW	HEX
	DB	"IN",0
	DW	INP
	DB	27H,0
	DW	CHRP
	DB	"TOP",0
	DW	TOP
	DB	"LEN",0
	DW	LEN
	DB	0
	DW	XP40
;
;++++++++++++++++++++++++++++++++++++++
;FOR-Schleife
;++++++++++++++++++++++++++++++++++++++
;
TBTO:	EQU	$-1
	DB	"TO",0
	DW	FR1
	DB	0
	DW	QWHAT
;
TBSTP:	EQU	$-1
	DB	"STEP",0
	DW	FR2
	DB	0
	DW	FR3
;
;++++++++++++++++++++++++++++++++++++++
;Vergleiche
;++++++++++++++++++++++++++++++++++++++
;
TBVGL:	EQU	$-1
	DB	">=",0
	DW	XP11
	DB	"#",0
	DW	XP12
	DB	">",0
	DW	XP13
	DB	"=",0
	DW	XP15
	DB	"<=",0
	DW	XP14
	DB	"<",0
	DW	XP16
	DB	0
	DW	XP17
;
;
;
DIRECT:	LD	HL,TBKDO		;Kommandoworte
;
;++++++++++++++++++++++++++++++++++++++
;Befehl in Tabelle HL suchen und ausfuehren
;++++++++++++++++++++++++++++++++++++++
;
EXEC:	CALL	IGNBLK			;Leerzeichen uebergehen
	PUSH	DE			;SAVE POINTER
EX1:	LD	A,(DE)			;IF FOUND '.' IN STRING
	INC	DE			;BEFORE ANY MISMATCH
	CP	A, '.'			;WE DECLARE A MATCH
	JR	Z, EX3
	INC	HL			;HL->TABLE
	CP	A, (HL)			;IF MATCH, TEST NEXT
	JR	Z, EX1
	LD	A,0			;ELSE, SEE IF endbyte 0
	DEC	DE			;IS SET, WHICH
	CP	A, (HL)			;IS THE JUMP ADDR. (HI)
	JR	Z, EX5			;YES, MATCHED
EX2:	INC	HL
	CP	A, (HL)
	JR	NZ, EX2
	INC	HL			;BUMP TO NEXT TAB. ITEM
	INC	HL
	POP	DE			;RESTORE STRING POINTER
	JR	EXEC			;TEST AGAINST NEXT ITEM
;
EX3:	LD	A,0			;PARTIAL MATCH, FIND
EX4:	INC	HL			;JUMP ADDR., WHICH IS
	CP	A, (HL)			;after endbyte 0
	JR	NZ, EX4
EX5:	INC	HL
	LD	A,(HL)			;LOAD HL WITH THE JUMP
	INC	HL			;ADDRESS FROM THE TABLE
	LD	H,(HL)
	LD	L,A
	POP	AF			;CLEAN UP THE GABAGE
	JP	(HL)			;AND WE GO DO IT

;-----------------------------------------------------------------
; ab hier neu robotron (und evtl. rdk??)
;-----------------------------------------------------------------
;
;++++++++++++++++++++++++++++++++++++++
;Ende im Eingabepuffer erreicht?
;++++++++++++++++++++++++++++++++++++++
;
M0961:	PUSH	HL
	LD	HL,(INPND)
	CP	A, L
	POP	HL
	RET
;
;++++++++++++++++++++++++++++++++++++++
;Anfang des Eingabepuffers erreicht?
;++++++++++++++++++++++++++++++++++++++
;
M0968:	PUSH	HL
	LD	HL,(BUFFER)
	CP	A, L
	POP	HL
	RET
;
;**************************************
;END ende - neues Speicherende
;**************************************
;
END:	CALL	EXPR			;ende holen
	EX	DE,HL
	LD	HL,STEND		;Standartspeichergrenze
	EX	DE,HL
	CALL	COMP
	JP	C, QSORRY		;wenn ende < STEND
;
	LD	A,H
	OR	A
	JP	M, QSORRY		;wenn ende < 0
;
	LD	A,(HL)
	CPL
	LD	(HL),A
	LD	B,(HL)
	CP	A, B
	JP	NZ, QSORRY		;wenn ende kein RAM
;
	LD	(INPND),HL		;neues Ende Inputpuffer
	LD	A,L
	SUB	132
	LD	L,A
	LD	A,H
	SBC	A, 0
	LD	H,A
	LD	(BUFFER),HL		;neuer Anfang Inputpuffer
	DEC	HL
	DEC	HL
	LD	(TXTEND),HL
	JP	RSTART
;
;**************************************
;BYE
;**************************************
;
BYE:	RST	38H			;Sprung zum Monitor
;
	JP	RSTART			;koennte entfallen
;
;**************************************
;CSAVE
;**************************************
;
CSAVE:	LD	SP,SYSSK
	CALL	IGNBLK			;Leerzeichen uebergehen
;
	LD	HL,FNAME
	PUSH	HL
	LD	B,10H
M09B0:	LD	(HL),' '		;Filenamenspuffer loeschen
	INC	HL
	DJNZ	M09B0
	POP	HL
;Zeichen aus Eingabestrom holen
M09B6:	LD	A,(DE)
	CP	A, '"'			;Filenamensbegrenzung?
	JR	NZ, M09BE		;nein
	INC	DE			;Uebergehen mehrerer '"'
	JR	M09B6
;
M09BE:	CP	A, CR			;Zeilenende erreicht?
	JR	Z, M09CB		;ja -> abspeichern
;
	LD	(HL),A			;Buchstabe in Puffer
	INC	HL			;uebernehmen
;
	LD	A,H			;Pufferende ueberschritten?
	OR	A			;( >= 100H )
	JR	NZ, M09CB		;dann abspeichern
	INC	DE			;sonst naechsten Buchstaben
	JR	M09B6
;File abspeichern
M09CB:	CALL	M0A0C			;Kopfadr. bereitstellen
	LD	HL,ARBRM		;Anfangsadresse
	LD	(FAADR),HL
	LD	HL,(TXTUNF)
	INC	HL			;Endadresse
	LD	(FEADR),HL
	CALL	SAVE			;Kopf absaven
	CALL	M0A19			;Fileadr. bereitstellen
	CALL	SAVE			;File absaven
	JP	RSTART
;
;**************************************
;CLOAD
;**************************************
;
CLOAD:	LD	SP,SYSSK
	CALL	M0A0C			;Kopfadr. bereitstellen
	CALL	LOAD			;Kopf lesen
;
	LD	HL,FNAME		;gelesenen Filenamen
	LD	DE,(CUPOS)		;anzeigen
	LD	BC,10H
	LDIR
	LD	(CUPOS),DE
	CALL	CRLF
;
	CALL	M0A19			;Fileadr. bereitstellen
	CALL	LOAD			;File laden
	JP	RSTART
;
;Kopfblockadressen in Monitor-ARG schreiben
;
M0A0C:	LD	HL,FAADR
	LD	(ARG1),HL
	LD	HL,FAADR+1FH
	LD	(ARG2),HL
	RET
;
;Fileadressen in Monitor-ARG schreiben
;
M0A19:	LD	HL,FAADR
	LD	DE,ARG1
	LD	BC,4
	LDIR
	RET
;
;**************************************
;CALL adr
;**************************************
;
CALLP:	CALL	EXPR			;adr holen
	PUSH	DE			;akt. Zeilenzeiger retten
	LD	BC,M0A2E		;Returnadr. auf Stack
	PUSH	BC
	JP	(HL)			;Programm starten
;
M0A2E:	POP	DE			;Zeilenzeiger restaurieren
	CALL	FINISH
;
;**************************************
;OUT (port)=wert            Portausgabe
;**************************************
;
OUTP:	CALL	PARN			;Port holen
	PUSH	HL
;
	CALL	TSTC			;folgt ein '=' ?
	DB	"="
	DW	M0A56-2			;nein --> Fehler
;
	CALL	EXPR			;wert holen
	LD	B,L
;
	LD	A,0D3H			;Befehl OUT n
	LD	(INOT),A
	POP	HL			;port
	LD	A,L
	LD	(INOT+1),A
	LD	A,0C9H			;Befehl RET
	LD	(INOT+2),A
;
	LD	A,B			;auszugebenden Wert
	CALL	INOT			;ausgeben
	CALL	FINISH
;
M0A56:	JP	QWHAT
;
;**************************************
;TAB (n)          Ausgabe n Leerzeichen
;**************************************
;
TAB:	CALL	PARN			;n holen
M0A5C:	LD	A,H
	OR	L
	CALL	Z, FINISH		;wenn n=0 weiter
;
	DEC	HL			;n erniedrigen
	LD	A,' '
	CALL	OTSTC			;Leerzeichen ausgeben
	JR	M0A5C			;bis n=0
;
;**************************************
;IN (port)                  Porteingabe
;**************************************
;
INP:	CALL	PARN			;port holen
	PUSH	HL
;
	LD	A,0DBH			;Befehl IN n
	LD	(INOT),A
	POP	HL
	LD	A,L			;port
	LD	(INOT+1),A
	LD	A,0C9H			;Befehl RET
	LD	(INOT+2),A
;
	CALL	INOT			;wert holen
	LD	H,0			;in HL uebergeben
	LD	L,A
	RET
;
;**************************************
;O$ adr                   Stringausgabe
;**************************************
;
OUTSTR:	CALL	EXPR			;adr holen
	PUSH	DE
	EX	DE,HL
	XOR	A			;Stringabschluss CR o. 0
	CALL	PRTSTG			;und String ausgeben
	POP	DE
	CALL	FINISH
;
;**************************************
;I$ adr                   Stringeingabe
;**************************************
;
INPSTR:	CALL	EXPR			;adr holen
	PUSH	DE
;
	EX	DE,HL			;soll ins Programm
	LD	HL,(TXTUNF)		;geschrieben werden?
	EX	DE,HL
	CALL	COMP
	JP	C, QSORRY		;ja --> Fehler
;
	LD	DE,(BUFFER)		;Inputpuffer
	CALL	INLI1			;Stringeingabe
	LD	B,H
	LD	C,L
	EX	DE,HL
	DEC	HL
	LD	DE,(BUFFER)
	PUSH	DE
	CALL	MVUP
	XOR	A
	LD	(BC),A
	POP	DE
	INC	HL
	CALL	SUBDE
	EX	DE,HL
	LD	HL,LENZK
	LD	(HL),E
	INC	HL
	LD	(HL),D
	POP	DE
	CALL	FINISH
;
;**************************************
;PEEK (adr)
;**************************************
;
PEEK:	CALL	PARN			;adr holen
	LD	L,(HL)			;und EXPR aud adr
	LD	H,0			;zurueckgeben
	RET
;
;**************************************
;POKE adr,wert
;**************************************
;
POKE:	CALL	EXPR			;adr holen
	PUSH	HL
;
	CALL	TSTC			;folgt ','
	DB	","
	DW	M0ADE-2			;nein --> Fehler
;
	CALL	EXPR			;wert holen
	LD	A,L			;und in adr schreiben
	POP	HL
	LD	(HL),A
	CALL	FINISH
;
M0ADE:	JP	QWHAT
;
;**************************************
;BYTE (n)         Anzeige ein Byte hexa
;**************************************
;
BYTE:	CALL	PARN			;n holen
	LD	A,L
	CALL	M0AF9			;n hexa ausgeben
	CALL	FINISH
;
;**************************************
;WORD (nn)          Anzeige 2 Byte hexa
;**************************************
;
WORD:	CALL	PARN			;nn holen
	LD	A,H			;1. Byte anzeigen
	CALL	M0AF9
	LD	A,L			;2. Byte anzeigen
	CALL	M0AF9
	CALL	FINISH
;
;Anzeige A hexa.
;
M0AF9:	PUSH	AF
	RRCA
	RRCA
	RRCA
	RRCA
	CALL	M0B02
	POP	AF
;
M0B02:	AND	A, 0FH			;eine Stelle separieren
	ADD	A, 90H			;ASCII-Korrektur
	DAA
	ADC	A, 40H			;wenn Ziffer A..F
	DAA
	JP	OTSTC
;
;**************************************
;'zeichen'                   ASCII-Code
;**************************************
;
CHRP:	LD	A,(DE)			;zeichen holen
	INC	DE
	LD	L,A			;HL erhaelt ASCII-Code
	LD	H,0
	CALL	TSTC			;folgt noch ein ' ?
	DB	27H
	DW	M0B19-2			;nein, dann Fehler
	RET
;
M0B19:	JP	QWHAT
;
;**************************************
;TOP - erste Adresse hinter Pgm
;**************************************
;
TOP:	LD	HL,(TXTUNF)		;Programmende
	INC	HL
	RET
;
;**************************************
;LEN
;**************************************
;
LEN:	LD	HL,(LENZK)		;Laenge Zeichenkette
	DEC	HL
	RET
;
;**************************************
;OUTTSTC code
;**************************************
;
OUTCHAR:	CALL	EXPR			;code holen
	LD	A,L
	CALL	OTSTC			;und Zeichen ausgeben
	CALL	FINISH
;
;**************************************
;INTSTC
;**************************************
;
INCHAR:	CALL	INCH			;Zeicheneingabe
	CP	A, 3			;>STOP< ?
	JP	Z, RSTART		;dann Warmstart
	LD	H,0
	LD	L,A			;sonst Code in HL
	RET		;uebergeben
;
;**************************************
;HEX (EXPR)
;**************************************
;
HEX:	PUSH	BC
	LD	HL,0			;Startwert
	CALL	TSTC			;folgt "("?
	DB	"("
	DW	M0B62-2			;nein -> Fehler
M0B46:	LD	A,(DE)			;Ziffer holen
	CP	A, CR
	JP	Z, QWHAT		;Fehler, wenn ")" fehlt
	CALL	M0B67			;ZahlenTSTNUMertierung
	ADD	HL,HL			;EXPR*16
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	LD	B,0			;+neue Ziffer
	LD	C,A
	ADD	HL,BC
	INC	DE
	CALL	TSTC			;naechstes Zeichen
	DB	")"
	DW	M0B60-2			;wenn EXPR zu Ende
	JR	M0B65			;sonst weiter
;
M0B60:	JR	M0B46
;
M0B62:	JP	QWHAT			;wenn Fehler
;
M0B65:	POP	BC
	RET
;
;Konvertierung ASCII-HEX
;
M0B67:	CP	A, '0'
	JP	M, QWHAT		;keine Ziffer
	CP	A, '9'
	JP	M, M0B7E
	JP	Z, M0B7E
	CP	A, 'A'
	JP	M, QWHAT		;keine HEX-Ziffer
	CP	A, 'G'
	JP	P, QWHAT		;keine HEX-Ziffer
M0B7E:	SUB	'0'			;ASCII-Wandlung
	CP	A, 0AH
	RET	M
	SUB	7			;Korrektur bei A..F
	RET
;
;++++++++++++++++++++++++++++++++++++++
;Tastaturpolling
;++++++++++++++++++++++++++++++++++++++
;
;fuer Flachfolientastatur !!!
;
CHKIO:	CALL	M0B93
	CP	A, 3			;S4-S? (PAUSE)
	JR	Z, M0B9C		;dann Zeitschleife
	CP	A, 5			;S4-K? (STOP)
	RET	NZ
	JP	RSTART			;dann Warmstart
;Tastaturabfrage
M0B93:	LD	A,3			;aktivieren Spalte 3
	OUT	8, A
	IN	A, 2
	AND	A, 0FH
	RET
;Zeitschleife
M0B9C:	PUSH	DE
	LD	DE,0FFFFH
M0BA0:	DEC	DE
	LD	A,D
	OR	E
	JR	NZ, M0BA0
M0BA5:	POP	DE
	RET

PEND:	EQU	$

	END
