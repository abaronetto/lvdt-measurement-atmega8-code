;
; prova_temporizzazioni.asm
;
; Created: 14/01/2016 18:58:23
; Author : Bruno
;

 ; DEFINIZIONE DEI REGISTRI UTILIZZATI
 .LIST
.DEF	mp = R16 ; registro multi-purpose
.DEF	mp1 = R17 ;secondo registro multi-purpose
.DEF	vard = R18 ; registro di decremento per la temporizzazione della verifica dell'alimentazione
.DEF	vars = R19 ; registro di decremento per la temporizzazione dell'acquisizione del segnale
.DEF	offL = R20 ; registro per la memorizzazione della parte bassa della tensione di offset
.DEF	offH = R21 ; registro per la memorizzazione della parte alta della tensione di offset
.DEF	spost = R22 ; registro che contiene il valore dello spostamento in binario
.DEF	cifra = R23 ; registro che conterrà il numero che indica la cifra dello spostamento 
.DEF	ncampioni = R24 ; definisce il numero di campioni acquisiti da mediare per misura di spostamento fornito
.DEF	ritardo =R25 ; variabile da decrementare per temporizzare l'uscita delle singole cifre e per l'acquisizione dei campioni
.EQU	cento = 100	; costante delle centinaia per il calcolo del numero di centinaia contenute in spost
.EQU	dieci = 10 ; costante delle decine per il calcolo del numero di decine contenute in spost
.EQU	uno = 1 ; costante delle unità per il calcolo del numero di decine contenute in spost
.EQU 	soglia_al = 230 ; soglia per l'attivazione del led

 ; termine delle direttive: inizio delle istruzioni

rjmp RESET ; Reset Handler
	reti	;rjmp EXT_INT0 ; IRQ0 Handler
	reti	;rjmp EXT_INT1 ; IRQ1 Handler
	reti	;rjmp TIM2_COMP ; Timer2 Compare Handler
	reti	;rjmp TIM2_OVF ; Timer2 Overflow Handler
	reti	;rjmp TIM1_CAPT ; Timer1 Capture Handler
	reti	;rjmp TIM1_COMPA ; Timer1 CompareA Handler
	reti	;rjmp TIM1_COMPB ; Timer1 CompareB Handler
	reti	;rjmp TIM1_OVF ; Timer1 Overflow Handler
	rjmp TIM0_OVF ; Timer0 Overflow Handler
	reti	;rjmp SPI_STC ; SPI Transfer Complete Handler
	reti	;rjmp USART_RXC ; USART RX Complete Handler
	reti	;rjmp USART_UDRE ; UDR Empty Handler
	reti	;rjmp USART_TXC ; USART TX Complete Handler
	reti    ;rjmp ADC_conv ; ADC Conversion Complete Handler
	reti	;rjmp EE_RDY ; EEPROM Ready Handler
	reti	;rjmp ANA_COMP ; Analog Comparator Handler
	reti	;rjmp TWSI ; Two-wire Serial Interface Handler
	reti	;rjmp SPM_RDY ; Store Program Memory Ready Handler


RESET:   ;inizializzazioni
ldi		mp,0x04
out		SPH,mp
ldi		mp,0x5f
out		SPL,mp
; inizializzazione della posizione dello stack pointer al fondo della stack

ldi		mp,0b00000001
out		DDRC,mp
; definizione di PC0 di PORTC come uscita per il led,
; le altre linee di PORTC sono definite come linee di ingresso

ldi		mp,0b00000000
out		PORTC,mp
; inizializzazione dei valori di PORTC a 0. Il led resterà spento.

ldi		mp,0b11111110
out		DDRB,mp
; definizione di tutta PORTB come uscita tranne il PB0,

ldi		mp,0b00001110
out		PORTB,mp
; inizializzazione dei valori di PORTB a 0 tranne i LE.

ldi		mp,0b00000101
out		TCCR0,mp
; selezione del prescaler del clock del TCNT0 a passo 1024 
; (se la frequenza iniziale è 1MHz, la frequenza a seguito del prescaler è 976,56 KHz)
	
ldi		mp,246
out		TCNT0,mp
; seleziona il tempo tra un overflow del TCNT0 e il successivo a circa 10ms (9,76ms)

ldi		mp,0b00000001
out		TIMSK,mp
; abilita l'interrupt in caso di overflow del TCNT0

ldi		vars,6
ldi		vard,249
; inizializzazione delle variabili contatore per la temporizzazione della verifica dell'alimentazione (vard) 
;e dell'inizio dell'acquisizione dei campioni del segnale del sensore (vars).
; Queste variabili saranno decrementate nella subroutine di risposta all'interrupt di TCNT0

