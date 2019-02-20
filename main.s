;****************** main.s ***************
; Program written by: ***Harish Rajanala and Yash Dhaduti***
; Date Created: 2/4/2017
; Last Modified: 1/18/2019
; Brief description of the program
;   The LED toggles at 2 Hz and a varying duty-cycle
; Hardware connections (External: One button and one LED)
;  PE2 is Button input  (1 means pressed, 0 means not pressed)
;  PE3 is LED output (1 activates external LED on protoboard)
;  PF4 is builtin button SW1 on Launchpad (Internal) 
;        Negative Logic (0 means pressed, 1 means not pressed)
; Overall functionality of this system is to operate like this
;   1) Make PE3 an output and make PE2 and PF4 inputs.
;   2) The system starts with the the LED toggling at 2Hz,
;      which is 2 times per second with a duty-cycle of 30%.
;      Therefore, the LED is ON for 150ms and off for 350 ms.
;   3) When the button (PE1) is pressed-and-released increase
;      the duty cycle by 20% (modulo 100%). Therefore for each
;      press-and-release the duty cycle changes from 30% to 70% to 70%
;      to 90% to 10% to 30% so on
;   4) Implement a "breathing LED" when SW1 (PF4) on the Launchpad is pressed:
;      a) Be creative and play around with what "breathing" means.
;         An example of "breathing" is most computers power LED in sleep mode
;         (e.g., https://www.youtube.com/watch?v=ZT6siXyIjvQ).
;      b) When (PF4) is released while in breathing mode, resume blinking at 2Hz.
;         The duty cycle can either match the most recent duty-
;         cycle or reset to 30%.
;      TIP: debugging the breathing LED algorithm using the real board.
; PortE device registers
GPIO_PORTE_DATA_R  EQU 0x400243FC
GPIO_PORTE_DIR_R   EQU 0x40024400
GPIO_PORTE_AFSEL_R EQU 0x40024420
GPIO_PORTE_DEN_R   EQU 0x4002451C
; PortF device registers
GPIO_PORTF_DATA_R  EQU 0x400253FC
GPIO_PORTF_DIR_R   EQU 0x40025400
GPIO_PORTF_AFSEL_R EQU 0x40025420
GPIO_PORTF_PUR_R   EQU 0x40025510
GPIO_PORTF_DEN_R   EQU 0x4002551C
GPIO_PORTF_LOCK_R  EQU 0x40025520
GPIO_PORTF_CR_R    EQU 0x40025524
GPIO_LOCK_KEY      EQU 0x4C4F434B  ; Unlocks the GPIO_CR register
SYSCTL_RCGCGPIO_R  EQU 0x400FE608
TOTAL EQU 0XFFD74F56
       IMPORT  TExaS_Init
       THUMB
       AREA    DATA, ALIGN=2
;global variables go here


       AREA    |.text|, CODE, READONLY, ALIGN=2
       THUMB
       EXPORT  Start
Start
 ; TExaS_Init sets bus clock at 80 MHz
     BL  TExaS_Init ; voltmeter, scope on PD3
	 
	LDR R0, =SYSCTL_RCGCGPIO_R
	LDR R1, [R0]
	ORR R1, #0X30
	STR R1, [R0] ; CLOCK START
	NOP
	NOP
	LDR R0, =GPIO_PORTE_DEN_R
	LDR R1, [R0]
	ORR R1, #0XC
	STR R1, [R0] ; ENABLE THE PORTS
	
	LDR R0, =GPIO_PORTE_DIR_R
	LDR R1, [R0]
	ORR R1, #0X8
	STR R1, [R0] ; OUT/IN PUT
	
	LDR R0, =GPIO_PORTF_DEN_R
	LDR R1, [R0]
	ORR R1, #0X10
	STR R1, [R0] ; ENABLE THE PORTS
	
	LDR R0, =GPIO_PORTF_DIR_R
	LDR R1, [R0]
	ORR R1, #0X0
	STR R1, [R0] ; OUT/IN PUT
	
	LDR R0, =GPIO_LOCK_KEY
	LDR R2, =GPIO_PORTF_LOCK_R
	STR R0, [R2]
	LDR R2, =GPIO_PORTF_CR_R
	MOV R1, #0X1
	STR R1, [R2]
	
	LDR R0, =GPIO_PORTE_AFSEL_R
	MOV R1, #0X0
	STR R1, [R0]
	LDR R0, =GPIO_PORTF_AFSEL_R
	MOV R1, #0X0
	STR R1, [R0]
	LDR R0, =GPIO_PORTF_PUR_R
	MOV R1, #0X10
	STR R1, [R0]
	; Initialization goes here


     CPSIE  I    ; TExaS voltmeter, scope runs on interrupts
	MOV R2, #0x0
	MOV R3, #0X0
	MOV R10, #-1
	LDR R8, =TOTAL
THANKYOU
	LDR R0, =GPIO_PORTE_DATA_R
	LDR R1, [R0]
	ORR R1, R1, #0X8
	STR R1, [R0]
	LDR R1, [R0]
	AND R6, R1, #0X4
	B NEXT; main engine goes here
	 
DELAYON
	LDR R0, =GPIO_PORTE_DATA_R
	LDR R1, [R0]
	AND R1, #0X4
	TST R1, R1
	BEQ SKIPFO
	ADD R6, R1, #0
SKIPFO 
	CMP R6, R1
	BNE NEXT
	SUBS R2, #1
	BNE DELAYON
	MOV R1, #0X0
	STR R1, [R0]
	ADD R7, R7, R8
	MUL R7, R10
DELAYOFF
		LDR R0, =GPIO_PORTE_DATA_R
		LDR R1, [R0]
		AND R1, #0X4
		TST R1, R1
		BEQ SKIPTHRE
		ADD R6, R1, #0
SKIPTHRE 
		CMP R6, R1
		BNE NEXT
		SUBS R7, #1
		BNE DELAYOFF
	B THANKYOU
	
NEXT
	CMP R6, #0
	BEQ SKIP
	ADD R3, R3, #4
SKIP 
	CMP R3, #20
	BNE SKIPTWO
	SUB R3, R3, #-20
SKIPTWO 
	LDR R7, =ARRAY
	LDR R7, [R7,R3]
	MOV R2, R7
	MOV R6, #0X0
	B DELAYON
ARRAY DCD 0XC3500, 0X145854, 0X1C7BAA, 0X249F00, 0X4100A
     ALIGN  
		 ; make sure the end of this section is aligned
     END        ; end of file

