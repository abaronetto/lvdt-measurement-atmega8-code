; DIRETTIVE DEI REGISTRI UTILIZZATI

.LIST
.DEF	flag_overrange = R13 ; registro utilizzato come flag per la verifica dello stato di over-range
.DEF	media_campioni_L= R14 ; registro utilizzato per la verifica dello stato di over-range: 
; condizione in cui la punta del sensore è schiacciata oltre il fondo corsa
.DEF	media_campioni_H= R15 ; registro utilizzato per la verifica dello stato di over-range
.DEF	mp = R16 ; registro multi-purpose
.DEF	mp1 = R17 ; secondo registro multi-purpose
.DEF	vard = R18 ; registro di decremento per la temporizzazione della verifica dell'alimentazione
.DEF	vars = R19 ; registro di decremento per la temporizzazione dell'acquisizione dei campioni del segnale del sensore
.DEF	offL = R20 ; registro per la memorizzazione della parte bassa della tensione di offset
; (codificata su 10 bit, questa tensione ha quindi una parte bassa e una parte alta)
.DEF	offH = R21 ; registro per la memorizzazione della parte alta della tensione di offset 
.DEF	spost = R22 ; registro che contiene il valore dello spostamento in binario (unità di misura decimi di millimetro)
; Sul display la misura è invece in millimetri, in quanto viene utilizzato il punto sul diplay dei millimetri.
.DEF	cifra = R23 ; registro che conterrà il numero che indica la cifra di centinaia, decine e unità
.DEF	ncampioni = R24 ; definisce il numero di campioni acquisiti da mediare prima di fornire la misura di spostamento
.DEF	ritardo = R25 ; variabile da decrementare per temporizzare l'uscita delle singole cifre sui display
.EQU	cento = 100	; costante per il calcolo del numero delle decine di millimetro contenute in spost
.EQU	dieci = 10 ; costante per il calcolo del numero di millimetri contenute in spost
.EQU	uno = 1 ; costante per il calcolo del numero decimi di millimetro contenute in spost
.EQU 	soglia_al = 218 ; costante che fissa la soglia di tensione a 2,3V nominali.
.EQU	dinamicaL = 0b10101111 ; parte bassa della dinamica della tensione in uscita dal circuito.
.EQU	dinamicaH = 0b00000010 ; parte alta della dinamica della tensione in uscita dal circuito.
; termine delle direttive: inizio delle istruzioni

 rjmp RESET ; Reset Handler
	reti	;rjmp EXT_INT0 ; IRQ0 Handler
	reti	;rjmp EXT_INT1 ; IRQ1 Handler
	reti	;rjmp TIM2_COMP ; Timer2 Compare Handler
	reti    ;TIM2_OVF ; Timer2 Overflow Handler
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
; inizializzazione della posizione dello stack pointer al fondo della RAM.
ldi		mp,0b00000001
out		DDRC,mp
; definizione della linea 0 di PORTC come uscita per il led di verifica della tensione di alimentazione.
; Le altre linee di PORTC sono definite come linee di ingresso.
ldi		mp,0x00
out		PORTC,mp
; inizializzazione dei valori di PORTC a 0. Il led resta inizialmente spento.
ldi		mp,0b11111110
out		DDRB,mp
; definizione delle linee 7,6,5,4,3,2,1 di PORTB come uscite per il pilotaggio dei display a sette segmenti
; L'altra linea di PORTB è definita come linea di ingresso ma non viene utilizzata.
ldi		mp,0b00001110
out		PORTB,mp
; inizializzazione delle linee 1,2,3 di PORTB a 1 in quanto sono utilizzati per pilotare i Latch Enable dei tre display che sono attivi bassi.
; Le linee 4,5,6,7 di PORTB sono utilizzati per inviare il numero corrispondente allo spostamento ai tre display. Vengono inizializzati a 0.
ldi		mp,0b00000011
out		DDRD,mp
; definizione delle linee 0 e 1 di PORTD come uscite rispettivamente per il led verde
;  di conferma di acquisizione dell'offset e per il led giallo di stato di over-range
ldi		mp,0x00
out		PORTD,mp
; inizializzazione dei valori di PORTD a 0. I due led sono inizialmente spenti.
ldi		mp,0b00000101
out		TCCR0,mp
; selezione del prescaler del TCCR0, passo 1024 (se la frequenza iniziale è 1MHz, la frequenza a seguito del prescaler è 976,56 KHz)
ldi		mp,246
out		TCNT0,mp
; seleziona il tempo tra un interrupt di overflow del TCNT0 e il successivo a circa 10ms (9,76ms)
ldi		mp,0b00000001
out		TIMSK,mp
; abilita l'interrupt in caso di overflow del TCNT0.
ldi		vard,249
ldi		vars,6
ldi		ncampioni,4
ldi		mp,0
mov		flag_overrange,mp
; inizializza vard a 249, che sarà decrementata dalla subroutine di risposta all'interrupt di overflow del TCNT0.
; inizializza vars a 5, che sarà decrementata dalla subroutine di risposta all'interrupt di overflow del TCNT0.
; inizializza ncampioni a 4, che sarà decrementata dalla subroutine di risposta all'interrupt di overflow di TCNT0
; inizializzazione del flag di verifica stato di over-range a 0.
ldi		mp,0b10000010
out		ADCSRA,mp
; programma l'ADC abilitandolo senza abilitare l'interrupt con un fattore di prescaling pari a 4.
ldi		mp,0b11000010
out		ADMUX,mp
; programma l'ADC perchè lavori con riferimento interno a 2,56V (misurando questa tensione sul circuito, è risultato che il vero valore sia circa 2,69V) 
; uscita giustificata a destra e sente l'input da PC2 (ADC2).