ldi 	mp,0b10000010
out		ADCSRA,mp
;  programma l'ADC in modo da abilitarlo senza abilitare l'interrupt e seleziona un fattore di prescaling pari a 4.
;  Deve precedere la selezione dell'ingresso.
ldi		mp,0b11100001
out		ADMUX,mp
;	programma l'ADC perché lavori con riferimento interno a 2,56V, 
;	giustifichi a sinistra il risultato e senta l'input su PC1 (ADC1)
;
sei
;
; abilita gli interrupt a livello di SREG
;

start_loop:
in	mp,PINC
andi	mp,0b00001000
cpi	mp,0b00001000   ; verifica che il bottone sia stato schiacciato. 
; Se è stato premuto, il livello logico sul PIN3 di PORTC è livello logico alto.
breq	start_loop		
; in caso non sia stato premuto, ripete la verifica

ldi		mp,0b11000010
out		ADMUX,mp		
; definisce il canale da cui acquisire il segnale: PC2 (ADC2) e giustifica a destra

in		mp,ADCSRA
ldi		mp1,0b01000000
or		mp,mp1
out		ADCSRA,mp		
; inizia la conversione

verifica_conversione_terminata:
in		mp,ADCSRA
ldi		mp1,0b01000000
and		mp,mp1
brne	verifica_conversione_terminata
; verifica che la conversione sia terminata: in caso contrario ripete la verifica.

in		offL,ADCL
in		offH,ADCH
; al termine della lable start_loop, la tensione di offset è stata acquisita e il suo valore numerico è contenuto in offL shiftato sei volte e offH.
ldi	mp,0b00000001
out	PORTC,mp
; come conferma che la tensione di offset sia stata acquisita, si accende un led rosso.


main_loop:

cpi vars,0b00000000
brne seconda_richiesta  ; attende che siano trascorsi 90ms 
ldi vars,6
ldi YH,0
ldi YL,0
ldi ncampioni,4
ldi mp,0b11000010
out ADMUX,mp
; cambio canale di acquisizione: PC2 (ADC2) e giustificato a destra. Acquisisco il segnale proveniente dal sensore

conversione:
in mp,ADCSRA
ldi mp1,0b01000000
or	mp,mp1
out	ADCSRA,mp
; inizio della conversione 
controllo_acquisizione_finita:
in mp,ADCSRA
ldi	mp1,0b01000000
and	mp,mp1
brne controllo_acquisizione_finita
; controllo che l'acquisizione sia finita

in mp,ADCL
in mp1,ADCH
; lettura della tensione acquisita (segnale proveniente dal sensore) 
sbc mp,offL
sub mp1,offH
; il valore acquisito viene sottratto a quello dell'offset. Sottrazione a 10 bit
lsl mp1
lsl mp1
lsl mp1
lsl mp1
lsl mp1
lsl mp1
lsr mp
lsr mp
add mp,mp1
; shifta sei volte a sinistra la parte alta del segnale sottratto e due volte a destra la parte bassa. 
; Sommando i due registri si ottiene si ottiene il valore diviso per quattro
ldi mp1,0
add YL,mp
adc YH,mp1
; YL e YH sono utilizzati come unico registro a 16 bit dove verrà contenuta la somma di 4 campioni divisi per 4 (quindi la media di 4 campioni).
; A tale valore verrà associato il corrispettivo valore di spostamento tramite una lookuptable.

dec ncampioni
cpi ncampioni,0
breq visualizzazione
ldi ritardo, 124
ldi mp,0b00000010
out TCCR0,mp
ldi	mp,251
out	TCNT0,mp
; imposta il TCNT0 in modo da avere un overflow ogni 40 microsecondi 
attesa_ritardo:
cpi ritardo,0
brne attesa_ritardo
rjmp conversione
; ripeto la conversione dopo 1ms
visualizzazione:
ldi ncampioni,4
; inizializza il numero di campioni a 4
ldi ZL,low(table<<1)
ldi ZH,high(table<<1) ; carica sul registro Z l'indirizzo del primo elemento della table
add ZL,YL
adc ZH,YH
; somma al registro Z il contenuto del registro Y in modo da puntare al valore corretto di spostamento
lpm spost,Z
; carica su mp1 il valore contenuto a quell'indirizzo, che rappresenta lo spostamento associato a quel valore di Y

rjmp  conteggio_display

