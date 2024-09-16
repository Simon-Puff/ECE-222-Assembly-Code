;*-------------------------------------------------------------------
;* Name:    	lab_4_program.s 
;* Purpose: 	A sample style for lab-4
;* Term:		Winter 2024
; LUT
; R6 Permamently Occupied
; R11 Permamently Occupied
; R0 should be the delay counter, Permanently Occipied
;*-------------------------------------------------------------------
				THUMB 								; Declare THUMB instruction set 
				AREA 	My_code, CODE, READONLY 	; 
				EXPORT 		__MAIN 					; Label __MAIN is used externally 
                                EXPORT          EINT3_IRQHandler
				ENTRY 

__MAIN

; The following lines are similar to previous labs.
; They just turn off all LEDs 
				LDR			R10, =LED_BASE_ADR		; R10 is a  pointer to the base address for the LEDs
				MOV 		R3, #0xB0000000		; Turn off three LEDs on port 1  
				STR 		R3, [r10, #0x20]
				MOV 		R3, #0x0000007C
				STR 		R3, [R10, #0x40] 	; Turn off five LEDs on port 2 

; This line is very important in your main program
; Initializes R11 to a 16-bit non-zero value and NOTHING else can write to R11 !!
				MOV			R11, #0xABCD		; Init the random number generator with a non-zero number
ISR_RETURN
				MOV			R6, #0				; The return address will clear any important registers and reset all the IO pins again just to be safe
				
				LDR			R4, =ISER0			; Interrupt Set-Enable reg 0
				MOV			R8, #0x200000		; The 21th bit is set to 1
				STR			R8,[R4]
				
				LDR			R4, =IO2IntEnf		; Falling Edge Enable
				MOV			R8, #0x400			; bit 10 is set to 1
				STR			R8, [R4]
				
; --------------------------------------------------------------------------------------	
LOOP_BLINK 		BL 			RNG					; Get R6
				MOV 		R0,#0x3E8			; Runs the delay for 0.25 second delay
				BL			DELAY
				MOV 		R3, #0				; Turns ON LEDs on port 1  
				STR 		R3, [R10, #0x20]	
				MOV 		R3, #0
				STR 		R3, [R10, #0x40] 	; Turn ON LEDs on port 2
				MOV 		R0,#0x3E8			; Runs the delay for 0.25 second delay
				BL			DELAY	
				MOV 		R3, #0xB0000000		; Turn off three LEDs on port 1  
				STR 		R3, [r10, #0x20]
				MOV 		R3, #0x0000007C
				STR 		R3, [R10, #0x40] 	; Turn ON the left 5 LEDs on port 2
				B 			LOOP_BLINK
; ---------------------------------------------------------------------------------------
				
				
		;
		; Your main program can appear here 
		;
				
				
				
;*------------------------------------------------------------------- 
; Subroutine RNG ... Generates a pseudo-Random Number in R11 
;*------------------------------------------------------------------- 
; R11 holds a random number as per the Linear feedback shift register (Fibonacci) on WikiPedia
; R11 MUST be initialized to a non-zero 16-bit value at the start of the program
; R11 can be read anywhere in the code but must only be written to by this subroutine
RNG 			STMFD		R13!,{R1-R5, R14} 	; Random Number Generator 
				MOV			R5, #21
				AND			R1, R11, #0x8000
				AND			R2, R11, #0x2000
				LSL			R2, #2
				EOR			R3, R1, R2
				AND			R1, R11, #0x1000
				LSL			R1, #3
				EOR			R3, R3, R1
				AND			R1, R11, #0x0400
				LSL			R1, #5
				EOR			R3, R3, R1			; The new bit to go into the LSB is present
				LSR			R3, #15
				LSL			R11, #1
				ORR			R11, R11, R3
				
				SDIV 		R1, R11, R5        ; R1 = R11 / 21
				CMP 		R1, #0             ; Compare quotient to 0
				BGE			Positive
				NEG 		R1, R1              ; If negative, negate it to get abs value
Positive
				MUL 		R2, R1, R5          ; R2 = abs(quotient) * 21
				SUB 		R3, R11, R2         ; R3 = R11 - R2, which is R11 mod 21
				ADD 		R3, R3, #5          ; R3 = (R11 mod 21) + 5
				MOV 		R4, #10	            ; Move 10000 into R4
				MUL 		R6, R3, R4          ; R6 = R3 * 10
												; instead of putting into R0, we now put into R6
				
				
				LDMFD		R13!,{R1-R5, R15}



;*------------------------------------------------------------------- 
; Subroutine DELAY ... Causes a delay of 100ms * R0 times
;*------------------------------------------------------------------- 
; 		aim for better than 10% accuracy
DELAY			; this delay still produce 100mu s delay
				STMFD		R13!,{R2, R14}; only R2 and R14 preserved
Refill
				CBZ			R0, exitDelay
				SUB			R0, #1
				;MOV			R2, #1
				MOV 		R2, #0x085
LOOP
				SUBS		R2, #1
				BNE			LOOP
				BEQ			Refill
				
				
exitDelay		LDMFD		R13!,{R2, R15}

; The Interrupt Service Routine MUST be in the startup file for simulation 
;   to work correctly.  Add it where there is the label "EINT3_IRQHandler
;
;*------------------------------------------------------------------- 
; Interrupt Service Routine (ISR) for EINT3_IRQHandler 
;*------------------------------------------------------------------- 
; This ISR handles the interrupt triggered when the INT0 push-button is pressed 
; with the assumption that the interrupt activation is done in the main program
EINT3_IRQHandler 	
				STMFD		R13!,{R1, R2, R4, R5, R7, R8, R14} 		; Use this command if you need it
				
COUNT_DOWN		
				MOV            R1,#0x0			; clear every registers
                MOV            R2,#0x0
           		MOV            R5,#0x0
;DISPLAY_NUM
				BFI         R5, R6, #0, #8             ; Replace bit 0 to bit 7 (8 bits) of R5 with
                                                       		       ; bit 0 to bit 7 from R3
               	BFI         R2, R5, #0, #5             ;P2 ORDER: 2,3,4,5,6. Take the first 5 bits and store it in R2

                LSR         R5, R5, #5                 ;shifting the 5 bits that are put into R2
                BFI         R1, R5, #0, #3             ;P1 ORDER: 28,29,31. Take the MSB 3 bits and store it in R1


                RBIT         R1, R1                    ; Reverse the order of bits in R1 (P1 ORDER currently: 31,30,29)
                RBIT         R2, R2                    ; Reverse the order of the bits in R2 (P2 ORDER: 6,5,4,3,2,1)


                LSR         R1, R1, #1                 ; Shift R1 bits to the right by 1 bit (31st bit is now at 30th bit location)
                ADD         R1,#0x40000000             ; ADDS 1 to the 30th bit to brings the ("31st" bit to the 31st location)
                LSR         R2, R2, #25                ; Shift R2 bits to the right by 26 bits

                ;EOR means if the number is the same -> 0, if not the same -> 1
                EOR        R1,#0xB0000000
                EOR        R2,#0x07C                  ;0 becomes 1 and 1 becomes 0 for bit 6-2:    Register for Port 2 complete
                		

                STR         R1, [R10, #0x20]
                STR         R2, [R10, #0x40]

; Internal Delay				
				MOV		R0, #0x2710
Refill_in
				CBZ		R0, exitDelay_in
				SUB		R0, #1
				MOV 		R8, #0x085
LOOP_in
				SUBS		R8, #1
				BNE		LOOP_in
				BEQ		Refill_in
exitDelay_in
; Decrement R6
				SUB		R6, #10
				CMP		R6, #0
				BHI		COUNT_DOWN					; Branch on Lower than or Same


				LDR 	R7, =IO2IntClr
				MOV		R4, #0x400						; bit 10 is set to 1
				STR		R4, [R7]
				;B		LOOP_BLINK
				LDMFD 		R13!,{R1, R2, R4, R5, R7, R8, R15}				; Use this command if you used STMFD (otherwise use BX LR) 


;*-------------------------------------------------------------------
; Below is a list of useful registers with their respective memory addresses.
;*------------------------------------------------------------------- 
LED_BASE_ADR	EQU 	0x2009c000 		; Base address of the memory that controls the LEDs 
PINSEL3			EQU 	0x4002C00C 		; Pin Select Register 3 for P1[31:16]
PINSEL4			EQU 	0x4002C010 		; Pin Select Register 4 for P2[15:0]
FIO1DIR			EQU		0x2009C020 		; Fast Input Output Direction Register for Port 1 
FIO2DIR			EQU		0x2009C040 		; Fast Input Output Direction Register for Port 2 
FIO1SET			EQU		0x2009C038 		; Fast Input Output Set Register for Port 1 
FIO2SET			EQU		0x2009C058 		; Fast Input Output Set Register for Port 2 
FIO1CLR			EQU		0x2009C03C 		; Fast Input Output Clear Register for Port 1 
FIO2CLR			EQU		0x2009C05C 		; Fast Input Output Clear Register for Port 2 
IO2IntEnf		EQU		0x400280B4		; GPIO Interrupt Enable for port 2 Falling Edge 
ISER0			EQU		0xE000E100		; Interrupt Set-Enable Register 0 
IO2IntClr       EQU		0x400280AC
				ALIGN 

				END 