sei 
; abilita gli interrupt a livello di SREG.

start_loop:

in	mp,PINC
andi	mp,0b00001000
cpi	mp,0b00000000   ; verifica che il bottone sia stato schiacciato. 
; Se è stato premuto, il livello logico sul PIN3 di PORTC è livello logico basso.
brne	start_loop		
; in caso non sia stato premuto, viene ripetuto il ciclo condizionato.
in		mp,ADCSRA
ldi		mp1,0b01000000
or		mp,mp1
out		ADCSRA,mp		
; inizia la conversione
verifica_conversione_terminata_offset:
in		mp,ADCSRA
ldi		mp1,0b01000000
and		mp,mp1
brne	verifica_conversione_terminata_offset 
; aspetta che la conversione sia pronta 
; testando ADSC in ADCSRA: a conversione terminata ADSC torna a 0
in	offL,ADCL
in	offH,ADCH
; la tensione acquisita è quella relativa alla posizione di riposo del sensore, codificata su 10 bit.
ldi		mp,dinamicaL
ldi		mp1,dinamicaH
sub offL,mp
sbc offH,mp1
; A questa tensione viene sottratto il valore numerico relativo alla dinamica del sensore.
; In questo modo si ottiene il valore numerico relativo alla tensione di offset, 
; cioè quella corrispondente al fondo corsa del sensore (punta totalmente schiacciata).
; Al termine della label start_loop, la tensione di offset è stata acquisita.
ldi	mp,0b00000001
out	PORTD,mp
; come conferma che la tensione di offset sia stata acquisita, si accende un led verde.