seconda_richiesta:
cpi		vard,0x00
brne	next02
; confronta se la variabile di decremento è a 0: in caso negativo il program counter salta alla lable next01, che riporta il program counter all'inizio del main_loop
ldi		vard,249
; inizializza vard
ldi		mp,0b11100001
out		ADMUX,mp
; sceglie il canale da cui prendere il segnale da convertire: PC1 (ADC1)
in		mp,ADCSRA
ldi		mp1,0b01000000
or		mp,mp1
out		ADCSRA,mp
; inizia la conversione

verifica_conversione_terminata1:
in		mp,ADCSRA
ldi		mp1,0b01000000
and		mp,mp1
brne	verifica_conversione_terminata1
; verifica che la conversione sia terminata: in caso contrario ripete la verifica.
in		mp,ADCH
; legge il valore convertito su 8 bit
cpi		mp,soglia_al 
brsh	spegne_led
;ldi		mp,0b00000001
;out		PORTC,mp
; accende il led se la soglia non è stata superata
rjmp main_loop
; ricomincia il ciclo principale
spegne_led:
;ldi mp,0b00000000
;out PORTC,mp
; spegne il led se la soglia è stata superata
rjmp main_loop
; ricomincia il ciclo principale

next01:
rjmp seconda_richiesta

next02: 
rjmp main_loop

conteggio_display:
ldi		cifra,0
;inizializza la variabile per il conteggio di centinaia, decine e unità a 0

verifica_esistenza_centinaia: ;verifica che spost sia minore di 100: in questo caso il registro delle centinaia resterà pari a 0
cpi		spost,cento
brlo	verifica_esistenza_decine 

conteggio_centinaia: ;inizio conteggio cifra delle centinaia
inc		cifra
subi	spost,cento
cpi		spost,cento	
brsh	conteggio_centinaia

uscita_centinaia: ; lable per portare sul display delle centinaia la cifra delle centinaia. 
lsl		cifra
lsl		cifra
lsl		cifra
lsl		cifra
; shifta a sinistra di 4 bit il numero delle centinaia, 
; in modo tale che i quattro bit che indicano tale valore 
; (essendo una cifra, al massimo vale 9, che è esprimibile con 4 bit) 
; si posizionino correttamente sui bit 7,6,5,4.
ldi		mp,0b00001100
or		cifra,mp
; scrive sul registro delle centinaia, 
; in corrispondenza dei bit 3,2,1 i livelli corretti per pilotare il LE delle centinaia (sono attivi bassi)
out		PORTB,cifra
; manda il valore delle centinaia all'ingresso del demodulatore delle centinaia
ldi		ritardo,1 ; si attende un intervallo di tempo di 40 microsecondi prima di disattivare il LE. 
; Quando avverrà la disattivazione si avrà la visualizzazione della cifra delle centinaia sul display delle centinaia
ritardo_per_visualizzazione_corretta_centinaia:
cpi		ritardo,0
brne	ritardo_per_visualizzazione_corretta_centinaia
in		mp,PORTB     ;legge PORTB per poi poter disattivare il LE delle centinaia: così la cifra verrà visualizzata sul display
ldi		mp1,0b00000010
or		mp,mp1
out		PORTB,mp ;viene disabilitato il LE delle centinaia: in questo modo si visualizzerà la cifra sul display delle centinaia
ldi 	cifra,0 ; riinizializzazione della variabile contatore di centinaia, decine e unità

verifica_esistenza_decine: ; termine del conteggio delle centinaia e verifica che spost sia minore di 10: 
; in questo caso il registro delle decine resterà pari a 0
 cpi	spost,dieci
brlo	verifica_esistenza_unita

conteggio_decine:  ; inizio del conteggio cifra delle decine
inc		cifra
subi	spost,dieci
cpi		spost,dieci
brsh	conteggio_decine

uscita_decine: ; lable per portare sul display delle decine la cifra delle decine. 

