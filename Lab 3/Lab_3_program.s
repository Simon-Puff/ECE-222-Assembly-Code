; ECE-222 Lab ... Winter 2013 term 
; Lab 3 sample code




; register LUT
; - R10 Permenant pinter to the base address for the LEDS
; - R11 Permenant occupied
; - R0  Delay Repeat times
; - R1  Store the INT0 push button
; - R8  Store the INT0 status bit, later used for a copy of the reaction time (R9)
; - R9  Reaction time counter
; - R5	Globally used for which part of R9 is displaying



				THUMB 		; Thumb instruction set 
                AREA 		My_code, CODE, READONLY
                EXPORT 		__MAIN
				ENTRY  
__MAIN

; The following lines are similar to Lab-1 but use a defined address to make it easier.
; They just turn off all LEDs 
				LDR			R10, =LED_BASE_ADR		; R10 is a permenant pointer to the base address for the LEDs, offset of 0x20 and 0x40 for the ports

				MOV 		R3, #0xB0000000		; Turn off three LEDs on port 1  
				STR 		R3, [r10, #0x20]
				MOV 		R3, #0x0000007C
				STR 		R3, [R10, #0x40] 	; Turn off five LEDs on port 2 
				
;SIMPLE_RESET
;				MOV			R1, #0
;SIMPLE_COUNTER
;				ADD			R1, #1
;				MOV			R3, R1
;				BL			DISPLAY_NUM
;				MOV			R0, #0x3E8
;				BL			DELAY
;				CMP			R1, #256
;				BNE			SIMPLE_COUNTER
;				BEQ			SIMPLE_RESET

; This line is very important in your main program
; Initializes R11 to a 16-bit non-zero value and NOTHING else can write to R11 !!
				MOV			R11, #0xABCD		; Init the random number generator with a non-zero number
				BL 			RandomNum			; Will return with R11 that contains the random number delay
				
				;MOV		R0, R11
				BL			DELAY
				
TURN_P1_29_ON	
				
				MOV			R2, #0xDFFFFFFF
				;LDR			R4, [R10]
				;EOR			R4, R4, R2
				STR			R2, [R10, #0x20]
				
				MOV			R8, #0
				MOV			R9, #0
				B			PULLING_IO
; Display the number in R3 onto the 8 LEDs
DISPLAY_NUM
                ;The reason we flip the bits, is once we refer the chart, we can notice an
                ; ascending order for port 1 and port 2, that leads to a ordering issue as
                ; our register logically was designed to be in decending order, not to mention
                ; that we have 2 different ports to manipulate, and one of them is not
                ; consecutive

                ; therefore the general logic will be we take the required bits, flip the order
                ; then push them to the correct position, modify the content inside those pins
                ; without touching the rest, since they serve for other purposes
				STMFD		R13!,{R1, R2, R5, R14}
                ; reset the registers just in case
				MOV            R1,#0x0
                MOV            R2,#0x0
                MOV            R5,#0x0
                ; we move the content inside R3 to R5, note that R3 comes from SHOW_ON_LED
                ; now R3 contains those 8 bits with LED on/off info in the LS 8 bits
                BFI         R5, R3, #0, #8             ; Replace bit 0 to bit 7 (8 bits) of R5 with
                                                       ; bit 0 to bit 7 from R3
                BFI         R2, R5, #0, #5             ;P2 ORDER: 2,3,4,5,6. Take the first 5 bits and store it in R2

                LSR         R5, R5, #5                 ;shifting the 5 bits that are put into R2
                BFI         R1, R5, #0, #3             ;P1 ORDER: 28,29,31. Take the MSB 3 bits and store it in R1


                RBIT         R1, R1                     ; Reverse the order of bits in R1 (P1 ORDER currently: 31,30,29)
                RBIT         R2, R2                     ; Reverse the order of the bits in R2 (P2 ORDER: 6,5,4,3,2,1)


                LSR         R1, R1, #1                 ; Shift R1 bits to the right by 1 bit (31st bit is now at 30th bit location)
                ADD         R1,#0x40000000            ; ADDS 1 to the 30th bit to brings the ("31st" bit to the 31st location)
                LSR         R2, R2, #25              ; Shift R2 bits to the right by 26 bits

                ;EOR means if the number is the same -> 0, if not the same -> 1
                ;EOR         R1,#0xFFFFFFFF            ;0 becomes 1 and 1 becomes 0 for bit 31,29,28:    Register for Port 1 is complete
                EOR        R1,#0xB0000000
                EOR         R2,#0x07C                  ;0 becomes 1 and 1 becomes 0 for bit 6-2:    Register for Port 2 complete
                ;EOR         R2,#0xFFFFFFFF

                STR         R1, [R10, #0x20]
                STR         R2, [R10, #0x40]
				

; Usefull commaands:  RBIT (reverse bits), BFC (bit field clear), LSR & LSL to shift bits left and right, ORR & AND and EOR for bitwise operations

				LDMFD		R13!,{R1, R2, R5, R15}

;
; R11 holds a 16-bit random number via a pseudo-random sequence as per the Linear feedback shift register (Fibonacci) on WikiPedia
; R11 holds a non-zero 16-bit number.  If a zero is fed in the pseudo-random sequence will stay stuck at 0
; Take as many bits of R11 as you need.  If you take the lowest 4 bits then you get a number between 1 and 15.
;   If you take bits 5..1 you'll get a number between 0 and 15 (assuming you right shift by 1 bit).
;
; R11 MUST be initialized to a non-zero 16-bit value at the start of the program OR ELSE!
; R11 can be read anywhere in the code but must only be written to by this subroutine
RandomNum		STMFD		R13!,{R1, R2, R3, R4, R5, R14}

				MOV			R5, #9
				AND			R1, R11, #0x8000
				AND			R2, R11, #0x2000
				LSL			R2, #2
				EOR			R3, R1, R2
				AND			R1, R11, #0x1000
				LSL			R1, #3
				EOR			R3, R3, R1
				AND			R1, R11, #0x0400
				LSL			R1, #5
				EOR			R3, R3, R1		; the new bit to go into the LSB is present
				LSR			R3, #15
				LSL			R11, #1
				ORR			R11, R11, R3
				;MOV			R11, #0x4E20
				
				
				
				SDIV 		R1, R11, R5        ; R1 = R11 / 9
				CMP 		R1, #0             ; Compare quotient to 0
				BGE			Positive
				NEG 		R1, R1              ; If negative, negate it to get abs value
Positive
				MUL 		R2, R1, R5          ; R2 = abs(quotient) * 9
				SUB 		R3, R11, R2         ; R3 = R11 - R2, which is R11 mod 9
				ADD 		R3, R3, #2          ; R3 = (R11 mod 9) + 2
				MOV 		R4, #10000          ; Move 10000 into R4
				MUL 		R0, R3, R4          ; R0 = R3 * 10000
				
				
				LDMFD		R13!,{R1, R2, R3, R4, R5, R15}

;
;		Delay 0.1ms (100us) * R0 times
; 		aim for better than 10% accuracy
;               The formula to determine the number of loop cycles is equal to Clock speed x Delay time / (#clock cycles)
;               where clock speed = 4MHz and if you use the BNE or other conditional branch command, the #clock cycles =
;               2 if you take the branch, and 1 if you don't.
;---------------------------------------------------------------------------
DELAY			
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
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
PULLING_IO
				LDR			R1, =FIO2PIN
				LDR			R1, [R1]; here we store content inside FIO2PIN
				
				LSR			R1, #10; logic shift right 10 bits since INT0 status stores in the index 10 of FIO2PIN
				BFI			R8, R1, #0, #1; We take the LSB of R1, store it into R8
				
				MOV			R0, #1; introduce 100mus delay counter
				BL			DELAY; automatic return
				
				ADD			R9, #1
				
				CMP			R8, #0
				BNE			PULLING_IO
				MOV			R8, R9
				; if not pulling IO part ends, and we are nevering going to return to this point
				; R8 now becomes the copy of R9, reaction time
;-----------------------------------------------------------------------------
RESET
				MOV			R9, R8 ; reset R9 using R8 which also means we are opearting on R9
				MOV			R5, #4 ; reset R5 as the counter for which part of the
				32 bit register is displaying
SHOW_ON_LED
				MOV			R3, #0 ; reset R3 as a storage of the 8 bit numbers
				BFI			R3, R9, #0, #8 ; move the LSB 8 bits of R9, to R3

				LSR			R9, #8 ; Logic shift right 8 bits for the use of next loop
				BL			DISPLAY_NUM ; branch to display num with the value in R3
				MOV			R0, #0x4E20; introduce a 2s delay
				BL			DELAY
				SUBS		R5, #1 ; subtract counter by 1, and also update the PSR flag
				
				BNE			SHOW_ON_LED ; if not equal to 0, it means the cycle is not done and there is more bits to dispaly
				MOV			R0, #0xC350; if BNE instruction is not passed, then it comes to here, introduce additional 5 second delay to make a total 5 second delay
				BL			DELAY
				BEQ			RESET
				
				









LED_BASE_ADR	EQU 	0x2009c000 		; Base address of the memory that controls the LEDs 
PINSEL3			EQU 	0x4002c00c 		; Address of Pin Select Register 3 for P1[31:16]
PINSEL4			EQU 	0x4002c010 		; Address of Pin Select Register 4 for P2[15:0]
FIO2PIN			EQU		0x2009c054		; Address of FIO2PIN
;	Usefull GPIO Registers
;	FIODIR  - register to set individual pins as input or output
;	FIOPIN  - register to read and write pins
;	FIOSET  - register to set I/O pins to 1 by writing a 1
;	FIOCLR  - register to clr I/O pins to 0 by writing a 1

				ALIGN 

				END 