main_loop:
ldi mp,1
cpi vars,0
brne next02 ; salto condizionato a verifica_Val se non sono trascorsi 60ms.
; (la seconda richiesta è la verifica su vard, relativa alla temporizzazione della verifica della tensione di alimentazione)
ldi	mp,246
out	TCNT0,mp
ldi	vars,1
dec	ncampioni
; si reinizializza TCNT0 a 246 e vars a 1 affinchè tale variabile si azzeri in 10ms (tempo tra l'acquisizione di un campione e il successivo)
ldi mp,0b11000010
out ADMUX,mp
; reinizializzazione di ADMUX: sente l'input da PC2 (ADC2) con giustificazione a destra.
; Acquisisce il segnale proveniente dal sensore più circuito di interfacciamento.
acquisizione:
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
; aspetta che la conversione sia pronta
; testando ADSC in ADCSRA: a conversione terminata ADSC torna a 0
in mp,ADCL
in mp1,ADCH
; lettura della tensione acquisita codificata in 10 bit
lsr mp
lsr mp
lsl mp1
lsl mp1
lsl mp1
lsl mp1
lsl mp1
lsl mp1
add mp,mp1
ldi mp1,0
add YL,mp
adc YH,mp1
; il numero acquisito viene diviso per quattro tramite 6 shift a sinistra della parte alta
; e due shift a destra della parte bassa. In seguito viene sommata la parte bassa e la parte alta
; al registro Y a 16 bit utilizzato per contenere il valore somma di 4 campioni. In questo modo 
; viene effettuata la media di 4 campioni.
ldi mp,1 ; questo valore caricato su mp serve per garantire che 
; qualora avvenisse il seguente salto condizionato a next02, ne conseguirebbe un salto condizionato a next03
; dove a sua volta avverrebbe un salto condizionato a verifica_Val. Questo è stato necessario
; in quanto senza l'utilizzo di next02 e next03 si avrebbe un out of reach relativo ai brne. 
cpi ncampioni,0
brne next02
; se il numero di campioni acquisito è pari a 4, ncampioni sarà pari a 0 e quindi 
; si procede all'assegnazione dello spostamento corrispondente e alla sua visualizzazione. 
; In caso contrario invece si procede con la verifica su vard con un salto condizionato a next02.
mov	media_campioni_H,YH 
mov	media_campioni_L,YL
;  vengono copiate la parte bassa e la parte alta del registro di somma Y dopo aver acquisito   
;  quattro campioni mediati. Questo valore viene utilizzato in seguito per la verifica dello stato di over-range
sub YL,offL
sbc YH,offH
; al registro di somma viene sottratto l'offset precedentemente acquisito.
ldi ZL,low(table<<1)
ldi ZH,high(table<<1) 
; carica sul registro Z l'indirizzo del primo elemento della table
add ZL,YL
adc ZH,YH 
; carica sul registro Z l'indirizzo dell'elemento rappresentato dal contenuto del registro Y
lpm spost,Z
; carica su spost il valore contenuto a quell'indirizzo, 
; che rappresenta lo spostamento associato a quel valore di Y
ldi mp,0
cp	media_campioni_H,mp
brne visualizzazione_spost ; salto condizionato a conteggio_cifre qualora la parte alta di Y
; sia diversa da 0: questo significa che non c'è condizione di over-range.
sub	media_campioni_L,offL
brpl visualizzazione_spost 
; se il numero contenuto nella parte bassa del registro di somma Y è minore di offL, 
; allora lo stato di over-range è ON
; In caso contrario avviene un salto condizionato a visualizzazione_spost.
ldi mp1,0b00000011
out PORTD,mp1
ldi spost,0
ldi mp,1
mov flag_overrange,mp ; utilizzato come flag di stato over-range ON
; Come conferma dello stato di over-range, viene associato uno spostamento nullo
; e viene acceso il led giallo di over-range.
visualizzazione_spost: ; inizia il conteggio delle cifre delle decine di millimetro, millimetri e decimi di millimetro.
ldi cifra,0 ; reinizializzazione della variabile cifra a 0.
ldi mp,0
cp flag_overrange,mp
brne conteggio_decine_mm ; salto condizionato a conteggio_decine_mm
; qualora fosse a 1 il flag di stato di over-range ON. 
ldi mp1,0b00000001
out PORTD,mp1
; In caso contrario (stato di over-range OFF) il led giallo di over-range ON viene spento
ldi mp,0
mov flag_overrange,mp ; reinizializzazione del flag di overrange a 0

ldi mp,0 ; flag per evitare che a causa del cpi in next02 avvenga il salto condizionato a next03.
next02: 
cpi mp,1
breq next03 ; salto condizionato a next03 qualora il valore contenuto in mp fosse pari a 1.

conteggio_decine_mm: ; inizio del ciclo di conteggio della cifra delle decine di millimetro:
cpi		spost,cento
brlo	uscita_decine_mm ; salto condizionato a uscita_decine_mm 
; qualora il valore contenuto in spost fosse minore di 100
inc		cifra
subi	spost,cento 
; conteggio della cifra delle decine di millimetro per sottrazioni successive
cpi		spost,cento
brsh	conteggio_decine_mm ; salto condizionato a conteggio_decine_mm
; qualora il valore in spost fosse maggiore o uguale a 100

uscita_decine_mm: ; label per visualizzare sul display delle decine di millimetro la cifra delle decine di millimetro. 
lsl		cifra
lsl		cifra
lsl		cifra
lsl		cifra
; shifta a sinistra di 4 bit il numero delle decine di millimetro, 
; in modo tale che i quattro bit che indicano tale valore 
; (essendo una cifra, al massimo vale 9, che è esprimibile con 4 bit) 
; si posizionino correttamente sui bit 7,6,5,4.
ldi		mp,0b00001100
or		cifra,mp
; carica sul registro delle decine di millimetro, in corrispondenza dei bit 3,2,1 
; i livelli corretti per pilotare il LE delle decine di millimetro (sono attivi bassi)
out		PORTB,cifra
; manda il valore delle decine di millimetro all'ingresso del demodulatore delle decine di millimetro
ldi		ritardo,1 
; si reinizializza la variabile ritardo a 1 
ldi		mp,250
out		TCNT0,mp
ldi		mp,0b00000010
out		TCCR0,mp
; prescaler TCCR0, passo 8 (periodo del clock pari a 8 microsecondi)
; si reinizializza TCNT0 in modo che vi sia un overflow dopo 48 microsecondi.
ritardo_disattivazione_LE_decine_mm:
cpi		ritardo,0
brne	ritardo_disattivazione_LE_decine_mm ; salto condizionato a  ritardo_disattivazione_LE_centinaia 
; qualora non fosse trascorso un intervallo di tempo pari a 48 microsecondi.
in	mp,PORTB     ;legge PORTB per poi poter disattivare il LE delle decine di millimetro: 
; così la cifra viene visualizzata sul display delle decine di millimetro
ldi	mp1,0b00000010
or 	mp,mp1
out 	PORTB,mp 
;viene disabilitato il LE delle decine di millimetro: in questo modo si visualizzerà la cifra sul display delle decine di millimetro
ldi 	cifra,0 
; reinizializzazione della variabile contatore di decine di millimetro, millimetri e decimi di millimetro

conteggio_millimetri: ; inizio del ciclo condizionato del conteggio della cifra dei millimetri
cpi		spost,dieci
brlo	uscita_millimetri ; salto condizionato a uscita_millimetri 
; qualora il valore contenuto in spost fosse minore di 10
inc		cifra
subi	spost,dieci 
; conteggio della cifra dei millimetri per sottrazioni successive
cpi		spost,dieci
brsh	conteggio_millimetri ; salto condizionato a conteggio_millimetri 
; qualora il valore contenuto in spost sia maggiore o uguale a 10

uscita_millimetri: ; label per visualizzare sul display dei millimetri la cifra dei millimetri. 

lsl		cifra
lsl		cifra
lsl		cifra
lsl		cifra
; shifta a sinistra di 4 bit il numero dei millimetri, 
; in modo tale che i quattro bit che indicano tale valore 
; (essendo una cifra, al massimo vale 9, che è esprimibile con 4 bit) 
; si posizionino correttamente sui bit 7,6,5,4.
ldi		mp,0b00001010
or		cifra,mp
; scrive sul registro dei millimetri, 
; in corrispondenza dei bit 3,2,1 i livelli corretti 
; per pilotare il LE dei millimetri (sono attivi bassi)
out		PORTB,cifra
; manda il valore dei millimetri all'ingresso del demodulatore dei millimetri
ldi		ritardo,1 
; reinizializzazione della variabile ritardo a 1
ritardo_disattivazione_LE_millimetri:
cpi		ritardo,0
brne	ritardo_disattivazione_LE_millimetri ; salto condizionato a ritardo_disattivazione_LE_millimetri 
; qualora non fosse trascorso un intervallo di tempo pari a 48 microsecondi.
in	mp,PORTB     ;legge PORTB per poi poter disattivare il LE dei millimetri:
;  così la cifra verrà visualizzata sul display dei millimetri.
ldi	mp1,0b00000100
or 	mp,mp1
out 	PORTB,mp ; viene disabilitato il LE dei millimetri: 
; in questo modo viene visualizzata la cifra sul display dei millimetri.
ldi 	cifra,0 ; reinizializzazione della variabile contatore di decine di millimetri, millimetri e decimi di millimetro
ldi mp,0 ; flag per evitare che a causa del cpi in next03 
; avvenga il salto condizionato a verifica_Val.

next03:
cpi mp,1
breq verifica_Val ; salto condizionato a verifica_Val 
; qualora il contenuto in mp fosse pari a 1

conteggio_decimi_mm: ; inizio del ciclo del conteggio cifra dei decimi di millimetro
cpi		spost,uno
brlo	uscita_decimi_mm ; salto condizionato a uscita_decimi_mm 
; qualora il valore contenuto in spost fosse minore di 10
inc		cifra
subi	spost,uno 
; conteggio della cifra dei decimi di millimetro per sottrazioni successive
cpi		spost,uno
brsh	conteggio_decimi_mm ; salto condizionato a conteggio_decimi_mm 
; qualora il valore contenuto in spost sia maggiore o uguale a 1

uscita_decimi_mm: ; lable per visualizzare sul display dei decimi di millimetro la cifra dei decimi di millimetro. 

lsl		cifra
lsl		cifra
lsl		cifra
lsl		cifra
; shifta a sinistra di 4 bit il numero dei decimi di millimetro, 
; in modo tale che i quattro bit che indicano tale valore 
; (essendo una cifra, al massimo vale 9, che è esprimibile con 4 bit) 
; si posizionino correttamente sui bit 7,6,5,4.
ldi		mp,0b00000110
or		cifra,mp
; scrive sul registro dei decimi di millimetro, in corrispondenza dei bit 3,2,1 i livelli corretti 
; per pilotare il LE dei decimi di millimetro (sono attivi bassi)
out		PORTB,cifra
; manda il valore dei decimi di millimetro all'ingresso del demodulatore dei decimi di millimetro

ldi		ritardo,1 ; si reinizializza la variabile ritardo a 1
ritardo_disattivazione_LE_decimi_mm:
cpi		ritardo,0
brne	ritardo_disattivazione_LE_decimi_mm ; salto condizionato a ritardo_disattivazione_LE_decimi_mm 
; qualora non fossero trascori 48 microsecondi.
in	mp,PORTB     ;legge PORTB per poi poter disattivare il LE dei decimi di millimetro: 
; così la cifra verrà visualizzata sul display
ldi	mp1,0b00001000
or 	mp,mp1
out PORTB,mp ;viene disabilitato il LE dei decimi di millimetro: 
; in questo modo viene visualizzata la cifra sul display dei decimi di millimetro.

; terminato il conteggio delle cifre e la loro visualizzazione sui display
ldi 	cifra,0 ; reinizializzazione della variabile contatore delle decine di millimetro, millimetri e decimi di millimetro
ldi		mp,0b00000101
out		TCCR0,mp
; selezione del prescaler del TCCR0, passo 1024
ldi		mp,246
out		TCNT0,mp
; reinizializzazione TCNT0 a 246 per decremento vars (overflow di TCNT0 dopo circa 10ms)
ldi vars,6 ; reinizializzazione di vars a 6
ldi YL,0
ldi YH,0
; reinizializzazione del registro di somma Y a 0
ldi ncampioni,4
; reinizializzaizione della variabile ncampioni a 4

verifica_Val: 
cpi		vard,0x00
brne	next01 ; salto condizionato a next01 qualora non fossero trascorsi circa 2,5 secondi
ldi		vard,249 ; reinizializza vard a 249
ldi		mp,0b11100001
out		ADMUX,mp 
; reinizializza ADMUX: sente l'input da PC1 (ADC1) e giustificato a sinistra.
in		mp,ADCSRA
ldi		mp1,0b01000000
or		mp,mp1
out		ADCSRA,mp
; inizio  della conversione
verifica_conversione_terminata:
in		mp,ADCSRA
ldi		mp1,0b01000000
and		mp,mp1
brne	verifica_conversione_terminata
; aspetta che la conversione sia pronta
; testando ADSC in ADCSRA: a conversione terminata ADSC torna a 0
in		mp,ADCH
; legge il valore convertito su 8 bit
cpi		mp,soglia_al 
brlo	controllo_tensione_minore ; salto condizionato a controllo_tensione_minore qualora
; la tensione di alimentazione fosse sotto la soglia di 4,6V. 
ldi 	mp,0b00000000
out		PORTC,mp
; spegne il led rosso se la soglia è stata superata
controllo_tensione_minore:
in		mp,ADCH
cpi		mp,soglia_al
brsh	next01 ; salto condizionato a next01 qualora
; la tensione di alimentazione superi la soglia di 4,6V. 
ldi		mp,0b00000001
out		PORTC,mp
; accende il led rosso se la soglia non è stata superata

next01:
rjmp main_loop

TIM0_OVF: 
push mp
in mp,SREG
push mp
in mp,TCCR0
andi mp,0b00000111
cpi mp,0b00000101
brne temporizzazione_ritardo ; salto condizionato a temporizzazione_ritardo qualora
; TCCR0 fosse inizializzato con prescaler con passo diverso da 1024
ldi	mp,246  
out TCNT0,mp ; reinizializzazione di TCNT0
dec vars
dec vard
; decremento di vard e vars
in	mp,TCCR0
andi mp,0b00000111
cpi	mp,0b00000101
breq recupero_stack ; salto condizionato a recupero_stack 
; qualora il registro TCCR0 fosse inizializzato con prescaler con passo uguale a 1024
temporizzazione_ritardo:
ldi mp, 250
out TCNT0,mp ; reinizializzazione di TCNT0
dec ritardo
recupero_stack:
pop	mp
out	SREG,mp
pop mp
reti

table: ; lookup-table contenente i valori di spostamento che vengono associati alla media dei
; campioni acquisiti del segnale proveniente dal sensore più circuito di condizionamento.
.db 0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,6,6,6,6,7,7,7,7,8,8,8,8,9,9,9,9,10,10,10,10,11,11,11,12,12,12,12,13,13,13,13,14,14,14,14,15,15,15,15,16,16,16,16,17,17,17,17,18,18,18,18,19,19,19,19,20,20,20,20,21,21,21,21,22,22,22,22,23,23,23,24,24,24,24,25,25,25,25,26,26,26,26,27,27,27,27,28,28,28,28,29,29,29,29,30,30,30,30,31,31,31,31,32,32,32,32,33,33,33,33,34,34,34,34,35,35,35,36,36,36,36,37,37,37,37,38,38,38,38,39,39,39,39,40,40,40,40,41,41,41,41,42,42,42,42,43,43,43,43,44,44,44,44,45,45,45,45,46,46,46,46,47,47,47,48,48,48,48,49,49,49,49,50,50,50,50,51,51,51,51,52,52,52,52,53,53,53,53,54,54,54,54,55,55,55,55,56,56,56,56,57,57,57,57,58,58,58,58,59,59,59,60,60,60,60,61,61,61,61,62,62,62,62,63,63,63,63,64,64,64,64,65,65,65,65,66,66,66,66,67,67,67,67,68,68,68,68,69,69,69,69,70,70,70,70,71,71,71,71,71,72,72,72,72,73,73,73,73,73,74,74,74,74,75,75,75,75,75,76,76,76,76,77,77,77,77,77,78,78,78,78,79,79,79,79,79,80,80,80,80,81,81,81,81,81,82,82,82,82,83,83,83,83,83,84,84,84,84,85,85,85,85,85,86,86,86,86,87,87,87,87,87,88,88,88,88,89,89,89,89,89,90,90,90,90,91,91,91,91,91,92,92,92,92,93,93,93,93,93,94,94,94,94,95,95,95,95,95,96,96,96,96,97,97,97,97,97,98,98,98,98,99,99,99,99,99,100,100,100,100,101,101,101,101,101,102,102,102,102,103,103,103,103,103,104,104,104,104,105,105,105,105,105,106,106,106,106,107,107,107,107,107,108,108,108,108,109,109,109,109,109,110,110,110,110,110,111,111,111,111,111,112,112,112,112,113,113,113,113,113,114,114,114,114,115,115,115,115,115,116,116,116,116,117,117,117,117,117,118,118,118,118,119,119,119,119,119,120,120,120,120,121,121,121,121,121,122,122,122,122,123,123,123,123,123,124,124,124,124,125,125,125,125,125,126,126,126,126,127,127,127,127,127,128,128,128,128,129,129,129,129,129,130,130,130,130,131,131,131,131,131,132,132,132,132,133,133,133,133,133,134,134,134,134,135,135,135,135,135,136,136,136,136,137,137,137,137,137,138,138,138,138,139,139,139,139,139,140,140,140,140,141,141,141,141,141,142,142,142,142,143,143,143,143,143,144,144,144,144,145,145,145,145,146,146,146,146,146,147,147,147,147,148,148,148,148,148,149,149,149,149,150,150,150,150,150,151,151,151,151,152,152,152,152,152,153,153,153,153,154,154,154,154,154,155,155,155,155,156,156,156,156,156,157,157,157,157,158,158,158,158,158,159,159,159,159,159,159,160,160,160,160,160,160,160,160