lsl		cifra
lsl		cifra
lsl		cifra
lsl		cifra
; shifta a sinistra di 4 bit il numero delle decine, in modo tale che i quattro bit che indicano tale valore (essendo una cifra, al massimo vale 9, che è esprimibile con 4 bit) si posizionino correttamente sui bit 7,6,5,4.
ldi		mp,0b00001010
or		cifra,mp
; scrive sul registro delle decine, in corrispondenza dei bit 3,2,1 i livelli corretti per pilotare il LE delle decine (sono attivi bassi)
out		PORTB,cifra
; manda il valore delle centinaia all'ingresso del demodulatore delle decine
ldi		ritardo,1 ; si attende un intervallo di tempo di 40 microsecondi prima di disattivare il LE. Quando avverrà la disattivazione si avrà la visualizzazione della cifra delle centinaia sul display delle centinaia
; si inizializza il timer counter 0 in modo che abbia un prescaler pari a 8 (periodo del clock pari a 8 microsecondi) e che vada in overflow dopo 8 microsecondi
ritardo_per_visualizzazione_corretta_decine:
cpi		ritardo,0
brne	ritardo_per_visualizzazione_corretta_decine
in		mp,PORTB     ;legge PORTB per poi poter disattivare il LE delle decine: così la cifra verrà visualizzata sul display
andi	mp,0b11111110 ; controllo sui pin letti
ldi		mp1,0b00000100
or		mp,mp1
out		PORTB,mp ;viene disabilitato il LE delle decine: in questo modo si visualizzerà la cifra sul display delle decine
ldi 	cifra,0 ; riinizializzazione della variabile contatore di centinaia, decine e unità

verifica_esistenza_unita: ; termine del conteggio delle decine e verifica che spost sia minore di 1: in questo caso il registro delle unità resterà pari a 0
cpi		spost,uno
brlo	uscita_unita

conteggio_unita: ;inizio del conteggio cifra delle unità
inc		cifra
subi	spost,uno
cpi		spost,uno
brsh	conteggio_unita

uscita_unita: ; lable per portare sul display delle unità la cifra delle unità. 

lsl		cifra
lsl		cifra
lsl		cifra
lsl		cifra
; shifta a sinistra di 4 bit il numero delle unità, in modo tale che i quattro bit che indicano tale valore (essendo una cifra, al massimo vale 9, che è esprimibile con 4 bit) si posizionino correttamente sui bit 7,6,5,4.
ldi		mp,0b00000110
or		cifra,mp
; scrive sul registro delle unità, in corrispondenza dei bit 3,2,1 i livelli corretti per pilotare il LE delle unità (sono attivi bassi)
out		PORTB,cifra
; manda il valore delle unità all'ingresso del demodulatore delle unità

ldi		ritardo,1 ; si attende un intervallo di tempo di 40 microsecondi prima di disattivare il LE. Quando avverrà la disattivazione si avrà la visualizzazione della cifra delle centinaia sul display delle centinaia
; si inizializza il timer counter 0 in modo che abbia un prescaler pari a 8 (periodo del clock pari a 8 microsecondi) e che vada in overflow dopo 8 microsecondi
ritardo_per_visualizzazione_corretta_unita:
cpi		ritardo,0
brne	ritardo_per_visualizzazione_corretta_unita
in		mp,PORTB     ;legge PORTB per poi poter disattivare il LE delle unità: così la cifra verrà visualizzata sul display
ldi		mp1,0b00001000
or		mp,mp1
out		PORTB,mp ;viene disabilitato il LE delle unità: in questo modo si visualizzerà la cifra sul display delle unità
; terminato il conteggio delle cifre e la loro visualizzazione sui display
ldi 	cifra,0 ; riinizializzazione della variabile contatore di centinaia, decine e unità

ldi mp,0b00000101
out TCCR0,mp
ldi	mp,246
out	TCNT0,mp
; il TCNT0 viene reimpostato in modo che abbia un overflow ogni 10ms

rjmp next01


TIM0_OVF: 
push mp
in mp,SREG
push mp
in mp,TCCR0
cpi mp,0b00000101
brne temporizzazione_ritardo
rjmp temporizzazione_standard

ripresa_stack:
pop mp
out SREG,mp
pop mp
reti

temporizzazione_standard:
ldi	mp,246
out TCNT0,mp
dec vard
dec vars
rjmp ripresa_stack

temporizzazione_ritardo:
ldi mp, 251
out TCNT0,mp
dec ritardo
rjmp ripresa_stack

table:
.db 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 5, 6, 6, 6, 6, 7, 7, 7, 7, 7, 8, 8, 8, 8, 9, 9, 9, 9, 9, 10, 10, 10, 10, 11, 11, 11, 11, 11, 12, 12, 12, 12, 13, 13, 13, 13, 13, 14, 14, 14, 14, 15, 15, 15, 15, 15, 16, 16, 16, 16, 16, 17, 17, 17, 17, 18, 18, 18, 18, 18, 19, 19, 19, 19, 20, 20, 20, 20, 20, 21, 21, 21, 21, 22, 22, 22, 22, 22, 23, 23, 23, 23, 24, 24, 24, 24, 24, 25, 25, 25, 25, 26, 26, 26, 26, 26, 27, 27, 27, 27, 28, 28, 28, 28, 28, 29, 29, 29, 29, 30, 30, 30, 30, 30, 31, 31, 31, 31, 32, 32, 32, 32, 32, 33, 33, 33, 33, 33, 34, 34, 34, 34, 35, 35, 35, 35, 35, 36, 36, 36, 36, 37, 37, 37, 37, 37, 38, 38, 38, 38, 39, 39, 39, 39, 39, 40, 40, 40, 40, 41, 41, 41, 41, 41, 42, 42, 42, 42, 43, 43, 43, 43, 43, 44, 44, 44, 44, 45, 45, 45, 45, 45, 46, 46, 46, 46, 47, 47, 47, 47, 47, 48, 48, 48, 48, 49, 49, 49, 49, 49, 50, 50, 50, 50, 50, 51, 51, 51, 51, 52, 52, 52, 52, 52, 53, 53, 53, 53, 54, 54, 54, 54, 54, 55, 55, 55, 55, 56, 56, 56, 56, 56, 57, 57, 57, 57, 58, 58, 58, 58, 58, 59, 59, 59, 59, 60, 60, 60, 60, 60, 61, 61, 61, 61, 62, 62, 62, 62, 62, 63, 63, 63, 63, 64, 64, 64, 64, 64, 65, 65, 65, 65, 66, 66, 66, 66, 66, 67, 67, 67, 67, 67, 68, 68, 68, 68, 69, 69, 69, 69, 69, 70, 70, 70, 70, 71, 71, 71, 71, 71, 72, 72, 72, 72, 73, 73, 73, 73, 73, 74, 74, 74, 74, 75, 75, 75, 75, 75, 76, 76, 76, 76, 77, 77, 77, 77, 77, 78, 78, 78, 78, 79, 79, 79, 79, 79, 80, 80, 80, 80, 81, 81, 81, 81, 81, 82, 82, 82, 82, 83, 83, 83, 83, 83, 84, 84, 84, 84, 84, 85, 85, 85, 85, 86, 86, 86, 86, 86, 87, 87, 87, 87, 88, 88, 88, 88, 88, 89, 89, 89, 89, 90, 90, 90, 90, 90, 91, 91, 91, 91, 92, 92, 92, 92, 92, 93, 93, 93, 93, 94, 94, 94, 94, 94, 95, 95, 95, 95, 96, 96, 96, 96, 96, 97, 97, 97, 97, 98, 98, 98, 98, 98, 99, 99, 99, 99, 99, 100, 100, 100, 100, 100, 101, 101, 101, 101, 101, 102, 102, 102, 102, 103, 103, 103, 103, 103, 104, 104, 104, 104, 105, 105, 105, 105, 105, 106, 106, 106, 106, 107, 107, 107, 107, 107, 108, 108, 108, 108, 109, 109, 109, 109, 109, 110, 110, 110, 110, 111, 111, 111, 111, 111, 112, 112, 112, 112, 113, 113, 113, 113, 113, 114, 114, 114, 114, 115, 115, 115, 115, 115, 116, 116, 116, 116, 116, 117, 117, 117, 117, 118, 118, 118, 118, 118, 119, 119, 119, 119, 120, 120, 120, 120, 120, 121, 121, 121, 121, 122, 122, 122, 122, 122, 123, 123, 123, 123, 124, 124, 124, 124, 124, 125, 125, 125, 125, 126, 126, 126, 126, 126, 127, 127, 127, 127, 128, 128, 128, 128, 128, 129, 129, 129, 129, 130, 130, 130, 130, 130, 131, 131, 131, 131, 132, 132, 132, 132, 132, 133, 133, 133, 133, 133, 134, 134, 134, 134, 135, 135, 135, 135, 135, 136, 136, 136, 136, 137, 137, 137, 137, 137, 138, 138, 138, 138, 139, 139, 139, 139, 139, 140, 140, 140, 140, 141, 141, 141, 141, 141, 142, 142, 142, 142, 143, 143, 143, 143, 143, 144, 144, 144, 144, 145, 145, 145, 145, 145, 146, 146, 146, 146, 147, 147, 147, 147, 147, 148, 148, 148, 148, 149, 149, 149, 149, 149, 150, 150, 150, 150, 150, 151, 151, 151, 151, 152, 152, 152, 152, 152, 153, 153, 153, 153, 154, 154, 154, 154, 154, 155, 155, 155, 155, 156, 156, 156, 156, 156, 157, 157, 157, 157, 158, 158, 158, 158, 158, 159, 159, 159, 159, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
